# ✅ Add Test Users for Testing Phase

## 🎯 Current Test Users (Round 1)

Add these 4 emails to Google OAuth test users:

1. `nikhilshingane@gmail.com`
2. `shinganenikhil842@gmail.com`
3. `ruchitamamulkar@gmail.com`
4. `savitashingane63@gmail.com`

---

## 📋 Step-by-Step: Add Test Users

### Step 1: Go to OAuth Consent Screen

**URL:**
```
https://console.cloud.google.com/apis/credentials/consent?project=buildkit-1695f
```

**OR navigate:**
- Google Cloud Console → Select project `buildkit-1695f`
- APIs & Services → OAuth consent screen

---

### Step 2: Find "Test users" Section

**Look for:**
- Section titled **"Test users"**
- Should be on the same page as app configuration
- If you're on OAuth Overview, click "Settings" or navigate to consent screen

---

### Step 3: Add Users

1. **Scroll down** to "Test users" section
2. **Click:** "+ ADD USERS" button
3. **Paste all emails** (one per line or comma-separated):
   ```
   nikhilshingane@gmail.com
   shinganenikhil842@gmail.com
   ruchitamamulkar@gmail.com
   savitashingane63@gmail.com
   ```
4. **Click:** "ADD" or "SAVE"

---

### Step 4: Verify

**You should see:**
- All 4 emails listed under "Test users"
- Status showing they're added

---

## ✅ What Happens After Adding

**For test users:**
- ✅ They can use the chatbot without "App not verified" warning
- ✅ They can connect YouTube, Google, Instagram, Facebook
- ✅ They'll see "This app is in testing mode" (normal for test phase)
- ✅ They can proceed with "Continue" button

**For non-test users:**
- ❌ They'll see "App not verified" warning
- ❌ They can't use the app (by design in testing mode)

---

## 📝 Adding More Test Users Later

**When you provide 5-10 more emails:**

1. Go to same "Test users" section
2. Click "+ ADD USERS"
3. Add all new emails
4. Save

**I'll create a script to help you add them quickly!**

---

## 🎯 Testing Checklist

**After adding test users, test:**

- [ ] User 1 can connect YouTube
- [ ] User 1 can connect Instagram
- [ ] User 1 can connect Facebook
- [ ] User 1 can connect Google
- [ ] User 1 can query chatbot
- [ ] User 2 can connect all platforms
- [ ] User 3 can connect all platforms
- [ ] User 4 can connect all platforms
- [ ] All users can sync content
- [ ] All users can query saved content

---

## ⚠️ Important Notes

**Testing Mode:**
- ✅ Perfect for development and testing
- ✅ Only test users can access
- ✅ No Google verification needed
- ✅ Can add up to 100 test users

**Production Mode:**
- ⏸️ Hold off until testing is complete
- ⏸️ Requires Google verification
- ⏸️ Takes 1-2 weeks for approval
- ⏸️ We'll do this after testing phase

---

## 🔗 Quick Links

**OAuth Consent Screen:**
```
https://console.cloud.google.com/apis/credentials/consent?project=buildkit-1695f
```

**Test Users Section:**
- Scroll down on consent screen page
- Look for "Test users" heading

---

## ✅ Confirmation

**This approach is perfect!**

- ✅ Testing phase first = Smart approach
- ✅ Adding test users = Works immediately
- ✅ Testing thoroughly = Catch issues early
- ✅ Production later = Smooth launch

**You're all set! Add the 4 emails and start testing!**

