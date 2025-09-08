"""
Advanced CPCB Air Quality Data Scraper with Enhanced Features

This enhanced version provides additional functionality:
- State/City-specific data collection
- Historical data retrieval attempts
- Enhanced error recovery
- Data validation and quality checks
- Multiple output formats
"""

import requests
from bs4 import BeautifulSoup
import pandas as pd
import json
import time
import logging
from datetime import datetime, timedelta
import re
from typing import List, Dict, Optional, Union
import urllib.parse
import configparser
import os
from dataclasses import dataclass

@dataclass
class StationData:
    """Data class for storing station information"""
    name: str
    state: str
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    aqi: Optional[float] = None
    pollutants: Dict[str, float] = None
    timestamp: str = None
    
    def __post_init__(self):
        if self.pollutants is None:
            self.pollutants = {}
        if self.timestamp is None:
            self.timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')

class AdvancedCPCBAirQualityScraper:
    """Enhanced scraper with advanced features"""
    
    def __init__(self, config_file: str = "config.ini"):
        """Initialize the enhanced scraper"""
        self.config = self.load_config(config_file)
        self.session = requests.Session()
        
        # Enhanced headers with more browser-like behavior
        self.headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
            'Accept-Language': 'en-US,en;q=0.9',
            'Accept-Encoding': 'gzip, deflate, br',
            'Connection': 'keep-alive',
            'Upgrade-Insecure-Requests': '1',
            'Sec-Fetch-Dest': 'document',
            'Sec-Fetch-Mode': 'navigate',
            'Sec-Fetch-Site': 'none',
            'Cache-Control': 'max-age=0'
        }
        self.session.headers.update(self.headers)
        
        # Configuration
        self.request_delay = self.config.getfloat('scraper_settings', 'request_delay', fallback=2.0)
        self.request_timeout = self.config.getint('scraper_settings', 'request_timeout', fallback=30)
        self.max_retries = self.config.getint('scraper_settings', 'max_retries', fallback=3)
        
        # URLs
        self.base_url = "https://app.cpcbccr.com/AQI_India/"
        self.api_base_url = "https://app.cpcbccr.com/ccr_docs/"
        
        # Data storage
        self.stations = []
        self.failed_requests = []
        
        # Setup logging
        self.setup_logging()
        
    def load_config(self, config_file: str) -> configparser.ConfigParser:
        """Load configuration from file"""
        config = configparser.ConfigParser()
        if os.path.exists(config_file):
            config.read(config_file)
            logging.info(f"Configuration loaded from {config_file}")
        else:
            logging.warning(f"Configuration file {config_file} not found, using defaults")
        return config
    
    def setup_logging(self):
        """Setup enhanced logging"""
        log_level = self.config.get('scraper_settings', 'log_level', fallback='INFO')
        logging.basicConfig(
            level=getattr(logging, log_level.upper()),
            format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler('cpcb_scraper_advanced.log'),
                logging.StreamHandler()
            ]
        )
        self.logger = logging.getLogger(__name__)
    
    def make_request_with_retry(self, url: str, params: Optional[Dict] = None, retries: int = None) -> Optional[requests.Response]:
        """Make request with retry logic"""
        if retries is None:
            retries = self.max_retries
        
        for attempt in range(retries + 1):
            try:
                time.sleep(self.request_delay)
                
                response = self.session.get(url, params=params, timeout=self.request_timeout)
                response.raise_for_status()
                
                self.logger.info(f"Successfully fetched: {url} (attempt {attempt + 1})")
                return response
                
            except requests.exceptions.RequestException as e:
                self.logger.warning(f"Request failed for {url} (attempt {attempt + 1}/{retries + 1}): {str(e)}")
                
                if attempt < retries:
                    # Exponential backoff
                    wait_time = self.request_delay * (2 ** attempt)
                    self.logger.info(f"Retrying in {wait_time} seconds...")
                    time.sleep(wait_time)
                else:
                    self.logger.error(f"All retry attempts failed for {url}")
                    self.failed_requests.append(url)
                    return None
    
    def discover_api_endpoints(self) -> List[str]:
        """Discover available API endpoints"""
        self.logger.info("Discovering API endpoints...")
        
        endpoints = []
        
        # Try to find API endpoints from the main page
        response = self.make_request_with_retry(self.base_url)
        if response:
            soup = BeautifulSoup(response.content, 'html.parser')
            
            # Look for API calls in JavaScript
            script_tags = soup.find_all('script')
            for script in script_tags:
                if script.string:
                    # Find AJAX calls and fetch requests
                    api_patterns = [
                        r'fetch\([\'"]([^\'"]+)[\'"]',
                        r'ajax\s*:\s*[\'"]([^\'"]+)[\'"]',
                        r'url\s*:\s*[\'"]([^\'"]+)[\'"]',
                        r'endpoint\s*:\s*[\'"]([^\'"]+)[\'"]'
                    ]
                    
                    for pattern in api_patterns:
                        matches = re.findall(pattern, script.string)
                        for match in matches:
                            if match.endswith(('.php', '.json', '.aspx')):
                                full_url = urllib.parse.urljoin(self.base_url, match)
                                if full_url not in endpoints:
                                    endpoints.append(full_url)
        
        # Common API endpoint patterns
        common_endpoints = [
            "data/aqi_data.json",
            "api/stations.php",
            "services/aqi_service.php",
            "data/realtime.json",
            "ajax/get_stations.php"
        ]
        
        for endpoint in common_endpoints:
            full_url = urllib.parse.urljoin(self.api_base_url, endpoint)
            endpoints.append(full_url)
        
        self.logger.info(f"Discovered {len(endpoints)} potential API endpoints")
        return endpoints
    
    def scrape_with_selenium_fallback(self):
        """Fallback method using Selenium for dynamic content"""
        try:
            from selenium import webdriver
            from selenium.webdriver.chrome.options import Options
            from selenium.webdriver.common.by import By
            from selenium.webdriver.support.ui import WebDriverWait
            from selenium.webdriver.support import expected_conditions as EC
            
            self.logger.info("Attempting Selenium fallback...")
            
            # Setup Chrome options
            chrome_options = Options()
            chrome_options.add_argument('--headless')
            chrome_options.add_argument('--no-sandbox')
            chrome_options.add_argument('--disable-dev-shm-usage')
            chrome_options.add_argument('--user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36')
            
            driver = webdriver.Chrome(options=chrome_options)
            
            try:
                driver.get(self.base_url)
                
                # Wait for content to load
                WebDriverWait(driver, 30).until(
                    EC.presence_of_element_located((By.TAG_NAME, "body"))
                )
                
                # Give extra time for dynamic content
                time.sleep(10)
                
                # Get page source after JavaScript execution
                html_content = driver.page_source
                soup = BeautifulSoup(html_content, 'html.parser')
                
                # Parse the dynamically loaded content
                stations = self.parse_station_data_from_html(soup)
                
                self.logger.info(f"Selenium fallback collected {len(stations)} stations")
                return stations
                
            finally:
                driver.quit()
                
        except ImportError:
            self.logger.warning("Selenium not available for fallback. Install with: pip install selenium")
            return []
        except Exception as e:
            self.logger.error(f"Selenium fallback failed: {str(e)}")
            return []
    
    def validate_station_data(self, station: StationData) -> bool:
        """Validate station data quality"""
        # Check if station has minimum required data
        if not station.name or not station.state:
            return False
        
        # Check if at least one pollutant value exists
        if not station.pollutants:
            return False
        
        # Validate pollutant values are reasonable
        for pollutant, value in station.pollutants.items():
            if value < 0 or value > 9999:  # Reasonable bounds
                self.logger.warning(f"Suspicious {pollutant} value for {station.name}: {value}")
                return False
        
        return True
    
    def scrape_comprehensive_data(self, target_states: Optional[List[str]] = None) -> List[StationData]:
        """Comprehensive data scraping with multiple strategies"""
        self.logger.info("Starting comprehensive data scraping...")
        
        all_stations = []
        
        # Strategy 1: API endpoints
        endpoints = self.discover_api_endpoints()
        for endpoint in endpoints:
            response = self.make_request_with_retry(endpoint)
            if response:
                try:
                    data = response.json()
                    stations = self.parse_api_response(data)
                    all_stations.extend(stations)
                    self.logger.info(f"API endpoint {endpoint} provided {len(stations)} stations")
                except json.JSONDecodeError:
                    pass
        
        # Strategy 2: HTML parsing
        response = self.make_request_with_retry(self.base_url)
        if response:
            soup = BeautifulSoup(response.content, 'html.parser')
            stations = self.parse_station_data_from_html(soup)
            all_stations.extend(stations)
            self.logger.info(f"HTML parsing provided {len(stations)} stations")
        
        # Strategy 3: Selenium fallback (if available)
        if not all_stations:
            selenium_stations = self.scrape_with_selenium_fallback()
            all_stations.extend(selenium_stations)
        
        # Filter by target states if specified
        if target_states:
            all_stations = [s for s in all_stations if s.state in target_states]
            self.logger.info(f"Filtered to {len(all_stations)} stations in target states: {target_states}")
        
        # Validate and clean data
        valid_stations = [s for s in all_stations if self.validate_station_data(s)]
        self.logger.info(f"Validated {len(valid_stations)} out of {len(all_stations)} stations")
        
        return valid_stations
    
    def parse_api_response(self, data: Union[Dict, List]) -> List[StationData]:
        """Parse API response data"""
        stations = []
        
        if isinstance(data, dict):
            # Handle different API response formats
            if 'stations' in data:
                data = data['stations']
            elif 'data' in data:
                data = data['data']
            elif 'results' in data:
                data = data['results']
            else:
                # Single station data
                data = [data]
        
        if isinstance(data, list):
            for item in data:
                station = self.parse_station_item(item)
                if station:
                    stations.append(station)
        
        return stations
    
    def parse_station_item(self, item: Dict) -> Optional[StationData]:
        """Parse individual station data item"""
        try:
            # Extract basic information with multiple key variations
            name = item.get('station_name') or item.get('name') or item.get('Station') or item.get('station')
            state = item.get('state') or item.get('State') or item.get('state_name')
            
            if not name or not state:
                return None
            
            # Extract coordinates
            lat = item.get('latitude') or item.get('lat') or item.get('Latitude')
            lon = item.get('longitude') or item.get('lng') or item.get('Longitude')
            
            try:
                lat = float(lat) if lat else None
                lon = float(lon) if lon else None
            except (ValueError, TypeError):
                lat = lon = None
            
            # Extract AQI
            aqi = item.get('aqi') or item.get('AQI') or item.get('aqi_value')
            try:
                aqi = float(aqi) if aqi else None
            except (ValueError, TypeError):
                aqi = None
            
            # Extract pollutants
            pollutants = {}
            pollutant_keys = ['PM2.5', 'PM10', 'NO2', 'SO2', 'CO', 'O3', 'NH3', 'Pb']
            
            for pollutant in pollutant_keys:
                value = None
                for key in [pollutant, pollutant.lower(), pollutant.upper(), pollutant.replace('.', '')]:
                    if key in item:
                        try:
                            value = float(item[key])
                            break
                        except (ValueError, TypeError):
                            continue
                
                if value is not None:
                    pollutants[pollutant] = value
            
            # Extract timestamp
            timestamp = item.get('timestamp') or item.get('last_update') or item.get('time')
            if not timestamp:
                timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            
            return StationData(
                name=name,
                state=state,
                latitude=lat,
                longitude=lon,
                aqi=aqi,
                pollutants=pollutants,
                timestamp=timestamp
            )
            
        except Exception as e:
            self.logger.error(f"Error parsing station item: {str(e)}")
            return None
    
    def parse_station_data_from_html(self, soup: BeautifulSoup) -> List[StationData]:
        """Enhanced HTML parsing for station data"""
        stations = []
        
        # Look for various HTML patterns
        patterns = [
            {'tag': 'div', 'class': re.compile(r'station|aqi|monitor', re.I)},
            {'tag': 'tr', 'class': None},
            {'tag': 'li', 'class': re.compile(r'station|city', re.I)}
        ]
        
        for pattern in patterns:
            elements = soup.find_all(pattern['tag'], class_=pattern['class'])
            for element in elements:
                station = self.extract_station_from_element(element)
                if station:
                    stations.append(station)
        
        # Look for embedded JSON data
        script_tags = soup.find_all('script')
        for script in script_tags:
            if script.string:
                json_patterns = [
                    r'var\s+stations\s*=\s*(\[.*?\]);',
                    r'data\s*:\s*(\[.*?\])',
                    r'stationData\s*=\s*(\{.*?\});'
                ]
                
                for pattern in json_patterns:
                    matches = re.findall(pattern, script.string, re.DOTALL)
                    for match in matches:
                        try:
                            data = json.loads(match)
                            json_stations = self.parse_api_response(data)
                            stations.extend(json_stations)
                        except json.JSONDecodeError:
                            continue
        
        return stations
    
    def extract_station_from_element(self, element) -> Optional[StationData]:
        """Extract station data from HTML element"""
        text = element.get_text(strip=True)
        
        if not text or len(text) < 10:  # Skip too short texts
            return None
        
        # Extract station name
        name_patterns = [
            r'^([^,\n]+?)(?:\s*[-,]\s*(?:AQI|State|PM))',
            r'Station[:\s]*([^,\n]+)',
            r'^([A-Za-z\s\-]+?)(?:\s*\d+)'
        ]
        
        name = None
        for pattern in name_patterns:
            match = re.search(pattern, text, re.I)
            if match:
                name = match.group(1).strip()
                break
        
        if not name:
            return None
        
        # Extract state (look for known Indian states)
        indian_states = [
            'Delhi', 'Mumbai', 'Maharashtra', 'Karnataka', 'Tamil Nadu', 'Kerala',
            'Andhra Pradesh', 'Telangana', 'Gujarat', 'Rajasthan', 'Punjab',
            'Haryana', 'Uttar Pradesh', 'Madhya Pradesh', 'West Bengal', 'Bihar',
            'Odisha', 'Jharkhand', 'Chhattisgarh', 'Assam', 'Himachal Pradesh',
            'Uttarakhand', 'Goa', 'Jammu and Kashmir', 'Ladakh'
        ]
        
        state = None
        for indian_state in indian_states:
            if indian_state.lower() in text.lower():
                state = indian_state
                break
        
        if not state:
            state = "Unknown"
        
        # Extract pollutant values
        pollutants = {}
        pollutant_patterns = [
            (r'PM2\.5[:\s]*(\d+\.?\d*)', 'PM2.5'),
            (r'PM10[:\s]*(\d+\.?\d*)', 'PM10'),
            (r'NO2[:\s]*(\d+\.?\d*)', 'NO2'),
            (r'SO2[:\s]*(\d+\.?\d*)', 'SO2'),
            (r'CO[:\s]*(\d+\.?\d*)', 'CO'),
            (r'O3[:\s]*(\d+\.?\d*)', 'O3')
        ]
        
        for pattern, pollutant_name in pollutant_patterns:
            match = re.search(pattern, text, re.I)
            if match:
                try:
                    value = float(match.group(1))
                    pollutants[pollutant_name] = value
                except ValueError:
                    continue
        
        if not pollutants:
            return None
        
        return StationData(
            name=name,
            state=state,
            pollutants=pollutants
        )
    
    def export_to_multiple_formats(self, stations: List[StationData], base_filename: str = "cpcb_aqi_data"):
        """Export data to multiple formats"""
        # Convert to DataFrame
        df = self.stations_to_dataframe(stations)
        
        # CSV export
        csv_filename = f"{base_filename}.csv"
        df.to_csv(csv_filename, index=False)
        self.logger.info(f"Data exported to {csv_filename}")
        
        # JSON export
        json_filename = f"{base_filename}.json"
        df.to_json(json_filename, orient='records', indent=2)
        self.logger.info(f"Data exported to {json_filename}")
        
        # Excel export (if xlsxwriter is available)
        try:
            excel_filename = f"{base_filename}.xlsx"
            with pd.ExcelWriter(excel_filename, engine='xlsxwriter') as writer:
                df.to_excel(writer, sheet_name='AQI_Data', index=False)
                
                # Add summary sheet
                summary_df = self.create_summary_dataframe(df)
                summary_df.to_excel(writer, sheet_name='Summary', index=False)
                
            self.logger.info(f"Data exported to {excel_filename}")
        except ImportError:
            self.logger.warning("xlsxwriter not available for Excel export")
        
        return df
    
    def stations_to_dataframe(self, stations: List[StationData]) -> pd.DataFrame:
        """Convert stations to pandas DataFrame"""
        rows = []
        
        for station in stations:
            for pollutant, value in station.pollutants.items():
                rows.append({
                    'Station': station.name,
                    'State': station.state,
                    'Latitude': station.latitude,
                    'Longitude': station.longitude,
                    'Pollutant': pollutant,
                    'Value': value,
                    'AQI': station.aqi,
                    'Timestamp': station.timestamp
                })
        
        return pd.DataFrame(rows)
    
    def create_summary_dataframe(self, df: pd.DataFrame) -> pd.DataFrame:
        """Create summary statistics DataFrame"""
        summary_data = []
        
        # Overall statistics
        summary_data.append({
            'Metric': 'Total Records',
            'Value': len(df)
        })
        
        summary_data.append({
            'Metric': 'Unique Stations',
            'Value': df['Station'].nunique()
        })
        
        summary_data.append({
            'Metric': 'States Covered',
            'Value': df['State'].nunique()
        })
        
        summary_data.append({
            'Metric': 'Pollutants Monitored',
            'Value': ', '.join(df['Pollutant'].unique())
        })
        
        # Pollutant statistics
        for pollutant in df['Pollutant'].unique():
            pollutant_data = df[df['Pollutant'] == pollutant]['Value']
            summary_data.extend([
                {
                    'Metric': f'{pollutant} - Count',
                    'Value': len(pollutant_data)
                },
                {
                    'Metric': f'{pollutant} - Mean',
                    'Value': round(pollutant_data.mean(), 2)
                },
                {
                    'Metric': f'{pollutant} - Max',
                    'Value': pollutant_data.max()
                },
                {
                    'Metric': f'{pollutant} - Min',
                    'Value': pollutant_data.min()
                }
            ])
        
        return pd.DataFrame(summary_data)

