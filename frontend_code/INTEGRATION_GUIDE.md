# Frontend-Backend Integration Guide

This guide explains how to connect the VayuDrishti Flutter frontend with the backend API and AQI web scraper.

## Overview

The frontend has been updated to integrate with:
1. **Backend TypeScript Server** - Provides REST API endpoints for AQI data
2. **AQI Web Scraper** - Collects real-time air quality data from CPCB and ISRO
3. **Real-time Updates** - WebSocket connection for live data updates

## Backend API Endpoints

The frontend connects to these backend endpoints:

### AQI Data
- `GET /api/aqi/latest?lat={lat}&lon={lon}&hours={hours}` - Get latest AQI by location
- `GET /api/aqi/station/{stationId}` - Get AQI data for specific station  
- `GET /api/aqi/historical?stationId={id}&from={date}&to={date}` - Get historical data

### User Management
- `GET /api/user/me` - Get current user profile
- `POST /api/user/fcm-token` - Register FCM token for notifications

### Health Check
- `GET /health` - Backend health status

## Configuration

### 1. Backend URL Configuration

The frontend is configured to connect to the backend via the `AppConfig` class. You can set the backend URL in several ways:

#### Option A: Environment Variables (Recommended)
```bash
# Set environment variable
export BACKEND_BASE_URL=http://your-backend-url:8080

# Or for development with local backend
export BACKEND_BASE_URL=http://localhost:8080
```

#### Option B: Dart Define Arguments
```bash
flutter run --dart-define=BACKEND_BASE_URL=http://your-backend-url:8080
```

#### Option C: Direct Configuration
Edit `lib/core/config.dart`:
```dart
static const String backendBaseUrl = 'http://your-backend-url:8080';
```

### 2. Supabase Configuration

If using Supabase for authentication:
```bash
export SUPABASE_URL=your-supabase-url
export SUPABASE_ANON_KEY=your-supabase-anon-key
```

## Key Integration Features

### 1. Data Models
Created Dart models that match the backend TypeScript interfaces:
- `LatestAqi` - Current air quality data
- `ForecastEntry` - Forecast predictions  
- `HealthRecommendation` - Health advice based on AQI
- `PollutantReading` - Individual pollutant measurements

### 2. API Client
- Enhanced HTTP client with error handling and logging
- Automatic retry logic for failed requests
- Timeout configuration
- Health check capabilities

### 3. Real-time Connection
- WebSocket client for live updates
- Automatic reconnection on connection loss
- Location and station-based subscriptions
- Error handling and status tracking

### 4. Connection Status Monitoring
- Visual indicators for backend connectivity
- Graceful fallback to cached/mock data when offline
- Connection retry mechanisms
- User-friendly error messages

## Usage

### 1. Start the Backend
First, ensure your backend is running:
```bash
cd backend
npm install
npm run dev
```

### 2. Start the Web Scraper
The web scraper should be feeding data to the backend:
```bash
cd aqi_web_scraper
pip install -r requirements.txt
python cpcb_aqi_scraper.py
```

### 3. Configure and Run Frontend
```bash
cd frontend_code

# Install dependencies
flutter pub get

# Run with environment variables
BACKEND_BASE_URL=http://localhost:8080 flutter run

# Or with dart-define
flutter run --dart-define=BACKEND_BASE_URL=http://localhost:8080
```

## Data Flow

1. **AQI Web Scraper** → Collects data from CPCB/ISRO sources
2. **Ingest Client** → Sends scraped data to backend `/api/ingest` endpoints
3. **Backend** → Stores data in Supabase, provides REST API and WebSocket updates
4. **Frontend** → Fetches data via API calls and receives real-time updates via WebSocket

## Error Handling

The frontend implements comprehensive error handling:

- **Network Errors**: Displays user-friendly messages and retry options
- **API Errors**: Handles different HTTP status codes appropriately
- **Offline Mode**: Falls back to cached data or mock data when backend unavailable
- **Connection Status**: Shows visual indicators for backend connectivity

## Features

### Real-time Updates
- Automatic subscription to location-based updates
- Live AQI data refresh without manual refresh
- Real-time health recommendations

### Offline Support
- Graceful degradation when backend is unavailable
- Mock data generation for development/testing
- Cached data display

### Connection Monitoring
- Visual connection status indicators in the app bar
- Connection summary messages
- Retry mechanisms for failed connections

## Development Tips

### 1. Testing Backend Connection
The app includes a health check feature. Look for connection status indicators in the app bar:
- 🟢 Green cloud icon: Full connectivity
- 🟠 Orange cloud icon: Partial connectivity  
- 🔴 Red cloud icon: No connectivity

### 2. Debugging
Enable debug logging by setting:
```bash
export DEBUG_LOGGING=true
```

### 3. Mock Data
If the backend is unavailable, the app automatically falls back to mock data for development purposes.

## Troubleshooting

### Common Issues

1. **"Backend offline" message**: 
   - Check if backend server is running
   - Verify the backend URL configuration
   - Check network connectivity

2. **"No data available" error**:
   - Ensure web scraper is running and feeding data
   - Check backend logs for ingestion errors
   - Verify Supabase database has data

3. **Real-time updates not working**:
   - Check WebSocket connection in browser dev tools
   - Verify backend WebSocket server is running
   - Check for firewall/proxy issues

4. **Location-based queries failing**:
   - Ensure GPS permissions are granted
   - Check if location services are enabled
   - Verify backend has location-based data

### Debug Commands

```bash
# Check backend health
curl http://localhost:8080/health

# Test AQI endpoint
curl "http://localhost:8080/api/aqi/latest?lat=28.6139&lon=77.2090&hours=24"

# View backend logs
docker logs backend-container  # if using Docker
```

## Next Steps

1. **Deploy Backend**: Deploy your backend to a cloud service
2. **Configure Production URLs**: Update config for production environment  
3. **Set up CI/CD**: Automate deployment of both frontend and backend
4. **Add Monitoring**: Implement application monitoring and error tracking
5. **Performance Optimization**: Add caching, optimize API calls
6. **Push Notifications**: Implement FCM for air quality alerts