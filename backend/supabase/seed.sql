-- Seed minimal stations
insert into public.stations (name, state, lat, lon)
values
	('Delhi - Anand Vihar', 'Delhi', 28.6469, 77.3158),
	('Mumbai - Bandra', 'Maharashtra', 19.0596, 72.8295)
on conflict do nothing;

-- Optional sample readings (use current timestamps)
insert into public.aqi_readings (station_id, timestamp, aqi, pollutants)
select id, now() - interval '30 minutes', 95, '[{"name":"PM2.5","value":45.5}]'::jsonb from public.stations where name = 'Delhi - Anand Vihar'
union all
select id, now() - interval '25 minutes', 120, '[{"name":"PM10","value":78.2}]'::jsonb from public.stations where name = 'Mumbai - Bandra'
;
