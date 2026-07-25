
with geom as (
    select
        station,
        tract,
        distance_m,
        bearing_deg,
        elevation_diff_m
    from {{ ref('int_tract_station_distance') }}
),

seasonal as (
    select
        station,
        season,
        prevailing_wind_direction_deg
    from {{ ref('int_prevailing_wind_direction') }}
),

joined as (
    select
        g.station,
        g.tract,
        s.season,
        g.distance_m,
        g.bearing_deg,
        g.elevation_diff_m,
        s.prevailing_wind_direction_deg
    from geom g
    join seasonal s
        on g.station = s.station
),

within_50km as (
    select *
    from joined
    where distance_m <= 50000
),

fallback as (
    -- For tracts with zero stations within 50 km, pick the nearest station
    select
        j.*
    from joined j
    join (
        select
            tract,
            season,
            min(distance_m) as min_dist
        from joined
        group by tract, season
        having count_if(distance_m <= 50000) = 0
    ) f
        on j.tract = f.tract
       and j.season = f.season
       and j.distance_m = f.min_dist
),

combined as (
    select * from within_50km
    union all
    select * from fallback
),

raw_weights as (
    select
        station,
        tract,
        season,

        -- Neutral fallback for missing wind direction
        coalesce(
            {{ wind_alignment('prevailing_wind_direction_deg', 'bearing_deg') }},
            0.5
        ) as wind_alignment,

        {{ elevation_penalty('elevation_diff_m') }} as elevation_penalty,
        {{ distance_taper('distance_m') }} as distance_factor,

        -- Scientifically grounded additive weighting model
        (
              0.6 * {{ distance_taper('distance_m') }}
            + 0.3 * {{ elevation_penalty('elevation_diff_m') }}
            + 0.1 * coalesce(
                    {{ wind_alignment('prevailing_wind_direction_deg', 'bearing_deg') }},
                    0.5
              )
        ) as raw_weight

    from combined
),

normalized as (
    select
        *,
        {{ normalize_weights('raw_weight', ['tract', 'season']) }} as final_weight
    from raw_weights
),

station_sets as (
    select
        tract,
        season,
        array_agg(station order by station) as stations_used
    from normalized
    group by tract, season
)

select
    n.*,
    s.stations_used
from normalized n
join station_sets s
    on n.tract = s.tract
   and n.season = s.season
