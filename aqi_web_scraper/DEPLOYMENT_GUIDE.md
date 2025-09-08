# CPCB Air Quality Data Scraper - Complete Guide

## Project Overview

This project provides a comprehensive Python-based solution for scraping air quality data from the Central Pollution Control Board (CPCB) and other reliable sources. The package includes multiple scraping strategies, error handling, data validation, and sample data generation.

## Package Contents

### Core Scripts
- **`cpcb_aqi_scraper.py`** - Main CPCB scraper with comprehensive error handling
- **`advanced_cpcb_scraper.py`** - Enhanced version with multiple data sources and fallback strategies
- **`alternative_aqi_scraper.py`** - Alternative scraper for when CPCB is unavailable
- **`generate_sample_data.py`** - Sample data generator for testing and demonstration

### Utility Scripts
- **`test_scraper.py`** - Unit tests and integration tests
- **`check_urls.py`** - URL availability checker
- **`run_scraper.bat`** - Windows batch script for easy execution

### Configuration Files
- **`requirements.txt`** - Python dependencies
- **`config.ini`** - Configuration settings
- **`README.md`** - This documentation

## Installation and Setup

### 1. Prerequisites
- Python 3.7 or higher
- Internet connection
- Windows/macOS/Linux

### 2. Install Dependencies

#### Using pip:
```bash
pip install -r requirements.txt
```

#### Using conda:
```bash
conda install requests beautifulsoup4 pandas lxml
```

### 3. Verify Installation
```bash
python test_scraper.py
```

## Usage Instructions

### Quick Start (Windows)
1. Double-click `run_scraper.bat`
2. The script will automatically install dependencies and run the scraper

### Manual Execution

#### Basic CPCB Scraper:
```bash
python cpcb_aqi_scraper.py
```

#### Advanced Scraper with Multiple Sources:
```bash
python advanced_cpcb_scraper.py
```

#### Alternative Scraper (when CPCB is unavailable):
```bash
python alternative_aqi_scraper.py
```

#### Generate Sample Data for Testing:
```bash
python generate_sample_data.py
```

## Output Files

### CSV Files Generated:
- **`cpcb_aqi_data.csv`** - Main output with detailed pollutant data
- **`sample_cpcb_aqi_data.csv`** - Sample data for demonstration
- **`sample_station_summary.csv`** - Station-wise summary
- **`alternative_aqi_data.csv`** - Data from alternative sources

### Log Files:
- **`cpcb_scraper.log`** - Main scraper logs
- **`cpcb_scraper_advanced.log`** - Advanced scraper logs
- **`air_quality_scraper.log`** - Alternative scraper logs

### Additional Formats:
- **`sample_aqi_data.json`** - JSON format for API integration
- **`cpcb_aqi_data.xlsx`** - Excel format (if xlsxwriter is installed)

## Data Schema

### CSV Output Format:
```
Station,State,Latitude,Longitude,Pollutant,Value,Timestamp
Delhi - Anand Vihar,Delhi,28.6469,77.3158,PM2.5,45.5,2025-09-08 12:00:00
Delhi - Anand Vihar,Delhi,28.6469,77.3158,PM10,78.2,2025-09-08 12:00:00
```

### Column Descriptions:
- **Station**: Name of the monitoring station
- **State**: State/region where station is located
- **Latitude**: Geographic latitude (decimal degrees)
- **Longitude**: Geographic longitude (decimal degrees)
- **Pollutant**: Type of pollutant (PM2.5, PM10, NO2, SO2, CO, O3, NH3, Pb)
- **Value**: Measured concentration value
- **Timestamp**: Data collection timestamp (YYYY-MM-DD HH:MM:SS)

## Configuration Options

Edit `config.ini` to customize scraper behavior:

```ini
[scraper_settings]
request_delay = 2                    # Delay between requests (seconds)
request_timeout = 30                 # Request timeout (seconds)
max_retries = 3                      # Maximum retry attempts
output_file = cpcb_aqi_data.csv     # Output filename
log_level = INFO                     # Logging level

[pollutants]
target_pollutants = PM2.5,PM10,NO2,SO2,CO,O3,NH3,Pb

[data_processing]
remove_duplicates = true
include_stations_without_coords = true
min_pollutants_per_station = 1
```

## Troubleshooting

### Common Issues and Solutions:

#### 1. Network Connectivity Issues
```
Error: Failed to resolve 'app.cpcbccr.com'
```
**Solutions:**
- Check internet connection
- Try alternative scraper: `python alternative_aqi_scraper.py`
- Use sample data generator: `python generate_sample_data.py`

#### 2. No Data Collected
```
No data was collected
```
**Solutions:**
- Run URL checker: `python check_urls.py`
- Check log files for detailed errors
- Increase request delay in config.ini
- Try different time of day (website may have maintenance windows)

