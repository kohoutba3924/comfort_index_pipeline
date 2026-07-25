{% macro circular_mean(direction_array) %}
(
    with angle as (
        select degrees(
            atan2(
                avg(sin(radians({{ direction_array }}))),
                avg(cos(radians({{ direction_array }})))
            )
        ) as ang
    )
    select case 
        when ang < 0 then ang + 360
        else ang
    end
    from angle
)
{% endmacro %}
