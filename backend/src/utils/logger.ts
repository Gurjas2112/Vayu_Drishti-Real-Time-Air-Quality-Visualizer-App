export const logger = {
	info: (msg: unknown, ...args: unknown[]) => console.log(msg, ...args),
	warn: (msg: unknown, ...args: unknown[]) => console.warn(msg, ...args),
	error: (msg: unknown, ...args: unknown[]) => console.error(msg, ...args),
};
