# Use Case Diagram - Vayu Drishti Air Quality Visualizer

## Mermaid Diagram

```mermaid
graph TB
    subgraph "Vayu Drishti Air Quality System"
        UC1[View Real-Time AQI]
        UC2[Select Location]
        UC3[View Forecast]
        UC4[View Interactive Map]
        UC5[Get Health Recommendations]
        UC6[View Pollutant Details]
        UC7[Generate Custom Predictions]
        UC8[View Feature Importance]
        UC9[View Model Performance]
        UC10[Compare Urban vs Rural]
        UC11[Export Data]
        UC12[Configure Settings]
    end
    
    subgraph Actors
        User[👤 User/Citizen]
        Researcher[👨‍🔬 Researcher]
        HealthWorker[⚕️ Health Worker]
        PolicyMaker[👔 Policy Maker]
    end
    
    subgraph "External Systems"
        CPCB[(CPCB API)]
        MERRA2[(MERRA-2 API)]
        INSAT[(INSAT-3DR API)]
        ML[🤖 ML Model]
    end
    
    User --> UC1
    User --> UC2
    User --> UC3
    User --> UC4
    User --> UC5
    User --> UC12
    
    Researcher --> UC6
    Researcher --> UC7
    Researcher --> UC8
    Researcher --> UC9
    
    HealthWorker --> UC1
    HealthWorker --> UC5
    HealthWorker --> UC10
    
    PolicyMaker --> UC10
    PolicyMaker --> UC11
    PolicyMaker --> UC9
    
    UC1 -.->|includes| UC2
    UC3 -.->|includes| UC1
    UC3 -.->|uses| ML
    UC4 -.->|includes| UC1
    UC5 -.->|extends| UC1
    UC7 -.->|uses| ML
    
    UC1 -->|fetches data| CPCB
    UC1 -->|fetches data| MERRA2
    UC1 -->|fetches data| INSAT
    UC7 -->|uses| ML
    
    style UC1 fill:#667eea
    style UC3 fill:#667eea
    style UC7 fill:#667eea
    style ML fill:#764ba2
```

## PlantUML Code

```plantuml
@startuml
left to right direction
skinparam packageStyle rectangle

actor "User/Citizen" as User
actor "Researcher" as Researcher
actor "Health Worker" as HealthWorker
actor "Policy Maker" as PolicyMaker

rectangle "Vayu Drishti Air Quality System" {
  usecase "View Real-Time AQI" as UC1
  usecase "Select Location\n(City/Rural)" as UC2
  usecase "View Forecast\n(1-72 hours)" as UC3
  usecase "View Interactive Map" as UC4
  usecase "Get Health\nRecommendations" as UC5
  usecase "View Pollutant\nDetails" as UC6
  usecase "Generate Custom\nPredictions" as UC7
  usecase "View Feature\nImportance" as UC8
  usecase "View Model\nPerformance" as UC9
  usecase "Compare Urban\nvs Rural AQI" as UC10
  usecase "Export Data" as UC11
  usecase "Configure Settings" as UC12
}

rectangle "External Systems" {
  usecase "CPCB API" as CPCB
  usecase "MERRA-2 API" as MERRA2
  usecase "INSAT-3DR API" as INSAT
  usecase "ML Model\n(Random Forest)" as ML
}

User --> UC1
User --> UC2
User --> UC3
User --> UC4
User --> UC5
User --> UC12

Researcher --> UC6
Researcher --> UC7
Researcher --> UC8
Researcher --> UC9

HealthWorker --> UC1
HealthWorker --> UC5
HealthWorker --> UC10

PolicyMaker --> UC10
PolicyMaker --> UC11
PolicyMaker --> UC9

UC1 ..> UC2 : <<include>>
UC3 ..> UC1 : <<include>>
UC3 ..> ML : <<uses>>
UC4 ..> UC1 : <<include>>
UC5 ..> UC1 : <<extend>>
UC7 ..> ML : <<uses>>

UC1 --> CPCB : <<fetch>>
UC1 --> MERRA2 : <<fetch>>
UC1 --> INSAT : <<fetch>>

@enduml
```

## Use Case Descriptions

### UC1: View Real-Time AQI
**Actor:** User, Health Worker  
**Description:** Display current AQI value with color-coded health category  
**Preconditions:** Location selected  
**Postconditions:** AQI displayed with category (Good/Moderate/Unhealthy/etc.)

### UC2: Select Location
**Actor:** User  
**Description:** Choose from 40 locations (10 major cities + 30 rural areas)  
**Preconditions:** Application loaded  
**Postconditions:** Location set, data fetched

### UC3: View Forecast
**Actor:** User, Researcher  
**Description:** View 1-72 hour AQI predictions using ML model  
**Preconditions:** Location selected, model loaded  
**Postconditions:** Forecast chart displayed with confidence intervals

### UC7: Generate Custom Predictions
**Actor:** Researcher  
**Description:** Input custom parameters for AQI prediction  
**Preconditions:** ML model loaded  
**Postconditions:** Custom AQI prediction generated

### UC10: Compare Urban vs Rural
**Actor:** Health Worker, Policy Maker  
**Description:** Compare AQI patterns between urban and rural areas  
**Preconditions:** Data available for both location types  
**Postconditions:** Comparative analysis displayed
