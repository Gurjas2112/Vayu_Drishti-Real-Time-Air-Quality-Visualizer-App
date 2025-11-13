"""
Integrated Data Pipeline - CPCB + MERRA-2 + INSAT-3DR
Vayu Drishti - Real-Time Air Quality Visualizer & Forecast App

This module integrates three data sources as per the system architecture:
1. CPCB Ground Stations - Real-time pollutant measurements
2. MERRA-2 Meteorological Data - Weather reanalysis data
3. INSAT-3DR Satellite Data - Aerosol Optical Depth (AOD)

Architecture:
    Satellite Data (INSAT-3DR) ──┐
    Meteorological (MERRA-2) ────┤──> Data Processing ──> ML Pipeline
    Ground Stations (CPCB) ──────┘
"""

import os
import sys
import pandas as pd
import numpy as np
import requests
import json
import logging
from datetime import datetime, timedelta
from typing import List, Dict, Optional, Tuple
from tqdm import tqdm
import warnings
warnings.filterwarnings('ignore')

# Scikit-learn imports
from sklearn.impute import KNNImputer
from sklearn.preprocessing import StandardScaler
from sklearn.model_selection import train_test_split

# Set random seed for reproducibility
RANDOM_SEED = 42
np.random.seed(RANDOM_SEED)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('integrated_pipeline.log', encoding='utf-8'),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)


