"""
ISRO Data Sources Checker

This script checks the availability of ISRO air quality data sources
and provides information about accessible endpoints.
"""

import requests
import time
from urllib.parse import urljoin

def check_isro_data_sources():
    """Check ISRO data sources for air quality information"""
    
    print("ISRO Air Quality Data Sources Checker")
    print("=" * 40)
    print()
    
    # ISRO and related air quality data sources
    sources = {
        "ISRO Main": "https://www.isro.gov.in/",
        "Bhuvan Geoportal": "https://bhuvan.nrsc.gov.in/",
        "Bhuvan Apps": "https://bhuvan-app1.nrsc.gov.in/",
        "VEDAS": "https://vedas.sac.gov.in/",
        "MOSDAC": "https://www.mosdac.gov.in/",
        "NRSC": "https://www.nrsc.gov.in/",
        "SAC ISRO": "https://www.sac.gov.in/",
        "Bhuvan Thematic": "https://bhuvan-app1.nrsc.gov.in/thematic/",
        "ISRO Geoportal": "https://bhuvan-app1.nrsc.gov.in/geoportal/",
        "Air Quality Portal": "https://bhuvan-app1.nrsc.gov.in/airquality/",
        "Pollution Monitoring": "https://bhuvan.nrsc.gov.in/pollution/",
        "Earth Observation": "https://earth.google.com/",  # Alternative satellite data
        "NASA Air Quality": "https://airquality.gsfc.nasa.gov/",  # Alternative space agency data
    }
    
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
    }
    
    accessible_sources = []
    air_quality_sources = []
    
    for name, url in sources.items():
        try:
            print(f"Checking: {name}")
            response = requests.get(url, headers=headers, timeout=15)
            
            if response.status_code == 200:
                print(f"  ✓ Accessible - Status: {response.status_code}")
                accessible_sources.append((name, url))
                
                # Check if it contains air quality related content
                content = response.text.lower()
                air_quality_keywords = [
                    'air quality', 'aqi', 'pollution', 'pm2.5', 'pm10', 
                    'atmospheric', 'aerosol', 'emission', 'environment'
                ]
                
                found_keywords = [kw for kw in air_quality_keywords if kw in content]
                if found_keywords:
                    print(f"  ✓ Contains air quality data: {', '.join(found_keywords[:3])}")
                    air_quality_sources.append((name, url, found_keywords))
                else:
                    print(f"  ? May not contain specific air quality data")
            else:
                print(f"  ✗ Not accessible - Status: {response.status_code}")
                
        except requests.exceptions.RequestException as e:
            print(f"  ✗ Error: {str(e)}")
        
        time.sleep(1)  # Be respectful
        print()
    
    print("=" * 50)
    print("SUMMARY")
    print("=" * 50)
    
    print(f"\nAccessible Sources ({len(accessible_sources)}):")
    for name, url in accessible_sources:
        print(f"  • {name}: {url}")
    
    print(f"\nSources with Air Quality Data ({len(air_quality_sources)}):")
    for name, url, keywords in air_quality_sources:
        print(f"  • {name}: {url}")
        print(f"    Keywords found: {', '.join(keywords[:5])}")
    
    if not accessible_sources:
        print("\n❌ No ISRO sources are currently accessible.")
        print("This could indicate:")
        print("• Network connectivity issues")
        print("• Temporary server maintenance")
        print("• Firewall/proxy restrictions")
        print("• Changes in URL structure")
    
    if accessible_sources and not air_quality_sources:
        print("\n⚠️  ISRO sources are accessible but may not have direct air quality data.")
        print("Consider these alternatives:")
        print("• Satellite imagery analysis for pollution mapping")
        print("• Atmospheric data from MOSDAC")
        print("• Environmental monitoring reports")
        print("• Integration with ground-based sensors")
    
    return accessible_sources, air_quality_sources

def suggest_isro_data_alternatives():
    """Suggest alternative approaches for getting ISRO air quality data"""
    
    print("\n" + "=" * 50)
    print("ALTERNATIVE APPROACHES FOR ISRO AIR QUALITY DATA")
    print("=" * 50)
    
    alternatives = [
        {
            "name": "Satellite Imagery Analysis",
            "description": "Use ISRO satellite imagery to analyze air pollution patterns",
            "sources": [
                "https://bhuvan.nrsc.gov.in/ - Satellite imagery portal",
                "RESOURCESAT, CARTOSAT satellite data",
                "Download imagery and analyze pollution using image processing"
            ]
        },
        {
            "name": "MOSDAC Atmospheric Data",
            "description": "Access atmospheric and meteorological data",
            "sources": [
                "https://www.mosdac.gov.in/ - Meteorological data",
                "Atmospheric products and weather data",
                "Aerosol optical depth measurements"
            ]
        },
        {
            "name": "VEDAS Earth Observation",
            "description": "Use VEDAS for earth observation and environmental monitoring",
            "sources": [
                "https://vedas.sac.gov.in/ - Earth observation portal",
                "Environmental monitoring datasets",
                "Land use and land cover analysis"
            ]
        },
        {
            "name": "API Integration",
            "description": "Look for ISRO APIs or data services",
            "sources": [
                "Check for REST APIs in ISRO portals",
                "Look for data download services",
                "Contact ISRO for data access permissions"
            ]
        },
        {
            "name": "Research Collaboration",
            "description": "Access ISRO data through academic or research partnerships",
            "sources": [
                "ISRO academic collaboration programs",
                "Research data sharing agreements",
                "Published research papers with ISRO data"
            ]
        }
    ]
    
    for i, alt in enumerate(alternatives, 1):
        print(f"\n{i}. {alt['name']}")
        print(f"   {alt['description']}")
        for source in alt['sources']:
            print(f"   • {source}")

def main():
    accessible, air_quality = check_isro_data_sources()
    suggest_isro_data_alternatives()
    
    print(f"\n" + "=" * 50)
    print("NEXT STEPS")
    print("=" * 50)
    
    if air_quality:
        print("\n✅ Found ISRO sources with air quality data!")
        print("Recommended actions:")
        print("1. Run the ISRO AQI scraper: python isro_aqi_scraper.py")
        print("2. Focus on the sources that showed air quality keywords")
        print("3. Check if any APIs or data download services are available")
    else:
        print("\n⚠️  No direct air quality data found in accessible ISRO sources.")
        print("Recommended actions:")
        print("1. Try the alternative approaches listed above")
        print("2. Use satellite imagery for pollution pattern analysis")
        print("3. Contact ISRO directly for data access information")
        print("4. Look for published research using ISRO air quality data")

if __name__ == "__main__":
    main()
