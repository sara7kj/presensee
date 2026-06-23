# 📍 PresenSee - Smart Attendance System

**PresenSee** is a comprehensive, AI-powered system designed to streamline and secure the attendance tracking process for field training and university students. Built with Flutter, it eliminates manual tracking flaws by enforcing real-time geographic and biometric validations through both a mobile application and a web portal.

---

## ✨ Key Features (Mobile App)

### 👤 For Trainees (Students)
* **Secure Check-In/Out:** Attendance is recorded only when the student is within the authorized training location using **GPS Validation**.
* **AI Face Verification:** Ensures the physical presence of the actual student to prevent proxy attendance.
* **Session Timer:** Automatically tracks the duration of the training session and notifies the user to check out.
* **Excuse Submission:** Easily submit absence excuses directly through the app.
* **Attendance History:** View past attendance records and tracked hours.

### 👨‍🏫 For Supervisors
* **Real-time Monitoring:** Track assigned students' attendance status instantly.
* **Excuse Management:** Review, approve, or reject students' submitted excuses.
* **Performance Dashboard:** Access insights into students' completed and remaining hours.

### ⚙️ For Admins (University Coordinators)
* **System Management:** Add, edit, or delete students, supervisors, and training locations.
* **Role Assignment:** Link students to their designated supervisors.
* *(Note: Admin functionalities are primarily designed as UI concepts for future scalability).*

---

## 🌐 Web Portal (Supervisor Dashboard)

In addition to the mobile application, **PresenSee** features a dedicated web platform. This portal is specifically optimized for supervisors, allowing them to manage and monitor training activities seamlessly from their desktops.

🔗 **Live Web App:** [Visit PresenSee Web Portal](https://presensee-1989d.web.app/)

**🧪 Demo Access (Supervisor Dashboard):**
Feel free to explore the supervisor functionalities using our test account:
* **Email:** `sara@psau.edu.sa`
* **Password:** `123456`

### 💻 Web Highlights:
* **Supervisor Dashboard (Fully Functional):** A comprehensive interface for supervisors to track real-time attendance, review student excuses, and monitor overall performance comfortably.
* **Admin Interface (UI Concept):** The web app includes a designed login and interface structure for the Admin role, serving as a conceptual foundation for future management integration.

---

## 🛠️ Tech Stack
* **Frontend:** [Flutter](https://flutter.dev/) (Dart) - *For both Mobile & Web*
* **Backend & Database:** Firebase (Authentication, Firestore, Storage, Hosting)
* **Core Technologies:** AI Facial Recognition, Geolocation (GPS)

---

## 📸 Screenshots

### 📱 Mobile Interfaces
<p align="center">
  <img src="https://github.com/user-attachments/assets/41e0bf71-9958-4d25-8025-09c33641e077" width="150" title="Home Page">
  <img src="https://github.com/user-attachments/assets/fbcd4130-bfcc-47a2-9890-a068d7aef560" width="150" title="Check-in Verification">
  <img src="https://github.com/user-attachments/assets/f9a46867-88f7-427b-b4d9-98e5444ee322" width="150" title="Timer">
  <img src="https://github.com/user-attachments/assets/3d46ae86-b67d-46af-bfb1-42926d5224d8" width="150" title="Sumbit Excuse">
  <img src="https://github.com/user-attachments/assets/ebf864f8-ee91-4829-b33f-4ba97019f7b6" width="150" title="Attendance History">
</p>

### 🖥️ Web Interfaces

<p align="center">
  <img src="https://github.com/user-attachments/assets/52ce153a-8657-4819-9620-df77413120dd" width="400" title="Supervisor Web Dashboard">
  <img src="https://github.com/user-attachments/assets/3ed82889-b893-406c-96ad-e7bea759ddf4" width="400" title="Students Screen">
  <img src="https://github.com/user-attachments/assets/8f71b3e4-868d-47c5-94ac-7e36fe4407b5" width="400" title="Excuses Screen">
</p>

---

## 🚀 Getting Started

To run this project locally, follow these steps:

### Prerequisites
* Install [Flutter SDK](https://docs.flutter.dev/get-started/install)
* Setup Android Studio / VS Code
* An active Firebase Project (You need to add `google-services.json` / `GoogleService-Info.plist` locally)

### Installation
1. Clone the repository:
   ```bash
   git clone [https://github.com/sara7kj/presensee.git](https://github.com/sara7kj/presensee.git)
