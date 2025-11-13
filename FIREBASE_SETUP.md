# Firebase Setup Instructions

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project" or select an existing project
3. Follow the setup wizard
4. Enable the following services:
   - **Firestore Database** (for storing chat sessions)
   - **Cloud Functions** (for backend API)
   - **Hosting** (for frontend deployment)
   - **Authentication** (optional, for user accounts)

## Step 2: Configure Firebase

1. In Firebase Console, go to **Project Settings** (gear icon)
2. Scroll down to "Your apps" section
3. Click the web icon (`</>`) to add a web app
4. Register your app and copy the configuration object

## Step 3: Update Firebase Configuration

1. Open `public/firebase-config.js`
2. Replace the placeholder values with your actual Firebase config:

```javascript
const firebaseConfig = {
  apiKey: "YOUR_API_KEY",
  authDomain: "YOUR_PROJECT_ID.firebaseapp.com",
  projectId: "YOUR_PROJECT_ID",
  storageBucket: "YOUR_PROJECT_ID.appspot.com",
  messagingSenderId: "YOUR_MESSAGING_SENDER_ID",
  appId: "YOUR_APP_ID"
};
```

## Step 4: Install Dependencies

### Install Firebase CLI (if not already installed)
```bash
npm install -g firebase-tools
```

### Login to Firebase
```bash
firebase login
```

### Install project dependencies

For the root project:
```bash
npm install
```

For Firebase Functions:
```bash
cd functions
npm install
cd ..
```

For the frontend:
```bash
cd public
npm install
cd ..
```

## Step 5: Initialize Firebase in Your Project

```bash
firebase init
```

Select:
- ✅ Firestore
- ✅ Functions
- ✅ Hosting

When prompted:
- Use an existing project (select your Firebase project)
- For Firestore rules, use `firestore.rules`
- For Functions, use `functions` directory
- For Hosting, use `public` directory

## Step 6: Deploy Firestore Rules

```bash
firebase deploy --only firestore:rules
```

## Step 7: Deploy Functions

```bash
firebase deploy --only functions
```

## Step 8: Run Locally (Development)

### Option 1: Run with Firebase Emulators
```bash
firebase emulators:start
```

### Option 2: Run frontend separately
```bash
cd public
npm run dev
```

The frontend will run on `http://localhost:3000`

## Step 9: Deploy to Firebase Hosting

```bash
# Build the frontend first
cd public
npm run build
cd ..

# Deploy everything
firebase deploy
```

Or deploy individually:
```bash
firebase deploy --only hosting
firebase deploy --only functions
```

## Testing the Chatbot

1. Start the development server or deploy to Firebase
2. Open the chatbot in your browser
3. Try these example queries:
   - "Where can we eat here North Indian?"
   - "Recall my last visit"
   - "Find Goa travel reels I saved last month"

## Troubleshooting

### Functions not working
- Make sure you've deployed functions: `firebase deploy --only functions`
- Check Firebase Console > Functions for any errors
- Verify your Firebase config in `public/firebase-config.js`

### Firestore permission errors
- Check `firestore.rules` file
- Make sure rules are deployed: `firebase deploy --only firestore:rules`

### CORS errors
- The functions already include CORS configuration
- If issues persist, check Firebase Console > Functions > Configuration

## Next Steps

1. **Add OpenAI Integration**: Replace the simple intent parser with OpenAI API for better NLU
2. **Add Google Places API**: Integrate real Google Places API for nearby search
3. **Add Google Timeline API**: Integrate for real location recall
4. **Add Social Media APIs**: Integrate YouTube, Instagram APIs for saved content
5. **Add Authentication**: Enable Firebase Auth for user accounts

## Environment Variables (Optional)

For production, you can use Firebase Functions environment variables:

```bash
firebase functions:config:set openai.key="YOUR_OPENAI_KEY"
firebase functions:config:set google.places.key="YOUR_GOOGLE_PLACES_KEY"
```

Then access in `functions/index.js`:
```javascript
const openaiKey = functions.config().openai.key;
```

