{% macro normalize_weights(raw_weight_col, group_by_cols) %}
(
    {{ raw_weight_col }}::double
    /
    nullif(
        sum({{ raw_weight_col }}) over (
            partition by
            {% for col in group_by_cols %}
                {{ col }}{% if not loop.last %}, {% endif %}
            {% endfor %}
        ),
        0
    )
)
{% endmacro %}
