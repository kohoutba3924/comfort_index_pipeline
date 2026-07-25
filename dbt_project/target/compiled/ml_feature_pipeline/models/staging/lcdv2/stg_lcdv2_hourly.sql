with src as (
    select *
    from read_parquet("../data/normalized/lcdv2/")
)

select
    cast(station as varchar) as station,
    cast(timestamp as timestamp) as timestamp,

    -- Temperature in °F
    cast(dry_bulb_temp as float) as dry_bulb_temp,
    cast(wet_bulb_temp as float) as wet_bulb_temp,
    cast(dew_point_temp as float) as dew_point_temp,

    -- Relative humidity %
    cast(relative_humidity as float) as relative_humidity,

    -- Wind speed in mph
    cast(wind_speed as float) as wind_speed,
    cast(wind_direction as float) as wind_direction,
    cast(wind_gust_speed as float) as wind_gust_speed,

    -- Precipitation in inches
    cast(precipitation as float) as precipitation,

    -- Visibility in miles
    cast(visibility as float) as visibility,

    -- Pressure in inHg
    cast(station_pressure as float) as station_pressure,
    cast(barometric_pressure as float) as barometric_pressure

from src