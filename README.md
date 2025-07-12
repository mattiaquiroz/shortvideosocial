# ShortVideoApp (Learning Project)

This is a personal practice project where I’m trying to build a basic version of a short-form video platform, similar to TikTok, Instagram Reels, or YouTube Shorts.

The purpose is to explore how such platforms work technically, both on the frontend (mobile interface) and backend (video handling, user management, etc.).

---

## Project Status

This is a work-in-progress project.  
It is primarily for learning and testing purposes.

Technologies I'm working with:
- Spring Boot (backend)
- PostgreSQL (database)
- Local file system for video storage
- Flutter (mobile app)

---

## Features (Planned / In Progress)

- [ ] User registration and login
- [ ] Upload short videos
- [ ] Store video metadata in the database
- [ ] Stream uploaded videos via backend
- [ ] User profiles
- [ ] Likes and comments
- [ ] Basic video feed
- [ ] Video playback with controls
- [ ] Mobile UI using Flutter

---

## Backend Stack

- Spring Boot (Java)
- PostgreSQL (running locally)
- Maven for dependency management
- Local file system used for storing video files

---

## Mobile App Stack

- Flutter for cross-platform development
- HTTP communication using the `http` package
- File picker integration for video upload
- Basic UI for testing core features

---

## How to Run Locally

### Backend
# Ensure PostgreSQL is running
# Run the Spring Boot application
mvn spring-boot:run

### Flutter App
flutter run
