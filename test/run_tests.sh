#!/bin/bash

# Profile Backend System Test Runner
# This script runs all tests for the profile backend system

echo "🧪 Profile Backend System Test Runner"
echo "======================================"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
    else
        echo -e "${RED}❌ $2${NC}"
    fi
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "ℹ️  $1"
}

# Check if Flutter is available
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter is not installed or not in PATH${NC}"
    exit 1
fi

print_info "Flutter version:"
flutter --version | head -1

echo ""
echo "📋 Running Unit Tests (No external dependencies required)"
echo "--------------------------------------------------------"

# Run Profile Service Tests
print_info "Running Profile Service model tests..."
flutter test test/services/profile_service_test.dart --reporter=compact
PROFILE_RESULT=$?
print_status $PROFILE_RESULT "Profile Service Tests"

# Run Media Service Tests
print_info "Running Media Service model tests..."
flutter test test/services/media_service_test.dart --reporter=compact
MEDIA_RESULT=$?
print_status $MEDIA_RESULT "Media Service Tests"

# Calculate unit test results
UNIT_TESTS_PASSED=0
if [ $PROFILE_RESULT -eq 0 ] && [ $MEDIA_RESULT -eq 0 ]; then
    UNIT_TESTS_PASSED=1
fi

echo ""
echo "🔗 Integration Tests (Requires Supabase setup)"
echo "----------------------------------------------"

# Check for environment variables
if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ]; then
    print_warning "Integration tests skipped - Supabase environment variables not set"
    print_info "To run integration tests, set:"
    print_info "  export SUPABASE_URL=\"your-supabase-project-url\""
    print_info "  export SUPABASE_ANON_KEY=\"your-supabase-anon-key\""
    INTEGRATION_RESULT=2  # Skipped
else
    print_info "Running End-to-End Integration tests..."
    print_warning "This will create temporary test users in your Supabase project"
    
    flutter test test/integration/profile_backend_e2e_test.dart --reporter=compact
    INTEGRATION_RESULT=$?
    print_status $INTEGRATION_RESULT "Integration Tests"
fi

echo ""
echo "📊 Test Summary"
echo "==============="

if [ $UNIT_TESTS_PASSED -eq 1 ]; then
    echo -e "${GREEN}✅ Unit Tests: PASSED${NC}"
    echo "   - Profile models and business logic working correctly"
    echo "   - Media models and business logic working correctly"
    echo "   - Error handling and edge cases covered"
else
    echo -e "${RED}❌ Unit Tests: FAILED${NC}"
    echo "   - Check model implementations and business logic"
fi

if [ $INTEGRATION_RESULT -eq 0 ]; then
    echo -e "${GREEN}✅ Integration Tests: PASSED${NC}"
    echo "   - User registration → profile creation → viewing: ✅"
    echo "   - Profile updates → realtime events: ✅"
    echo "   - Media upload → storage → database → realtime: ✅"
    echo "   - Media delete → database → storage cleanup: ✅"
elif [ $INTEGRATION_RESULT -eq 2 ]; then
    echo -e "${YELLOW}⚠️  Integration Tests: SKIPPED${NC}"
    echo "   - Supabase environment variables not configured"
else
    echo -e "${RED}❌ Integration Tests: FAILED${NC}"
    echo "   - Check Supabase configuration and connectivity"
    echo "   - Verify database migrations and RLS policies"
    echo "   - Check storage bucket configuration"
fi

echo ""
echo "🎯 Backend System Validation"
echo "============================"

if [ $UNIT_TESTS_PASSED -eq 1 ]; then
    if [ $INTEGRATION_RESULT -eq 0 ]; then
        echo -e "${GREEN}🎉 COMPLETE SUCCESS: All backend flows validated!${NC}"
        echo ""
        echo "✅ Profile backend system is fully functional:"
        echo "   • Database schema and migrations working"
        echo "   • RLS security policies enforced"
        echo "   • Storage buckets configured correctly"
        echo "   • Service layer implementations correct"
        echo "   • Realtime subscriptions working"
        echo "   • End-to-end flows validated"
        echo ""
        echo "🚀 Ready for production deployment!"
        exit 0
    elif [ $INTEGRATION_RESULT -eq 2 ]; then
        echo -e "${YELLOW}⚠️  PARTIAL SUCCESS: Unit tests passed, integration tests skipped${NC}"
        echo ""
        echo "✅ Core system components validated:"
        echo "   • Data models working correctly"
        echo "   • Business logic implemented properly"
        echo "   • Error handling comprehensive"
        echo ""
        echo "🔧 To complete validation, run integration tests with Supabase setup"
        exit 0
    else
        echo -e "${RED}❌ INTEGRATION ISSUES: Unit tests passed but integration failed${NC}"
        echo ""
        echo "✅ Core components are working"
        echo "❌ Backend integration has issues"
        echo ""
        echo "🔧 Check Supabase configuration and try again"
        exit 1
    fi
else
    echo -e "${RED}❌ SYSTEM FAILURE: Core unit tests failed${NC}"
    echo ""
    echo "❌ Basic system components have issues"
    echo "🔧 Fix model implementations and business logic first"
    exit 1
fi