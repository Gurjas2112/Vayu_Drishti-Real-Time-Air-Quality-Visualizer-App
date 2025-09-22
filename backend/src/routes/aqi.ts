import { Router } from 'express';
import { getLatestByLocation, getByStation, getHistorical } from '../controllers/aqiController.js';

export const router = Router();

router.get('/latest', getLatestByLocation);
router.get('/station/:stationId', getByStation);
router.get('/historical', getHistorical);
