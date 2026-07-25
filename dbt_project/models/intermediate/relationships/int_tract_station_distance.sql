
with stations as (
    select
        station,
        latitude as station_lat,
        longitude as station_lon,
        elevation_m as station_elev
    from {{ ref('int_station_dim_enriched') }}
),

tracts as (
    select
        tract,
        centroid_lat as tract_lat,
        centroid_lon as tract_lon,
        elevation_m as tract_elev
    from {{ ref('int_tract_dim_enriched') }}
),

cross_joined as (
    select
        s.station,
        t.tract,
        s.station_lat,
        s.station_lon,
        t.tract_lat,
        t.tract_lon,
        s.station_elev,
        t.tract_elev
    from stations s
    cross join tracts t
),

distance_calc as (
    select
        station,
        tract,

        -- haversine distance (meters)
        {{ haversine_distance('station_lat', 'station_lon', 'tract_lat', 'tract_lon') }} as distance_m,

        -- bearing station → tract (degrees)
        {{ bearing('station_lat', 'station_lon', 'tract_lat', 'tract_lon') }} as bearing_deg,

        -- elevation difference (meters)
        (tract_elev - station_elev) as elevation_diff_m

    from cross_joined
)

select * from distance_calc
