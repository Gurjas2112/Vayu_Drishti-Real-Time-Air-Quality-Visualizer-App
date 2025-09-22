import { Server } from 'socket.io';

let io: Server | null = null;

export function initRealtime(server: any) {
	io = new Server(server, { cors: { origin: '*'} });
	io.on('connection', (socket) => {
		socket.emit('welcome', { message: 'Connected to Vayu Drishti realtime' });
	});
	return io;
}

export function emitEvent(event: string, payload: unknown) {
	if (!io) return;
	io.emit(event, payload);
}
