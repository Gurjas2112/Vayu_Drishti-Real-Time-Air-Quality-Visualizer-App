Vayu Drishti Backend (Node.js + Supabase)

Stack:
- Node.js + Express (TypeScript)
- Supabase (PostgreSQL, Auth)
- Firebase Cloud Messaging (push notifications)
- TensorFlow Lite (AQI forecasting)

Quick Start:
1) cd backend && npm install
2) copy .env.example to .env and fill values
3) npm run dev

Scripts:
- dev: ts-node-dev src/server.ts
- build: tsc
- start: node dist/server.js

Key Paths:
- src/server.ts (entry)
- src/routes/*
- src/controllers/*
- src/services/* (supabase, fcm, forecast, health)
- src/utils/* (env, logger)
