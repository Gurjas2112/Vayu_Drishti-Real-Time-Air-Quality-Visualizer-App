import pandas as pd

df = pd.read_csv('integrated_aqi_dataset_v2.csv')

print('Dataset Statistics:')
print('=' * 60)
print(f'Total records: {len(df):,}')
print(f'Date range: {df["timestamp"].min()} to {df["timestamp"].max()}')
print(f'Unique stations: {df["station"].nunique()}')
print(f'Unique cities: {df["city"].nunique()}')
print(f'Unique states: {df["state"].nunique()}')

print(f'\nAQI Statistics:')
print(f'Mean AQI: {df["AQI"].mean():.2f}')
print(f'Min AQI: {df["AQI"].min():.2f}')
print(f'Max AQI: {df["AQI"].max():.2f}')

print(f'\nRecords per month:')
df['timestamp'] = pd.to_datetime(df['timestamp'])
monthly = df.groupby(df['timestamp'].dt.to_period('M')).size()
print(monthly)

print(f'\nFirst 3 records:')
print(df[['city', 'station', 'timestamp', 'PM2.5', 'AQI']].head(3))

print(f'\nLast 3 records:')
print(df[['city', 'station', 'timestamp', 'PM2.5', 'AQI']].tail(3))
