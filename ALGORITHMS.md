# ALGORITHMS.md — Core Algorithms & Macros

This document explains the core algorithms used in the ML Feature Pipeline. The algorithms match the exact logic implemented in the dbt macros provided in the project.

The algorithms fall into the following categories:

1. Geospatial calculations  
2. Elevation-based adjustments  
3. Seasonal prevailing wind direction  
4. Weighting logic  
5. Weighted hourly aggregation  
6. Utility algorithms  

---

## 1. Geospatial Algorithms

### 1.1 Haversine Distance

Macro: "haversine_distance"

Computes great-circle distance between tract centroid and station.

Formula:

distance_m = 2 * 6371000 * asin(  
    sqrt(  
        sin²( radians(lat2 - lat1) / 2 )  
        + cos( radians(lat1) )  
        * cos( radians(lat2) )  
        * sin²( radians(lon2 - lon1) / 2 )  
    )  
)  

Purpose: accurate geographic distance used for distance taper and station eligibility.

---

### 1.2 Bearing Calculation

Macro: "bearing"

Computes direction from station to track.

Formula:

bearing_rad = atan2(  
    sin(delta_lon) * cos(lat2_rad),  
    cos(lat1_rad) * sin(lat2_rad)  
    - sin(lat1_rad) * cos(lat2_rad) * cos(delta_lon)  
)  

bearing_deg_raw = degrees(bearing_rad)  

bearing_deg = (bearing_deg_raw + 360) % 360  


Purpose: directional context for wind alignment weighting.

---

## 2. Elevation Algorithms

### 2.1 Elevation Difference

elevation_diff_m = station_elevation_m − tract_elevation_m

Purpose: used directly in elevation_penalty.

---

### 2.2 Elevation Penalty

Macro: "elevation_penalty"

Formula:

elevation_penalty = 1 / (1 + abs(elevation_diff_m) / 100.0)

Properties:

- Smooth decay  
- Ranges 0–1  
- Penalizes large elevation differences  

---

## 3. Seasonal Prevailing Wind Direction

Macro: "circular_mean"

Computes circular mean of wind direction values.

Formula:

mean_sin = avg( sin( radians(direction) ) )  
mean_cos = avg( cos( radians(direction) ) )  

ang = degrees( atan2(mean_sin, mean_cos) )  

prevailing_direction_deg = case  
    when ang < 0 then ang + 360  
    else ang  
end  

Purpose: stable seasonal reference direction used in wind alignment weighting.

---

## 4. Weighting Algorithms

Weighting is performed in "int_station_weights".  
Four components combine to form final_weight.

---

### 4.1 Distance Taper

Macro: "distance_taper"

Formula:

if distance_m <= 50000:  
    distance_factor = max(0.0, 1.0 - (distance_m / 50000.0))  
else:  
    distance_factor = 0.0  

Properties:

- Linear decay from 1 → 0 across 0–50 km  
- Stations beyond 50 km contribute zero weight  

---

### 4.2 Wind Alignment (Bearing-Based)

Macro: "wind_alignment"

This compares **prevailing wind direction** to **bearing from tract to station**.

Formula:

delta_deg = (prevailing_direction_deg - bearing_deg + 360) % 360  

alignment = ( cos( radians(delta_deg) ) + 1.0 ) / 2.0  

Properties:

- Normalized to 0–1  
- 1 = perfectly aligned  
- 0 = opposite direction  
- Uses bearing_deg from Macro: "bearing"

---

### 4.3 Raw Weight

Formula:

"raw_weight = (0.6 * distance_factor) + (0.3 * elevation_penalty) + (0.1 * wind_alignment)"

Purpose: unnormalized station influence.

---

### 4.4 Final Weight Normalization

Macro: "normalize_weights"

Formula:

final_weight = raw_weight  
    / sum(raw_weight) over (partition by tract, season)  

Properties:

- Ensures weights sum to 1  
- Produces stable weighting across seasons  

---

## 5. Weighted Hourly Aggregation

Performed in bucket models:

- "int_lcdv2_hourly_weighted_bucket_00"  
- ...  
- "int_lcdv2_hourly_weighted_bucket_15"

Aggregation formula:

weighted_value = sum( final_weight * station_value )

Variables include:

- dry bulb temperature  
- wet bulb temperature  
- dew point  
- relative humidity  
- wind speed  
- wind direction  
- wind gust  
- precipitation  
- visibility  
- station pressure  
- barometric pressure  

Purpose: tract-level hourly weather features.

Note: weighted wind direction is computed using the circular_mean of weighted wind sin and weighted wind cos.

---

## 6. Utility Algorithms

### 6.1 Hour Flooring

Macro: "floor_hour"

Formula:

floored_timestamp = date_trunc('hour', ts)

Used to ensure consistent hourly timestamps. Macro used to improve code readability.

---

### 6.2 Final Subhourly Record Selection

Macro: "is_final_subhourly_record"

Formula:

row_number() over (  
    partition by station, date_trunc('hour', ts)  
    order by ts desc  
) = 1  

Purpose: selects the last subhourly record within each hour, used to extract the correct percipitation value from subhourly records where intra hour records are a running total. Macro used to improve code readability.

---

## 7. Summary

These algorithms combine geospatial reasoning, elevation adjustments, seasonal wind behavior, and weighted aggregation to assist in producing tract-level hourly weather features.
