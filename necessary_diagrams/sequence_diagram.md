# Sequence Diagram - Vayu Drishti Air Quality Visualizer

## Main Flow: AQI Forecast Generation

### Mermaid Diagram

```mermaid
sequenceDiagram
    actor User
    participant UI as Streamlit UI
    participant Cache as Data Cache
    participant CPCB as CPCB API
    participant MERRA2 as MERRA-2 API
    participant INSAT as INSAT-3DR API
    participant ML as Random Forest Model
    participant Viz as Visualization Engine
    
    User->>UI: Select Location (City/Rural)
    User->>UI: Set Forecast Horizon (1-72h)
    
    UI->>Cache: Check cached data
    alt Data cached and fresh
        Cache-->>UI: Return cached data
    else Data not cached or stale
        UI->>CPCB: Request pollutant data
        CPCB-->>UI: PM2.5, PM10, NO2, SO2, CO, O3, NH3
        
        UI->>MERRA2: Request meteorological data
        MERRA2-->>UI: Temp, Humidity, Wind, Pressure, etc.
        
        UI->>INSAT: Request satellite data
        INSAT-->>UI: AOD, Aerosol Index, Cloud Fraction
        
        UI->>Cache: Store fetched data
    end
    
    UI->>ML: Prepare feature vector (23 features)
    
    loop For each forecast hour
        ML->>ML: Scale features
        ML->>ML: Predict AQI
        ML-->>UI: AQI prediction + confidence
    end
    
    UI->>Viz: Generate forecast chart
    UI->>Viz: Generate pollutant trends
    UI->>Viz: Calculate statistics
    
    Viz-->>UI: Interactive charts
    UI-->>User: Display dashboard with forecast
    
    Note over User,Viz: Real-time updates every 5 minutes
```

## Custom Prediction Flow

```mermaid
sequenceDiagram
    actor Researcher
    participant UI as Custom Prediction UI
    participant Validator as Input Validator
    participant ML as Random Forest Model
    participant Health as Health Advisory Engine
    
    Researcher->>UI: Enter custom parameters
    Note over Researcher,UI: PM2.5, PM10, NO2, SO2, CO, O3, NH3<br/>Temp, Humidity, Wind, Pressure<br/>AOD, Aerosol Index, Cloud Fraction<br/>Latitude, Longitude
    
    UI->>Validator: Validate inputs
    
    alt Valid inputs
        Validator-->>UI: Validation passed
        
        UI->>ML: Create feature vector
        ML->>ML: Load scaler
        ML->>ML: Scale features
        ML->>ML: Predict AQI
        ML-->>UI: AQI = 142 (±4.57)
        
        UI->>Health: Get health recommendations
        Health->>Health: Determine AQI category
        Health->>Health: Generate advisory
        Health-->>UI: "Unhealthy for Sensitive Groups"
        
        UI-->>Researcher: Display prediction with confidence interval
        UI-->>Researcher: Show health recommendations
        
    else Invalid inputs
        Validator-->>UI: Validation errors
        UI-->>Researcher: Display error messages
        UI->>Researcher: Request valid inputs
    end
```

## Data Integration and Model Training Flow

```mermaid
sequenceDiagram
    participant Script as Training Script
    participant CPCB as CPCB Data Source
    participant MERRA2 as MERRA-2 Data
    participant INSAT as INSAT-3DR Data
    participant Pipeline as Data Pipeline
    participant ML as Random Forest
    participant Storage as Model Storage
    
    Script->>CPCB: Fetch historical pollutant data
    CPCB-->>Script: 7 pollutants × 503 stations
    
    Script->>MERRA2: Fetch meteorological data
    MERRA2-->>Script: 8 weather parameters
    
    Script->>INSAT: Fetch satellite data
    INSAT-->>Script: 6 aerosol parameters
    
    Script->>Pipeline: Integrate all data sources
    Pipeline->>Pipeline: Merge by timestamp & location
    Pipeline->>Pipeline: Handle missing values
    Pipeline->>Pipeline: Feature engineering
    Pipeline-->>Script: 76,272 samples × 23 features
    
    Script->>ML: Split data (train/val/test)
    Note over Script,ML: Train: 53,390<br/>Val: 11,441<br/>Test: 11,441
    
    ML->>ML: Fit StandardScaler
    ML->>ML: Train Random Forest
    Note over ML: n_estimators=100<br/>max_depth=20<br/>Training time: 8.3s
    
    ML->>ML: Cross-validation (5-fold)
    ML-->>Script: R² = 0.9994, RMSE = 4.57
    
    Script->>Storage: Save model
    Script->>Storage: Save scaler
    Script->>Storage: Save feature importance
    
    Storage-->>Script: Confirmation
    Script->>Script: Generate performance plots
```

## PlantUML Code

```plantuml
@startuml
title Vayu Drishti - AQI Forecast Generation Sequence

actor User
participant "Streamlit UI" as UI
database "Data Cache" as Cache
participant "CPCB API" as CPCB
participant "MERRA-2 API" as MERRA2
participant "INSAT-3DR API" as INSAT
participant "Random Forest\nModel" as ML
participant "Visualization\nEngine" as Viz

User -> UI: Select Location\n(City/Rural)
User -> UI: Set Forecast\nHorizon (1-72h)

UI -> Cache: Check cached data

alt Data cached and fresh
    Cache --> UI: Return cached data
else Data not cached or stale
    UI -> CPCB: Request pollutant data
    CPCB --> UI: PM2.5, PM10, NO2,\nSO2, CO, O3, NH3
    
    UI -> MERRA2: Request meteorological data
    MERRA2 --> UI: Temp, Humidity,\nWind, Pressure
    
    UI -> INSAT: Request satellite data
    INSAT --> UI: AOD, Aerosol Index,\nCloud Fraction
    
    UI -> Cache: Store fetched data
end

UI -> ML: Prepare feature vector\n(23 features)

loop For each forecast hour
    ML -> ML: Scale features
    ML -> ML: Predict AQI
    ML --> UI: AQI prediction\n+ confidence
end

UI -> Viz: Generate forecast chart
UI -> Viz: Generate pollutant trends
UI -> Viz: Calculate statistics

Viz --> UI: Interactive charts
UI --> User: Display dashboard\nwith forecast

note over User,Viz
    Real-time updates
    every 5 minutes
end note

@enduml
```

## Interaction Patterns

### Pattern 1: Real-Time Data Fetching
- **Caching Strategy**: Data cached for 5 minutes to reduce API calls
- **Parallel Requests**: All three data sources (CPCB, MERRA-2, INSAT-3DR) fetched simultaneously
- **Error Handling**: Fallback to cached data if API fails

### Pattern 2: ML Prediction Pipeline
- **Feature Preparation**: 23 features from 3 data sources
- **Scaling**: StandardScaler applied before prediction
- **Confidence Intervals**: ±4.57 AQI (RMSE) for 95% confidence

### Pattern 3: User Interaction
- **Reactive Updates**: Location or forecast horizon changes trigger new predictions
- **Progressive Loading**: Show cached data immediately, update with fresh data
- **Error Recovery**: Graceful degradation if external services unavailable
