# ML-evaluation-benchmark-analysis

This repository presents a reproducible workflow for generating synthetic customer-churn data, training a machine-learning model, validating model outputs, and independently recomputing evaluation metrics using Python and SQL.

The project was developed as a portfolio case study for data analysis and ML evaluation roles involving:

* structured dataset analysis;
* model-output validation;
* classification metrics;
* failure-mode investigation;
* subgroup analysis;
* Python and SQL integration;
* reproducible analytical workflows.

## Project Overview

The project simulates a customer-churn classification problem.

The target variable is defined as:

* `churn = 1`: the customer cancelled the subscription;
* `churn = 0`: the customer remained.

A synthetic dataset is generated using controlled statistical relationships. Logistic Regression is then used as the baseline classification model.

The model predictions and reported metrics are stored as analytical artifacts and independently evaluated using SQL.

## Project Workflow

```text
Synthetic data generation
        ↓
Data-quality validation
        ↓
Train/test split
        ↓
Feature preprocessing
        ↓
Logistic Regression training
        ↓
Predictions and probabilities
        ↓
Python metric calculation
        ↓
MySQL table creation and CSV import
        ↓
SQL metric recalculation
        ↓
Error, subgroup, and threshold analysis
```

## Repository Structure

```text
ml-evaluation-benchmark-analysis/
│
├── notebooks/
│   ├── Generate_data_and_ml_model.ipynb
│   └── SQL_ml_evaluation.ipynb
│
├── sql/
│   ├── generate_data_base.sql
│   └── mysql_analysis.sql
│
├── data/
│   ├── synthetic_customer_churn.csv
│   ├── logistic_regression_predictions.csv
│   └── reported_metrics.csv
│
├── models/
│   └── logistic_regression_pipeline.joblib
│
├── requirements.txt
└── README.md
```

## Dataset

The synthetic dataset contains 5,000 customer records and the following columns:

| Column            | Description                  |
| ----------------- | ---------------------------- |
| `customer_id`     | Unique customer identifier   |
| `age`             | Customer age                 |
| `region`          | Customer region              |
| `plan`            | Subscription plan            |
| `monthly_fee`     | Monthly subscription fee     |
| `months_active`   | Customer tenure in months    |
| `usage_hours`     | Monthly usage hours          |
| `support_tickets` | Number of support requests   |
| `failed_payments` | Number of failed payments    |
| `churn`           | Binary classification target |

The synthetic churn probability is influenced by interpretable relationships:

* failed payments increase churn probability;
* support tickets increase churn probability;
* higher usage reduces churn probability;
* longer tenure reduces churn probability;
* monthly fees, subscription plan, and region introduce additional effects.

## Important Data Limitation

The dataset is synthetic and was created for workflow demonstration and technical training.

It is suitable for:

* testing analytical pipelines;
* practicing ML evaluation;
* validating SQL queries;
* studying classification metrics;
* simulating model failure modes.

It should not be used to make claims about real customers or real business behavior.

## Machine-Learning Model

The baseline model is Logistic Regression with:

* numerical imputation;
* numerical standardization;
* categorical imputation;
* one-hot encoding;
* balanced class weights;
* reproducible train/test splitting.

The complete preprocessing and classification pipeline is saved as:

```text
logistic_regression_pipeline.joblib
```

## Generated Artifacts

The Python notebook generates:

```text
synthetic_customer_churn.csv
logistic_regression_predictions.csv
reported_metrics.csv
logistic_regression_metrics.json
logistic_regression_pipeline.joblib
```

The prediction file contains:

| Column              | Description                                |
| ------------------- | ------------------------------------------ |
| `experiment_id`     | Unique experiment identifier               |
| `customer_id`       | Customer identifier                        |
| `y_true`            | Actual churn label                         |
| `y_pred`            | Predicted churn label                      |
| `churn_probability` | Predicted probability of churn             |
| `model_name`        | Model type                                 |
| `model_version`     | Model version                              |
| `error_type`        | Correct, false positive, or false negative |

