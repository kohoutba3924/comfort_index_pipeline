# DESIGN_RATIONALE.md — Design Decisions & Engineering Rationale

This document explains the key design decisions behind the ML Feature Pipeline. Each decision reflects a balance of correctness, maintainability, performance, and clarity across both the Python ingestion layer and the dbt transformation layer.

The rationale is organized by architectural layer and major engineering themes.

---

## 1. Separation of Responsibilities: Python vs. dbt

### Decision
Use Python for ingestion, normalization, geospatial processing, and pipeline configuration; use dbt for relational modeling, weighting, and aggregation.

### Rationale
Python is better suited for:
- parsing raw external datasets,
- geospatial operations (centroids, bounding boxes),
- schema reconciliation,
- timestamp manipulation,
- file partitioning,
- handling inconsistent raw formats,
- parameterizing ingestion to support reruns for any U.S. state,
- modular pipeline structure that allows new data sources to be added easily,
- future support for full pipeline orchestration and logging.

dbt is better suited for:
- SQL transformations,
- dependency management,
- lineage tracking,
- automated testing,
- documentation generation,
- modular relational modeling.

### Outcome
A clean boundary:
- Python produces normalized Parquet files under directories such as "data/normalized/...".
- dbt consumes these files through staging models.

This separation keeps each tool focused on what it does best while ensuring the ingestion layer is flexible, configurable, and extensible.

---

## 2. Staging Layer Philosophy

### Decision
Keep staging models minimal: type casting, renaming, and structural cleanup only.

### Rationale
- Staging should mirror ingestion outputs.
- Heavy transformations in staging obscure lineage.
- Minimal staging makes debugging easier.
- Downstream layers remain clearer and more maintainable.

### Outcome
Staging models act as a stable interface between ingestion and transformation.

---

## 3. Intermediate Layer Structure

### Decision
Place all meaningful transformations in the intermediate layer, including:
- distance calculations,
- bearing calculations,
- elevation differences,
- prevailing wind direction,
- distance taper,
- elevation penalty,
- wind alignment,
- raw weight,
- normalized weight,
- hourly LCDv2 preparation.

### Rationale
- Intermediate models represent the “core logic” of the pipeline.
- Each transformation is isolated and testable.
- dbt’s DAG clearly shows how each step builds on the previous.
- The intermediate layer becomes the conceptual backbone of the project.

### Outcome
A transparent, modular transformation pipeline that is easy to reason about and validate.

---

## 4. Bucket Architecture for Parallelization

### Decision
Partition tracts into 16 spatial buckets and compute weighted hourly weather per bucket.

### Rationale
- LCDv2 is large; tract-level aggregation is computationally heavy.
- A monolithic model would be slow and memory-intensive.
- Bucketization:
  - reduces memory pressure,
  - improves runtime,
  - enables parallel execution,
  - isolates failures,
  - simplifies debugging.

### Outcome
Sixteen models:
- "int_lcdv2_hourly_weighted_bucket_00"
- ...
- "int_lcdv2_hourly_weighted_bucket_15"

Each processes a subset of tracts efficiently.

---

## 5. Weighting Model Design

### Decision
Use three weighting components:
- distance taper,
- elevation penalty,
- wind alignment (bearing-based),
combined using an additive weighting model:

raw_weight = (0.6 * distance_taper) + (0.3 * elevation_penalty) + (0.1 * wind_alignment)

### Rationale

#### Why additive weighting?
- Multiplicative weighting over-penalizes small deviations and amplifies noise.
- Additive weighting is used in several meteorological interpolation frameworks.
- It allows explicit control over influence ratios.

#### Distance taper (0.6 weight)
- Stations closer to a tract are more representative.
- Linear decay across 0–50 km is intuitive and stable.

#### Elevation penalty (0.3 weight)
- Elevation differences significantly affect temperature, pressure, and wind.
- Smooth decay avoids abrupt weight changes.

#### Wind alignment (0.1 weight)
- Uses bearing (tract → station) and prevailing seasonal wind direction.
- Normalized cosine ensures stable 0–1 scaling.

### Outcome
A physically meaningful weighting system that:
- reflects real meteorological influence ratios,
- avoids multiplicative instability,
- produces smoother, more interpretable weights,
- aligns with published spatial interpolation approaches.

---

## 6. Prevailing Wind Direction by Season

### Decision
Compute prevailing wind direction per station per meteorological season.

### Rationale
- Wind patterns vary significantly by season.
- Seasonal grouping reduces noise.
- Circular mean avoids directional discontinuities (e.g., 359° vs. 1°).

### Outcome
Stable seasonal wind direction values used in wind alignment weighting.

---

## 7. Final Layer as Thin Wrappers

### Decision
Final models ("dim_tract", "dim_station", "rel_station_weights", "rel_tract_station_distance", "fact_lcdv2_tract_hourly") are simple `SELECT * FROM {{ ref(...) }}` wrappers.

### Rationale
- Final models should present clean, stable schemas.
- Intermediate models contain the logic; final models expose the results.
- Thin wrappers improve readability and maintainability.
- Downstream consumers get predictable interfaces.

### Outcome
A clean final layer that is easy to document, test, and consume.

---

## 8. Summary

The design decisions in this pipeline reflect a deliberate engineering philosophy:

- Use each tool for what it does best.  
- Keep layers clean and well-defined.  
- Make transformations modular and testable.  
- Use physically meaningful algorithms.  
- Parameterize ingestion to support reruns for any U.S. state.  
- Maintain a modular ingestion structure that supports new data sources.  
- Preserve future compatibility with full pipeline orchestration and logging.  
- Produce stable, high-quality tract-level hourly weather features.  

This rationale underpins the entire ML Feature Pipeline and ensures it is both technically sound and easy to understand.
