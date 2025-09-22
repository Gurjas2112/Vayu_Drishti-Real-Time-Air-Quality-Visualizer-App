# Integration Test Script for VayuDrishti Frontend-Backend Connection
# This PowerShell script helps verify that the frontend can connect to the backend

Write-Host "🌬️  VayuDrishti Integration Test Script" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host

# Configuration
$BackendUrl = if ($env:BACKEND_URL) { $env:BACKEND_URL } else { "http://localhost:8080" }
$FlutterProjectDir = "."

Write-Host "📍 Configuration:" -ForegroundColor Yellow
Write-Host "  Backend URL: $BackendUrl" -ForegroundColor White
Write-Host "  Flutter Project: $FlutterProjectDir" -ForegroundColor White
Write-Host

# Function to check if a service is running
function Test-Service {
    param(
        [string]$Url,
        [string]$Name
    )
    
    Write-Host "🔍 Checking $Name... " -NoNewline -ForegroundColor White
    
    try {
        $response = Invoke-WebRequest -Uri $Url -TimeoutSec 5 -ErrorAction Stop
        if ($response.StatusCode -eq 200) {
            Write-Host "✅ Running" -ForegroundColor Green
            return $true
        }
    }
    catch {
        Write-Host "❌ Not responding" -ForegroundColor Red
        return $false
    }
}

# Function to test API endpoint
function Test-ApiEndpoint {
    param(
        [string]$Endpoint,
        [string]$Description
    )
    
    Write-Host "🧪 Testing $Description... " -NoNewline -ForegroundColor White
    
    try {
        $response = Invoke-WebRequest -Uri "$BackendUrl$Endpoint" -TimeoutSec 10 -ErrorAction Stop
        if ($response.StatusCode -eq 200) {
            Write-Host "✅ Success (HTTP $($response.StatusCode))" -ForegroundColor Green
            return $true
        }
    }
    catch {
        Write-Host "❌ Failed (HTTP $($_.Exception.Response.StatusCode.Value__))" -ForegroundColor Red
        if ($_.Exception.Message) {
            Write-Host "    Error: $($_.Exception.Message)" -ForegroundColor Red
        }
        return $false
    }
}

# Step 1: Check if backend is running
Write-Host "🚀 Step 1: Backend Health Check" -ForegroundColor Yellow
Write-Host "------------------------------" -ForegroundColor Yellow

if (Test-Service "$BackendUrl/health" "Backend Health") {
    Write-Host "✅ Backend is running and healthy!" -ForegroundColor Green
} else {
    Write-Host "❌ Backend is not running or not healthy" -ForegroundColor Red
    Write-Host "💡 Please start your backend server first:" -ForegroundColor Yellow
    Write-Host "   cd backend && npm run dev" -ForegroundColor White
    Write-Host
    exit 1
}
Write-Host

# Step 2: Test API endpoints
Write-Host "🔌 Step 2: API Endpoint Tests" -ForegroundColor Yellow
Write-Host "----------------------------" -ForegroundColor Yellow

# Test health endpoint
Test-ApiEndpoint "/health" "Health endpoint" | Out-Null

# Test AQI endpoint with sample coordinates (Delhi)
Test-ApiEndpoint "/api/aqi/latest?lat=28.6139&lon=77.2090&hours=24" "AQI latest data" | Out-Null

Write-Host

# Step 3: Check Flutter dependencies
Write-Host "📱 Step 3: Flutter Project Check" -ForegroundColor Yellow
Write-Host "-------------------------------" -ForegroundColor Yellow

if (-not (Test-Path "$FlutterProjectDir\pubspec.yaml")) {
    Write-Host "❌ Flutter project not found in $FlutterProjectDir" -ForegroundColor Red
    exit 1
}

Write-Host "🔍 Checking Flutter dependencies... " -NoNewline -ForegroundColor White

try {
    Set-Location $FlutterProjectDir
    $result = flutter pub deps 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Dependencies OK" -ForegroundColor Green
    } else {
        Write-Host "❌ Missing dependencies" -ForegroundColor Red
        Write-Host "💡 Run: flutter pub get" -ForegroundColor Yellow
        exit 1
    }
}
catch {
    Write-Host "❌ Error checking dependencies" -ForegroundColor Red
    Write-Host "💡 Make sure Flutter is installed and in PATH" -ForegroundColor Yellow
    exit 1
}

# Step 4: Verify configuration
Write-Host
Write-Host "⚙️  Step 4: Configuration Verification" -ForegroundColor Yellow
Write-Host "------------------------------------" -ForegroundColor Yellow

Write-Host "📋 Configuration Summary:" -ForegroundColor White
Write-Host "  • Backend URL: $BackendUrl" -ForegroundColor White
Write-Host "  • Environment: $($env:ENVIRONMENT ?? 'development')" -ForegroundColor White
Write-Host "  • Debug Logging: $($env:DEBUG_LOGGING ?? 'true')" -ForegroundColor White

# Check if config file exists and contains backend URL
if (Test-Path "lib\core\config.dart") {
    $configContent = Get-Content "lib\core\config.dart" -Raw
    if ($configContent -match "defaultValue: '$([regex]::Escape($BackendUrl))'") {
        Write-Host "✅ Backend URL configured correctly in config.dart" -ForegroundColor Green
    } elseif ($configContent -match "defaultValue: 'http://localhost:8080'") {
        Write-Host "⚠️  Using default localhost URL in config.dart" -ForegroundColor Yellow
        Write-Host "💡 For production, update lib\core\config.dart or use environment variables" -ForegroundColor Yellow
    } else {
        Write-Host "⚠️  Could not verify backend URL in config.dart" -ForegroundColor Yellow
    }
} else {
    Write-Host "⚠️  config.dart not found" -ForegroundColor Yellow
}

Write-Host

# Step 5: Run integration test
Write-Host "🧪 Step 5: Integration Test" -ForegroundColor Yellow
Write-Host "--------------------------" -ForegroundColor Yellow

Write-Host "🏃 Running Flutter app with backend connection..." -ForegroundColor White
Write-Host "💡 Look for these indicators in the app:" -ForegroundColor Yellow
Write-Host "   • Green cloud icon in app bar = Full connectivity" -ForegroundColor Green
Write-Host "   • Orange cloud icon = Partial connectivity" -ForegroundColor Yellow  
Write-Host "   • Red cloud icon = No connectivity" -ForegroundColor Red
Write-Host "   • Real AQI data instead of mock data" -ForegroundColor White
Write-Host

# Set environment variables
$env:BACKEND_BASE_URL = $BackendUrl
$env:DEBUG_LOGGING = "true"

Write-Host "🚀 Starting Flutter app..." -ForegroundColor Cyan
Write-Host "   Backend URL: $BackendUrl" -ForegroundColor White
Write-Host "   Press Ctrl+C to stop" -ForegroundColor White
Write-Host

# Run Flutter in debug mode
try {
    flutter run --dart-define=BACKEND_BASE_URL="$BackendUrl" --dart-define=DEBUG_LOGGING=true --dart-define=ENVIRONMENT=development
}
catch {
    Write-Host "❌ Error running Flutter app: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host
Write-Host "🎉 Integration test completed!" -ForegroundColor Green
Write-Host "💡 Check the app for real-time AQI data and connection status indicators." -ForegroundColor Yellow