# SevaPulse

A full-stack hospital/healthcare management platform connecting patients and doctors — appointment booking, prescriptions, medicine tracking, health feed, and real-time notifications, built with a Flutter mobile app and a Node.js/Express backend.

## Features

- **Multi-Role Access** – Separate flows for patients (Users) and Doctors
- **Appointment Booking** – Browse doctors by specialty, book and manage appointments
- **Prescriptions** – Doctors issue prescriptions; patients view and track them
- **Medicine Tracking** – Manage and track prescribed medicines
- **Health Feed** – Health tips and awareness content
- **Canteen Menu** – Hospital canteen ordering/browsing
- **Real-Time Notifications** – Push and in-app notifications via WebSockets
- **Billing** – Bill generation and tracking
- **Chatbot** – In-app health assistant chatbot
- **Government Schemes** – Info on relevant healthcare schemes

## Tech Stack

**Frontend** (`Frontend/`)
- Flutter (Dart)
- Provider (state management — Auth, Appointment, Medicine, Notification, Prescription, Theme providers)
- Socket.io client (real-time updates)
- Local notifications

**Backend** (`seva-pulse-backend/`)
- Node.js
- Express.js
- MongoDB (Mongoose)
- Socket.io (WebSocket service for real-time notifications)
- Multer (file uploads — prescriptions)

## Getting Started

### Prerequisites
- Node.js (v16+)
- MongoDB (local or Atlas)
- Flutter SDK

### Backend Setup

\`\`\`bash
cd seva-pulse-backend
npm install
\`\`\`

Create a `.env` file in `seva-pulse-backend/`:

\`\`\`
MONGO_URI=your_mongodb_connection_string
PORT=5000
JWT_SECRET=your_jwt_secret
\`\`\`

Run the backend:

\`\`\`bash
node server.js
\`\`\`

### Frontend Setup

\`\`\`bash
cd Frontend
flutter pub get
flutter run
\`\`\`

Update the API base URL in `Frontend/lib/core/constants/api_constants.dart` to point to your backend.

## Project Structure

\`\`\`
Sevapulse/
├── Frontend/                  # Flutter mobile app
│   └── lib/
│       ├── core/               # Constants, services, theme, utils
│       ├── data/                 # Models & providers
│       ├── features/              # Auth, Doctor, User screens
│       └── presentation/           # Shared widgets
└── seva-pulse-backend/        # Express backend
    ├── src/
    │   ├── config/              # DB config
    │   ├── controllers/          # Route logic
    │   ├── middleware/            # Auth, validation, error handling
    │   ├── models/                 # Mongoose schemas
    │   ├── routes/                  # API routes
    │   └── services/                  # Notifications, WebSocket
    └── uploads/                # Prescription file uploads
\`\`\`

## Roles

- **Patient (User)** – Book appointments, view prescriptions, track medicines, browse health feed
- **Doctor** – Manage patients, events, appointments, and prescriptions

## Future Improvements

- Payment integration for bill settlement
- Video consultation support
- Multi-language support for health content

## Author

Kedar — MERN + Flutter Developer