def main():
    """Main function for advanced scraper"""
    print("Advanced CPCB Air Quality Data Scraper")
    print("=" * 45)
    
    # Initialize scraper
    scraper = AdvancedCPCBAirQualityScraper()
    
    # Optional: specify target states
    target_states = None  # Set to ['Delhi', 'Maharashtra'] for specific states
    
    try:
        # Scrape data
        print("Starting comprehensive data collection...")
        stations = scraper.scrape_comprehensive_data(target_states)
        
        if stations:
            print(f"\nData Collection Summary:")
            print(f"Collected data from {len(stations)} stations")
            
            # Count pollutants
            all_pollutants = set()
            for station in stations:
                all_pollutants.update(station.pollutants.keys())
            
            print(f"Pollutants found: {', '.join(sorted(all_pollutants))}")
            
            # Export data
            print("\nExporting data to multiple formats...")
            df = scraper.export_to_multiple_formats(stations)
            
            # Display sample
            print(f"\nSample data (first 10 records):")
            print(df.head(10).to_string())
            
        else:
            print("No data was collected.")
            print("Check the log file for detailed error information.")
        
        # Report failed requests
        if scraper.failed_requests:
            print(f"\nFailed requests: {len(scraper.failed_requests)}")
            for url in scraper.failed_requests:
                print(f"  - {url}")
    
    except Exception as e:
        logging.error(f"Scraping failed: {str(e)}")
        print(f"Error: {str(e)}")

if __name__ == "__main__":
    main()
