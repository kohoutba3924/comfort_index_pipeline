{{ config(
    pre_hook=[
        "SET threads=1",
        "SET preserve_insertion_order=false"
    ]
) }}

-- 1. Filter tracts to this bucket
with tracts as (
    select
        tract,
        tract_bucket
    from {{ ref('int_tract_dim_enriched') }}
    where tract_bucket = 9
),

-- 2. Filter station weights to only tracts in this bucket
weights as (
    select
        w.station,
        w.tract,
        w.season,
        w.final_weight,
        w.stations_used
    from {{ ref('int_station_weights') }} w
    join tracts t using (tract)
),

-- 3. Filter hourly data to only those stations in weights
hourly as (
    select
        station,
        floored_timestamp,
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
        barometric_pressure,
        case
            when extract(month from floored_timestamp) in (12, 1, 2) then 'DJF'
            when extract(month from floored_timestamp) in (3, 4, 5) then 'MAM'
            when extract(month from floored_timestamp) in (6, 7, 8) then 'JJA'
            else 'SON'
        end as season
    from {{ ref('int_lcdv2_hourly') }}
    where station in (
        select distinct station
        from weights
    )
),

-- 4. Join hourly × weights for tracts in this bucket
joined as (
    select
        w.tract,
        h.floored_timestamp,
        h.season,
        h.station,
        w.final_weight,
        w.stations_used,

        h.dry_bulb_temp,
        h.wet_bulb_temp,
        h.dew_point_temp,
        h.relative_humidity,
        h.wind_speed,
        h.wind_direction,
        h.wind_gust_speed,
        h.precipitation,
        h.visibility,
        h.station_pressure,
        h.barometric_pressure
    from hourly h
    join weights w
      on h.station = w.station
     and h.season = w.season
),

-- 5. Weighted projections
weighted as (
    select
        tract,
        floored_timestamp,
        stations_used,

        final_weight * dry_bulb_temp        as weighted_dry_bulb_temp,
        final_weight * wet_bulb_temp        as weighted_wet_bulb_temp,
        final_weight * dew_point_temp       as weighted_dew_point_temp,
        final_weight * relative_humidity    as weighted_relative_humidity,
        final_weight * wind_speed           as weighted_wind_speed,
        final_weight * wind_gust_speed      as weighted_wind_gust_speed,
        final_weight * precipitation        as weighted_precipitation,
        final_weight * visibility           as weighted_visibility,
        final_weight * station_pressure     as weighted_station_pressure,
        final_weight * barometric_pressure  as weighted_barometric_pressure,

        final_weight * sin(radians(wind_direction)) as weighted_wind_sin,
        final_weight * cos(radians(wind_direction)) as weighted_wind_cos
    from joined
),

-- 6. Final aggregation for this bucket
aggregated as (
    select
        tract,
        floored_timestamp,
        min(stations_used) as stations_used,

        sum(weighted_dry_bulb_temp)         as weighted_dry_bulb_temp,
        sum(weighted_wet_bulb_temp)         as weighted_wet_bulb_temp,
        sum(weighted_dew_point_temp)        as weighted_dew_point_temp,
        sum(weighted_relative_humidity)     as weighted_relative_humidity,
        sum(weighted_wind_speed)            as weighted_wind_speed,
        sum(weighted_wind_gust_speed)       as weighted_wind_gust_speed,
        sum(weighted_precipitation)         as weighted_precipitation,
        sum(weighted_visibility)            as weighted_visibility,
        sum(weighted_station_pressure)      as weighted_station_pressure,
        sum(weighted_barometric_pressure)   as weighted_barometric_pressure,

        mod(
            degrees(
                atan2(
                    sum(weighted_wind_sin),
                    sum(weighted_wind_cos)
                    )
                    ) + 360,
                360
            ) as weighted_wind_direction
    from weighted
    group by tract, floored_timestamp
)

select *
from aggregated