class IntegratedDataPipeline:
    """
    Integrated data pipeline combining three data sources:
    - CPCB Ground Stations (pollutant measurements)
    - MERRA-2 Meteorological Data (weather parameters)
    - INSAT-3DR Satellite Data (aerosol optical depth)
    """
    
    def __init__(self, output_dir: str = None):
        """
        Initialize the integrated data pipeline.
        
        Args:
            output_dir: Directory to save processed datasets
        """
        self.output_dir = output_dir or os.path.dirname(__file__)
        
        # Data source paths
        self.cpcb_data_path = os.path.join(self.output_dir, 'aqi_data_final.csv')
        self.merra2_data_path = os.path.join(self.output_dir, 'merra2_meteorological_data.csv')
        self.insat_data_path = os.path.join(self.output_dir, 'insat3dr_satellite_data.csv')
        self.integrated_data_path = os.path.join(self.output_dir, 'integrated_aqi_dataset.csv')
        
        # Indian cities with coordinates
        self.cities = self._get_major_cities()
        
        logger.info("=" * 80)
        logger.info("🌍 INTEGRATED DATA PIPELINE - Multi-Source AQI System")
        logger.info("=" * 80)
        logger.info("📡 Data Sources:")
        logger.info("  1. CPCB Ground Stations   - Real-time pollutant measurements")
        logger.info("  2. MERRA-2 Meteorological - NASA weather reanalysis")
        logger.info("  3. INSAT-3DR Satellite    - ISRO aerosol optical depth")
        logger.info(f"🎯 Target Cities: {len(self.cities)}")
        logger.info(f"📁 Output Directory: {self.output_dir}")
        logger.info("=" * 80)
    
    def _get_major_cities(self) -> List[Dict]:
        """
        Get list of major Indian cities with coordinates for data integration.
        
        Returns:
            List of city dictionaries with metadata
        """
        cities = [
            {'name': 'Delhi', 'lat': 28.6139, 'lon': 77.2090, 'region': 'North'},
            {'name': 'Mumbai', 'lat': 19.0760, 'lon': 72.8777, 'region': 'West'},
            {'name': 'Bangalore', 'lat': 12.9716, 'lon': 77.5946, 'region': 'South'},
            {'name': 'Kolkata', 'lat': 22.5726, 'lon': 88.3639, 'region': 'East'},
            {'name': 'Chennai', 'lat': 13.0827, 'lon': 80.2707, 'region': 'South'},
            {'name': 'Hyderabad', 'lat': 17.3850, 'lon': 78.4867, 'region': 'South'},
            {'name': 'Pune', 'lat': 18.5204, 'lon': 73.8567, 'region': 'West'},
            {'name': 'Ahmedabad', 'lat': 23.0225, 'lon': 72.5714, 'region': 'West'},
            {'name': 'Jaipur', 'lat': 26.9124, 'lon': 75.7873, 'region': 'North'},
            {'name': 'Lucknow', 'lat': 26.8467, 'lon': 80.9462, 'region': 'North'},
            {'name': 'Chandigarh', 'lat': 30.7333, 'lon': 76.7794, 'region': 'North'},
            {'name': 'Bhopal', 'lat': 23.2599, 'lon': 77.4126, 'region': 'Central'},
        ]
        return cities
    
    def load_cpcb_data(self) -> pd.DataFrame:
        """
        Load CPCB ground station data from CSV.
        
        Returns:
            DataFrame with CPCB pollutant measurements
        """
        logger.info("\n📊 STEP 1: Loading CPCB Ground Station Data")
        logger.info("-" * 80)
        
        if not os.path.exists(self.cpcb_data_path):
            logger.error(f"❌ CPCB data file not found: {self.cpcb_data_path}")
            raise FileNotFoundError(f"CPCB data file not found: {self.cpcb_data_path}")
        
        # Load CPCB data
        df = pd.read_csv(self.cpcb_data_path)
        logger.info(f"✅ Loaded CPCB data: {len(df)} records")
        logger.info(f"   Columns: {', '.join(df.columns.tolist())}")
        logger.info(f"   Date range: {df['last_update'].min()} to {df['last_update'].max()}")
        
        # Pivot pollutants to columns
        df_pivoted = df.pivot_table(
            index=['country', 'state', 'city', 'station', 'last_update', 'latitude', 'longitude'],
            columns='pollutant_id',
            values='pollutant_avg',
            aggfunc='mean'
        ).reset_index()
        
        # Flatten column names
        df_pivoted.columns.name = None
        
        logger.info(f"✅ Pivoted data: {len(df_pivoted)} station-time records")
        logger.info(f"   Pollutants: {[col for col in df_pivoted.columns if col not in ['country', 'state', 'city', 'station', 'last_update', 'latitude', 'longitude']]}")
        
        return df_pivoted
    
    def generate_merra2_data(self, df_cpcb: pd.DataFrame) -> pd.DataFrame:
        """
        Generate MERRA-2 meteorological data for CPCB locations.
        
        In production, this would fetch real MERRA-2 data from NASA's API.
        For now, generates synthetic meteorological parameters.
        
        Args:
            df_cpcb: DataFrame with CPCB station locations
            
        Returns:
            DataFrame with meteorological parameters
        """
        logger.info("\n🌦️  STEP 2: Generating MERRA-2 Meteorological Data")
        logger.info("-" * 80)
        logger.info("ℹ️  Note: Using synthetic data. In production, connect to NASA MERRA-2 API")
        logger.info("   API: https://disc.gsfc.nasa.gov/datasets/")
        
        # Create meteorological features for each CPCB record
        merra2_data = []
        
        for idx, row in tqdm(df_cpcb.iterrows(), total=len(df_cpcb), desc="Generating MERRA-2 data"):
            # Parse timestamp
            try:
                timestamp = pd.to_datetime(row['last_update'], format='%d-%m-%Y %H:%M:%S')
            except:
                timestamp = pd.to_datetime(row['last_update'])
            
            # Seasonal patterns
            month = timestamp.month
            hour = timestamp.hour
            
            # Base meteorological parameters with realistic variations
            temp_base = 25 + 10 * np.sin(2 * np.pi * month / 12)  # Seasonal temperature
            humidity_base = 60 + 20 * np.sin(2 * np.pi * month / 12 + np.pi)  # Seasonal humidity
            
            # Add daily variation
            temp_daily = 5 * np.sin(2 * np.pi * hour / 24)
            humidity_daily = -10 * np.sin(2 * np.pi * hour / 24)
            
            # Add random noise
            temp = temp_base + temp_daily + np.random.normal(0, 2)
            humidity = np.clip(humidity_base + humidity_daily + np.random.normal(0, 5), 0, 100)
            wind_speed = np.abs(np.random.normal(3, 1.5))
            wind_direction = np.random.uniform(0, 360)
            pressure = 1013 + np.random.normal(0, 10)
            precipitation = np.random.gamma(2, 0.5) if np.random.random() < 0.2 else 0
            
            # MERRA-2 specific parameters
            boundary_layer_height = 500 + 1000 * np.sin(2 * np.pi * hour / 24) + np.random.normal(0, 100)
            surface_pressure = pressure + np.random.normal(0, 5)
            temperature_2m = temp + np.random.normal(0, 0.5)
            specific_humidity = humidity / 100 * 0.02  # kg/kg
            
            merra2_data.append({
                'latitude': row['latitude'],
                'longitude': row['longitude'],
                'timestamp': timestamp,
                'temperature': temp,
                'humidity': humidity,
                'wind_speed': wind_speed,
                'wind_direction': wind_direction,
                'pressure': pressure,
                'precipitation': precipitation,
                'boundary_layer_height': boundary_layer_height,
                'surface_pressure': surface_pressure,
                'temperature_2m': temperature_2m,
                'specific_humidity': specific_humidity,
                'data_source': 'MERRA-2'
            })
        
        df_merra2 = pd.DataFrame(merra2_data)
        logger.info(f"✅ Generated MERRA-2 data: {len(df_merra2)} records")
        logger.info(f"   Parameters: temperature, humidity, wind_speed, wind_direction, pressure,")
        logger.info(f"              precipitation, boundary_layer_height, surface_pressure, etc.")
        
        # Save MERRA-2 data
        df_merra2.to_csv(self.merra2_data_path, index=False)
        logger.info(f"💾 Saved MERRA-2 data to: {self.merra2_data_path}")
        
        return df_merra2
    
    def generate_insat3dr_data(self, df_cpcb: pd.DataFrame) -> pd.DataFrame:
        """
        Generate INSAT-3DR satellite data for CPCB locations.
        
        In production, this would fetch real INSAT-3DR data from ISRO's MOSDAC portal.
        For now, generates synthetic aerosol optical depth (AOD) data.
        
        Args:
            df_cpcb: DataFrame with CPCB station locations
            
        Returns:
            DataFrame with satellite-derived parameters
        """
        logger.info("\n🛰️  STEP 3: Generating INSAT-3DR Satellite Data")
        logger.info("-" * 80)
        logger.info("ℹ️  Note: Using synthetic data. In production, connect to ISRO MOSDAC")
        logger.info("   API: https://www.mosdac.gov.in/")
        
        # Create satellite features for each CPCB record
        insat_data = []
        
        for idx, row in tqdm(df_cpcb.iterrows(), total=len(df_cpcb), desc="Generating INSAT-3DR data"):
            # Parse timestamp
            try:
                timestamp = pd.to_datetime(row['last_update'], format='%d-%m-%Y %H:%M:%S')
            except:
                timestamp = pd.to_datetime(row['last_update'])
            
            # Seasonal and hourly patterns for AOD
            month = timestamp.month
            hour = timestamp.hour
            
            # AOD550 (Aerosol Optical Depth at 550nm) - higher in winter/pollution events
            aod_seasonal = 0.3 + 0.2 * np.sin(2 * np.pi * (month - 1) / 12)  # Peak in Nov-Feb
            aod_daily = 0.1 * (1 - np.abs(hour - 12) / 12)  # Peak at noon
            aod550 = np.clip(aod_seasonal + aod_daily + np.random.normal(0, 0.05), 0.05, 1.5)
            
            # Additional satellite parameters
            aerosol_index = aod550 * 2.5 + np.random.normal(0, 0.1)  # Unitless
            cloud_fraction = np.clip(np.random.beta(2, 5), 0, 1)  # 0-1
            surface_reflectance = 0.1 + np.random.normal(0, 0.02)
            
            # Angstrom exponent (particle size indicator)
            angstrom_exponent = 1.5 + np.random.normal(0, 0.2)
            
            # Single scattering albedo
            single_scattering_albedo = 0.95 + np.random.normal(0, 0.02)
            
            insat_data.append({
                'latitude': row['latitude'],
                'longitude': row['longitude'],
                'timestamp': timestamp,
                'aod550': aod550,
                'aerosol_index': aerosol_index,
                'cloud_fraction': cloud_fraction,
                'surface_reflectance': surface_reflectance,
                'angstrom_exponent': angstrom_exponent,
                'single_scattering_albedo': single_scattering_albedo,
                'satellite': 'INSAT-3DR',
                'data_source': 'INSAT-3DR'
            })
        
        df_insat = pd.DataFrame(insat_data)
        logger.info(f"✅ Generated INSAT-3DR data: {len(df_insat)} records")
        logger.info(f"   Parameters: aod550 (Aerosol Optical Depth), aerosol_index,")
        logger.info(f"              cloud_fraction, angstrom_exponent, etc.")
        
        # Save INSAT-3DR data
        df_insat.to_csv(self.insat_data_path, index=False)
        logger.info(f"💾 Saved INSAT-3DR data to: {self.insat_data_path}")
        
        return df_insat
    
    def integrate_data_sources(self, df_cpcb: pd.DataFrame, 
                                df_merra2: pd.DataFrame, 
                                df_insat: pd.DataFrame) -> pd.DataFrame:
        """
        Integrate all three data sources into a unified dataset.
        
        Args:
            df_cpcb: CPCB ground station data
            df_merra2: MERRA-2 meteorological data
            df_insat: INSAT-3DR satellite data
            
        Returns:
            Integrated DataFrame with all features
        """
        logger.info("\n🔗 STEP 4: Integrating Data Sources")
        logger.info("-" * 80)
        
        # Prepare CPCB data
        df_cpcb['timestamp'] = pd.to_datetime(df_cpcb['last_update'], format='%d-%m-%Y %H:%M:%S', errors='coerce')
        
        # Merge CPCB with MERRA-2 on location and timestamp
        logger.info("   Merging CPCB + MERRA-2...")
        df_merged = pd.merge(
            df_cpcb,
            df_merra2,
            on=['latitude', 'longitude', 'timestamp'],
            how='left'
        )
        logger.info(f"   ✅ Merged records: {len(df_merged)}")
        
        # Merge with INSAT-3DR on location and timestamp
        logger.info("   Merging CPCB + MERRA-2 + INSAT-3DR...")
        df_integrated = pd.merge(
            df_merged,
            df_insat,
            on=['latitude', 'longitude', 'timestamp'],
            how='left',
            suffixes=('', '_insat')
        )
        logger.info(f"   ✅ Integrated records: {len(df_integrated)}")
        
        # Add data source flags
        df_integrated['has_cpcb'] = True
        df_integrated['has_merra2'] = df_integrated['temperature'].notna()
        df_integrated['has_insat'] = df_integrated['aod550'].notna()
        
        # Calculate AQI if not present
        if 'AQI' not in df_integrated.columns:
            df_integrated['AQI'] = self._calculate_aqi(df_integrated)
        
        logger.info("\n📊 Integrated Dataset Summary:")
        logger.info(f"   Total records: {len(df_integrated)}")
        logger.info(f"   CPCB coverage: {df_integrated['has_cpcb'].sum()} records ({df_integrated['has_cpcb'].sum()/len(df_integrated)*100:.1f}%)")
        logger.info(f"   MERRA-2 coverage: {df_integrated['has_merra2'].sum()} records ({df_integrated['has_merra2'].sum()/len(df_integrated)*100:.1f}%)")
        logger.info(f"   INSAT-3DR coverage: {df_integrated['has_insat'].sum()} records ({df_integrated['has_insat'].sum()/len(df_integrated)*100:.1f}%)")
        logger.info(f"   Complete records: {(df_integrated['has_cpcb'] & df_integrated['has_merra2'] & df_integrated['has_insat']).sum()}")
        
        # Save integrated data
        df_integrated.to_csv(self.integrated_data_path, index=False)
        logger.info(f"\n💾 Saved integrated dataset to: {self.integrated_data_path}")
        logger.info(f"   Size: {os.path.getsize(self.integrated_data_path) / (1024*1024):.2f} MB")
        
        return df_integrated
    
    def _calculate_aqi(self, df: pd.DataFrame) -> pd.Series:
        """
        Calculate AQI from pollutant concentrations.
        Uses simplified AQI calculation based on PM2.5 and PM10.
        
        Args:
            df: DataFrame with pollutant columns
            
        Returns:
            Series with AQI values
        """
        aqi = pd.Series(index=df.index, dtype=float)
        
        # Use PM2.5 as primary indicator if available
        if 'PM2.5' in df.columns:
            pm25 = df['PM2.5'].fillna(0)
            # Simplified AQI calculation for PM2.5
            aqi = np.where(pm25 <= 30, pm25 * 50 / 30,
                  np.where(pm25 <= 60, 50 + (pm25 - 30) * 50 / 30,
                  np.where(pm25 <= 90, 100 + (pm25 - 60) * 100 / 30,
                  np.where(pm25 <= 120, 200 + (pm25 - 90) * 100 / 30,
                  np.where(pm25 <= 250, 300 + (pm25 - 120) * 100 / 130,
                          400 + (pm25 - 250) * 100 / 130)))))
        
        # Fallback to PM10 if PM2.5 not available
        elif 'PM10' in df.columns:
            pm10 = df['PM10'].fillna(0)
            aqi = np.where(pm10 <= 50, pm10,
                  np.where(pm10 <= 100, 50 + (pm10 - 50),
                  np.where(pm10 <= 250, 100 + (pm10 - 100) * 100 / 150,
                  np.where(pm10 <= 350, 200 + (pm10 - 250) * 100 / 100,
                          300 + (pm10 - 350) * 100 / 80))))
        else:
            # Default to moderate if no pollutants available
            aqi = 100
        
        return aqi
    
    def preprocess_integrated_data(self, df: pd.DataFrame) -> Tuple[pd.DataFrame, pd.DataFrame, pd.DataFrame]:
        """
        Preprocess integrated dataset and create train/val/test splits.
        
        Args:
            df: Integrated DataFrame
            
        Returns:
            Tuple of (train_df, val_df, test_df)
        """
        logger.info("\n🔧 STEP 5: Preprocessing Integrated Data")
        logger.info("-" * 80)
        
        # Remove rows with missing AQI
        df = df[df['AQI'].notna()].copy()
        logger.info(f"   Records with valid AQI: {len(df)}")
        
        # Select features for ML
        feature_columns = [
            # CPCB pollutants
            'PM2.5', 'PM10', 'NO2', 'SO2', 'CO', 'OZONE', 'NH3',
            # MERRA-2 meteorological
            'temperature', 'humidity', 'wind_speed', 'wind_direction', 
            'pressure', 'precipitation', 'boundary_layer_height',
            # INSAT-3DR satellite
            'aod550', 'aerosol_index', 'cloud_fraction', 'angstrom_exponent',
            # Location
            'latitude', 'longitude'
        ]
        
        # Keep only available features
        available_features = [col for col in feature_columns if col in df.columns]
        logger.info(f"   Available features: {len(available_features)}")
        
        # Create feature matrix
        X = df[available_features].copy()
        y = df['AQI'].copy()
        
        # Impute missing values
        logger.info("   Imputing missing values...")
        imputer = KNNImputer(n_neighbors=5)
        X_imputed = pd.DataFrame(
            imputer.fit_transform(X),
            columns=X.columns,
            index=X.index
        )
        
        # Add temporal features
        df['hour'] = df['timestamp'].dt.hour
        df['day_of_week'] = df['timestamp'].dt.dayofweek
        df['month'] = df['timestamp'].dt.month
        df['is_weekend'] = df['day_of_week'].isin([5, 6]).astype(int)
        
        temporal_features = ['hour', 'day_of_week', 'month', 'is_weekend']
        X_imputed[temporal_features] = df[temporal_features]
        
        # Combine features and target
        df_processed = X_imputed.copy()
        df_processed['AQI'] = y
        df_processed['city'] = df['city']
        df_processed['timestamp'] = df['timestamp']
        
        # Split data: 70% train, 15% validation, 15% test
        logger.info("   Creating train/val/test splits...")
        train_df, temp_df = train_test_split(df_processed, test_size=0.3, random_state=RANDOM_SEED)
        val_df, test_df = train_test_split(temp_df, test_size=0.5, random_state=RANDOM_SEED)
        
        logger.info(f"\n✅ Data splits created:")
        logger.info(f"   Training set:   {len(train_df)} records ({len(train_df)/len(df_processed)*100:.1f}%)")
        logger.info(f"   Validation set: {len(val_df)} records ({len(val_df)/len(df_processed)*100:.1f}%)")
        logger.info(f"   Test set:       {len(test_df)} records ({len(test_df)/len(df_processed)*100:.1f}%)")
        
        # Save splits
        train_path = os.path.join(self.output_dir, 'train_data_integrated.csv')
        val_path = os.path.join(self.output_dir, 'val_data_integrated.csv')
        test_path = os.path.join(self.output_dir, 'test_data_integrated.csv')
        
        train_df.to_csv(train_path, index=False)
        val_df.to_csv(val_path, index=False)
        test_df.to_csv(test_path, index=False)
        
        logger.info(f"\n💾 Saved data splits:")
        logger.info(f"   {train_path}")
        logger.info(f"   {val_path}")
        logger.info(f"   {test_path}")
        
        return train_df, val_df, test_df
    
    def run_pipeline(self):
        """
        Execute the complete integrated data pipeline.
        """
        logger.info("\n" + "=" * 80)
        logger.info("🚀 STARTING INTEGRATED DATA PIPELINE")
        logger.info("=" * 80)
        
        # Step 1: Load CPCB data
        df_cpcb = self.load_cpcb_data()
        
        # Step 2: Generate MERRA-2 meteorological data
        df_merra2 = self.generate_merra2_data(df_cpcb)
        
        # Step 3: Generate INSAT-3DR satellite data
        df_insat = self.generate_insat3dr_data(df_cpcb)
        
        # Step 4: Integrate all data sources
        df_integrated = self.integrate_data_sources(df_cpcb, df_merra2, df_insat)
        
        # Step 5: Preprocess and create splits
        train_df, val_df, test_df = self.preprocess_integrated_data(df_integrated)
        
        logger.info("\n" + "=" * 80)
        logger.info("✅ INTEGRATED DATA PIPELINE COMPLETED SUCCESSFULLY")
        logger.info("=" * 80)
        logger.info("\n📊 Final Dataset Summary:")
        logger.info(f"   Data Sources: CPCB + MERRA-2 + INSAT-3DR")
        logger.info(f"   Total features: {len(train_df.columns) - 3}")  # Exclude AQI, city, timestamp
        logger.info(f"   Training samples: {len(train_df)}")
        logger.info(f"   Validation samples: {len(val_df)}")
        logger.info(f"   Test samples: {len(test_df)}")
        logger.info("\n🎯 Next Step: Train LSTM + Random Forest models on integrated dataset")
        logger.info("   Command: python aqi_forecasting_model.py --use-integrated-data")
        logger.info("=" * 80)


def main():
    """
    Main execution function.
    """
    # Initialize pipeline
    pipeline = IntegratedDataPipeline()
    
    # Run complete pipeline
    pipeline.run_pipeline()


if __name__ == '__main__':
    main()
