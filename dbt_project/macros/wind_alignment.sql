{% macro wind_alignment(prevailing_direction_deg, bearing_deg) %}
    (
        -- Δθ = prevailing wind - bearing, normalized to [0, 360)
        with angle_diff as (
            select
                (
                    ({{ prevailing_direction_deg }} - {{ bearing_deg }}) + 360
                ) % 360 as delta_deg
        )
        select
            (
                -- cos(Δθ) in radians, then rescale from [-1, 1] to [0, 1]
                (cos(radians(delta_deg)) + 1.0) / 2.0
            ) as alignment
        from angle_diff
    )
{% endmacro %}
