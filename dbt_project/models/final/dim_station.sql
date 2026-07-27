
select
    *
from {{ ref('int_station_dim_enriched') }}
