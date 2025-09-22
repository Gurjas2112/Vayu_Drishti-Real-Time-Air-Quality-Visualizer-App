import { supabase } from './supabaseClient.js';

async function getLastAqi(stationId: string): Promise<number> {
	const { data } = await supabase.from('latest_aqi').select('aqi').eq('station_id', stationId).single();
	return Number(data?.aqi ?? 0);
}

export async function forecastAqiNextHours(stationId: string, hours: number) {
	const last = await getLastAqi(stationId);
	const values = Array.from({ length: hours }, () => last);
	return values.map((v, i) => ({ hour: i + 1, aqi: v }));
}
