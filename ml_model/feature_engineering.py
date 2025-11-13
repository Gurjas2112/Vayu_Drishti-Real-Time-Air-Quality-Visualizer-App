"""
Feature Engineering Module for AQI Prediction
Applies the same feature engineering as used in model training
"""
import numpy as np
import pandas as pd
from datetime import datetime

def engineer_features(features_dict):
    """
    Apply advanced feature engineering to match the 69 features used in training.
    
    Parameters:
    -----------
    features_dict : dict
        Dictionary with base features (pollutants, weather, satellite, timestamp)
    
    Returns:
    --------
    dict : Dictionary with all 69 engineered features
    """
    
    # Extract base features
    pm25 = features_dict.get('PM2.5', 0)
    pm10 = features_dict.get('PM10', 0)
    no2 = features_dict.get('NO2', 0)
    so2 = features_dict.get('SO2', 0)
    co = features_dict.get('CO', 0)
    ozone = features_dict.get('OZONE', 0)
    nh3 = features_dict.get('NH3', 0)
    
    temp = features_dict.get('temperature', 25)
    humidity = features_dict.get('humidity', 60)
    wind_speed = features_dict.get('wind_speed', 3)
    wind_dir = features_dict.get('wind_direction', 180)
    pressure = features_dict.get('pressure', 1013)
    precip = features_dict.get('precipitation', 0)
    bl_height = features_dict.get('boundary_layer_height', 500)
    surf_pressure = features_dict.get('surface_pressure', 1013)
    
    aod550 = features_dict.get('aod550', 0.3)
    aerosol_idx = features_dict.get('aerosol_index', 0.6)
    cloud_frac = features_dict.get('cloud_fraction', 0.2)
    surf_refl = features_dict.get('surface_reflectance', 0.1)
    angstrom = features_dict.get('angstrom_exponent', 1.5)
    ssa = features_dict.get('single_scattering_albedo', 0.9)
    
    timestamp = features_dict.get('timestamp', datetime.now())
    if isinstance(timestamp, str):
        timestamp = pd.to_datetime(timestamp)
    
    # Start with base features
    engineered = features_dict.copy()
    
    # 1. Pollutant Interactions
    engineered['pm_ratio'] = pm25 / (pm10 + 1e-6)
    engineered['pm_sum'] = pm25 + pm10
    engineered['pm_product'] = pm25 * pm10
    engineered['no2_so2_interaction'] = no2 * so2
    engineered['ozone_no2_ratio'] = ozone / (no2 + 1e-6)
    engineered['combustion_index'] = co + no2 + so2
    
    # 2. Weather-Pollutant Interactions
    engineered['heat_index'] = temp * humidity / 100
    engineered['pm_dispersion'] = pm25 / (wind_speed + 1e-6)
    engineered['pm_concentration'] = pm25 * (1 - humidity/100)
    engineered['temp_ozone'] = temp * ozone
    
    # 3. Atmospheric Stability Indicators
    engineered['mixing_potential'] = bl_height * wind_speed
    engineered['ventilation_coef'] = bl_height * wind_speed / (pm25 + 1e-6)
    engineered['air_density_proxy'] = pressure / (temp + 273.15)
    
    # 4. Satellite-Weather Interactions
    engineered['hygroscopic_growth'] = aod550 * (humidity / 100)
    engineered['aerosol_dispersion'] = aod550 / (wind_speed + 1e-6)
    
    # 5. Polynomial Features (capturing non-linear relationships)
    engineered['PM2.5_squared'] = pm25 ** 2
    engineered['PM2.5_cbrt'] = np.cbrt(pm25)
    engineered['PM10_squared'] = pm10 ** 2
    engineered['PM10_cbrt'] = np.cbrt(pm10)
    engineered['NO2_squared'] = no2 ** 2
    engineered['NO2_cbrt'] = np.cbrt(no2)
    engineered['OZONE_squared'] = ozone ** 2
    engineered['OZONE_cbrt'] = np.cbrt(ozone)
    
    # 6. Temporal Interactions
    hour = timestamp.hour
    engineered['morning_pollution'] = 1 if 6 <= hour <= 10 else 0
    engineered['hour_temp_interaction'] = hour * temp
    
    # 7. Moving Averages (using current values as proxy since we don't have historical data in real-time)
    # In real-time prediction, these would be NaN or use default values
    engineered['PM2.5_ma3'] = pm25  # Simplified - use current value
    engineered['PM2.5_ma6'] = pm25
    engineered['PM10_ma3'] = pm10
    engineered['PM10_ma6'] = pm10
    engineered['NO2_ma3'] = no2
    engineered['NO2_ma6'] = no2
    engineered['OZONE_ma3'] = ozone
    engineered['OZONE_ma6'] = ozone
    
    # 8. Statistical Aggregations across pollutants
    pollutants = [pm25, pm10, no2, so2, co, ozone, nh3]
    engineered['avg_pollutant_level'] = np.mean(pollutants)
    engineered['max_pollutant_level'] = np.max(pollutants)
    engineered['pollutant_variance'] = np.var(pollutants)
    
    return engineered

def get_feature_order():
    """
    Returns the exact order of features as used in model training (69 features total).
    """
    feature_order = [
        # Base pollutant features (7)
        'CO', 'NH3', 'NO2', 'OZONE', 'PM10', 'PM2.5', 'SO2',
        
        # Weather features (8)
        'temperature', 'humidity', 'pressure', 'wind_speed', 'wind_direction',
        'precipitation', 'boundary_layer_height', 'surface_pressure',
        
        # Satellite features (6)
        'aod550', 'aerosol_index', 'cloud_fraction', 'surface_reflectance',
        'angstrom_exponent', 'single_scattering_albedo',
        
        # Temporal features (12)
        'hour', 'day', 'month', 'day_of_week', 'is_weekend', 'is_rush_hour',
        'hour_sin', 'hour_cos', 'dow_sin', 'dow_cos', 'month_sin', 'month_cos',
        
        # Engineered features (36)
        'pm_ratio', 'pm_sum', 'pm_product', 'no2_so2_interaction', 'ozone_no2_ratio', 
        'combustion_index', 'heat_index', 'pm_dispersion', 'pm_concentration', 'temp_ozone',
        'mixing_potential', 'ventilation_coef', 'air_density_proxy',
        'hygroscopic_growth', 'aerosol_dispersion',
        'PM2.5_squared', 'PM2.5_cbrt', 'PM10_squared', 'PM10_cbrt',
        'NO2_squared', 'NO2_cbrt', 'OZONE_squared', 'OZONE_cbrt',
        'morning_pollution', 'hour_temp_interaction',
        'PM2.5_ma3', 'PM2.5_ma6', 'PM10_ma3', 'PM10_ma6',
        'NO2_ma3', 'NO2_ma6', 'OZONE_ma3', 'OZONE_ma6',
        'avg_pollutant_level', 'max_pollutant_level', 'pollutant_variance'
    ]
    
    return feature_order
