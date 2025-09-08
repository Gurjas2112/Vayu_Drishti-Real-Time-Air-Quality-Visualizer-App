"""
ISRO Air Quality Data Collection Summary

This script provides a comprehensive summary of ISRO air quality data collection capabilities
and demonstrates the data structure available from ISRO satellite-based monitoring systems.
"""

import pandas as pd
import os
from datetime import datetime
import matplotlib.pyplot as plt
import seaborn as sns

def display_isro_data_summary():
    """Display comprehensive summary of ISRO air quality data collection"""
    
    print("ISRO AIR QUALITY DATA COLLECTION - SUMMARY REPORT")
    print("=" * 60)
    print(f"Generated on: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print()
    
    # Find the latest data files
    csv_files = [f for f in os.listdir('.') if f.startswith('isro_air_quality_data_') and f.endswith('.csv')]
    
    if not csv_files:
        print("❌ No ISRO air quality data files found!")
        return
    
    latest_file = sorted(csv_files)[-1]
    print(f"📁 Latest data file: {latest_file}")
    
    # Load and analyze the data
    df = pd.read_csv(latest_file)
    
    print("\n📊 DATA OVERVIEW")
    print("-" * 30)
    print(f"Total records: {len(df):,}")
    print(f"Date range: {df['timestamp'].min()} to {df['timestamp'].max()}")
    print(f"Data sources: {df['data_source'].nunique()}")
    print(f"Satellites: {df['satellite'].nunique()}")
    print(f"Cities covered: {df['city'].nunique()}")
    print(f"States covered: {df['state'].nunique()}")
    
    print("\n🛰️ DATA SOURCES")
    print("-" * 30)
    source_summary = df.groupby(['data_source', 'satellite']).size().reset_index(name='records')
    for _, row in source_summary.iterrows():
        print(f"• {row['data_source']} ({row['satellite']}): {row['records']} records")
    
    print("\n🏙️ GEOGRAPHICAL COVERAGE")
    print("-" * 30)
    location_summary = df.groupby(['city', 'state', 'region']).size().reset_index(name='records')
    for _, row in location_summary.iterrows():
        print(f"• {row['city']}, {row['state']} ({row['region']}): {row['records']} records")
    
    print("\n📈 AIR QUALITY STATISTICS")
    print("-" * 30)
    print(f"PM2.5 range: {df['pm25_ug_m3'].min():.1f} - {df['pm25_ug_m3'].max():.1f} μg/m³")
    print(f"PM10 range: {df['pm10_ug_m3'].min():.1f} - {df['pm10_ug_m3'].max():.1f} μg/m³")
    print(f"AQI range: {df['aqi'].min():.0f} - {df['aqi'].max():.0f}")
    print(f"Average AQI: {df['aqi'].mean():.1f}")
    
    # Air quality categorization
    df['aqi_category'] = pd.cut(df['aqi'], 
                               bins=[0, 50, 100, 150, 200, 300, float('inf')],
                               labels=['Good', 'Moderate', 'Unhealthy for Sensitive', 
                                      'Unhealthy', 'Very Unhealthy', 'Hazardous'])
    
    print(f"\n🎯 AQI DISTRIBUTION")
    print("-" * 30)
    aqi_dist = df['aqi_category'].value_counts()
    for category, count in aqi_dist.items():
        percentage = (count / len(df)) * 100
        print(f"• {category}: {count} records ({percentage:.1f}%)")
    
    print("\n🔬 SATELLITE DATA PARAMETERS")
    print("-" * 30)
    print(f"Aerosol Optical Depth range: {df['aerosol_optical_depth'].min():.3f} - {df['aerosol_optical_depth'].max():.3f}")
    print(f"Pixel resolutions: {', '.join(df['pixel_resolution'].unique())}")
    print(f"Data quality levels: {', '.join(df['data_quality'].unique())}")
    print(f"Processing levels: {', '.join(df['processing_level'].unique())}")
    
    print("\n🌍 REGIONAL ANALYSIS")
    print("-" * 30)
    regional_aqi = df.groupby('region')['aqi'].agg(['mean', 'min', 'max', 'count']).round(1)
    for region, stats in regional_aqi.iterrows():
        print(f"• {region}: Avg AQI {stats['mean']}, Range {stats['min']}-{stats['max']} ({stats['count']} records)")
    
    return df

def create_visualization(df):
    """Create basic visualization of ISRO air quality data"""
    try:
        print("\n📊 Creating data visualizations...")
        
        # Set up the plotting style
        plt.style.use('default')
        fig, ((ax1, ax2), (ax3, ax4)) = plt.subplots(2, 2, figsize=(15, 12))
        
        # 1. AQI by City
        city_aqi = df.groupby('city')['aqi'].mean().sort_values(ascending=True)
        city_aqi.plot(kind='barh', ax=ax1, color='skyblue')
        ax1.set_title('Average AQI by City (ISRO Satellite Data)')
        ax1.set_xlabel('AQI')
        
        # 2. PM2.5 vs PM10 correlation
        ax2.scatter(df['pm25_ug_m3'], df['pm10_ug_m3'], alpha=0.6, color='orange')
        ax2.set_xlabel('PM2.5 (μg/m³)')
        ax2.set_ylabel('PM10 (μg/m³)')
        ax2.set_title('PM2.5 vs PM10 Correlation')
        
        # 3. AQI distribution by data source
        sources = df['data_source'].unique()
        for i, source in enumerate(sources):
            source_data = df[df['data_source'] == source]['aqi']
            ax3.hist(source_data, alpha=0.7, label=source, bins=20)
        ax3.set_xlabel('AQI')
        ax3.set_ylabel('Frequency')
        ax3.set_title('AQI Distribution by Data Source')
        ax3.legend()
        
        # 4. Temporal pattern (hourly)
        df['hour'] = pd.to_datetime(df['timestamp']).dt.hour
        hourly_aqi = df.groupby('hour')['aqi'].mean()
        hourly_aqi.plot(kind='line', ax=ax4, marker='o', color='green')
        ax4.set_xlabel('Hour of Day')
        ax4.set_ylabel('Average AQI')
        ax4.set_title('Hourly AQI Pattern')
        ax4.grid(True, alpha=0.3)
        
        plt.tight_layout()
        plt.savefig('isro_air_quality_analysis.png', dpi=300, bbox_inches='tight')
        print("📈 Visualization saved as: isro_air_quality_analysis.png")
        
    except ImportError:
        print("⚠️  Matplotlib not available. Skipping visualization.")
    except Exception as e:
        print(f"⚠️  Visualization error: {str(e)}")

def show_data_usage_examples():
    """Show examples of how to use the ISRO air quality data"""
    
    print("\n💡 DATA USAGE EXAMPLES")
    print("=" * 60)
    
    examples = [
        {
            "title": "Real-time Air Quality Monitoring",
            "description": "Use ISRO satellite data for real-time air quality assessment",
            "code": """
# Load ISRO air quality data
df = pd.read_csv('isro_air_quality_data_latest.csv')

# Get current air quality for specific city
city_data = df[df['city'] == 'Delhi'].sort_values('timestamp').tail(1)
current_aqi = city_data['aqi'].values[0]
print(f"Current AQI in Delhi: {current_aqi}")
"""
        },
        {
            "title": "Air Quality Trend Analysis",
            "description": "Analyze air quality trends using satellite observations",
            "code": """
# Analyze PM2.5 trends by region
regional_trends = df.groupby(['region', 'timestamp'])['pm25_ug_m3'].mean()
print(regional_trends.head())

# Calculate daily averages
df['date'] = pd.to_datetime(df['timestamp']).dt.date
daily_avg = df.groupby('date')['aqi'].mean()
"""
        },
        {
            "title": "Satellite Data Quality Assessment",
            "description": "Evaluate data quality from different satellites",
            "code": """
# Compare data quality across satellites
quality_summary = df.groupby(['satellite', 'data_quality']).size()
print(quality_summary)

# Filter high-quality data only
high_quality = df[df['data_quality'] == 'Level-2']
print(f"High quality records: {len(high_quality)}")
"""
        },
        {
            "title": "Atmospheric Parameter Analysis",
            "description": "Analyze atmospheric parameters from satellite measurements",
            "code": """
# Correlate AOD with PM2.5
correlation = df[['aerosol_optical_depth', 'pm25_ug_m3']].corr()
print("AOD vs PM2.5 correlation:")
print(correlation)

# Analyze column density data
no2_stats = df['no2_column_density'].describe()
print("NO2 column density statistics:")
print(no2_stats)
"""
        }
    ]
    
    for i, example in enumerate(examples, 1):
        print(f"\n{i}. {example['title']}")
        print(f"   {example['description']}")
        print(f"   Code example:")
        print(example['code'])

def show_next_steps():
    """Show recommended next steps for ISRO air quality data collection"""
    
    print("\n🚀 RECOMMENDED NEXT STEPS")
    print("=" * 60)
    
    steps = [
        "1. API Integration",
        "   • Contact ISRO for official API access",
        "   • Explore MOSDAC data download services",
        "   • Set up automated data collection",
        
        "2. Data Enhancement", 
        "   • Combine ISRO data with ground station measurements",
        "   • Integrate weather data for better analysis",
        "   • Add real-time alerts and notifications",
        
        "3. Advanced Analytics",
        "   • Implement machine learning for AQI prediction",
        "   • Create pollution hotspot detection",
        "   • Develop air quality forecasting models",
        
        "4. Visualization & Reporting",
        "   • Build interactive dashboards",
        "   • Create automated reports",
        "   • Develop mobile-friendly interfaces",
        
        "5. Research Collaboration",
        "   • Partner with academic institutions",
        "   • Contribute to environmental research",
        "   • Publish findings and methodologies"
    ]
    
    for step in steps:
        print(step)

def main():
    """Main function to run the complete summary"""
    
    # Display data summary
    df = display_isro_data_summary()
    
    if df is not None:
        # Create visualizations
        create_visualization(df)
        
        # Show usage examples
        show_data_usage_examples()
        
        # Show next steps
        show_next_steps()
        
        print("\n✅ ISRO Air Quality Data Collection Summary Complete!")
        print("📁 Check the generated files for detailed data and visualizations.")
    else:
        print("❌ Unable to generate summary - no data files found.")

if __name__ == "__main__":
    main()
