{% macro bearing(lat1, lon1, lat2, lon2) %}
(
    with angles as (
        select
            radians({{ lat1 }}) as lat1_rad,
            radians({{ lon1 }}) as lon1_rad,
            radians({{ lat2 }}) as lat2_rad,
            radians({{ lon2 }}) as lon2_rad
    ),
    calc as (
        select
            lat1_rad,
            lon1_rad,
            lat2_rad,
            lon2_rad,
            (lon2_rad - lon1_rad) as delta_lon
        from angles
    ),
    bearing_raw as (
        select
            degrees(
                atan2(
                    sin(delta_lon) * cos(lat2_rad),
                    cos(lat1_rad) * sin(lat2_rad)
                    - sin(lat1_rad) * cos(lat2_rad) * cos(delta_lon)
                )
            ) as bearing_deg_raw
        from calc
    )
    select
        -- Normalize bearing to [0, 360)
        (bearing_deg_raw + 360) % 360 as bearing_deg
    from bearing_raw
)
{% endmacro %}
