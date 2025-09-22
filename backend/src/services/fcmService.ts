import admin from 'firebase-admin';
import { getEnv } from '../utils/env.js';

let initialized = false;

function initializeFirebase() {
	if (initialized) return;
	const credentialsPath = process.env.FIREBASE_CREDENTIALS_PATH;
	const projectId = process.env.FIREBASE_PROJECT_ID;
	const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
	const privateKey = process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n');

	if (credentialsPath) {
		admin.initializeApp({
			credential: admin.credential.cert(credentialsPath),
		});
		initialized = true;
		return;
	}

	if (projectId && clientEmail && privateKey) {
		admin.initializeApp({
			credential: admin.credential.cert({
				projectId,
				clientEmail,
				privateKey,
			}),
		});
		initialized = true;
		return;
	}

	throw new Error('Firebase credentials not configured');
}

export async function sendAqiAlert(token: string, title: string, body: string, data?: Record<string, string>) {
	if (!initialized) initializeFirebase();
	await admin.messaging().send({ token, notification: { title, body }, data });
}
