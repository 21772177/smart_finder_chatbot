#!/bin/bash

# Smart Finder Chatbot - GitHub Update Script
# This script helps you push changes to GitHub

cd "$(dirname "$0")"

echo "🚀 Smart Finder Chatbot - GitHub Update"
echo "========================================"
echo ""

# Check if commit message provided
if [ -z "$1" ]; then
    echo "Usage: ./update_github.sh \"Your commit message\""
    echo ""
    echo "Example: ./update_github.sh \"Add new feature\""
    exit 1
fi

COMMIT_MSG="$1"

echo "📋 Checking git status..."
git status

echo ""
echo "📦 Adding all changes..."
git add .

echo ""
echo "💾 Committing changes..."
git commit -m "$COMMIT_MSG"

echo ""
echo "🚀 Pushing to GitHub..."
echo "   (You may need to enter your GitHub credentials)"
git push origin main

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Successfully pushed to GitHub!"
    echo "   Repository: https://github.com/21772177/smart_finder_chatbot"
else
    echo ""
    echo "❌ Push failed. Common issues:"
    echo "   1. Authentication required - use GitHub Personal Access Token"
    echo "   2. Check your internet connection"
    echo "   3. Verify repository URL: git remote -v"
    echo ""
    echo "💡 To set up authentication:"
    echo "   git remote set-url origin https://YOUR_TOKEN@github.com/21772177/smart_finder_chatbot.git"
    echo "   Or use SSH: git remote set-url origin git@github.com:21772177/smart_finder_chatbot.git"
fi

