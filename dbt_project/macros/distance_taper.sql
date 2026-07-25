{% macro distance_taper(distance_m) %}
(
    case
        when {{ distance_m }} <= 50000
            then greatest(0.0, 1.0 - ({{ distance_m }} / 50000.0))
        else 0.0
    end
)
{% endmacro %}
