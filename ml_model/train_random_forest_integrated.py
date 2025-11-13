#!/usr/bin/env python3
"""
Random Forest Model for Integrated AQI Prediction
==================================================

Fast, accurate model using Random Forest on integrated dataset
(CPCB + MERRA-2 + INSAT-3DR)

Features:
- Multi-threaded training (n_jobs=-1)
- Optimized hyperparameters for speed + accuracy
- Feature importance analysis
- Cross-validation for robust evaluation
- Model persistence for deployment

Training Time: ~2-5 minutes (vs 30-60 min for LSTM)
Expected Accuracy: R² > 0.95
"""

import os
import sys
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from pathlib import Path
import joblib
import logging
from datetime import datetime
from sklearn.ensemble import RandomForestRegressor
from sklearn.metrics import mean_squared_error, mean_absolute_error, r2_score
from sklearn.model_selection import cross_val_score
from sklearn.preprocessing import StandardScaler
import warnings
warnings.filterwarnings('ignore')

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('rf_training.log', encoding='utf-8'),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)


class RandomForestAQIPredictor:
    """
    Random Forest model for AQI prediction using integrated data sources.
    """
    
    def __init__(self, data_dir: str = None, n_estimators: int = 200, max_depth: int = 30):
        """
        Initialize Random Forest predictor.
        
        Args:
            data_dir: Directory containing training data
            n_estimators: Number of trees (default: 200 for speed+accuracy balance)
            max_depth: Maximum tree depth (default: 30 to prevent overfitting)
        """
        self.data_dir = data_dir or os.path.dirname(__file__)
        self.n_estimators = n_estimators
        self.max_depth = max_depth
        
        # Paths
        self.train_path = os.path.join(self.data_dir, 'train_data_integrated_v2.csv')
        self.val_path = os.path.join(self.data_dir, 'val_data_integrated_v2.csv')
        self.test_path = os.path.join(self.data_dir, 'test_data_integrated_v2.csv')
        self.model_path = os.path.join(self.data_dir, 'rf_aqi_model_integrated.pkl')
        self.scaler_path = os.path.join(self.data_dir, 'rf_scaler_integrated.pkl')
        
        # Model components
        self.model = None
        self.scaler = StandardScaler()
        self.feature_names = None
        self.feature_importance = None
        
        logger.info("=" * 80)
        logger.info("🌲 RANDOM FOREST AQI PREDICTOR - INTEGRATED DATASET")
        logger.info("=" * 80)
        logger.info(f"📁 Data Directory: {self.data_dir}")
        logger.info(f"🌳 Model Config: {n_estimators} trees, max_depth={max_depth}")
        logger.info("=" * 80)
    
    def load_data(self) -> tuple:
        """
        Load and prepare training, validation, and test data.
        """
        logger.info("\n📊 STEP 1: Loading Data")
        logger.info("-" * 80)
        
        # Load datasets
        train_df = pd.read_csv(self.train_path)
        val_df = pd.read_csv(self.val_path)
        test_df = pd.read_csv(self.test_path)
        
        logger.info(f"✅ Training data: {len(train_df):,} records")
        logger.info(f"✅ Validation data: {len(val_df):,} records")
        logger.info(f"✅ Test data: {len(test_df):,} records")
        
        # Define feature columns
        pollutant_features = ['PM2.5', 'PM10', 'NO2', 'SO2', 'CO', 'OZONE', 'NH3']
        merra2_features = ['temperature', 'humidity', 'wind_speed', 'wind_direction', 
                          'pressure', 'precipitation', 'boundary_layer_height', 'surface_pressure']
        insat_features = ['aod550', 'aerosol_index', 'cloud_fraction', 
                         'surface_reflectance', 'angstrom_exponent', 'single_scattering_albedo']
        location_features = ['latitude', 'longitude']
        
        # Combine all features
        self.feature_names = (pollutant_features + merra2_features + 
                             insat_features + location_features)
        
        logger.info(f"\n📋 Feature Categories:")
        logger.info(f"   🏭 CPCB Pollutants: {len(pollutant_features)} features")
        logger.info(f"   🌦️  MERRA-2 Meteorological: {len(merra2_features)} features")
        logger.info(f"   🛰️  INSAT-3DR Satellite: {len(insat_features)} features")
        logger.info(f"   📍 Location: {len(location_features)} features")
        logger.info(f"   ✅ Total: {len(self.feature_names)} features")
        
        # Prepare X, y
        X_train = train_df[self.feature_names].fillna(0).values
        y_train = train_df['AQI'].values
        
        X_val = val_df[self.feature_names].fillna(0).values
        y_val = val_df['AQI'].values
        
        X_test = test_df[self.feature_names].fillna(0).values
        y_test = test_df['AQI'].values
        
        logger.info(f"\n📊 Data Shapes:")
        logger.info(f"   X_train: {X_train.shape}, y_train: {y_train.shape}")
        logger.info(f"   X_val: {X_val.shape}, y_val: {y_val.shape}")
        logger.info(f"   X_test: {X_test.shape}, y_test: {y_test.shape}")
        
        return X_train, y_train, X_val, y_val, X_test, y_test
    
    def train_model(self, X_train: np.ndarray, y_train: np.ndarray,
                   X_val: np.ndarray, y_val: np.ndarray):
        """
        Train Random Forest model with optimized hyperparameters.
        """
        logger.info("\n🌲 STEP 2: Training Random Forest Model")
        logger.info("-" * 80)
        
        # Scale features
        logger.info("   Scaling features...")
        X_train_scaled = self.scaler.fit_transform(X_train)
        X_val_scaled = self.scaler.transform(X_val)
        
        # Initialize Random Forest with optimized parameters
        logger.info(f"   Initializing Random Forest...")
        logger.info(f"   - n_estimators: {self.n_estimators}")
        logger.info(f"   - max_depth: {self.max_depth}")
        logger.info(f"   - min_samples_split: 5")
        logger.info(f"   - min_samples_leaf: 2")
        logger.info(f"   - n_jobs: -1 (all CPU cores)")
        
        self.model = RandomForestRegressor(
            n_estimators=self.n_estimators,
            max_depth=self.max_depth,
            min_samples_split=5,
            min_samples_leaf=2,
            max_features='sqrt',  # Speed optimization
            n_jobs=-1,  # Use all CPU cores
            random_state=42,
            verbose=1
        )
        
        # Train model
        logger.info(f"\n⏱️  Training started at {datetime.now().strftime('%H:%M:%S')}")
        logger.info("   (This will take ~2-5 minutes...)")
        
        start_time = datetime.now()
        self.model.fit(X_train_scaled, y_train)
        training_time = (datetime.now() - start_time).total_seconds()
        
        logger.info(f"\n✅ Training completed in {training_time:.1f} seconds ({training_time/60:.1f} minutes)")
        
        # Validation predictions
        logger.info("\n📈 Evaluating on validation set...")
        y_val_pred = self.model.predict(X_val_scaled)
        
        val_mse = mean_squared_error(y_val, y_val_pred)
        val_rmse = np.sqrt(val_mse)
        val_mae = mean_absolute_error(y_val, y_val_pred)
        val_r2 = r2_score(y_val, y_val_pred)
        
        logger.info(f"\n📊 Validation Metrics:")
        logger.info(f"   MSE:  {val_mse:.2f}")
        logger.info(f"   RMSE: {val_rmse:.2f}")
        logger.info(f"   MAE:  {val_mae:.2f}")
        logger.info(f"   R²:   {val_r2:.4f}")
        
        # Feature importance
        self.feature_importance = pd.DataFrame({
            'feature': self.feature_names,
            'importance': self.model.feature_importances_
        }).sort_values('importance', ascending=False)
        
        logger.info(f"\n🔝 Top 10 Most Important Features:")
        for idx, row in self.feature_importance.head(10).iterrows():
            logger.info(f"   {row['feature']:30s} {row['importance']:.4f}")
        
        return training_time
    
    def evaluate_model(self, X_test: np.ndarray, y_test: np.ndarray):
        """
        Evaluate model on test set.
        """
        logger.info("\n🎯 STEP 3: Final Evaluation on Test Set")
        logger.info("-" * 80)
        
        # Scale test data
        X_test_scaled = self.scaler.transform(X_test)
        
        # Predictions
        y_test_pred = self.model.predict(X_test_scaled)
        
        # Metrics
        test_mse = mean_squared_error(y_test, y_test_pred)
        test_rmse = np.sqrt(test_mse)
        test_mae = mean_absolute_error(y_test, y_test_pred)
        test_r2 = r2_score(y_test, y_test_pred)
        
        logger.info(f"📊 Test Set Metrics:")
        logger.info(f"   MSE:  {test_mse:.2f}")
        logger.info(f"   RMSE: {test_rmse:.2f}")
        logger.info(f"   MAE:  {test_mae:.2f}")
        logger.info(f"   R²:   {test_r2:.4f}")
        
        # Error distribution
        errors = y_test - y_test_pred
        error_std = np.std(errors)
        
        logger.info(f"\n📈 Error Analysis:")
        logger.info(f"   Mean Error: {np.mean(errors):.2f}")
        logger.info(f"   Error Std Dev: {error_std:.2f}")
        logger.info(f"   Max Overestimate: {np.max(errors):.2f}")
        logger.info(f"   Max Underestimate: {np.min(errors):.2f}")
        
        # Accuracy percentages
        within_5 = np.sum(np.abs(errors) <= 5) / len(errors) * 100
        within_10 = np.sum(np.abs(errors) <= 10) / len(errors) * 100
        within_20 = np.sum(np.abs(errors) <= 20) / len(errors) * 100
        
        logger.info(f"\n🎯 Prediction Accuracy:")
        logger.info(f"   Within ±5 AQI:  {within_5:.1f}%")
        logger.info(f"   Within ±10 AQI: {within_10:.1f}%")
        logger.info(f"   Within ±20 AQI: {within_20:.1f}%")
        
        return {
            'mse': test_mse,
            'rmse': test_rmse,
            'mae': test_mae,
            'r2': test_r2,
            'predictions': y_test_pred,
            'actuals': y_test
        }
    
    def cross_validate(self, X: np.ndarray, y: np.ndarray, cv: int = 5):
        """
        Perform cross-validation for robust evaluation.
        """
        logger.info("\n🔄 STEP 4: Cross-Validation")
        logger.info("-" * 80)
        
        X_scaled = self.scaler.transform(X)
        
        logger.info(f"   Running {cv}-fold cross-validation...")
        cv_scores = cross_val_score(
            self.model, X_scaled, y, 
            cv=cv, 
            scoring='r2',
            n_jobs=-1
        )
        
        logger.info(f"\n📊 Cross-Validation Results:")
        logger.info(f"   R² Scores: {[f'{s:.4f}' for s in cv_scores]}")
        logger.info(f"   Mean R²: {cv_scores.mean():.4f}")
        logger.info(f"   Std Dev: {cv_scores.std():.4f}")
        
        return cv_scores
    
    def save_model(self):
        """
        Save trained model and scaler for deployment.
        """
        logger.info("\n💾 STEP 5: Saving Model")
        logger.info("-" * 80)
        
        # Save model
        joblib.dump(self.model, self.model_path)
        model_size = os.path.getsize(self.model_path) / (1024 * 1024)
        logger.info(f"   ✅ Model saved: {self.model_path}")
        logger.info(f"      Size: {model_size:.2f} MB")
        
        # Save scaler
        joblib.dump(self.scaler, self.scaler_path)
        logger.info(f"   ✅ Scaler saved: {self.scaler_path}")
        
        # Save feature importance
        importance_path = os.path.join(self.data_dir, 'feature_importance_rf.csv')
        self.feature_importance.to_csv(importance_path, index=False)
        logger.info(f"   ✅ Feature importance saved: {importance_path}")
    
    def plot_results(self, results: dict):
        """
        Create visualization plots.
        """
        logger.info("\n📊 STEP 6: Creating Visualizations")
        logger.info("-" * 80)
        
        # Create figure with subplots
        fig, axes = plt.subplots(2, 2, figsize=(16, 12))
        fig.suptitle('Random Forest AQI Prediction Results - Integrated Dataset', 
                     fontsize=16, fontweight='bold')
        
        # 1. Actual vs Predicted
        ax1 = axes[0, 0]
        ax1.scatter(results['actuals'], results['predictions'], alpha=0.3, s=10)
        ax1.plot([0, 500], [0, 500], 'r--', lw=2, label='Perfect Prediction')
        ax1.set_xlabel('Actual AQI', fontsize=12)
        ax1.set_ylabel('Predicted AQI', fontsize=12)
        ax1.set_title(f"Actual vs Predicted (R² = {results['r2']:.4f})", fontsize=14)
        ax1.legend()
        ax1.grid(True, alpha=0.3)
        
        # 2. Residual Plot
        ax2 = axes[0, 1]
        residuals = results['actuals'] - results['predictions']
        ax2.scatter(results['predictions'], residuals, alpha=0.3, s=10)
        ax2.axhline(y=0, color='r', linestyle='--', lw=2)
        ax2.set_xlabel('Predicted AQI', fontsize=12)
        ax2.set_ylabel('Residuals', fontsize=12)
        ax2.set_title('Residual Plot', fontsize=14)
        ax2.grid(True, alpha=0.3)
        
        # 3. Error Distribution
        ax3 = axes[1, 0]
        ax3.hist(residuals, bins=50, edgecolor='black', alpha=0.7)
        ax3.axvline(x=0, color='r', linestyle='--', lw=2)
        ax3.set_xlabel('Prediction Error (Actual - Predicted)', fontsize=12)
        ax3.set_ylabel('Frequency', fontsize=12)
        ax3.set_title(f"Error Distribution (MAE = {results['mae']:.2f})", fontsize=14)
        ax3.grid(True, alpha=0.3)
        
        # 4. Feature Importance
        ax4 = axes[1, 1]
        top_features = self.feature_importance.head(15)
        ax4.barh(range(len(top_features)), top_features['importance'])
        ax4.set_yticks(range(len(top_features)))
        ax4.set_yticklabels(top_features['feature'])
        ax4.set_xlabel('Importance', fontsize=12)
        ax4.set_title('Top 15 Feature Importance', fontsize=14)
        ax4.grid(True, alpha=0.3, axis='x')
        
        plt.tight_layout()
        
        # Save plot
        plot_path = os.path.join(self.data_dir, 'rf_results_integrated.png')
        plt.savefig(plot_path, dpi=300, bbox_inches='tight')
        logger.info(f"   ✅ Plots saved: {plot_path}")
        
        plt.close()
    
    def run_complete_pipeline(self):
        """
        Execute complete training and evaluation pipeline.
        """
        logger.info("\n" + "=" * 80)
        logger.info("🚀 STARTING RANDOM FOREST TRAINING PIPELINE")
        logger.info("=" * 80)
        
        start_time = datetime.now()
        
        # Load data
        X_train, y_train, X_val, y_val, X_test, y_test = self.load_data()
        
        # Train model
        training_time = self.train_model(X_train, y_train, X_val, y_val)
        
        # Evaluate
        results = self.evaluate_model(X_test, y_test)
        
        # Cross-validate
        cv_scores = self.cross_validate(X_test, y_test, cv=5)
        
        # Save model
        self.save_model()
        
        # Plot results
        self.plot_results(results)
        
        total_time = (datetime.now() - start_time).total_seconds()
        
        logger.info("\n" + "=" * 80)
        logger.info("✅ RANDOM FOREST TRAINING COMPLETED SUCCESSFULLY")
        logger.info("=" * 80)
        logger.info(f"\n⏱️  Time Summary:")
        logger.info(f"   Training Time: {training_time:.1f}s ({training_time/60:.1f} min)")
        logger.info(f"   Total Pipeline Time: {total_time:.1f}s ({total_time/60:.1f} min)")
        logger.info(f"\n📊 Final Performance:")
        logger.info(f"   Test R²: {results['r2']:.4f}")
        logger.info(f"   Test RMSE: {results['rmse']:.2f}")
        logger.info(f"   Test MAE: {results['mae']:.2f}")
        logger.info(f"   Cross-Val Mean R²: {cv_scores.mean():.4f} (±{cv_scores.std():.4f})")
        logger.info("\n🎯 Model ready for deployment!")
        logger.info("=" * 80)


def main():
    """Main execution function."""
    # Initialize predictor with optimized parameters
    predictor = RandomForestAQIPredictor(
        data_dir='aqi_web_scraper',
        n_estimators=200,  # Good balance of speed and accuracy
        max_depth=30  # Prevent overfitting
    )
    
    # Run complete pipeline
    predictor.run_complete_pipeline()


if __name__ == "__main__":
    main()
