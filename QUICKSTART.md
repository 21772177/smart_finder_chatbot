# Quick Start Guide

## Prerequisites

- Node.js 18+ installed
- Firebase account
- Firebase CLI installed: `npm install -g firebase-tools`

## Setup Steps

### 1. Install Dependencies

```bash
# Install root dependencies
npm install

# Install Firebase Functions dependencies
cd functions
npm install
cd ..

# Install frontend dependencies
cd public
npm install
cd ..
```

### 2. Configure Firebase

1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Enable Firestore Database
3. Enable Cloud Functions
4. Enable Hosting
5. Copy your Firebase config from Project Settings
6. Update `public/firebase-config.js` with your config values

### 3. Initialize Firebase

```bash
firebase login
firebase init
```

Select:
- Firestore
- Functions  
- Hosting

### 4. Run Locally

**Option A: Using Firebase Emulators (Recommended for development)**

```bash
firebase emulators:start
```

Then open: `http://localhost:4000` (Firebase UI) or `http://localhost:5000` (Hosting)

**Option B: Run Frontend Separately (with Firebase Emulators)**

```bash
# Start only functions emulator
firebase emulators:start --only functions,hosting
```

Open: `http://localhost:5000` (Hosting emulator)

**Note:** The frontend is vanilla JavaScript (no build step needed). For production, just deploy directly to Firebase Hosting.

### 5. Deploy to Firebase

```bash
# Deploy everything (no build needed for vanilla JS frontend)
firebase deploy

# Or deploy individually:
firebase deploy --only functions
firebase deploy --only hosting
firebase deploy --only firestore:rules
```

## Testing the Chatbot

Once running, try these queries:
- "Where can we eat here North Indian?"
- "Recall my last visit"
- "Find Goa travel reels I saved last month"

## Project Structure

```
smart_finder_chatbot/
├── functions/          # Firebase Cloud Functions (Backend API)
│   ├── index.js       # Main API endpoints
│   └── package.json
├── public/            # Frontend (Vanilla JS)
│   ├── index.html     # Main chatbot UI (single file)
│   ├── firebase-config.js  # Firebase config (optional, not used in vanilla version)
│   └── src/           # React version (optional, not used)
│       ├── App.jsx
│       └── App.css
├── firebase.json      # Firebase configuration
├── firestore.rules    # Firestore security rules
└── FIREBASE_SETUP.md  # Detailed setup instructions
```

## Troubleshooting

### Functions not working
- Make sure functions are deployed: `firebase deploy --only functions`
- Check Firebase Console > Functions for errors
- Verify Firebase config in `public/firebase-config.js`

### CORS errors
- Functions already include CORS configuration
- Check that functions are deployed correctly

### Frontend build errors
- Make sure all dependencies are installed: `cd public && npm install`
- Check Node.js version (should be 18+)

## Next Steps

1. Add OpenAI integration for better NLU
2. Integrate Google Places API for real nearby search
3. Add Google Timeline API for location recall
4. Integrate social media APIs (YouTube, Instagram)

