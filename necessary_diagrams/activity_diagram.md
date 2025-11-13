# Activity Diagram - Vayu Drishti Air Quality Visualizer

## Main User Flow - AQI Forecast Generation

### Mermaid Diagram

```mermaid
flowchart TD
    Start([User Opens Application]) --> SelectLocationType{Select Location Type}
    
    SelectLocationType -->|Major Cities| SelectCity[Select City from 10 Options]
    SelectLocationType -->|Rural Areas| SelectRural[Select Rural Area from 30 Options]
    
    SelectCity --> SetForecast[Set Forecast Horizon 1-72 hours]
    SelectRural --> SetForecast
    
    SetForecast --> CheckCache{Data Cached?}
    
    CheckCache -->|Yes & Fresh| LoadCache[Load from Cache]
    CheckCache -->|No or Stale| FetchData[Fetch Data from APIs]
    
    FetchData --> ParallelFetch{Parallel API Calls}
    
    ParallelFetch --> FetchCPCB[Fetch CPCB Data<br/>7 Pollutants]
    ParallelFetch --> FetchMERRA2[Fetch MERRA-2 Data<br/>8 Weather Params]
    ParallelFetch --> FetchINSAT[Fetch INSAT-3DR Data<br/>6 Satellite Params]
    
    FetchCPCB --> MergeData[Merge All Data Sources]
    FetchMERRA2 --> MergeData
    FetchINSAT --> MergeData
    
    MergeData --> SaveCache[Save to Cache<br/>TTL: 5 minutes]
    SaveCache --> PrepareFeatures[Prepare Feature Vector<br/>23 Features]
    LoadCache --> PrepareFeatures
    
    PrepareFeatures --> ScaleFeatures[Scale Features<br/>StandardScaler]
    
    ScaleFeatures --> MLPrediction{For Each Forecast Hour}
    
    MLPrediction --> PredictAQI[Random Forest Prediction]
    PredictAQI --> CalculateConfidence[Calculate Confidence Interval<br/>±4.57 AQI]
    
    CalculateConfidence --> MoreHours{More Hours?}
    MoreHours -->|Yes| MLPrediction
    MoreHours -->|No| AggregateResults[Aggregate Predictions]
    
    AggregateResults --> CategorizeAQI[Categorize AQI<br/>Good/Moderate/Unhealthy/etc.]
    
    CategorizeAQI --> GenerateCharts[Generate Visualizations]
    
    GenerateCharts --> CreateForecastChart[Create Forecast Chart<br/>with Confidence Bands]
    GenerateCharts --> CreatePollutantTrends[Create Pollutant Trends]
    GenerateCharts --> CreateMap[Create Interactive Map]
    
    CreateForecastChart --> GenerateHealth[Generate Health Advisory]
    CreatePollutantTrends --> GenerateHealth
    CreateMap --> GenerateHealth
    
    GenerateHealth --> DisplayDashboard[Display Dashboard]
    
    DisplayDashboard --> UserAction{User Action}
    
    UserAction -->|Change Location| SelectLocationType
    UserAction -->|Change Horizon| SetForecast
    UserAction -->|View Different Page| NavigatePage[Navigate to Page]
    UserAction -->|Custom Prediction| CustomFlow[Go to Custom Prediction]
    UserAction -->|Exit| End([End Session])
    
    NavigatePage --> DisplayDashboard
    
    style Start fill:#667eea
    style End fill:#764ba2
    style MLPrediction fill:#48c774
    style DisplayDashboard fill:#f14668
```

## Custom Prediction Flow

