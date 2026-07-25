with base as (
    select
        station,
        timestamp,
        dry_bulb_temp,
        wet_bulb_temp,
        dew_point_temp,
        relative_humidity,
        wind_speed,
        wind_direction,
        wind_gust_speed,
        precipitation,
        visibility,
        station_pressure,
        barometric_pressure
    from {{ ref('stg_lcdv2_hourly') }}
),

with_flags as (
    select
        *,
        {{ is_final_subhourly_record('timestamp', 'station') }} as is_final,
        {{ floor_hour('timestamp') }} as floored_timestamp
    from base
),

aggregated as (
    select
        station,
        floored_timestamp,

        avg(dry_bulb_temp) as dry_bulb_temp,
        avg(wet_bulb_temp) as wet_bulb_temp,
        avg(dew_point_temp) as dew_point_temp,
        avg(relative_humidity) as relative_humidity,
        avg(wind_speed) as wind_speed,
        {{ circular_mean('wind_direction') }} as wind_direction,
        max(wind_gust_speed) as wind_gust_speed,
        -- precipitation: final subhourly record only
        max(case when is_final then precipitation end) as precipitation,
        avg(visibility) as visibility,
        avg(station_pressure) as station_pressure,
        avg(barometric_pressure) as barometric_pressure

    from with_flags
    group by station, floored_timestamp
)

select * from aggregated
