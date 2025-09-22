-- RPC: get nearest station's latest AQI for a given lat/lon
create or replace function public.get_nearest_station_aqi(lat double precision, lon double precision)
returns jsonb
language plpgsql
stable
as $$
declare
	result jsonb;
begin
	select to_jsonb(t) into result from (
		select la.station_id as "stationId",
			( select s.name from public.stations s where s.id = la.station_id ) as "stationName",
			( select s.lat from public.stations s where s.id = la.station_id ) as lat,
			( select s.lon from public.stations s where s.id = la.station_id ) as lon,
			la.aqi as aqi,
			la.pollutants as pollutants,
			la.timestamp as timestamp
		from public.latest_aqi la
		join public.stations st on st.id = la.station_id
		order by earth_distance(ll_to_earth(lat, lon), ll_to_earth(st.lat, st.lon)) asc
		limit 1
	) t;
	return result;
end;
$$;

-- RPC: upsert station by name and location, returns id
create or replace function public.upsert_station(_name text, _state text, _lat double precision, _lon double precision)
returns uuid
language plpgsql
volatile
as $$
declare
	_station_id uuid;
begin
	insert into public.stations(name, state, lat, lon)
	values (_name, _state, _lat, _lon)
	on conflict (name, lat, lon)
		do update set state = excluded.state
	returning id into _station_id;
	return _station_id;
end;
$$;
