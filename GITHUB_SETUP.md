# 📦 GitHub Repository Setup

## ✅ Repository Information

- **Repository URL**: https://github.com/21772177/smart_finder_chatbot.git
- **Branch**: `main`
- **Status**: ✅ Initial commit pushed successfully

---

## 🔐 Authentication Setup (First Time Only)

GitHub requires authentication to push. Choose one method:

### Option 1: Personal Access Token (Recommended)

1. **Create a GitHub Personal Access Token:**
   - Go to: https://github.com/settings/tokens
   - Click "Generate new token (classic)"
   - Select scopes: `repo` (full control)
   - Copy the token

2. **Use token for authentication:**
   ```bash
   git remote set-url origin https://YOUR_TOKEN@github.com/21772177/smart_finder_chatbot.git
   ```

### Option 2: SSH Key (More Secure)

1. **Generate SSH key:**
   ```bash
   ssh-keygen -t ed25519 -C "your_email@example.com"
   ```

2. **Add to GitHub:**
   - Copy public key: `cat ~/.ssh/id_ed25519.pub`
   - Add to: https://github.com/settings/keys

3. **Use SSH URL:**
   ```bash
   git remote set-url origin git@github.com:21772177/smart_finder_chatbot.git
   ```

### Option 3: GitHub CLI

```bash
# Install GitHub CLI
sudo apt install gh  # or brew install gh on Mac

# Authenticate
gh auth login

# Then push normally
git push origin main
```

---

## 🔄 How to Update GitHub in Future

### Option 1: Quick Update Script (Easiest)

```bash
cd /home/nikhilesh/Android/Sdk/smart_finder_chatbot
./update_github.sh "Your commit message"
```

### Option 2: Manual Push

```bash
cd /home/nikhilesh/Android/Sdk/smart_finder_chatbot

# Check status
git status

# Add all changes
git add .

# Commit with descriptive message
git commit -m "Description of changes"

# Push to GitHub
git push origin main
```

---

## 📋 What's Included in Repository

### ✅ Committed Files:
- All source code (functions/, public/)
- Configuration files (firebase.json, package.json, etc.)
- Documentation (README.md, setup guides, etc.)
- Architecture and planning documents

### ❌ Excluded (via .gitignore):
- `node_modules/` - Dependencies
- `.firebase/` - Firebase cache
- `.env` files - Environment variables
- Build outputs
- IDE settings
- Log files
- Package folders (smartfinder_v3_pkce_package/, etc.)

---

## 🔐 Important Notes

### Environment Variables
**DO NOT commit sensitive data:**
- API keys
- OAuth client secrets
- Firebase service account keys
- Any `.env` files

These should be configured in Firebase Functions config:
```bash
firebase functions:config:set youtube.client_id="..."
firebase functions:config:set youtube.client_secret="..."
```

### Firebase Configuration
- `.firebaserc` is committed (contains project ID)
- `firebase.json` is committed (contains hosting/functions config)
- Actual credentials are stored in Firebase, not in repo

---

## 🚀 Deployment Workflow

1. **Make changes locally**
2. **Test changes**
3. **Commit to git**: `git add . && git commit -m "message"`
4. **Push to GitHub**: `git push origin main`
5. **Deploy to Firebase**: `firebase deploy --only functions,hosting`

---

## 📝 Commit Message Guidelines

Use descriptive commit messages:

**Good:**
- `"Add Instagram OAuth support"`
- `"Fix YouTube API error handling"`
- `"Update frontend UI for better UX"`
- `"Integrate Gemini v2 package"`

**Avoid:**
- `"Update"`
- `"Fix"`
- `"Changes"`

---

## 🔄 Syncing with Remote

If you make changes on another machine:

```bash
# Pull latest changes
git pull origin main

# If there are conflicts, resolve them, then:
git add .
git commit -m "Resolve merge conflicts"
git push origin main
```

---

## 📊 Repository Structure

```
smart_finder_chatbot/
├── functions/          # Firebase Cloud Functions
│   ├── services/      # Service modules
│   └── index.js        # Main function entry
├── public/             # Frontend files
│   └── index.html      # Main UI
├── firebase.json       # Firebase config
├── .gitignore         # Git ignore rules
├── README.md          # Project documentation
└── *.md              # Setup guides
```

---

## ✅ Current Status

- ✅ Repository initialized
- ✅ Remote configured
- ✅ Initial commit pushed
- ✅ .gitignore configured
- ✅ Ready for future updates

**All future changes should be committed and pushed to keep GitHub in sync!**

