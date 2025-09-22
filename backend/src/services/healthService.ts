type PollutantReading = { name: string; value: number };

type HealthAdvice = {
	category: string;
	advice: string[];
	maskRecommended: boolean;
	outdoorActivity: 'ok' | 'limit' | 'avoid';
};

export function generateHealthRecommendations(aqi: number, pollutants: PollutantReading[]): HealthAdvice {
	let category = 'Good';
	let advice: string[] = ['Enjoy your day!'];
	let maskRecommended = false;
	let outdoorActivity: 'ok' | 'limit' | 'avoid' = 'ok';

	if (aqi <= 50) {
		category = 'Good';
		advice = ['Air quality is satisfactory.'];
		maskRecommended = false;
		outdoorActivity = 'ok';
	} else if (aqi <= 100) {
		category = 'Satisfactory';
		advice = ['Sensitive groups should monitor symptoms.'];
		maskRecommended = false;
		outdoorActivity = 'ok';
	} else if (aqi <= 200) {
		category = 'Moderate';
		advice = ['Consider limiting prolonged outdoor exertion.'];
		maskRecommended = true;
		outdoorActivity = 'limit';
	} else if (aqi <= 300) {
		category = 'Poor';
		advice = ['Reduce outdoor activities, wear a mask if necessary.'];
		maskRecommended = true;
		outdoorActivity = 'limit';
	} else if (aqi <= 400) {
		category = 'Very Poor';
		advice = ['Avoid outdoor activities; use air purifiers indoors.'];
		maskRecommended = true;
		outdoorActivity = 'avoid';
	} else {
		category = 'Severe';
		advice = ['Stay indoors; avoid all outdoor exertion; monitor health symptoms.'];
		maskRecommended = true;
		outdoorActivity = 'avoid';
	}

	const pm25 = pollutants.find((p) => p.name.toLowerCase() === 'pm2.5');
	if (pm25 && pm25.value > 60) advice.push('High PM2.5: wear N95 outdoors.');
	const ozone = pollutants.find((p) => p.name.toLowerCase() === 'o3' || p.name.toLowerCase() === 'ozone');
	if (ozone && ozone.value > 180) advice.push('High Ozone: avoid afternoon outdoor activity.');

	return { category, advice, maskRecommended, outdoorActivity };
}
