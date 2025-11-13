# Cleanup Instructions for Buildkit Project

## Current State
The Buildkit project (`buildkit-1695f`) currently has:
- **26 existing Cloud Functions** (test cases, payments, etc.)
- **1 Firestore database** (default)

## Cleanup Options

### Option 1: Delete All Functions (Recommended)
This will remove all existing functions so we can deploy the chatbot fresh.

```bash
# Delete all functions one by one
firebase functions:delete approveTestCase --force
firebase functions:delete approveTestCaseCallable --force
firebase functions:delete getAvailableTests --force
firebase functions:delete getCompanyTestCases --force
firebase functions:delete getCompanyTests --force
firebase functions:delete getCompanyTestsCallable --force
firebase functions:delete getPaymentStatus --force
firebase functions:delete getPendingTestCases --force
firebase functions:delete getTransactionHistory --force
firebase functions:delete getTransactionHistoryCallable --force
firebase functions:delete getWalletBalance --force
firebase functions:delete getWalletBalanceCallable --force
firebase functions:delete initiateUPIPayout --force
firebase functions:delete initiateUPIPayoutCallable --force
firebase functions:delete paymentCallback --force
firebase functions:delete processPayout --force
firebase functions:delete rejectTestCase --force
firebase functions:delete rejectTestCaseCallable --force
firebase functions:delete seedTestUsers --force
firebase functions:delete setUserRoleAndProfile --force
firebase functions:delete startTestSession --force
firebase functions:delete startTestSessionCallable --force
firebase functions:delete submitTest --force
firebase functions:delete submitTestCallable --force
firebase functions:delete submitTestCase --force
firebase functions:delete submitTestCaseCallable --force
firebase functions:delete updateUPIID --force
firebase functions:delete validateTest --force
firebase functions:delete validateTestCallable --force
```

### Option 2: Use the Cleanup Script
```bash
./cleanup_buildkit.sh
```

### Option 3: Manual Deletion via Firebase Console
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select project: **Buildkit**
3. Go to **Functions** section
4. Delete each function manually

## Firestore Data Cleanup

### Option 1: Delete via Firebase Console (Recommended)
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select project: **Buildkit**
3. Go to **Firestore Database**
4. Delete collections manually or use the console's delete option

### Option 2: Keep Firestore (Recommended for Smart Finder)
The chatbot will use its own collections:
- `sessions`
- `messages`
- `content_index`
- `users`

These won't conflict with existing data, so you can keep the existing Firestore data if you want.

## After Cleanup

Once functions are deleted, you can deploy the chatbot:

```bash
# Deploy functions
firebase deploy --only functions

# Deploy hosting
firebase deploy --only hosting

# Deploy Firestore rules
firebase deploy --only firestore:rules
```

## Quick Start (Fresh Setup)

If you want to start completely fresh:

1. **Delete all functions** (use script above)
2. **Initialize Firebase services**:
   ```bash
   firebase init
   ```
   Select:
   - ✅ Firestore (use existing database)
   - ✅ Functions (yes, overwrite)
   - ✅ Hosting (yes, overwrite)
3. **Deploy**:
   ```bash
   firebase deploy
   ```

## Important Notes

⚠️ **Warning**: 
- Deleting functions is **permanent** and cannot be undone
- Make sure you have backups if you need the old functions
- Firestore data deletion is also **permanent**

✅ **Safe to Keep**:
- Firestore database structure (collections won't conflict)
- Hosting configuration (can be overwritten)

