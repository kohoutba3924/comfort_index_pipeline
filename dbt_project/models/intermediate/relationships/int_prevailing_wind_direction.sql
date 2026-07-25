
with hourly as (
    select
        station,
        wind_direction,
        floored_timestamp,

        case
            when extract(month from floored_timestamp) in (12, 1, 2) then 'DJF'
            when extract(month from floored_timestamp) in (3, 4, 5) then 'MAM'
            when extract(month from floored_timestamp) in (6, 7, 8) then 'JJA'
            else 'SON'
        end as season
    from {{ ref('int_lcdv2_hourly') }}
),

seasonal_grouped as (
    select
        station,
        season,
        {{ circular_mean('wind_direction') }} as prevailing_wind_direction_deg
    from hourly
    group by station, season
),

overall_grouped as (
    select
        station,
        {{ circular_mean('wind_direction') }} as overall_prevailing_wind_direction_deg
    from hourly
    group by station
)

select
    sg.station,
    sg.season,
    coalesce(
        sg.prevailing_wind_direction_deg,
        og.overall_prevailing_wind_direction_deg
    ) as prevailing_wind_direction_deg
from seasonal_grouped sg
left join overall_grouped og
    on sg.station = og.station
