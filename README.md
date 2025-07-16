# ShortVideoApp (Learning Project)

This is a personal practice project where I’m trying to build a basic version of a short-form video platform, similar to TikTok, Instagram Reels, or YouTube Shorts.

The purpose is to explore how such platforms work technically, both on the frontend (mobile interface) and backend (video handling, user management, etc.).

---

## Project Status

This is a work-in-progress project.  
It is primarily for learning and testing purposes.

---

## Features (Planned / In Progress)

- [ ] Upload short videos
- [ ] Settings
- [X] User registration and login
- [X] Store video metadata in the database
- [X] Stream uploaded videos via backend
- [X] User profiles
- [X] Likes and comments
- [X] Basic video feed
- [X] Video playback with controls

---

## Backend Stack

- Spring Boot (Java)
- PostgreSQL
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
```bash
# Ensure PostgreSQL is running and that you changed application-example.properties to application.properties with your db info
# Run the Spring Boot application
mvn spring-boot:run

# Flutter App
flutter run
