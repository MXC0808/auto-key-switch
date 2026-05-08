#!/bin/bash
# E2E Test Runner for AutoKeySwitch Punctuation Feature
# Prerequisites:
#   1. AutoKeySwitch app is running
#   2. Accessibility permission granted
#   3. "Force English Punctuation" feature is enabled
#   4. Chinese input method is available

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RESULTS=()
PASSED=0
FAILED=0

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_pass() { echo -e "${GREEN}PASS${NC}: $1"; ((PASSED++)); }
log_fail() { echo -e "${RED}FAIL${NC}: $1"; ((FAILED++)); }
log_info() { echo -e "${YELLOW}INFO${NC}: $1"; }

# Check prerequisites
log_info "Checking prerequisites..."

# Check if AutoKeySwitch is running
if pgrep -x "AutoKeySwitch" > /dev/null; then
    log_info "AutoKeySwitch is running"
else
    log_fail "AutoKeySwitch is not running. Please start it first."
    exit 1
fi

# Check Accessibility permission
if osascript -e 'tell application "System Events" to get name of first process' > /dev/null 2>&1; then
    log_info "Accessibility permission: granted"
else
    log_fail "Accessibility permission not granted. Enable in System Settings > Privacy & Security > Accessibility"
    exit 1
fi

echo ""
echo "========================================="
echo "  AutoKeySwitch E2E Punctuation Tests"
echo "========================================="
echo ""

# Test 1: Basic punctuation test
log_info "Running basic punctuation test..."
RESULT=$(osascript "$SCRIPT_DIR/punctuation_basic_test.scpt" 2>&1) || true
if echo "$RESULT" | grep -q "FAIL"; then
    log_fail "Basic punctuation test"
    echo "$RESULT"
else
    log_pass "Basic punctuation test"
    echo "$RESULT"
fi
echo ""

# Test 2: Shift+Number test
log_info "Running Shift+Number test..."
RESULT=$(osascript "$SCRIPT_DIR/shift_number_test.scpt" 2>&1) || true
if echo "$RESULT" | grep -q "FAIL"; then
    log_fail "Shift+Number test"
    echo "$RESULT"
else
    log_pass "Shift+Number test"
    echo "$RESULT"
fi
echo ""

# Summary
echo "========================================="
echo "  Results: $PASSED passed, $FAILED failed"
echo "========================================="

if [ "$FAILED" -gt 0 ]; then
    exit 1
fi
