with station as (
    select
        station,
        name,
        latitude,
        longitude,
        data_coverage,
        min_date,
        max_date
    from {{ ref('stg_lcdv2_station') }}
),

elev as (
    select
        station,
        elevation_m
    from {{ ref('stg_station_elevation') }}
)

select
    station.station,
    station.name,
    station.latitude,
    station.longitude,
    elev.elevation_m,
    station.data_coverage,
    station.min_date,
    station.max_date

from station
left join elev using (station)
