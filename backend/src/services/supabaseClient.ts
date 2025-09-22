import { createClient } from '@supabase/supabase-js';
import { getEnv } from '../utils/env.js';

const supabaseUrl = getEnv('SUPABASE_URL');
const supabaseKey = getEnv('SUPABASE_SERVICE_ROLE_KEY', getEnv('SUPABASE_ANON_KEY'));
export const supabase = createClient(supabaseUrl, supabaseKey);

export type PollutantReading = { name: string; value: number };
export type LatestAqi = {
	stationId: string;
	stationName: string;
	lat: number;
	lon: number;
	aqi: number;
	pollutants: PollutantReading[];
	timestamp: string;
};

export async function getUserFromToken(jwt: string) {
	// Verify using auth API
	const { data, error } = await supabase.auth.getUser(jwt);
	if (error || !data?.user) return null;
	return data.user;
}

export async function getUserProfile(userId: string) {
	// Create profile table later if needed; return minimal info for now
	return { id: userId };
}

export async function upsertFcmToken(userId: string, token: string, platform: 'android'|'ios'|'web') {
	const { error } = await supabase
		.from('fcm_tokens')
		.upsert({ token, user_id: userId, platform })
		.select('token')
		.single();
	if (error) throw error;
}

export async function listAllFcmTokens(): Promise<string[]> {
	const { data, error } = await supabase.from('fcm_tokens').select('token');
	if (error) throw error;
	return (data ?? []).map((r: any) => r.token as string);
}

export async function queryAqiByLocation(lat: number, lon: number): Promise<LatestAqi> {
	// Placeholder: nearest station by distance; assumes a view or RPC exists
	const { data, error } = await supabase.rpc('get_nearest_station_aqi', { lat, lon });
	if (error || !data) throw error || new Error('No data');
	return data as LatestAqi;
}

export async function queryAqiByStation(stationId: string): Promise<LatestAqi> {
	const { data, error } = await supabase.from('latest_aqi').select('*').eq('station_id', stationId).single();
	if (error || !data) throw error || new Error('No data');
	return {
		stationId: data.station_id,
		stationName: data.station_name,
		lat: data.lat,
		lon: data.lon,
		aqi: data.aqi,
		pollutants: data.pollutants ?? [],
		timestamp: data.timestamp,
	};
}

export async function queryHistoricalAqi(stationId: string, from: Date, to: Date) {
	const { data, error } = await supabase
		.from('aqi_readings')
		.select('*')
		.eq('station_id', stationId)
		.gte('timestamp', from.toISOString())
		.lte('timestamp', to.toISOString())
		.order('timestamp', { ascending: true });
	if (error) throw error;
	return data;
}

export async function upsertCpcbData(payload: unknown[]) {
	const { error } = await supabase.from('aqi_readings').upsert(payload, { onConflict: 'station_id,timestamp' });
	if (error) throw error;
}

export async function upsertIsroData(payload: unknown[]) {
	const { error } = await supabase.from('isro_satellite_readings').upsert(payload, { onConflict: 'tile_id,timestamp' });
	if (error) throw error;
}