#### 3. Rate Limiting
```
Request failed: 429 Too Many Requests
```
**Solutions:**
- Increase `request_delay` in config.ini
- Reduce number of target cities in advanced scraper
- Wait and try again later

#### 4. SSL Certificate Errors
```
SSL: CERTIFICATE_VERIFY_FAILED
```
**Solutions:**
- Update certificates: `pip install --upgrade certifi`
- Check corporate firewall settings
- Use alternative data sources

#### 5. Permission Errors
```
Permission denied writing to file
```
**Solutions:**
- Run as administrator (Windows)
- Check file permissions
- Change output directory

## Technical Details

### Scraping Strategies:
1. **API Endpoints** - Attempts to find JSON APIs
2. **HTML Parsing** - Parses dashboard HTML structure  
3. **JavaScript Extraction** - Extracts embedded JSON data
4. **Alternative Sources** - Falls back to reliable third-party sources

### Data Validation:
- Removes duplicate entries
- Validates coordinate formats
- Checks pollutant value ranges
- Handles missing data gracefully

### Error Handling:
- Network timeout protection
- Retry logic with exponential backoff
- Comprehensive logging
- Graceful degradation

## Best Practices

### Responsible Scraping:
- Respects robots.txt guidelines
- Implements reasonable delays between requests
- Uses proper User-Agent headers
- Includes error handling to avoid server overload

### Data Quality:
- Validates all collected data
- Removes obvious outliers
- Provides data quality metrics
- Includes data collection timestamps

### Performance:
- Efficient memory usage
- Parallel processing where appropriate
- Progress monitoring and logging
- Configurable rate limiting

## Sample Data Analysis

The package includes sample data demonstrating typical output:

```python
import pandas as pd

# Load sample data
df = pd.read_csv('sample_cpcb_aqi_data.csv')

# Basic statistics
print(f"Stations: {df['Station'].nunique()}")
print(f"States: {df['State'].nunique()}")
print(f"Pollutants: {', '.join(df['Pollutant'].unique())}")

# Pollutant analysis
for pollutant in df['Pollutant'].unique():
    data = df[df['Pollutant'] == pollutant]['Value']
    print(f"{pollutant}: {data.mean():.2f} ± {data.std():.2f}")
```

## Legal and Ethical Considerations

### Compliance:
- Educational and research use only
- Respects website terms of service
- Implements responsible scraping practices
- Provides proper attribution

### Data Privacy:
- Only collects publicly available data
- No personal information collected
- Aggregated data only
- Transparent data collection process

## Advanced Usage

### Custom Data Sources:
```python
from cpcb_aqi_scraper import CPCBAirQualityScraper

scraper = CPCBAirQualityScraper()
# Add custom endpoint
scraper.api_endpoints.append('https://custom-api.example.com/data')
data = scraper.scrape_all_data()
```

### Filtering by State:
```python
from advanced_cpcb_scraper import AdvancedCPCBAirQualityScraper

scraper = AdvancedCPCBAirQualityScraper()
# Only collect data from specific states
target_states = ['Delhi', 'Maharashtra', 'Karnataka']
data = scraper.scrape_comprehensive_data(target_states)
```

### Custom Data Processing:
```python
# Load and process data
df = pd.read_csv('cpcb_aqi_data.csv')

# Calculate AQI categories
def categorize_aqi(pm25_value):
    if pm25_value <= 12: return 'Good'
    elif pm25_value <= 35.4: return 'Moderate'
    elif pm25_value <= 55.4: return 'Unhealthy for Sensitive Groups'
    elif pm25_value <= 150.4: return 'Unhealthy'
    else: return 'Very Unhealthy'

pm25_data = df[df['Pollutant'] == 'PM2.5']
pm25_data['AQI_Category'] = pm25_data['Value'].apply(categorize_aqi)
```

## Support and Updates

### Getting Help:
1. Check this documentation
2. Review log files for error details
3. Run the test suite: `python test_scraper.py`
4. Try the sample data generator for testing

### Updating the Package:
1. Check for website structure changes
2. Update URL endpoints in the scripts
3. Modify parsing logic if needed
4. Test with sample data first

### Contributing:
- Report issues with detailed logs
- Suggest improvements
- Share alternative data sources
- Contribute parsing improvements

## Version History

- **v1.0** - Initial release with basic CPCB scraping
- **v1.1** - Added alternative data sources and enhanced error handling
- **v1.2** - Added advanced scraper with multiple strategies
- **v1.3** - Added sample data generation and comprehensive testing

---

**Note**: This scraper is designed for educational and research purposes. Always ensure compliance with website terms of service and local regulations when scraping data.
