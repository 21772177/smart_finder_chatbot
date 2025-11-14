# ✅ Testing Checklist

## 📋 Round 1 Test Users

1. **nikhilshingane@gmail.com**
2. **shinganenikhil842@gmail.com**
3. **ruchitamamulkar@gmail.com**
4. **savitashingane63@gmail.com**

---

## 🔍 Test Scenarios

### Test 1: OAuth Connection

**For each user, test:**

- [ ] **YouTube Connection**
  - Click "Connect YouTube"
  - Complete OAuth flow
  - Should see success message
  - No "App not verified" error (if test user added)

- [ ] **Instagram Connection**
  - Click "Connect Instagram"
  - Complete OAuth flow
  - Should see success message

- [ ] **Facebook Connection**
  - Click "Connect Facebook"
  - Complete OAuth flow
  - Should see success message

- [ ] **Google Connection**
  - Click "Connect Google"
  - Complete OAuth flow
  - Should see success message
  - No "App not verified" error (if test user added)

---

### Test 2: Content Sync

**After connecting platforms:**

- [ ] **Background Sync**
  - Wait 30-60 seconds after connection
  - Check browser console for sync status
  - Should see "Syncing..." messages (in console, not UI)
  - Should complete without errors

- [ ] **Sync Verification**
  - Check Firestore database
  - Verify content is indexed
  - Verify embeddings are created

---

### Test 3: Chatbot Queries

**Test these queries for each user:**

#### YouTube Queries:
- [ ] "Show me my saved YouTube videos"
- [ ] "What playlists did I create?"
- [ ] "Find my liked videos"
- [ ] "Show me my watch later list"
- [ ] "What videos did I save?"

#### Instagram Queries:
- [ ] "Show me my saved Instagram posts"
- [ ] "What reels did I save?"
- [ ] "Find my Instagram media"
- [ ] "Show my Instagram content"

#### Facebook Queries:
- [ ] "Show me my saved Facebook posts"
- [ ] "What did I save on Facebook?"
- [ ] "Find my Facebook saved items"

#### Google/Places Queries:
- [ ] "Show nearby places I visited"
- [ ] "Where did I go recently?"
- [ ] "Find places near me"
- [ ] "Show my location history"

#### Mixed Queries:
- [ ] "Show me all my saved content"
- [ ] "What did I save across all platforms?"
- [ ] "Find content about [topic]"

---

### Test 4: Error Handling

**Test error scenarios:**

- [ ] **Invalid Query**
  - Ask: "asdfghjkl"
  - Should handle gracefully
  - Should provide helpful response

- [ ] **Platform Not Connected**
  - Disconnect a platform
  - Ask about that platform
  - Should suggest connecting

- [ ] **Network Error**
  - Disconnect internet
  - Try query
  - Should handle gracefully

---

### Test 5: User Experience

**Check UX:**

- [ ] **UI Responsiveness**
  - Buttons respond quickly
  - No lag or freezing
  - Smooth animations

- [ ] **Messages**
  - No sync messages visible on UI
  - Background sync is silent
  - Only user queries show responses

- [ ] **OAuth Flow**
  - Popup opens correctly
  - OAuth completes smoothly
  - Tokens received properly
  - No errors in console

---

## 📊 Test Results Template

### User: [Email]

**Date:** [Date]

**OAuth Connections:**
- YouTube: ✅ / ❌ (Notes: ________)
- Instagram: ✅ / ❌ (Notes: ________)
- Facebook: ✅ / ❌ (Notes: ________)
- Google: ✅ / ❌ (Notes: ________)

**Content Sync:**
- Status: ✅ / ❌
- Time taken: ________ seconds
- Errors: ________

**Queries Tested:**
- Query 1: ✅ / ❌ (Response: ________)
- Query 2: ✅ / ❌ (Response: ________)
- Query 3: ✅ / ❌ (Response: ________)

**Issues Found:**
1. ________
2. ________
3. ________

**Overall Status:** ✅ Pass / ❌ Fail

---

## 🐛 Common Issues & Solutions

### Issue: "App not verified" error
**Solution:** Make sure test user email is added to Google OAuth test users list

### Issue: OAuth popup doesn't close
**Solution:** Check browser console for errors, verify postMessage is working

### Issue: Content not syncing
**Solution:** Check Firebase Functions logs, verify API keys are set

### Issue: Queries return "No results"
**Solution:** Verify content sync completed, check Firestore for indexed content

### Issue: Instagram asking for login
**Solution:** This is normal - Instagram OAuth requires login

---

## ✅ Testing Completion Criteria

**All tests pass when:**
- ✅ All 4 users can connect all platforms
- ✅ All OAuth flows complete successfully
- ✅ Content syncs for all users
- ✅ Queries return accurate results
- ✅ No critical errors
- ✅ User experience is smooth

**Then:**
- ✅ Ready for Round 2 testing
- ✅ Or ready for production (if all good)

---

## 📝 Notes

**Document any:**
- Unexpected behavior
- Performance issues
- UI/UX improvements needed
- Feature requests
- Bugs found

**Share results with me for fixes!**

