# INGESTION.md — Ingestion & Normalization Pipeline

This document describes the Python-based ingestion and normalization pipeline that prepares all raw data sources for downstream processing in dbt. The ingestion layer is responsible for extracting, validating, normalizing, and partitioning external datasets into a consistent, analysis-ready format.

---

## 1. Overview

The ingestion pipeline processes three primary external datasets:

- NOAA LCDv2 (Local Climatological Data)
- TIGER/Line Census Tracts
- ACS 5-Year Demographic Estimates

All ingestion logic is implemented in Python, consuming raw data via external api endpoints and stored under a raw data directory; "data/raw". These files are then used to produce normalized Parquet files stored under a normalized data directory; "data/normalized". These Parquet files serve as the input to the dbt staging layer.

---

## 2. NOAA LCDv2 Ingestion

**Source:** Hourly weather observations and station metadata from NOAA’s LCDv2 archive.

**Key responsibilities:**

- Bulk file acquisition  
  Download LCDv2 station metadata and annual LCDv2 files for all relevant stations and years.

- Schema normalization  
  Standardize column names and enforce consistent types across years.

- Unit handling  
  LCDv2 values are already in final units (°F, knots, miles, inches, inHg).  
  No unit conversion is performed during ingestion.

- Partitioning  
  Write normalized Parquet files partitioned by station and year, e.g.  
  "data/normalized/lcdv2/{station_id}/{year}/part.parquet".

**Output:**
LCDv2 station metadata stored under "data/external/lcdv2_stations.parquet".  
Normalized hourly LCDv2 Parquet files stored under "data/normalized/lcdv2".

---

## 3. TIGER/Line Tract Ingestion

**Source:** Census tract shapefiles from TIGER/Line.

**Key responsibilities:**

- Geometry ingestion  
  Read tract shapefiles using a geospatial library and extract polygons.

- Centroid calculation  
  Compute tract centroids in latitude/longitude.

**Output:**  
A normalized tract geometry file such as "data/normalized/tiger_tracts.parquet".

---

## 4. ACS 5-Year Demographic Ingestion

**Source:** American Community Survey (ACS) 5-year estimates.

**Key responsibilities:**

- Raw file ingestion  
  Read ACS CSV files containing tract-level demographic attributes.

- Column normalization  
  Rename ACS columns to consistent, readable names.

- Join key alignment  
  Normalize tract identifiers to match TIGER/Line tract IDs.

**Output:**  
A normalized ACS demographic file such as "data/normalized/acs_5yr.parquet".

---

## 5. Elevation Data Ingestion

**Source:** USGS National Map Elevation Point Query Service (EPQS)

**Key responsibilities:**

- Station elevation merge  
  Ingest station elevation data keyed by station ID.

- Tract elevation merge  
  Ingest tract elevation data keyed by tract centroid location.

**Output:**  
"data/raw/elevation/station_elevation.parquet"  
"data/raw/elevation/tract_elevation.parquet"

---

## 6. Ingestion → dbt Interface

The python ingestion and normalization layers hand off normalized Parquet files to dbt.  
Staging models read directly from these outputs:

- "data/external/lcdv2_stations" → stg_lcdv2_stations 
- "data/normalized/lcdv2/..." → stg_lcdv2_hourly  
- "data/normalized/tiger_tracts.parquet" → stg_tiger_tracts  
- "data/normalized/acs_5yr.parquet" → stg_acs_5yr  
- "data/raw/elevation/station_elevation.parquet" → stg_station_elevation  
- "data/raw/elevation/tract_elevation.parquet" → stg_tract_elevation

dbt is not responsible for downloading files, parsing shapefiles, or performing heavy geospatial operations. Those responsibilities remain in Python.

---

## 7. Summary

The ingestion pipeline:

- Centralizes external data acquisition and normalization.
- Handles normalization concerns before dbt.
- Produces consistent, partitioned Parquet datasets ready for relational modeling.
- Provides a clean boundary where dbt can focus on tract–station relationships, weighting algorithms, hourly aggregation, and final feature construction.

This separation of concerns keeps dbt focused on SQL transformations while Python handles the heavier ingestion and normalization workload.
