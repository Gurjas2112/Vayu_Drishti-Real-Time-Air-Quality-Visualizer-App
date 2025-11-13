#!/usr/bin/env python3
"""
Enhanced Integrated Data Pipeline with Temporal Expansion
===========================================================

This pipeline:
1. Loads CPCB ground station data
2. Expands temporally (generates data for multiple days/hours)
3. Adds MERRA-2 meteorological data
4. Adds INSAT-3DR satellite data
5. Creates integrated dataset with 24+ features

Result: 3400+ records expanded to 20,000+ records (7 days × 24 hours)
"""

import os
import sys
import numpy as np
import pandas as pd
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, List, Tuple
from tqdm import tqdm
import logging

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('integrated_pipeline_v2.log', encoding='utf-8'),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)


class EnhancedIntegratedDataPipeline:
    """
    Enhanced pipeline with temporal expansion for realistic time-series dataset.
    """
    
    def __init__(self, output_dir: str = None, num_days: int = 7, hours_per_day: int = 24):
        """
        Initialize enhanced pipeline.
        
        Args:
            output_dir: Directory to save processed datasets
            num_days: Number of days to generate historical data (default: 7)
            hours_per_day: Hours to sample per day (default: 24 for hourly data)
        """
        self.output_dir = output_dir or os.path.dirname(__file__)
        self.num_days = num_days
        self.hours_per_day = hours_per_day
        
        # Data paths
        self.cpcb_data_path = os.path.join(self.output_dir, 'aqi_data_final.csv')
        self.merra2_data_path = os.path.join(self.output_dir, 'merra2_meteorological_data_v2.csv')
        self.insat_data_path = os.path.join(self.output_dir, 'insat3dr_satellite_data_v2.csv')
        self.integrated_data_path = os.path.join(self.output_dir, 'integrated_aqi_dataset_v2.csv')
        
        logger.info("=" * 80)
        logger.info("🌍 ENHANCED INTEGRATED DATA PIPELINE v2.0")
        logger.info("=" * 80)
        logger.info("📊 Temporal Expansion Configuration:")
        logger.info(f"   Historical Days: {num_days}")
        logger.info(f"   Hours per Day: {hours_per_day}")
        logger.info(f"   Expected Records: 3400 × {num_days} × {hours_per_day//24} = ~{3400 * num_days * hours_per_day // 24:,}")
        logger.info("📡 Data Sources: CPCB + MERRA-2 + INSAT-3DR")
        logger.info("=" * 80)
    
    def load_and_expand_cpcb_data(self) -> pd.DataFrame:
        """
        Load CPCB data and expand temporally by generating historical hours.
        
        Returns:
            Expanded DataFrame with temporal dimension
        """
        logger.info("\n📊 STEP 1: Loading & Expanding CPCB Data")
        logger.info("-" * 80)
        
        # Load original data
        df = pd.read_csv(self.cpcb_data_path)
        logger.info(f"✅ Loaded CPCB data: {len(df):,} records")
        logger.info(f"   Columns: {', '.join(df.columns[:8])}...")
        
        # Parse the base timestamp
        df['last_update'] = pd.to_datetime(df['last_update'], format='%d-%m-%Y %H:%M:%S', errors='coerce')
        base_timestamp = df['last_update'].iloc[0]
        logger.info(f"   Base timestamp: {base_timestamp}")
        
        # Pivot to get one row per station (wide format)
        df_pivot = df.pivot_table(
            index=['country', 'state', 'city', 'station', 'latitude', 'longitude', 'last_update'],
            columns='pollutant_id',
            values='pollutant_avg',
            aggfunc='mean'
        ).reset_index()
        
        logger.info(f"📊 Pivoted to station-level: {len(df_pivot):,} unique stations")
        
        # Generate historical timestamps
        timestamps = []
        for day_offset in range(self.num_days):
            for hour in range(0, 24, 24 // self.hours_per_day):
                ts = base_timestamp - timedelta(days=self.num_days - 1 - day_offset, hours=24 - hour)
                timestamps.append(ts)
        
        logger.info(f"⏰ Generating {len(timestamps)} timestamps over {self.num_days} days")
        
        # Expand each station record across all timestamps
        expanded_records = []
        for _, station_row in tqdm(df_pivot.iterrows(), total=len(df_pivot), desc="Expanding stations"):
            for timestamp in timestamps:
                record = station_row.to_dict()
                record['last_update'] = timestamp
                record['timestamp'] = timestamp
                
                # Add temporal variation to pollutants (realistic diurnal patterns)
                hour = timestamp.hour
                day_factor = 1 + 0.3 * np.sin(2 * np.pi * hour / 24 - np.pi/2)  # Peak afternoon
                noise_factor = np.random.uniform(0.8, 1.2)
                
                for pollutant in ['PM2.5', 'PM10', 'NO2', 'SO2', 'CO', 'OZONE', 'NH3']:
                    if pollutant in record and pd.notna(record[pollutant]):
                        record[pollutant] = record[pollutant] * day_factor * noise_factor
                
                expanded_records.append(record)
        
        df_expanded = pd.DataFrame(expanded_records)
        logger.info(f"✅ Expanded dataset: {len(df_expanded):,} records")
        logger.info(f"   Expansion factor: {len(df_expanded) / len(df_pivot):.1f}x")
        
        return df_expanded
    
    def generate_merra2_data(self, df_cpcb: pd.DataFrame) -> pd.DataFrame:
        """
        Generate MERRA-2 meteorological data for each CPCB record.
        """
        logger.info("\n🌦️  STEP 2: Generating MERRA-2 Meteorological Data")
        logger.info("-" * 80)
        logger.info("ℹ️  Note: Using synthetic data. In production, connect to NASA MERRA-2 API")
        logger.info("   API: https://disc.gsfc.nasa.gov/datasets/")
        
        merra2_data = []
        for _, row in tqdm(df_cpcb.iterrows(), total=len(df_cpcb), desc="Generating MERRA-2 data"):
            timestamp = row['timestamp']
            lat, lon = row['latitude'], row['longitude']
            hour = timestamp.hour
            month = timestamp.month
            
            # Seasonal patterns
            temp_base = 25 + 10 * np.sin(2 * np.pi * (month - 3) / 12)  # Peak May-June
            humidity_base = 60 + 20 * np.sin(2 * np.pi * month / 12 + np.pi)  # Peak monsoon
            
            # Diurnal patterns
            temp_daily = 5 * np.sin(2 * np.pi * (hour - 6) / 24)  # Peak afternoon
            humidity_daily = -10 * np.sin(2 * np.pi * (hour - 6) / 24)
            
            # Add noise
            temp = temp_base + temp_daily + np.random.normal(0, 2)
            humidity = np.clip(humidity_base + humidity_daily + np.random.normal(0, 5), 0, 100)
            wind_speed = np.abs(np.random.normal(3, 1.5))
            wind_direction = np.random.uniform(0, 360)
            pressure = 1013 + np.random.normal(0, 10)
            precipitation = np.random.gamma(2, 0.5) if np.random.random() < 0.15 else 0
            
            # MERRA-2 specific
            boundary_layer_height = 500 + 1000 * np.sin(2 * np.pi * (hour - 6) / 24) + np.random.normal(0, 100)
            surface_pressure = pressure + np.random.normal(0, 5)
            
            merra2_data.append({
                'latitude': lat,
                'longitude': lon,
                'timestamp': timestamp,
                'temperature': temp,
                'humidity': humidity,
                'wind_speed': wind_speed,
                'wind_direction': wind_direction,
                'pressure': pressure,
                'precipitation': precipitation,
                'boundary_layer_height': boundary_layer_height,
                'surface_pressure': surface_pressure
            })
        
        df_merra2 = pd.DataFrame(merra2_data)
        logger.info(f"✅ Generated MERRA-2 data: {len(df_merra2):,} records")
        
        # Save
        df_merra2.to_csv(self.merra2_data_path, index=False)
        logger.info(f"💾 Saved to: {self.merra2_data_path}")
        
        return df_merra2
    
    def generate_insat3dr_data(self, df_cpcb: pd.DataFrame) -> pd.DataFrame:
        """
        Generate INSAT-3DR satellite data for each CPCB record.
        """
        logger.info("\n🛰️  STEP 3: Generating INSAT-3DR Satellite Data")
        logger.info("-" * 80)
        logger.info("ℹ️  Note: Using synthetic data. In production, connect to ISRO MOSDAC")
        logger.info("   API: https://www.mosdac.gov.in/")
        
        insat_data = []
        for _, row in tqdm(df_cpcb.iterrows(), total=len(df_cpcb), desc="Generating INSAT-3DR data"):
            timestamp = row['timestamp']
            lat, lon = row['latitude'], row['longitude']
            hour = timestamp.hour
            month = timestamp.month
            
            # AOD550 seasonal pattern (winter pollution peak in India)
            aod_seasonal = 0.3 + 0.2 * np.sin(2 * np.pi * (month - 11) / 12)  # Peak Nov-Jan
            aod_daily = 0.1 * (1 - abs(hour - 12) / 12)  # Peak at noon
            aod550 = np.clip(aod_seasonal + aod_daily + np.random.normal(0, 0.05), 0.05, 1.5)
            
            aerosol_index = aod550 * np.random.uniform(1.5, 2.5)
            cloud_fraction = np.random.beta(2, 5)  # More clear days
            surface_reflectance = np.random.uniform(0.05, 0.15)
            angstrom_exponent = np.random.uniform(1.0, 2.0)
            single_scattering_albedo = np.random.uniform(0.85, 0.95)
            
            insat_data.append({
                'latitude': lat,
                'longitude': lon,
                'timestamp': timestamp,
                'aod550': aod550,
                'aerosol_index': aerosol_index,
                'cloud_fraction': cloud_fraction,
                'surface_reflectance': surface_reflectance,
                'angstrom_exponent': angstrom_exponent,
                'single_scattering_albedo': single_scattering_albedo
            })
        
        df_insat = pd.DataFrame(insat_data)
        logger.info(f"✅ Generated INSAT-3DR data: {len(df_insat):,} records")
        
        # Save
        df_insat.to_csv(self.insat_data_path, index=False)
        logger.info(f"💾 Saved to: {self.insat_data_path}")
        
        return df_insat
    
    def integrate_data_sources(self, df_cpcb: pd.DataFrame, df_merra2: pd.DataFrame, 
                               df_insat: pd.DataFrame) -> pd.DataFrame:
        """
        Merge all three data sources on spatial-temporal keys.
        """
        logger.info("\n🔗 STEP 4: Integrating Data Sources")
        logger.info("-" * 80)
        
        # Merge CPCB + MERRA-2
        logger.info("   Merging CPCB + MERRA-2...")
        df_merged = pd.merge(
            df_cpcb,
            df_merra2,
            on=['latitude', 'longitude', 'timestamp'],
            how='left'
        )
        logger.info(f"   ✅ Merged records: {len(df_merged):,}")
        
        # Merge with INSAT-3DR
        logger.info("   Merging + INSAT-3DR...")
        df_integrated = pd.merge(
            df_merged,
            df_insat,
            on=['latitude', 'longitude', 'timestamp'],
            how='left'
        )
        logger.info(f"   ✅ Integrated records: {len(df_integrated):,}")
        
        # Calculate AQI
        logger.info("   Calculating AQI...")
        df_integrated['AQI'] = df_integrated.apply(self._calculate_aqi, axis=1)
        
        # Add data coverage flags
        df_integrated['has_cpcb'] = df_integrated['PM2.5'].notna() | df_integrated['PM10'].notna()
        df_integrated['has_merra2'] = df_integrated['temperature'].notna()
        df_integrated['has_insat'] = df_integrated['aod550'].notna()
        
        logger.info(f"\n📊 Integrated Dataset Summary:")
        logger.info(f"   Total records: {len(df_integrated):,}")
        logger.info(f"   CPCB coverage: {df_integrated['has_cpcb'].sum():,} ({df_integrated['has_cpcb'].mean()*100:.1f}%)")
        logger.info(f"   MERRA-2 coverage: {df_integrated['has_merra2'].sum():,} ({df_integrated['has_merra2'].mean()*100:.1f}%)")
        logger.info(f"   INSAT-3DR coverage: {df_integrated['has_insat'].sum():,} ({df_integrated['has_insat'].mean()*100:.1f}%)")
        
        # Save
        df_integrated.to_csv(self.integrated_data_path, index=False)
        file_size = os.path.getsize(self.integrated_data_path) / (1024 * 1024)
        logger.info(f"\n💾 Saved integrated dataset to: {self.integrated_data_path}")
        logger.info(f"   Size: {file_size:.2f} MB")
        
        return df_integrated
    
    def _calculate_aqi(self, row: pd.Series) -> float:
        """Calculate AQI from pollutants (simplified)."""
        pm25 = row.get('PM2.5', np.nan)
        pm10 = row.get('PM10', np.nan)
        
        if pd.notna(pm25):
            return pm25 * 2  # Simplified AQI
        elif pd.notna(pm10):
            return pm10 * 1.5
        else:
            return np.nan
    
    def create_train_val_test_splits(self, df: pd.DataFrame, 
                                     train_ratio: float = 0.7,
                                     val_ratio: float = 0.15) -> Tuple[pd.DataFrame, pd.DataFrame, pd.DataFrame]:
        """
        Create temporal train/val/test splits.
        """
        logger.info("\n🔧 STEP 5: Creating Train/Val/Test Splits")
        logger.info("-" * 80)
        
        # Remove records without AQI
        df_valid = df[df['AQI'].notna()].copy()
        logger.info(f"   Records with valid AQI: {len(df_valid):,}")
        
        # Sort by timestamp for temporal split
        df_valid = df_valid.sort_values('timestamp')
        
        # Split indices
        n = len(df_valid)
        train_end = int(n * train_ratio)
        val_end = int(n * (train_ratio + val_ratio))
        
        train_df = df_valid.iloc[:train_end]
        val_df = df_valid.iloc[train_end:val_end]
        test_df = df_valid.iloc[val_end:]
        
        logger.info(f"\n✅ Data splits created:")
        logger.info(f"   Training set:   {len(train_df):,} records ({len(train_df)/n*100:.1f}%)")
        logger.info(f"   Validation set: {len(val_df):,} records ({len(val_df)/n*100:.1f}%)")
        logger.info(f"   Test set:       {len(test_df):,} records ({len(test_df)/n*100:.1f}%)")
        
        # Save
        train_path = os.path.join(self.output_dir, 'train_data_integrated_v2.csv')
        val_path = os.path.join(self.output_dir, 'val_data_integrated_v2.csv')
        test_path = os.path.join(self.output_dir, 'test_data_integrated_v2.csv')
        
        train_df.to_csv(train_path, index=False)
        val_df.to_csv(val_path, index=False)
        test_df.to_csv(test_path, index=False)
        
        logger.info(f"\n💾 Saved data splits:")
        logger.info(f"   {train_path}")
        logger.info(f"   {val_path}")
        logger.info(f"   {test_path}")
        
        return train_df, val_df, test_df
    
    def run_pipeline(self):
        """Execute the complete pipeline."""
        logger.info("\n" + "=" * 80)
        logger.info("🚀 STARTING ENHANCED INTEGRATED DATA PIPELINE")
        logger.info("=" * 80)
        
        # Step 1: Load and expand CPCB data
        df_cpcb_expanded = self.load_and_expand_cpcb_data()
        
        # Step 2: Generate MERRA-2 data
        df_merra2 = self.generate_merra2_data(df_cpcb_expanded)
        
        # Step 3: Generate INSAT-3DR data
        df_insat = self.generate_insat3dr_data(df_cpcb_expanded)
        
        # Step 4: Integrate all sources
        df_integrated = self.integrate_data_sources(df_cpcb_expanded, df_merra2, df_insat)
        
        # Step 5: Create splits
        train_df, val_df, test_df = self.create_train_val_test_splits(df_integrated)
        
        logger.info("\n" + "=" * 80)
        logger.info("✅ ENHANCED INTEGRATED DATA PIPELINE COMPLETED SUCCESSFULLY")
        logger.info("=" * 80)
        logger.info(f"\n📊 Final Dataset Summary:")
        logger.info(f"   Data Sources: CPCB + MERRA-2 + INSAT-3DR")
        logger.info(f"   Total records: {len(df_integrated):,}")
        logger.info(f"   Features: ~24 (7 pollutants + 9 MERRA-2 + 6 INSAT-3DR + 2 location)")
        logger.info(f"   Training samples: {len(train_df):,}")
        logger.info(f"   Validation samples: {len(val_df):,}")
        logger.info(f"   Test samples: {len(test_df):,}")
        logger.info(f"\n🎯 Next Step: Train LSTM models on integrated dataset")
        logger.info("=" * 80)


if __name__ == "__main__":
    # Initialize pipeline with 7 days of hourly data
    pipeline = EnhancedIntegratedDataPipeline(
        output_dir=os.path.dirname(__file__),
        num_days=7,  # Generate 7 days of historical data
        hours_per_day=24  # Hourly data
    )
    
    # Run complete pipeline
    pipeline.run_pipeline()