## Evaluation Metrics

The workflow evaluates:

* accuracy;
* precision;
* recall;
* specificity;
* F1-score;
* ROC-AUC;
* PR-AUC;
* log loss;
* confusion-matrix components.

The confusion-matrix metrics are independently recalculated from prediction-level data:

```text
True Positive:
Actual churn = 1 and predicted churn = 1

True Negative:
Actual churn = 0 and predicted churn = 0

False Positive:
Actual churn = 0 and predicted churn = 1

False Negative:
Actual churn = 1 and predicted churn = 0
```

## SQL and Database Workflow

Two SQL implementations are included.

### SQLite notebook

`SQL_ml_evaluation.ipynb` creates and analyzes a SQLite database inside Google Colab.

### MySQL Workbench scripts

The `sql/` directory contains scripts designed for MySQL 8.0 and MySQL Workbench.

* `generate_data_base.sql` creates the schema and relational tables.
* `mysql_analysis.sql` performs data-quality checks and analytical queries.

## MySQL Tables

The MySQL schema contains:

```text
customers
experiments
predictions
reported_metrics
```

The relationships are:

```text
experiments
    └── predictions

customers
    └── predictions

experiments
    └── reported_metrics
```

The composite primary key of the predictions table is:

```text
experiment_id + customer_id
```

This allows the same customer to receive predictions from multiple experiments.

## Running the Project

### 1. Run the Python notebook

Open and execute:

```text
notebooks/Generate_data_and_ml_model.ipynb
```

This creates the synthetic dataset, trains the model, calculates metrics, and exports the analytical artifacts.

### 2. Create the MySQL schema

Open MySQL Workbench and run:

```text
sql/generate_data_base.sql
```

### 3. Import the CSV files

Import the files in this order:

1. `synthetic_customer_churn.csv` into `customers`;
2. insert `EXP_001` into `experiments`;
3. `logistic_regression_predictions.csv` into `predictions`;
4. `reported_metrics.csv` into `reported_metrics`.

Expected record counts:

| Table              | Expected rows |
| ------------------ | ------------: |
| `customers`        |          5000 |
| `experiments`      |             1 |
| `predictions`      |          1000 |
| `reported_metrics` |             7 |

### 4. Run the SQL analysis

Execute:

```text
sql/mysql_analysis.sql
```

The script performs:

* table-count validation;
* duplicated-prediction checks;
* invalid-probability checks;
* invalid-label checks;
* foreign-key consistency checks;
* source-label consistency validation;
* confusion-matrix recalculation;
* classification-metric recalculation;
* log-loss recalculation;
* error-type analysis;
* confident-error investigation;
* performance analysis by plan;
* performance analysis by region;
* classification-threshold analysis;
* estimated business-cost comparison.

## Threshold Analysis

The project evaluates several decision thresholds:

```text
0.20
0.30
0.40
0.50
0.60
0.70
0.80
```

The example business-cost assumptions are:

```text
False negative cost = 500
False positive cost = 30
```

These values are hypothetical and are used only to demonstrate cost-sensitive model evaluation.

## Technologies

* Python
* NumPy
* Pandas
* Matplotlib
* scikit-learn
* Joblib
* Jupyter Notebook
* Google Colab
* SQLite
* MySQL 8.0
* MySQL Workbench
* SQL

## Current Experiment

| Experiment | Model               | Version | Status    |
| ---------- | ------------------- | ------- | --------- |
| `EXP_001`  | Logistic Regression | `v1`    | Completed |

Future versions of the project may include:

* Logistic Regression hyperparameter tuning;
* Random Forest;
* Gradient Boosting;
* multiple model experiments;
* automated experiment ranking;
* drift analysis;
* calibration analysis;
* additional subgroup evaluations.

## Reproducibility

The project uses:

```python
RANDOM_SEED = 42
```

This ensures that the synthetic dataset, train/test split, and model workflow can be reproduced consistently.

