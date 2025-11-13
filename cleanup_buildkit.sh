#!/bin/bash
# Cleanup script to remove all existing functions from Buildkit project

echo "⚠️  WARNING: This will delete ALL existing functions from Buildkit project!"
echo "Project: buildkit-1695f"
echo ""
read -p "Are you sure you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Cancelled."
    exit 0
fi

echo ""
echo "Deleting all existing functions..."

# Get list of all functions and delete them
firebase functions:list --format json | jq -r '.[] | "\(.name)"' | while read func; do
    if [ ! -z "$func" ]; then
        echo "Deleting: $func"
        firebase functions:delete "$func" --force 2>/dev/null || echo "  (Could not delete $func - may need manual deletion)"
    fi
done

echo ""
echo "✅ Cleanup complete!"
echo ""
echo "Note: Firestore data will need to be cleared manually through Firebase Console"
echo "      or you can delete collections programmatically if needed."

