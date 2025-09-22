import { getEnv } from '../utils/env.js';
import { upsertCpcbData, upsertIsroData, listAllFcmTokens } from '../services/supabaseClient.js';
import { emitEvent } from '../services/realtimeService.js';
import { sendAqiAlert } from '../services/fcmService.js';

function isAuthorized(req: any): boolean {
	const secret = getEnv('INGEST_SHARED_SECRET', '');
	const header = req.headers && (req.headers['x-ingest-secret'] || req.headers['X-Ingest-Secret']);
	return typeof header === 'string' && header === secret;
}

async function maybeBroadcastHighAqi(source: 'cpcb'|'isro', maxAqi: number) {
	const threshold = Number(process.env.HIGH_AQI_THRESHOLD ?? '300');
	if (maxAqi < threshold) return;
	const tokens = await listAllFcmTokens();
	const title = 'Air Quality Alert';
	const body = `High AQI detected (${maxAqi}) from ${source.toUpperCase()}`;
	await Promise.all(tokens.map((t) => sendAqiAlert(t, title, body, { aqi: String(maxAqi), source })));
}

export async function ingestCpcb(req: any, res: any) {
	if (!isAuthorized(req)) return res.status(401).json({ error: 'Unauthorized' });
	try {
		const payload = Array.isArray(req.body) ? req.body : [];
		await upsertCpcbData(payload);
		emitEvent('aqi:update', { source: 'cpcb', count: payload.length });
		const maxAqi = payload.reduce((m: number, r: any) => Math.max(m, Number(r?.aqi ?? 0)), 0);
		await maybeBroadcastHighAqi('cpcb', maxAqi);
		return res.json({ status: 'ok' });
	} catch (_err) {
		return res.status(500).json({ error: 'Internal server error' });
	}
}

export async function ingestIsro(req: any, res: any) {
	if (!isAuthorized(req)) return res.status(401).json({ error: 'Unauthorized' });
	try {
		const payload = Array.isArray(req.body) ? req.body : [];
		await upsertIsroData(payload);
		emitEvent('aqi:update', { source: 'isro', count: payload.length });
		const maxAqi = payload.reduce((m: number, r: any) => Math.max(m, Number(r?.aqi ?? 0)), 0);
		await maybeBroadcastHighAqi('isro', maxAqi);
		return res.json({ status: 'ok' });
	} catch (_err) {
		return res.status(500).json({ error: 'Internal server error' });
	}
}