```mermaid
flowchart TD
    Start([User Selects Custom Prediction]) --> InputForm[Display Input Form<br/>23 Parameters]
    
    InputForm --> UserInputs{User Enters Values}
    
    UserInputs --> ValidateInputs[Validate All Inputs]
    
    ValidateInputs --> ValidationCheck{Valid?}
    
    ValidationCheck -->|No| ShowErrors[Show Error Messages]
    ShowErrors --> InputForm
    
    ValidationCheck -->|Yes| PrepareVector[Create Feature Vector]
    
    PrepareVector --> ScaleInputs[Scale Inputs<br/>StandardScaler]
    
    ScaleInputs --> PredictCustom[Random Forest Prediction]
    
    PredictCustom --> CalculateCI[Calculate Confidence Interval]
    
    CalculateCI --> DetermineCategory[Determine AQI Category]
    
    DetermineCategory --> GetHealthAdvice[Get Health Recommendations]
    
    GetHealthAdvice --> DisplayResults[Display Prediction Results]
    
    DisplayResults --> ShowAQI[Show AQI Value<br/>with Color Coding]
    DisplayResults --> ShowConfidence[Show Confidence Interval]
    DisplayResults --> ShowHealth[Show Health Advisory]
    
    ShowAQI --> UserChoice{User Choice}
    ShowConfidence --> UserChoice
    ShowHealth --> UserChoice
    
    UserChoice -->|New Prediction| InputForm
    UserChoice -->|Back to Dashboard| Dashboard([Go to Dashboard])
    UserChoice -->|Exit| End([End])
    
    style Start fill:#667eea
    style End fill:#764ba2
    style PredictCustom fill:#48c774
```

## Data Integration and Caching Activity

```mermaid
flowchart TD
    Start([Data Request Received]) --> CheckCache{Cache Entry Exists?}
    
    CheckCache -->|Yes| CheckTTL{Cache Fresh?<br/>< 5 minutes old}
    CheckCache -->|No| InitFetch[Initialize API Fetch]
    
    CheckTTL -->|Yes| ReturnCache[Return Cached Data]
    CheckTTL -->|No| InvalidateCache[Invalidate Cache]
    
    InvalidateCache --> InitFetch
    
    InitFetch --> ParallelAPI[Parallel API Calls]
    
    ParallelAPI --> CPCB[Call CPCB API]
    ParallelAPI --> MERRA2[Call MERRA-2 API]
    ParallelAPI --> INSAT[Call INSAT-3DR API]
    
    CPCB --> CPCBCheck{Success?}
    MERRA2 --> MERRA2Check{Success?}
    INSAT --> INSATCheck{Success?}
    
    CPCBCheck -->|Yes| CPCBData[Store CPCB Data]
    CPCBCheck -->|No| CPCBRetry{Retry < 3?}
    
    MERRA2Check -->|Yes| MERRA2Data[Store MERRA-2 Data]
    MERRA2Check -->|No| MERRA2Retry{Retry < 3?}
    
    INSATCheck -->|Yes| INSATData[Store INSAT Data]
    INSATCheck -->|No| INSATRetry{Retry < 3?}
    
    CPCBRetry -->|Yes| CPCB
    CPCBRetry -->|No| UseCPCBDefault[Use Default/Cached CPCB]
    
    MERRA2Retry -->|Yes| MERRA2
    MERRA2Retry -->|No| UseMERRA2Default[Use Default/Cached MERRA-2]
    
    INSATRetry -->|Yes| INSAT
    INSATRetry -->|No| UseINSATDefault[Use Default/Cached INSAT]
    
    CPCBData --> MergeAllData[Merge All Data Sources]
    MERRA2Data --> MergeAllData
    INSATData --> MergeAllData
    UseCPCBDefault --> MergeAllData
    UseMERRA2Default --> MergeAllData
    UseINSATDefault --> MergeAllData
    
    MergeAllData --> ValidateData[Validate Merged Data]
    
    ValidateData --> DataQuality{Data Quality OK?}
    
    DataQuality -->|Yes| SaveToCache[Save to Cache<br/>with Timestamp]
    DataQuality -->|No| LogError[Log Data Quality Issues]
    
    SaveToCache --> ReturnData[Return Fresh Data]
    LogError --> ReturnData
    ReturnCache --> ReturnData
    
    ReturnData --> End([End])
    
    style Start fill:#667eea
    style End fill:#764ba2
    style MergeAllData fill:#48c774
```

## Model Training Activity (Offline Process)

