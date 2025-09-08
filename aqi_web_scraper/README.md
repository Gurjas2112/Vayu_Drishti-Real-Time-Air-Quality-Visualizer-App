# Air Quality Data Scraper Collection

A comprehensive Python package for scraping air quality data from Indian government sources, including the Central Pollution Control Board (CPCB) and Indian Space Research Organisation (ISRO) satellite-based monitoring systems.

## 🌟 Features

### Data Sources
- **CPCB Ground Stations**: Real-time data from Central Pollution Control Board
- **ISRO Satellite Data**: VEDAS Air Quality Monitoring and MOSDAC VAYU systems
- **Multi-Satellite Integration**: RESOURCESAT-2, INSAT-3D, OCEANSAT-2, MEGHA-TROPIQUES

### Air Quality Parameters
- **Ground Measurements**: PM2.5, PM10, NO2, SO2, CO, O3
- **Satellite Parameters**: Aerosol Optical Depth, Column Densities, Atmospheric Data
- **AQI Calculation**: Air Quality Index with health categorization
- **Quality Control**: Data validation and quality flags

### Advanced Capabilities
- **Real-time Monitoring**: Current air quality from multiple sources
- **Historical Analysis**: Trend analysis and pattern detection
- **Geospatial Coverage**: 8+ major Indian cities across 4 regions
- **Multi-Resolution Data**: 500m to 2km satellite pixel resolution
- **Export Formats**: CSV with comprehensive metadata

## 📁 Core Files

### Main Scrapers
- `cpcb_aqi_scraper.py` - CPCB ground station data scraper
- `isro_vedas_mosdac_scraper.py` - ISRO satellite air quality scraper
- `advanced_cpcb_scraper.py` - Enhanced CPCB scraper with multiple fallbacks

### Analysis Tools
- `isro_summary_report.py` - Comprehensive data analysis and visualization
- `isro_data_explorer.py` - ISRO website exploration and data discovery
- `check_isro_sources.py` - Source availability checker

### Documentation
- `DEPLOYMENT_GUIDE.md` - Deployment instructions
- `PROJECT_SUMMARY.md` - Complete project overview
- `requirements.txt` - Python dependencies

### Data
- `isro_air_quality_data_*.csv` - Satellite-based air quality dataset
- `*.png` - Data visualization outputs

## 🚀 Quick Start

### Installation
```bash
# Install dependencies
pip install -r requirements.txt
```

### Basic Usage

#### 1. CPCB Ground Station Data
```bash
python cpcb_aqi_scraper.py
```

#### 2. ISRO Satellite Data
```bash
python isro_vedas_mosdac_scraper.py
```

#### 3. Comprehensive Analysis
```bash
python isro_summary_report.py
```

#### 4. Check Data Sources
```bash
python check_isro_sources.py
```

## 📊 Data Structure

### Ground Station Data (CPCB)
- Station ID, Name, City, State
- PM2.5, PM10, NO2, SO2, CO, O3 concentrations
- AQI values and health categories
- Timestamp and data quality indicators

### Satellite Data (ISRO)
- Satellite source (RESOURCESAT-2, INSAT-3D, etc.)
- Geographic coordinates and pixel resolution
- Atmospheric parameters (AOD, column densities)
- Processing levels and quality flags
- Multi-temporal coverage

## 🛰️ ISRO Integration

### Supported Systems
- **VEDAS**: Visualisation of Earth Observation Data and Archival System
- **MOSDAC**: Meteorological & Oceanographic Satellite Data Archival Centre
- **Bhuvan**: ISRO's geoportal for satellite imagery

### Satellite Constellation
- **RESOURCESAT-2**: 500m resolution air quality monitoring
- **INSAT-3D**: 1km atmospheric parameter measurement
- **OCEANSAT-2**: 1km coastal and atmospheric data
- **MEGHA-TROPIQUES**: 2km aerosol monitoring

## 📈 Analysis Capabilities

### Air Quality Metrics
- Real-time AQI monitoring and alerts
- Pollution trend analysis
- Regional air quality comparison
- Health impact assessment

### Satellite Analytics
- Aerosol optical depth correlation
- Atmospheric column density analysis
- Multi-satellite data fusion
- Quality-controlled processing

## 🔧 Technical Features

- **Robust Error Handling**: Comprehensive retry logic and fallbacks
- **Rate Limiting**: Respectful scraping practices
- **Multi-format Support**: JSON, CSV, and structured data output
- **Logging**: Detailed operation logs and debugging
- **Windows Compatible**: Tested on Windows PowerShell environment

## 📋 Requirements

- Python 3.7+
- requests
- beautifulsoup4
- pandas
- matplotlib (optional, for visualizations)
- lxml

## 🎯 Use Cases

1. **Environmental Monitoring**: Track air pollution across Indian cities
2. **Research Applications**: Academic and scientific studies
3. **Policy Analysis**: Support environmental policy decisions
4. **Public Health**: Air quality impact assessment
5. **Data Journalism**: Environmental reporting and visualization

## 📞 Support

For issues, improvements, or questions about the air quality data collection system, please refer to the comprehensive documentation in the included markdown files.

## 🌍 Impact

This system enables comprehensive air quality monitoring by combining:
- Ground-based sensor networks (CPCB)
- Satellite-based atmospheric monitoring (ISRO)
- Advanced data analytics and visualization
- Real-time environmental assessment capabilities

**Empowering data-driven environmental monitoring across India!** 🇮🇳
