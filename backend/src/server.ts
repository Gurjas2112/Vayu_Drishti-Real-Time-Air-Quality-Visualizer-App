import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import morgan from 'morgan';
import http from 'http';
import { getEnv } from './utils/env.js';
import { router as apiRouter } from './routes/index.js';
import { initRealtime } from './services/realtimeService.js';

const app = express();

app.use(cors());
app.use(express.json({ limit: '1mb' }));
app.use(morgan('dev'));

app.get('/health', (_req: any, res: any) => {
  res.json({ status: 'ok' });
});

app.use('/api', apiRouter);

const server = http.createServer(app);
initRealtime(server);

const port = Number(getEnv('PORT', '8080'));
server.listen(port, () => {
  // eslint-disable-next-line no-console
  console.log(`Backend listening on http://localhost:${port}`);
});
