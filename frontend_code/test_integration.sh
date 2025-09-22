#!/bin/bash

# Integration Test Script for VayuDrishti Frontend-Backend Connection
# This script helps verify that the frontend can connect to the backend

echo "🌬️  VayuDrishti Integration Test Script"
echo "======================================"
echo

# Configuration
BACKEND_URL="${BACKEND_URL:-http://localhost:8080}"
FLUTTER_PROJECT_DIR="."

echo "📍 Configuration:"
echo "  Backend URL: $BACKEND_URL"
echo "  Flutter Project: $FLUTTER_PROJECT_DIR"
echo

# Function to check if a service is running
check_service() {
    local url=$1
    local name=$2
    
    echo -n "🔍 Checking $name... "
    
    if curl -s --connect-timeout 5 "$url" > /dev/null 2>&1; then
        echo "✅ Running"
        return 0
    else
        echo "❌ Not responding"
        return 1
    fi
}

# Function to test API endpoint
test_api_endpoint() {
    local endpoint=$1
    local description=$2
    
    echo -n "🧪 Testing $description... "
    
    local response=$(curl -s -w "%{http_code}" --connect-timeout 10 "$BACKEND_URL$endpoint")
    local http_code="${response: -3}"
    local body="${response%???}"
    
    if [ "$http_code" -eq 200 ]; then
        echo "✅ Success (HTTP $http_code)"
        return 0
    else
        echo "❌ Failed (HTTP $http_code)"
        if [ ! -z "$body" ]; then
            echo "    Response: $body"
        fi
        return 1
    fi
}

# Step 1: Check if backend is running
echo "🚀 Step 1: Backend Health Check"
echo "------------------------------"
if check_service "$BACKEND_URL/health" "Backend Health"; then
    echo "✅ Backend is running and healthy!"
else
    echo "❌ Backend is not running or not healthy"
    echo "💡 Please start your backend server first:"
    echo "   cd backend && npm run dev"
    echo
    exit 1
fi
echo

# Step 2: Test API endpoints
echo "🔌 Step 2: API Endpoint Tests"
echo "----------------------------"

# Test health endpoint
test_api_endpoint "/health" "Health endpoint"

# Test AQI endpoint with sample coordinates (Delhi)
test_api_endpoint "/api/aqi/latest?lat=28.6139&lon=77.2090&hours=24" "AQI latest data"

echo

# Step 3: Check Flutter dependencies
echo "📱 Step 3: Flutter Project Check"
echo "-------------------------------"

if [ ! -f "$FLUTTER_PROJECT_DIR/pubspec.yaml" ]; then
    echo "❌ Flutter project not found in $FLUTTER_PROJECT_DIR"
    exit 1
fi

echo -n "🔍 Checking Flutter dependencies... "
cd "$FLUTTER_PROJECT_DIR"

if flutter pub deps > /dev/null 2>&1; then
    echo "✅ Dependencies OK"
else
    echo "❌ Missing dependencies"
    echo "💡 Run: flutter pub get"
    exit 1
fi

# Step 4: Verify configuration
echo
echo "⚙️  Step 4: Configuration Verification"
echo "------------------------------------"

echo "📋 Configuration Summary:"
echo "  • Backend URL: $BACKEND_URL"
echo "  • Environment: ${ENVIRONMENT:-development}"
echo "  • Debug Logging: ${DEBUG_LOGGING:-true}"

# Check if config file exists and contains correct backend URL
if grep -q "defaultValue: '$BACKEND_URL'" lib/core/config.dart 2>/dev/null; then
    echo "✅ Backend URL configured correctly in config.dart"
elif grep -q "defaultValue: 'http://localhost:8080'" lib/core/config.dart 2>/dev/null; then
    echo "⚠️  Using default localhost URL in config.dart"
    echo "💡 For production, update lib/core/config.dart or use environment variables"
else
    echo "⚠️  Could not verify backend URL in config.dart"
fi

echo

# Step 5: Run integration test
echo "🧪 Step 5: Integration Test"
echo "--------------------------"

echo "🏃 Running Flutter app with backend connection..."
echo "💡 Look for these indicators in the app:"
echo "   • Green cloud icon in app bar = Full connectivity"
echo "   • Orange cloud icon = Partial connectivity"
echo "   • Red cloud icon = No connectivity"
echo "   • Real AQI data instead of mock data"
echo

# Set environment variables and run Flutter
export BACKEND_BASE_URL="$BACKEND_URL"
export DEBUG_LOGGING=true

echo "🚀 Starting Flutter app..."
echo "   Backend URL: $BACKEND_BASE_URL"
echo "   Press Ctrl+C to stop"
echo

# Run Flutter in debug mode
flutter run --dart-define=BACKEND_BASE_URL="$BACKEND_URL" \
           --dart-define=DEBUG_LOGGING=true \
           --dart-define=ENVIRONMENT=development

echo
echo "🎉 Integration test completed!"
echo "💡 Check the app for real-time AQI data and connection status indicators."