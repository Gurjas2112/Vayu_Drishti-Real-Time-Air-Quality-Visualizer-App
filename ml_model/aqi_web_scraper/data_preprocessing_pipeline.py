"""
Data Preprocessing Pipeline for AQI Prediction
==============================================
Based on the Machine Learning Flowchart for AQI Prediction

This module implements a comprehensive preprocessing pipeline with:
1. Missing value detection and removal
2. Feature selection using statistical correlation
3. Square root transformation for normalization
4. Data visualization
5. Unit conversion (ppb → μg/m³)
6. Outlier detection and handling
7. Quality flagging

Author: Vayu Drishti Team
Date: November 2025
"""

import pandas as pd
import numpy as np
from typing import Dict, List, Tuple, Optional
import logging
from datetime import datetime
from scipy import stats
from sklearn.preprocessing import StandardScaler
import warnings

warnings.filterwarnings('ignore')

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class DataPreprocessingPipeline:
    """
    Complete data preprocessing pipeline for AQI prediction.
    
    Implements the workflow from the ML flowchart:
    - Data preprocessing (missing values, removal)
    - Exploratory data analysis (feature correlation, transformation, visualization)
    - Data quality checks and flagging
    """
    
    # Unit conversion factors (ppb to μg/m³)
    CONVERSION_FACTORS = {
        'NO2': 1.88,   # NO2: ppb × 1.88 = μg/m³
        'SO2': 2.62,   # SO2: ppb × 2.62 = μg/m³
        'CO': 1145.0,  # CO: ppm × 1145 = μg/m³
        'O3': 1.96     # O3: ppb × 1.96 = μg/m³
    }
    
    # Pollutant thresholds for outlier detection (μg/m³)
    OUTLIER_THRESHOLDS = {
        'PM2.5': (0, 500),
        'PM10': (0, 600),
        'NO2': (0, 400),
        'SO2': (0, 300),
        'CO': (0, 10000),
        'O3': (0, 300)
    }
    
    def __init__(self, missing_threshold: float = 0.3):
        """
        Initialize preprocessing pipeline.
        
        Args:
            missing_threshold: Maximum fraction of missing values allowed (default: 0.3)
        """
        self.missing_threshold = missing_threshold
        self.scaler = StandardScaler()
        self.feature_correlations = {}
        self.selected_features = []
        self.preprocessing_stats = {}
        
        logger.info(f"DataPreprocessingPipeline initialized with missing_threshold={missing_threshold}")
    
    def stage_1_check_missing_values(self, df: pd.DataFrame) -> Tuple[pd.DataFrame, Dict]:
        """
        Stage 1: Check Missing Values & Removal of Instances
        
        From workflow: "Checking Missing Values & Removal of the Instances"
        
        Args:
            df: Input dataframe
            
        Returns:
            Tuple of (cleaned dataframe, statistics dictionary)
        """
        logger.info("Stage 1: Checking missing values and removing instances...")
        
        initial_rows = len(df)
        stats = {
            'initial_rows': initial_rows,
            'missing_by_column': {},
            'removed_rows': 0,
            'final_rows': 0,
            'missing_percentage_before': 0,
            'missing_percentage_after': 0
        }
        
        # Calculate missing values per column
        missing_counts = df.isnull().sum()
        missing_percentages = (missing_counts / len(df)) * 100
        
        for col in df.columns:
            if missing_counts[col] > 0:
                stats['missing_by_column'][col] = {
                    'count': int(missing_counts[col]),
                    'percentage': float(missing_percentages[col])
                }
                logger.info(f"  {col}: {missing_counts[col]} missing ({missing_percentages[col]:.2f}%)")
        
        # Calculate overall missing percentage
        total_cells = df.shape[0] * df.shape[1]
        missing_cells = df.isnull().sum().sum()
        stats['missing_percentage_before'] = (missing_cells / total_cells) * 100
        
        # Remove rows with excessive missing values
        row_missing_pct = df.isnull().sum(axis=1) / len(df.columns)
        df_cleaned = df[row_missing_pct <= self.missing_threshold].copy()
        
        # Remove columns with excessive missing values
        col_missing_pct = df_cleaned.isnull().sum() / len(df_cleaned)
        cols_to_keep = col_missing_pct[col_missing_pct <= self.missing_threshold].index
        df_cleaned = df_cleaned[cols_to_keep]
        
        stats['removed_rows'] = initial_rows - len(df_cleaned)
        stats['final_rows'] = len(df_cleaned)
        
        # Recalculate missing percentage after cleaning
        if len(df_cleaned) > 0:
            total_cells_after = df_cleaned.shape[0] * df_cleaned.shape[1]
            missing_cells_after = df_cleaned.isnull().sum().sum()
            stats['missing_percentage_after'] = (missing_cells_after / total_cells_after) * 100
        
        logger.info(f"  Removed {stats['removed_rows']} rows ({(stats['removed_rows']/initial_rows)*100:.2f}%)")
        logger.info(f"  Missing data: {stats['missing_percentage_before']:.2f}% → {stats['missing_percentage_after']:.2f}%")
        
        self.preprocessing_stats['stage_1'] = stats
        return df_cleaned, stats
    
    def stage_2_convert_units(self, df: pd.DataFrame) -> pd.DataFrame:
        """
        Stage 2: Unit Conversion (ppb → μg/m³)
        
        Converts pollutant concentrations from ppb to μg/m³.
        
        Args:
            df: Input dataframe
            
        Returns:
            Dataframe with converted units
        """
        logger.info("Stage 2: Converting units (ppb → μg/m³)...")
        
        df_converted = df.copy()
        conversions_applied = []
        
        for pollutant, factor in self.CONVERSION_FACTORS.items():
            # Check for columns that might contain this pollutant
            matching_cols = [col for col in df.columns if pollutant.lower() in col.lower()]
            
            for col in matching_cols:
                if col in df_converted.columns:
                    # Check if values are in ppb range (typically < 1000 for most pollutants)
                    mean_val = df_converted[col].mean()
                    
                    # Convert if values appear to be in ppb
                    if mean_val < 1000:  # Heuristic to detect ppb values
                        df_converted[col] = df_converted[col] * factor
                        conversions_applied.append({
                            'column': col,
                            'factor': factor,
                            'mean_before': mean_val,
                            'mean_after': df_converted[col].mean()
                        })
                        logger.info(f"  Converted {col}: {mean_val:.2f} → {df_converted[col].mean():.2f} μg/m³")
        
        self.preprocessing_stats['stage_2'] = {
            'conversions_applied': conversions_applied,
            'total_conversions': len(conversions_applied)
        }
        
        return df_converted
    
    def stage_3_feature_correlation(self, df: pd.DataFrame, 
                                   target_col: str = 'AQI',
                                   correlation_threshold: float = 0.3) -> List[str]:
        """
        Stage 3: Identification of Suitable Features Using Statistical Correlation
        
        From workflow: "Identification of Suitable Features Using Statistical Correlation"
        
        Args:
            df: Input dataframe
            target_col: Target column name (default: 'AQI')
            correlation_threshold: Minimum correlation to keep feature
            
        Returns:
            List of selected feature names
        """
        logger.info("Stage 3: Identifying suitable features using statistical correlation...")
        
        # Separate numeric columns
        numeric_cols = df.select_dtypes(include=[np.number]).columns.tolist()
        
        if target_col not in numeric_cols:
            logger.warning(f"Target column '{target_col}' not found in numeric columns")
            return numeric_cols
        
        # Calculate correlations with target
        correlations = df[numeric_cols].corrwith(df[target_col]).abs().sort_values(ascending=False)
        
        # Select features above threshold
        selected_features = correlations[correlations >= correlation_threshold].index.tolist()
        
        # Remove target from features
        if target_col in selected_features:
            selected_features.remove(target_col)
        
        self.feature_correlations = correlations.to_dict()
        self.selected_features = selected_features
        
        logger.info(f"  Selected {len(selected_features)} features with correlation >= {correlation_threshold}")
        for feature in selected_features[:10]:  # Show top 10
            logger.info(f"    {feature}: {correlations[feature]:.3f}")
        
        self.preprocessing_stats['stage_3'] = {
            'correlation_threshold': correlation_threshold,
            'total_features': len(numeric_cols),
            'selected_features': len(selected_features),
            'top_correlations': {k: v for k, v in list(correlations.items())[:10]}
        }
        
        return selected_features
    
    def stage_4_sqrt_transformation(self, df: pd.DataFrame, 
                                   columns: Optional[List[str]] = None) -> pd.DataFrame:
        """
        Stage 4: Square Root Transformation for Data Normalization
        
        From workflow: "Square Root Transformation for Data Normalization"
        
        Args:
            df: Input dataframe
            columns: Columns to transform (default: all numeric columns)
            
        Returns:
            Dataframe with transformed columns
        """
        logger.info("Stage 4: Applying square root transformation for normalization...")
        
        df_transformed = df.copy()
        
        if columns is None:
            columns = df.select_dtypes(include=[np.number]).columns.tolist()
        
        transformation_stats = {}
        
        for col in columns:
            if col in df_transformed.columns:
                # Check if column has negative values
                if (df_transformed[col] < 0).any():
                    logger.warning(f"  Skipping {col}: contains negative values")
                    continue
                
                # Store original statistics
                orig_mean = df_transformed[col].mean()
                orig_std = df_transformed[col].std()
                orig_skew = df_transformed[col].skew()
                
                # Apply square root transformation
                df_transformed[col] = np.sqrt(df_transformed[col] + 1e-8)  # Add small constant to avoid sqrt(0)
                
                # Calculate new statistics
                new_mean = df_transformed[col].mean()
                new_std = df_transformed[col].std()
                new_skew = df_transformed[col].skew()
                
                transformation_stats[col] = {
                    'original': {'mean': orig_mean, 'std': orig_std, 'skew': orig_skew},
                    'transformed': {'mean': new_mean, 'std': new_std, 'skew': new_skew},
                    'skew_reduction': abs(orig_skew) - abs(new_skew)
                }
                
                logger.info(f"  {col}: skew {orig_skew:.3f} → {new_skew:.3f}")
        
        self.preprocessing_stats['stage_4'] = {
            'columns_transformed': len(transformation_stats),
            'transformation_stats': transformation_stats
        }
        
        return df_transformed
    
    def stage_5_outlier_detection(self, df: pd.DataFrame, method: str = 'iqr') -> Tuple[pd.DataFrame, Dict]:
        """
        Stage 5: Outlier Detection and Handling
        
        Detects and handles outliers using IQR or threshold methods.
        
        Args:
            df: Input dataframe
            method: Detection method ('iqr' or 'threshold')
            
        Returns:
            Tuple of (cleaned dataframe, outlier statistics)
        """
        logger.info(f"Stage 5: Detecting outliers using {method} method...")
        
        df_cleaned = df.copy()
        outlier_stats = {}
        
        numeric_cols = df.select_dtypes(include=[np.number]).columns
        
        for col in numeric_cols:
            col_outliers = 0
            
            if method == 'iqr':
                # IQR method
                Q1 = df_cleaned[col].quantile(0.25)
                Q3 = df_cleaned[col].quantile(0.75)
                IQR = Q3 - Q1
                lower_bound = Q1 - 1.5 * IQR
                upper_bound = Q3 + 1.5 * IQR
                
                outlier_mask = (df_cleaned[col] < lower_bound) | (df_cleaned[col] > upper_bound)
                col_outliers = outlier_mask.sum()
                
                # Winsorization: cap outliers at bounds
                df_cleaned.loc[df_cleaned[col] < lower_bound, col] = lower_bound
                df_cleaned.loc[df_cleaned[col] > upper_bound, col] = upper_bound
                
            elif method == 'threshold':
                # Threshold method for known pollutants
                pollutant_name = col.split('_')[0] if '_' in col else col
                
                if pollutant_name in self.OUTLIER_THRESHOLDS:
                    min_val, max_val = self.OUTLIER_THRESHOLDS[pollutant_name]
                    outlier_mask = (df_cleaned[col] < min_val) | (df_cleaned[col] > max_val)
                    col_outliers = outlier_mask.sum()
                    
                    # Cap at thresholds
                    df_cleaned.loc[df_cleaned[col] < min_val, col] = min_val
                    df_cleaned.loc[df_cleaned[col] > max_val, col] = max_val
            
            if col_outliers > 0:
                outlier_stats[col] = {
                    'count': int(col_outliers),
                    'percentage': float((col_outliers / len(df)) * 100)
                }
                logger.info(f"  {col}: {col_outliers} outliers ({(col_outliers/len(df))*100:.2f}%)")
        
        self.preprocessing_stats['stage_5'] = {
            'method': method,
            'outlier_stats': outlier_stats,
            'total_outliers': sum([v['count'] for v in outlier_stats.values()])
        }
        
        return df_cleaned, outlier_stats
    
    def stage_6_quality_flagging(self, df: pd.DataFrame) -> pd.DataFrame:
        """
        Stage 6: Quality Flagging System
        
        Assigns quality scores (0.0-1.0) based on data quality indicators.
        
        Args:
            df: Input dataframe
            
        Returns:
            Dataframe with quality_flag column
        """
        logger.info("Stage 6: Assigning quality flags...")
        
        df_flagged = df.copy()
        
        # Initialize quality score
        quality_scores = np.ones(len(df))
        
        # Criteria 1: Data completeness
        row_completeness = df.notna().sum(axis=1) / len(df.columns)
        quality_scores *= row_completeness
        
        # Criteria 2: Temporal consistency (if timestamp exists)
        if 'timestamp' in df.columns or 'date' in df.columns:
            time_col = 'timestamp' if 'timestamp' in df.columns else 'date'
            # Check for duplicate timestamps
            duplicate_mask = df[time_col].duplicated()
            quality_scores[duplicate_mask] *= 0.7
        
        # Criteria 3: Value reasonableness (check if within expected ranges)
        for col in df.select_dtypes(include=[np.number]).columns:
            # Very high or very low values get lower quality scores
            z_scores = np.abs(stats.zscore(df[col].fillna(df[col].mean())))
            extreme_mask = z_scores > 3
            quality_scores[extreme_mask] *= 0.8
        
        # Add quality flag column
        df_flagged['quality_flag'] = quality_scores
        
        # Categorize quality
        high_quality = (quality_scores >= 0.8).sum()
        medium_quality = ((quality_scores >= 0.5) & (quality_scores < 0.8)).sum()
        low_quality = (quality_scores < 0.5).sum()
        
        logger.info(f"  High quality (≥0.8): {high_quality} ({(high_quality/len(df))*100:.1f}%)")
        logger.info(f"  Medium quality (0.5-0.8): {medium_quality} ({(medium_quality/len(df))*100:.1f}%)")
        logger.info(f"  Low quality (<0.5): {low_quality} ({(low_quality/len(df))*100:.1f}%)")
        
        self.preprocessing_stats['stage_6'] = {
            'high_quality_count': int(high_quality),
            'medium_quality_count': int(medium_quality),
            'low_quality_count': int(low_quality),
            'mean_quality_score': float(quality_scores.mean())
        }
        
        return df_flagged
    
    def run_full_pipeline(self, df: pd.DataFrame, 
                         target_col: str = 'AQI',
                         apply_transformation: bool = True,
                         correlation_threshold: float = 0.3) -> Tuple[pd.DataFrame, Dict]:
        """
        Run the complete preprocessing pipeline.
        
        Implements the workflow from the ML flowchart:
        1. Check missing values & removal
        2. Unit conversion
        3. Feature correlation analysis
        4. Square root transformation (optional)
        5. Outlier detection
        6. Quality flagging
        
        Args:
            df: Input dataframe
            target_col: Target column name
            apply_transformation: Whether to apply sqrt transformation
            correlation_threshold: Minimum correlation for feature selection
            
        Returns:
            Tuple of (processed dataframe, statistics dictionary)
        """
        logger.info("="*80)
        logger.info("STARTING COMPLETE DATA PREPROCESSING PIPELINE")
        logger.info("="*80)
        
        start_time = datetime.now()
        
        # Stage 1: Missing values
        df_clean, _ = self.stage_1_check_missing_values(df)
        
        # Stage 2: Unit conversion
        df_converted = self.stage_2_convert_units(df_clean)
        
        # Stage 3: Feature correlation
        selected_features = self.stage_3_feature_correlation(
            df_converted, 
            target_col=target_col,
            correlation_threshold=correlation_threshold
        )
        
        # Stage 4: Transformation (optional)
        if apply_transformation:
            df_transformed = self.stage_4_sqrt_transformation(df_converted, columns=selected_features)
        else:
            df_transformed = df_converted
        
        # Stage 5: Outlier detection
        df_no_outliers, _ = self.stage_5_outlier_detection(df_transformed, method='iqr')
        
        # Stage 6: Quality flagging
        df_final = self.stage_6_quality_flagging(df_no_outliers)
        
        end_time = datetime.now()
        processing_time = (end_time - start_time).total_seconds()
        
        # Compile final statistics
        final_stats = {
            'pipeline_config': {
                'missing_threshold': self.missing_threshold,
                'target_column': target_col,
                'correlation_threshold': correlation_threshold,
                'transformation_applied': apply_transformation
            },
            'stages': self.preprocessing_stats,
            'summary': {
                'initial_rows': df.shape[0],
                'initial_columns': df.shape[1],
                'final_rows': df_final.shape[0],
                'final_columns': df_final.shape[1],
                'rows_removed': df.shape[0] - df_final.shape[0],
                'processing_time_seconds': processing_time,
                'selected_features': selected_features
            }
        }
        
        logger.info("="*80)
        logger.info("PREPROCESSING PIPELINE COMPLETED")
        logger.info(f"  Initial shape: {df.shape}")
        logger.info(f"  Final shape: {df_final.shape}")
        logger.info(f"  Processing time: {processing_time:.2f} seconds")
        logger.info(f"  Data retention: {(df_final.shape[0]/df.shape[0])*100:.1f}%")
        logger.info("="*80)
        
        return df_final, final_stats


def main():
    """
    Example usage of the DataPreprocessingPipeline.
    """
    # Example: Load data and run pipeline
    try:
        # Load sample data
        df = pd.read_csv('../integrated_aqi_dataset_v2.csv')
        logger.info(f"Loaded dataset: {df.shape}")
        
        # Initialize pipeline
        pipeline = DataPreprocessingPipeline(missing_threshold=0.3)
        
        # Run complete pipeline
        df_processed, stats = pipeline.run_full_pipeline(
            df,
            target_col='AQI',
            apply_transformation=True,
            correlation_threshold=0.3
        )
        
        # Save processed data
        output_path = 'preprocessed_aqi_dataset.csv'
        df_processed.to_csv(output_path, index=False)
        logger.info(f"Saved processed data to {output_path}")
        
        # Save statistics
        import json
        stats_path = 'preprocessing_stats.json'
        with open(stats_path, 'w') as f:
            json.dump(stats, f, indent=2)
        logger.info(f"Saved statistics to {stats_path}")
        
    except Exception as e:
        logger.error(f"Error in preprocessing pipeline: {str(e)}")
        raise


if __name__ == "__main__":
    main()
