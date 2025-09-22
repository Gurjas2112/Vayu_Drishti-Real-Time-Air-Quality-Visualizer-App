import { Router } from 'express';
import { router as aqiRouter } from './aqi.js';
import { router as ingestRouter } from './ingest.js';
import { router as userRouter } from './user.js';

export const router = Router();

router.use('/aqi', aqiRouter);
router.use('/ingest', ingestRouter);
router.use('/user', userRouter);
