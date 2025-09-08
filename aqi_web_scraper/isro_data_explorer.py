"""
Simple ISRO Data Explorer

This script explores ISRO websites to understand their structure
and look for any available environmental/air quality data.
"""

import requests
import json
from bs4 import BeautifulSoup
import pandas as pd
from datetime import datetime
import re
import time

class ISRODataExplorer:
    def __init__(self):
        self.headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
            'Accept-Language': 'en-US,en;q=0.5',
            'Accept-Encoding': 'gzip, deflate',
            'Connection': 'keep-alive',
            'Upgrade-Insecure-Requests': '1'
        }
        self.session = requests.Session()
        self.session.headers.update(self.headers)
        
    def explore_website(self, url, name):
        """Explore a website and extract useful information"""
        try:
            print(f"\nExploring: {name}")
            print("-" * 40)
            
            response = self.session.get(url, timeout=15)
            if response.status_code != 200:
                print(f"Status: {response.status_code} - Not accessible")
                return None
                
            print(f"Status: {response.status_code} - Accessible")
            
            soup = BeautifulSoup(response.content, 'html.parser')
            
            # Extract title
            title = soup.find('title')
            if title:
                print(f"Title: {title.text.strip()}")
                
            # Look for navigation links
            nav_links = []
            for a in soup.find_all('a', href=True):
                href = a['href']
                text = a.text.strip()
                
                # Look for environment/air quality related links
                if any(keyword in text.lower() for keyword in 
                       ['air', 'environment', 'pollution', 'atmospheric', 'data', 'download']):
                    nav_links.append((text, href))
                    
            if nav_links:
                print(f"Relevant links found ({len(nav_links)}):")
                for text, href in nav_links[:10]:  # Limit to 10
                    if href.startswith('http'):
                        print(f"  • {text}: {href}")
                    else:
                        full_url = requests.compat.urljoin(url, href)
                        print(f"  • {text}: {full_url}")
            
            # Look for data download sections
            data_sections = soup.find_all(['div', 'section'], 
                                        class_=re.compile(r'data|download|service', re.I))
            if data_sections:
                print(f"Data sections found: {len(data_sections)}")
                
            # Look for API documentation
            api_mentions = soup.find_all(text=re.compile(r'API|REST|JSON|XML', re.I))
            if api_mentions:
                print(f"API references found: {len(api_mentions)}")
                
            # Check for forms (might indicate data query interfaces)
            forms = soup.find_all('form')
            if forms:
                print(f"Forms found: {len(forms)} (potential data query interfaces)")
                
            return {
                'url': url,
                'name': name,
                'status': response.status_code,
                'title': title.text.strip() if title else 'No title',
                'relevant_links': nav_links,
                'data_sections': len(data_sections),
                'api_mentions': len(api_mentions),
                'forms': len(forms)
            }
            
        except Exception as e:
            print(f"Error exploring {name}: {str(e)}")
            return None
    
    def create_sample_isro_data(self):
        """Create realistic sample ISRO air quality data"""
        print("\nCreating sample ISRO air quality data...")
        
        # ISRO satellite-based air quality data structure
        locations = [
            {"city": "Bengaluru", "state": "Karnataka", "lat": 12.9716, "lon": 77.5946},
            {"city": "Mumbai", "state": "Maharashtra", "lat": 19.0760, "lon": 72.8777},
            {"city": "Delhi", "state": "Delhi", "lat": 28.7041, "lon": 77.1025},
            {"city": "Chennai", "state": "Tamil Nadu", "lat": 13.0827, "lon": 80.2707},
            {"city": "Hyderabad", "state": "Telangana", "lat": 17.3850, "lon": 78.4867},
            {"city": "Ahmedabad", "state": "Gujarat", "lat": 23.0225, "lon": 72.5714},
            {"city": "Pune", "state": "Maharashtra", "lat": 18.5204, "lon": 73.8567},
            {"city": "Kolkata", "state": "West Bengal", "lat": 22.5726, "lon": 88.3639}
        ]
        
        # Simulate satellite-derived air quality data
        data = []
        base_time = datetime.now()
        
        for i, location in enumerate(locations):
            # Simulate hourly data for the last 24 hours
            for hour in range(24):
                timestamp = base_time.replace(hour=hour, minute=0, second=0, microsecond=0)
                
                # Simulate satellite-derived values (typically less frequent than ground stations)
                pm25 = 35 + (i * 5) + (hour * 0.8) + ((-1) ** hour * 5)
                pm10 = pm25 * 1.8 + 10
                no2 = 20 + (i * 2) + (hour * 0.3)
                so2 = 10 + (i * 1.5) + (hour * 0.2)
                co = 1.2 + (i * 0.1) + (hour * 0.05)
                o3 = 45 + (i * 3) + (hour * 0.5)
                
                # Calculate AQI (simplified)
                aqi = max(pm25 * 2, pm10 * 1.2, no2 * 1.5, so2 * 2.5, co * 15, o3 * 1.8)
                
                data.append({
                    'timestamp': timestamp.strftime('%Y-%m-%d %H:%M:%S'),
                    'data_source': 'ISRO_Satellite',
                    'satellite': f'RESOURCESAT-{(i % 3) + 1}',
                    'city': location['city'],
                    'state': location['state'],
                    'latitude': location['lat'],
                    'longitude': location['lon'],
                    'pm25': round(pm25, 1),
                    'pm10': round(pm10, 1),
                    'no2': round(no2, 1),
                    'so2': round(so2, 1),
                    'co': round(co, 2),
                    'o3': round(o3, 1),
                    'aqi': round(aqi, 0),
                    'quality_flag': 'Good' if aqi < 50 else 'Moderate' if aqi < 100 else 'Poor',
                    'pixel_resolution': '500m',
                    'cloud_coverage': f"{(hour * 3) % 30}%",
                    'data_quality': 'Validated' if hour % 3 == 0 else 'Preliminary'
                })
        
        df = pd.DataFrame(data)
        
        # Save sample data
        filename = f"sample_isro_air_quality_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv"
        df.to_csv(filename, index=False)
        
        print(f"Sample ISRO data saved to: {filename}")
        print(f"Records created: {len(data)}")
        print(f"Cities covered: {len(locations)}")
        print(f"Time range: Last 24 hours")
        print(f"Data sources: ISRO Satellite constellation")
        
        return df
    
    def run_exploration(self):
        """Run complete ISRO data exploration"""
        print("ISRO Air Quality Data Explorer")
        print("=" * 50)
        
        # ISRO websites to explore
        sites = {
            "ISRO Main": "https://www.isro.gov.in/",
            "Bhuvan Geoportal": "https://bhuvan.nrsc.gov.in/",
            "VEDAS": "https://vedas.sac.gov.in/",
            "MOSDAC": "https://www.mosdac.gov.in/",
            "NRSC": "https://www.nrsc.gov.in/",
            "SAC ISRO": "https://www.sac.gov.in/"
        }
        
        results = []
        for name, url in sites.items():
            result = self.explore_website(url, name)
            if result:
                results.append(result)
            time.sleep(2)  # Be respectful
        
        # Create summary report
        print("\n" + "=" * 50)
        print("EXPLORATION SUMMARY")
        print("=" * 50)
        
        accessible_sites = [r for r in results if r['status'] == 200]
        print(f"Accessible sites: {len(accessible_sites)}/{len(sites)}")
        
        sites_with_data = [r for r in results if r['data_sections'] > 0 or r['forms'] > 0]
        print(f"Sites with potential data access: {len(sites_with_data)}")
        
        sites_with_apis = [r for r in results if r['api_mentions'] > 0]
        print(f"Sites mentioning APIs: {len(sites_with_apis)}")
        
        # Show recommendations
        print("\nRECOMMENDATIONS:")
        print("1. ISRO focuses on satellite imagery and earth observation")
        print("2. Direct air quality monitoring may not be primary function")
        print("3. Consider atmospheric/aerosol data from satellite imagery")
        print("4. Look for research publications using ISRO data")
        print("5. Contact ISRO directly for specialized data access")
        
        # Create sample data for demonstration
        sample_df = self.create_sample_isro_data()
        
        return results, sample_df

def main():
    explorer = ISRODataExplorer()
    results, sample_data = explorer.run_exploration()
    
    print(f"\nExploration completed!")
    print(f"Check the generated CSV file for sample ISRO air quality data structure.")

if __name__ == "__main__":
    main()
