# Midterm Todo Application

A cross-platform Todo mobile application built with Flutter and BLoC state management, communicating with a containerized Node.js (Express) backend.

## Midterm Requirements Checklist
- [x] **Cross-platform Mobile App**: Built using Flutter.
- [x] **State Management**: Implemented using the BLoC pattern (`flutter_bloc`).
- [x] **Server Communication**: REST API interaction between Flutter app and backend.
- [x] **Docker Containerization**: Backend packaged with Docker & Docker Compose.
- [x] **GitHub Integration**: Source code pushed to GitHub repository.

---

## Project Structure

```text
todo_project/
├── backend/
│   ├── Dockerfile
│   ├── package.json
│   └── server.js
├── todo_app/            # Flutter mobile application
│   ├── lib/
│   │   └── main.dart    # BLoC, Repository, UI, and Model
│   └── pubspec.yaml
├── docker-compose.yml
└── README.md
```

---

## How to Run

### 1. Run Backend Server

#### Option A: Using Docker Compose (Recommended)
Ensure Docker Desktop is running, then execute:
```bash
docker compose up --build
```
The server will start at `http://localhost:3000/todos`.

#### Option B: Running Locally (Node.js)
```bash
cd backend
npm install
node server.js
```

---

### 2. Run Flutter Mobile App

1. Navigate to the app directory:
   ```bash
   cd todo_app
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Launch the application:
   ```bash
   flutter run -d chrome
   ```
   *(Or target `windows`, `android`, or `ios` depending on your environment).*