import { NextFunction } from 'express';
import { getUserFromToken } from '../services/supabaseClient.js';

export async function requireAuth(req: any, res: any, next: NextFunction) {
	try {
		const header = req.headers && (req.headers.authorization || req.headers.Authorization);
		if (!header || typeof header !== 'string' || !header.startsWith('Bearer ')) {
			return res.status(401).json({ error: 'Unauthorized' });
		}
		const token = header.slice('Bearer '.length).trim();
		const user = await getUserFromToken(token);
		if (!user) return res.status(401).json({ error: 'Unauthorized' });
		req.user = user;
		next();
	} catch (_err) {
		return res.status(401).json({ error: 'Unauthorized' });
	}
}
