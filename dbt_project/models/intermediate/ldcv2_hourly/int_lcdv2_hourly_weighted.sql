select * from {{ ref('int_lcdv2_hourly_weighted_bucket_00') }}
union all
select * from {{ ref('int_lcdv2_hourly_weighted_bucket_01') }}
union all
select * from {{ ref('int_lcdv2_hourly_weighted_bucket_02') }}
union all
select * from {{ ref('int_lcdv2_hourly_weighted_bucket_03') }}
union all
select * from {{ ref('int_lcdv2_hourly_weighted_bucket_04') }}
union all
select * from {{ ref('int_lcdv2_hourly_weighted_bucket_05') }}
union all
select * from {{ ref('int_lcdv2_hourly_weighted_bucket_06') }}
union all
select * from {{ ref('int_lcdv2_hourly_weighted_bucket_07') }}
union all
select * from {{ ref('int_lcdv2_hourly_weighted_bucket_08') }}
union all
select * from {{ ref('int_lcdv2_hourly_weighted_bucket_09') }}
union all
select * from {{ ref('int_lcdv2_hourly_weighted_bucket_10') }}
union all
select * from {{ ref('int_lcdv2_hourly_weighted_bucket_11') }}
union all
select * from {{ ref('int_lcdv2_hourly_weighted_bucket_12') }}
union all
select * from {{ ref('int_lcdv2_hourly_weighted_bucket_13') }}
union all
select * from {{ ref('int_lcdv2_hourly_weighted_bucket_14') }}
union all
select * from {{ ref('int_lcdv2_hourly_weighted_bucket_15') }}
