#!/bin/bash
# Delete all existing functions from Buildkit project

echo "Deleting all existing functions from Buildkit project..."
echo ""

# List of all functions to delete
functions=(
    "approveTestCase"
    "approveTestCaseCallable"
    "getAvailableTests"
    "getCompanyTestCases"
    "getCompanyTests"
    "getCompanyTestsCallable"
    "getPaymentStatus"
    "getPendingTestCases"
    "getTransactionHistory"
    "getTransactionHistoryCallable"
    "getWalletBalance"
    "getWalletBalanceCallable"
    "initiateUPIPayout"
    "initiateUPIPayoutCallable"
    "paymentCallback"
    "processPayout"
    "rejectTestCase"
    "rejectTestCaseCallable"
    "seedTestUsers"
    "setUserRoleAndProfile"
    "startTestSession"
    "startTestSessionCallable"
    "submitTest"
    "submitTestCallable"
    "submitTestCase"
    "submitTestCaseCallable"
    "updateUPIID"
    "validateTest"
    "validateTestCallable"
)

deleted=0
failed=0

for func in "${functions[@]}"; do
    echo -n "Deleting $func... "
    if firebase functions:delete "$func" --force 2>/dev/null; then
        echo "✅"
        ((deleted++))
    else
        echo "❌ (may not exist or already deleted)"
        ((failed++))
    fi
done

echo ""
echo "Summary:"
echo "  Deleted: $deleted"
echo "  Failed: $failed"
echo ""
echo "✅ Function cleanup complete!"
echo ""
echo "Next steps:"
echo "  1. Deploy chatbot functions: firebase deploy --only functions"
echo "  2. Deploy hosting: firebase deploy --only hosting"
echo "  3. Deploy Firestore rules: firebase deploy --only firestore:rules"

