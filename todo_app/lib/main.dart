import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:equatable/equatable.dart';

// --- 1. MODEL ---
class Todo extends Equatable {
  final int id;
  final String title;
  final bool completed;

  const Todo({required this.id, required this.title, required this.completed});

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'],
      title: json['title'],
      completed: json['completed'] ?? false,
    );
  }

  @override
  List<Object?> get props => [id, title, completed];
}

// --- 2. REPOSITORY ---
class TodoRepository {
  // Для Chrome / Windows app / iOS: 'http://localhost:3000/todos'
  // Для Android Emulator: 'http://10.0.2.2:3000/todos'
  static const String baseUrl = 'http://localhost:3000/todos';

  Future<List<Todo>> fetchTodos() async {
    final response = await http.get(Uri.parse(baseUrl));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Todo.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load todos');
    }
  }

  Future<Todo> addTodo(String title) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'title': title}),
    );
    if (response.statusCode == 201) {
      return Todo.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to add todo');
    }
  }

  Future<void> deleteTodo(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/$id'));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete todo');
    }
  }
}

// --- 3. EVENTS & STATES ---
abstract class TodoEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadTodosEvent extends TodoEvent {}

class AddTodoEvent extends TodoEvent {
  final String title;
  AddTodoEvent(this.title);

  @override
  List<Object?> get props => [title];
}

class DeleteTodoEvent extends TodoEvent {
  final int id;
  DeleteTodoEvent(this.id);

  @override
  List<Object?> get props => [id];
}

abstract class TodoState extends Equatable {
  @override
  List<Object?> get props => [];
}

class TodoLoadingState extends TodoState {}

class TodoLoadedState extends TodoState {
  final List<Todo> todos;
  TodoLoadedState(this.todos);

  @override
  List<Object?> get props => [todos];
}

class TodoErrorState extends TodoState {
  final String message;
  TodoErrorState(this.message);

  @override
  List<Object?> get props => [message];
}

// --- 4. BLOC ---
class TodoBloc extends Bloc<TodoEvent, TodoState> {
  final TodoRepository repository;

  TodoBloc(this.repository) : super(TodoLoadingState()) {
    on<LoadTodosEvent>((event, emit) async {
      emit(TodoLoadingState());
      try {
        final todos = await repository.fetchTodos();
        emit(TodoLoadedState(todos));
      } catch (e) {
        emit(TodoErrorState(e.toString()));
      }
    });

    on<AddTodoEvent>((event, emit) async {
      try {
        await repository.addTodo(event.title);
        add(LoadTodosEvent());
      } catch (e) {
        emit(TodoErrorState(e.toString()));
      }
    });

    on<DeleteTodoEvent>((event, emit) async {
      try {
        await repository.deleteTodo(event.id);
        add(LoadTodosEvent());
      } catch (e) {
        emit(TodoErrorState(e.toString()));
      }
    });
  }
}

// --- 5. UI ---
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: RepositoryProvider(
        create: (context) => TodoRepository(),
        child: BlocProvider(
          create: (context) => TodoBloc(context.read<TodoRepository>())..add(LoadTodosEvent()),
          child: const TodoScreen(),
        ),
      ),
    );
  }
}

class TodoScreen extends StatelessWidget {
  const TodoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('Todo List (BLoC + Server)')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: textController,
                    decoration: const InputDecoration(labelText: 'New Task'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    if (textController.text.isNotEmpty) {
                      context.read<TodoBloc>().add(AddTodoEvent(textController.text));
                      textController.clear();
                    }
                  },
                )
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<TodoBloc, TodoState>(
              builder: (context, state) {
                if (state is TodoLoadingState) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is TodoLoadedState) {
                  return ListView.builder(
                    itemCount: state.todos.length,
                    itemBuilder: (context, index) {
                      final item = state.todos[index];
                      return ListTile(
                        title: Text(item.title),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            context.read<TodoBloc>().add(DeleteTodoEvent(item.id));
                          },
                        ),
                      );
                    },
                  );
                } else if (state is TodoErrorState) {
                  return Center(child: Text('Error: ${state.message}'));
                }
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }
}