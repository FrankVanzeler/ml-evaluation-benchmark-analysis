-- Create the data base if this not exists
CREATE DATABASE IF NOT EXISTS ml_evaluation;

USE ml_evaluation;

SHOW DATABASES LIKE 'ml_evaluation';

USE ml_evaluation;

SHOW TABLES;

USE ml_evaluation;
-- Check the number of row in the customer table
SELECT COUNT(*) AS customer_count
FROM customers;
-- checking the data in 10 row
SELECT *
FROM customers
LIMIT 10;


USE ml_evaluation;
-- This is to add the values from the csv that is correspondent to the experiments
INSERT INTO experiments (
    experiment_id,
    model_name,
    model_version,
    dataset_name,
    dataset_version,
    status
)
VALUES (
    'EXP_001',
    'logistic_regression',
    'v1',
    'synthetic_customer_churn',
    'v1',
    'completed'
);

SELECT *
FROM experiments;

SELECT COUNT(*) AS prediction_count
FROM predictions;

SELECT *
FROM predictions
LIMIT 10;

-- This query is to remove the data from the table to import again.
USE ml_evaluation;

START TRANSACTION;

DELETE FROM reported_metrics;
DELETE FROM predictions;
DELETE FROM experiments;
DELETE FROM customers;

COMMIT;

SELECT
    'customers' AS table_name,
    COUNT(*) AS record_count
FROM customers

UNION ALL

SELECT
    'experiments',
    COUNT(*)
FROM experiments

UNION ALL

SELECT
    'predictions',
    COUNT(*)
FROM predictions

UNION ALL

SELECT
    'reported_metrics',
    COUNT(*)
FROM reported_metrics;


USE ml_evaluation;

SET FOREIGN_KEY_CHECKS = 0;

SELECT @@FOREIGN_KEY_CHECKS;

TRUNCATE TABLE reported_metrics;
TRUNCATE TABLE predictions;
TRUNCATE TABLE experiments;
TRUNCATE TABLE customers;

SET FOREIGN_KEY_CHECKS = 1;

SELECT
    'customers' AS table_name,
    COUNT(*) AS record_count
FROM customers

UNION ALL

SELECT
    'experiments',
    COUNT(*)
FROM experiments

UNION ALL

SELECT
    'predictions',
    COUNT(*)
FROM predictions

UNION ALL

SELECT
    'reported_metrics',
    COUNT(*)
FROM reported_metrics;

-- check the table

USE ml_evaluation;

SHOW TABLES;