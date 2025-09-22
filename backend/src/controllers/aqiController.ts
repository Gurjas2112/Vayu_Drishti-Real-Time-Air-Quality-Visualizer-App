import { forecastAqiNextHours } from '../services/forecastService.js';
import { generateHealthRecommendations } from '../services/healthService.js';
import { queryAqiByLocation, queryAqiByStation, queryHistoricalAqi } from '../services/supabaseClient.js';

export async function getLatestByLocation(req: any, res: any) {
	try {
		const { lat, lon, hours = '24' } = req.query as { lat?: string; lon?: string; hours?: string };
		if (!lat || !lon) return res.status(400).json({ error: 'lat and lon are required' });
		const latest = await queryAqiByLocation(Number(lat), Number(lon));
		const forecast = await forecastAqiNextHours(latest.stationId, Number(hours));
		const health = generateHealthRecommendations(latest.aqi, latest.pollutants);
		return res.json({ latest, forecast, health });
	} catch (err) {
		return res.status(500).json({ error: 'Internal server error' });
	}
}

export async function getByStation(req: any, res: any) {
	try {
		const { stationId } = req.params as { stationId: string };
		const data = await queryAqiByStation(stationId);
		const forecast = await forecastAqiNextHours(stationId, 24);
		const health = generateHealthRecommendations(data.aqi, data.pollutants);
		return res.json({ latest: data, forecast, health });
	} catch (err) {
		return res.status(500).json({ error: 'Internal server error' });
	}
}

export async function getHistorical(req: any, res: any) {
	try {
		const { stationId, from, to } = req.query as { stationId?: string; from?: string; to?: string };
		if (!stationId || !from || !to) return res.status(400).json({ error: 'stationId, from, to are required' });
		const data = await queryHistoricalAqi(stationId, new Date(from), new Date(to));
		return res.json({ data });
	} catch (err) {
		return res.status(500).json({ error: 'Internal server error' });
	}
}
