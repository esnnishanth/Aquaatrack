<div align="center">
  <img src="https://github.com/user-attachments/assets/469ddb76-9b4f-47d8-bcb7-5397bdff5bcd" width="150"/>
  <img src="https://github.com/user-attachments/assets/7fbf64f3-ebef-4bbe-b7f3-a24fc7d2781a" width="150"/>
  <img src="https://github.com/user-attachments/assets/95692c4d-70ea-4a55-b8ec-b815ae48c0f0" width="150"/>
  <img src="https://github.com/user-attachments/assets/1304d6c6-bf85-4790-96cb-0a031d474220" width="150"/>
  <img src="https://github.com/user-attachments/assets/a43ef59b-8744-4efd-8adf-1f7f15eacb33" width="150"/>
  <img src="https://github.com/user-attachments/assets/982c40fe-aa15-448e-b09d-2c235bc287f2" width="150"/>
</div>

# AquaTrack

Water bore management system — Flutter mobile app + Express/MongoDB API.

## Project Structure

```
aquatrack/
├── api/              # Vercel serverless entry point
├── server/           # Express API (routes, models, helpers)
│   ├── models/       # Mongoose schemas
│   ├── routes/       # API route handlers
│   └── views/        # EJS admin dashboard
├── mobile_app/       # Flutter cross-platform app
└── AGENTS.md         # Vercel deploy notes
```

## Features

- **Multi-role auth**: Owner, Manager, Agent, Worker — Google Sign-In + email OTP
- **Bore management**: Track bores, owners, agents, workers, pipe stock
- **OCR bill scanning**: Snap a bore bill — Gemini extracts water charges, meter readings & pipe details
- **Finance**: Labour payments, normal expenses, pipe stock tracking, PDF report generation
- **Admin dashboard**: EJS-based web dashboard at `/admin`
- **Serverless-ready**: Deploy on Vercel as a single serverless function

## Prerequisites

- Node.js 18+
- Flutter SDK 3.10+
- MongoDB Atlas (or local MongoDB)
- Google Cloud Console project (for Sign-In & Gemini API)
- Gmail app password (for email OTP)

## Setup

### 1. Clone & install backend
```bash
git clone <repo-url>
cd aquatrack
npm install
cd server && npm install && cd ..
```

### 2. Environment variables
Copy the following into `.env` at the project root:

```env
MONGO_URI="mongodb+srv://<user>:<pass>@cluster.mongodb.net/aquatrack"
EMAIL_USER=your.email@gmail.com
EMAIL_PASS="your-gmail-app-password"
GOOGLE_CLIENT_ID_ANDROID="..."
GOOGLE_CLIENT_ID_WEB="..."
GOOGLE_CLIENT_SECRET="..."
GROQ_API_KEY="..."       # used for OCR (Gemini via Groq)
```

### 3. Run backend locally
```bash
npm run dev
# Server starts on http://localhost:9000
```

### 4. Run Flutter app
```bash
cd mobile_app
flutter pub get
flutter run
```

## API Endpoints

| Endpoint            | Method | Description            |
|---------------------|--------|------------------------|
| `/api/auth`         | POST   | Sign in / sign up      |
| `/api/send-otp`     | POST   | Send email OTP         |
| `/api/verify-otp`   | POST   | Verify email OTP       |
| `/api/owners`       | GET    | List owners            |
| `/api/managers`     | GET    | List managers          |
| `/api/ocr`          | POST   | Scan bore bill (image) |
| `/admin`            | GET    | Admin dashboard        |
| `/api/health`       | GET    | Health check           |

## Deploy to Vercel

```bash
npx vercel deploy --prod --force --yes
```

> See [AGENTS.md](AGENTS.md) for Vercel-specific notes and SSO protection.

## Tech Stack

| Layer      | Technology                        |
|-----------|-----------------------------------|
| Mobile    | Flutter, Dart, Provider           |
| Backend   | Node.js, Express                  |
| Database  | MongoDB, Mongoose                 |
| Auth      | Google Sign-In, JWT, Email OTP    |
| OCR       | Google Gemini AI                  |
| PDF       | pdf, printing (Flutter)           |
| Hosting   | Vercel (serverless)               |