```mermaid
flowchart TD
    Start([Start Model Training]) --> LoadConfig[Load Configuration]
    
    LoadConfig --> CollectHistoricalData[Collect Historical Data]
    
    CollectHistoricalData --> FetchCPCBHistory[Fetch CPCB Historical<br/>503 Stations]
    CollectHistoricalData --> FetchMERRA2History[Fetch MERRA-2 Historical]
    CollectHistoricalData --> FetchINSATHistory[Fetch INSAT-3DR Historical]
    
    FetchCPCBHistory --> IntegrateData[Integrate All Sources<br/>76,272 Samples]
    FetchMERRA2History --> IntegrateData
    FetchINSATHistory --> IntegrateData
    
    IntegrateData --> CleanData[Data Cleaning & Preprocessing]
    
    CleanData --> HandleMissing[Handle Missing Values]
    HandleMissing --> RemoveOutliers[Remove Outliers]
    RemoveOutliers --> FeatureEngineering[Feature Engineering<br/>23 Features]
    
    FeatureEngineering --> SplitData[Split Dataset<br/>Train/Val/Test]
    
    SplitData --> TrainSet[Training: 53,390 samples]
    SplitData --> ValSet[Validation: 11,441 samples]
    SplitData --> TestSet[Test: 11,441 samples]
    
    TrainSet --> FitScaler[Fit StandardScaler<br/>on Training Data]
    
    FitScaler --> TransformTrain[Transform Training Data]
    FitScaler --> TransformVal[Transform Validation Data]
    FitScaler --> TransformTest[Transform Test Data]
    
    TransformTrain --> InitRF[Initialize Random Forest<br/>n_estimators=100, max_depth=20]
    
    InitRF --> TrainModel[Train Model<br/>Training Time: 8.3s]
    
    TrainModel --> CrossValidation[5-Fold Cross-Validation]
    
    CrossValidation --> EvaluateFolds[Evaluate Each Fold]
    
    EvaluateFolds --> CalculateMetrics[Calculate Metrics<br/>R², RMSE, MAE]
    
    CalculateMetrics --> CheckPerformance{R² > 0.99?}
    
    CheckPerformance -->|No| TuneHyperparameters[Tune Hyperparameters]
    TuneHyperparameters --> InitRF
    
    CheckPerformance -->|Yes| TestModel[Test on Test Set]
    
    TestModel --> GenerateReports[Generate Performance Reports]
    
    GenerateReports --> FeatureImportance[Calculate Feature Importance]
    GenerateReports --> PredictionPlots[Generate Prediction Plots]
    GenerateReports --> ConfusionMetrics[Generate Confusion Metrics]
    
    FeatureImportance --> SaveModel[Save Model to Disk<br/>rf_aqi_model_integrated.pkl]
    PredictionPlots --> SaveModel
    ConfusionMetrics --> SaveModel
    
    SaveModel --> SaveScaler[Save Scaler<br/>rf_scaler_integrated.pkl]
    
    SaveScaler --> SaveMetadata[Save Feature Importance<br/>feature_importance_rf.csv]
    
    SaveMetadata --> ValidateModel[Validate Saved Model]
    
    ValidateModel --> ValidationCheck{Validation Pass?}
    
    ValidationCheck -->|No| LogError[Log Error & Rollback]
    ValidationCheck -->|Yes| DeployModel[Model Ready for Deployment]
    
    LogError --> End([End - Failed])
    DeployModel --> End2([End - Success])
    
    style Start fill:#667eea
    style End fill:#764ba2
    style End2 fill:#48c774
    style TrainModel fill:#f14668
```

## PlantUML Code

