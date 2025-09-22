import { Router } from 'express';
import { requireAuth } from '../middleware/auth.js';
import { upsertFcmToken, getUserProfile } from '../services/supabaseClient.js';

export const router = Router();

router.get('/me', requireAuth, async (req: any, res: any) => {
	const profile = await getUserProfile(req.user.id);
	res.json({ user: req.user, profile });
});

router.post('/fcm-token', requireAuth, async (req: any, res: any) => {
	const { token, platform } = req.body || {};
	if (!token || !platform) return res.status(400).json({ error: 'token and platform required' });
	await upsertFcmToken(req.user.id, token, platform);
	res.json({ status: 'ok' });
});
