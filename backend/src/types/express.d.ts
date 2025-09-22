declare module 'express' {
	export interface Request { [key: string]: any }
	export interface Response { [key: string]: any }
	export interface NextFunction { (err?: any): void }
	export function Router(): any;
	const _default: any;
	export default _default;
}
