import { Router } from 'express';
import { ingestCpcb, ingestIsro } from '../controllers/ingestController.js';

export const router = Router();

router.post('/cpcb', ingestCpcb);
router.post('/isro', ingestIsro);
