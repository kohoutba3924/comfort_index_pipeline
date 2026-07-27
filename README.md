# ML Feature Pipeline

The ML Feature Pipeline is a modular, production‑inspired data engineering system that builds tract‑level hourly weather features by combining meteorological, geospatial, and census datasets. The pipeline integrates a Python ingestion layer with a dbt transformation layer to produce high‑quality, analysis‑ready features suitable for downstream machine learning workflows.

This repository contains the complete implementation of the pipeline, including ingestion, normalization, transformation, weighting, aggregation, and final feature store construction.

---

## 1. Project Structure

The project consists of two major components:

### A. Python Ingestion & Normalization

Located in a modular src‑based Python project structure, responsible for:

- Downloading and normalizing external datasets.
- Performing geospatial operations (centroids, bounding boxes).
- Producing normalized Parquet files.

The ingestion layer is fully parameterized to support rerunning the pipeline for any U.S. state via configuration settings. Its modular structure also supports adding new data sources with minimal changes and is designed to accommodate future orchestration and logging.

### B. dbt Transformation Layer

Located in the "dbt_project/" directory, responsible for:

- Staging normalized Parquet files.
- Aggregating subhourly station observations to an hourly data resolution. 
- Computing tract–station distances, bearings, and elevation differences.
- Computing seasonal prevailing wind direction.
- Computing distance taper, elevation penalty, and wind alignment.
- Applying an additive weighting model:

  raw_weight = (0.6 * distance_taper) + (0.3 * elevation_penalty) + (0.1 * wind_alignment)

- Normalizing weights per tract‑season.
- Aggregating weighted hourly weather features across 16 parallel spatial buckets.
- Producing final dimensional and fact tables:
  - "dim_tract"
  - "dim_station"
  - "rel_station_weights"
  - "rel_tract_station_distance"
  - "fact_lcdv2_tract_hourly"

---

## 2. Data Sources

The pipeline integrates multiple authoritative datasets:

### NOAA Local Climatological Data (LCDv2)

Hourly station‑level weather observations.  
Dataset: https://www.ncei.noaa.gov/products/land-based-station/local-climatological-data  
API: https://www.ncdc.noaa.gov/cdo-web/webservices/v2

### U.S. Census Bureau — TIGER/Line Shapefiles (Census Tracts)

Geospatial tract boundaries and identifiers.  
Technical Documentation: https://www2.census.gov/geo/pdfs/maps-data/data/tiger/tgrshp2023/TGRSHP2023_TechDoc.pdf  
Shapefiles: https://www2.census.gov/geo/tiger/TIGER2023/TRACT/

### ACS 5‑Year Estimates

Tract‑level demographic attributes.  
API: https://api.census.gov/data/2023/acs/acs5  
Variables: https://api.census.gov/data/2023/acs/acs5/variables.html  
Technical Documentation: https://www.census.gov/programs-surveys/acs/technical-documentation.html

### USGS National Map Elevation Point Query Service (EPQS)

Elevation data for stations and tracts.  
Dataset: https://apps.nationalmap.gov/epqs/  
API: https://nationalmap.gov/epqs/pqs.php

---

## 3. Pipeline Flow

High‑level architecture:

Raw External Data  
   ↓  
Python Ingestion & Normalization    
   ↓  
dbt Staging Models  
   ↓  
dbt Intermediate Models  
   ↓  
dbt Final Models  

---

## 4. Running the Pipeline

A placeholder for an orchestration layer has been added under the src directory. Once completed, the pipeline orchestrater will centralize the running and management of the pipeline, including raw data ingestion, normalization, and all dbt model processing and outputs. Until then, each Python ingestion and normalization module must be run manaually. The only dependencies to account for are that all ingestion modules must be ran prior to normalization modules. Once all manual python modules have been manually run, the dbt portion of the pipeline may be fully executed via the 'dbt build' command.

---

## 5. Final Output

The pipeline produces a complete final layer consisting of **two dimensional tables**, **two relational tables**, and a **tract‑level hourly fact table**. Together, these form a clean, production‑style star schema suitable for downstream machine learning workflows.

---

### Dimensional Tables

#### "dim_tract"
A tract‑level dimension table containing:
- tract identifiers
- centroid coordinates
- bounding box fields
- elevation
- ACS demographic attributes
- spatial bucket assignment

This table provides the geographic and socioeconomic context for tract‑level weather features.

#### "dim_station"
A station‑level dimension table containing:
- station identifiers
- geographic coordinates
- elevation
- station metadata

This table provides the physical and operational characteristics of each weather station used in the weighting process.

---

### Relational Tables

#### "rel_tract_station_distance"
A relationship table containing:
- tract ID
- station ID
- haversine distance from station to tract centroid (meters)
- bearing from station to tract (degrees),
- elevation difference (meters).

This table encodes the geospatial relationships between tracts and stations and serves as the foundation for distance taper, elevation penalty, and wind alignment used in aggregation weighting.

#### "rel_station_weights"
A relationship table containing:
- tract ID
- station ID
- season
- distance taper
- elevation penalty
- wind alignment
- raw weight
- normalized final weight

This table represents the full weighting model used to compute tract‑level hourly weather features. It exposes the influence each station contributes to each tract‑season combination.

---

### Fact Table

#### "fact_lcdv2_tract_hourly"
The final tract‑level hourly weather fact table containing weighted values for:
- temperature,
- humidity,
- wind speed,
- wind direction,
- wind gust,
- precipitation,
- visibility,
- station pressure,
- barometric pressure.

Each value is computed using an additive weighting model and aggregated across all relevant stations for a given tract.

---

## 6. Documentation

Additional project documentation is located in the following files:

- "INGESTION.md" - Python ingestion & normalization pipeline  
- "ARCHITECTURE.md" - end‑to‑end pipeline architecture
- "DAG.md" - a review of each final models dependency graph  
- "ALGORITHMS.md" - geospatial, weighting, and aggregation algorithms  
- "DESIGN_RATIONALE.md" - engineering decisions and rationale  

---

## 7. Summary

The ML Feature Pipeline is a fully implemented, modular, production‑inspired data engineering system that integrates multiple external datasets, applies physically meaningful weighting algorithms, and produces high‑quality tract‑level hourly weather features. Its architecture balances clarity, modularity, and performance, and its final models provide a strong foundation for downstream machine learning workflows.