```plantuml
@startuml
title Activity Diagram - AQI Forecast Generation

start
:User Opens Application;

:Select Location Type;
if (Major Cities?) then (yes)
  :Select City from 10 Options;
else (no)
  :Select Rural Area from 30 Options;
endif

:Set Forecast Horizon (1-72 hours);

:Check Data Cache;
if (Data Cached and Fresh?) then (yes)
  :Load from Cache;
else (no)
  fork
    :Fetch CPCB Data\n(7 Pollutants);
  fork again
    :Fetch MERRA-2 Data\n(8 Weather Parameters);
  fork again
    :Fetch INSAT-3DR Data\n(6 Satellite Parameters);
  end fork
  
  :Merge All Data Sources;
  :Save to Cache (TTL: 5 min);
endif

:Prepare Feature Vector\n(23 Features);
:Scale Features\n(StandardScaler);

repeat
  :Random Forest Prediction;
  :Calculate Confidence Interval\n(±4.57 AQI);
repeat while (More Forecast Hours?) is (yes)
->no;

:Aggregate Predictions;
:Categorize AQI\n(Good/Moderate/Unhealthy);

fork
  :Create Forecast Chart;
fork again
  :Create Pollutant Trends;
fork again
  :Create Interactive Map;
end fork

:Generate Health Advisory;
:Display Dashboard;

:User Action;
if (Change Settings?) then (yes)
  :Update Configuration;
  backward:Reload Data;
else if (Custom Prediction?) then (yes)
  :Go to Custom Prediction Flow;
else if (Exit?) then (yes)
  stop
else (continue)
  :Continue Viewing;
endif

@enduml
```

## Key Activity Descriptions

### 1. **Location Selection Activity**
- **Duration**: < 1 second
- **User Input**: Location type (City/Rural) and specific location
- **Output**: Selected location with coordinates
- **Validation**: Location must exist in database (40 options)

### 2. **Data Fetching Activity**
- **Duration**: 1-3 seconds (with cache), 3-8 seconds (without cache)
- **Parallel Execution**: Three API calls run simultaneously
- **Error Handling**: Retry mechanism (max 3 attempts per API)
- **Fallback**: Use cached data if APIs fail

### 3. **ML Prediction Activity**
- **Duration**: 50-100 ms per prediction
- **Input**: 23 features (CPCB + MERRA-2 + INSAT-3DR + Location)
- **Processing**: 
  1. Feature scaling
  2. Random Forest prediction
  3. Confidence calculation
- **Output**: AQI value with ±4.57 confidence interval

### 4. **Visualization Activity**
- **Duration**: 500 ms - 2 seconds
- **Components**:
  - Forecast chart with Plotly
  - Interactive map with Folium
  - Pollutant trend charts
- **Interactivity**: User can zoom, pan, hover for details

### 5. **Health Advisory Activity**
- **Duration**: < 100 ms
- **Input**: Predicted AQI value
- **Logic**:
  - 0-50: Good
  - 51-100: Moderate
  - 101-150: Unhealthy for Sensitive Groups
  - 151-200: Unhealthy
  - 201-300: Very Unhealthy
  - 300+: Hazardous
- **Output**: Health recommendations and activity suggestions

## Error Handling Activities

### API Failure Handling
```mermaid
flowchart TD
    APICall[API Call] --> Timeout{Timeout?}
    Timeout -->|Yes| Retry[Retry Attempt]
    Retry --> RetryCount{Attempts < 3?}
    RetryCount -->|Yes| APICall
    RetryCount -->|No| UseCache[Use Cached Data]
    Timeout -->|No| Success[Return Data]
    UseCache --> LogWarning[Log Warning]
```

### Data Quality Validation
```mermaid
flowchart TD
    Data[Received Data] --> CheckNull{Null Values?}
    CheckNull -->|Yes| Impute[Impute Missing]
    CheckNull -->|No| CheckRange{In Valid Range?}
    Impute --> CheckRange
    CheckRange -->|No| Clip[Clip to Valid Range]
    CheckRange -->|Yes| ValidData[Valid Data]
    Clip --> ValidData
```

## Performance Metrics

| Activity | Average Duration | Max Duration |
|----------|-----------------|--------------|
| Location Selection | 0.1s | 0.5s |
| Data Fetch (Cached) | 0.2s | 0.5s |
| Data Fetch (Fresh) | 2.5s | 8s |
| Feature Preparation | 0.05s | 0.1s |
| ML Prediction (1 hour) | 0.08s | 0.15s |
| ML Prediction (72 hours) | 3s | 6s |
| Visualization | 1s | 3s |
| Total (Cached) | 2s | 5s |
| Total (Fresh) | 5s | 15s |
