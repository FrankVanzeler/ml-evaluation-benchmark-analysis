USE ml_evaluation;

-- 1. TABLE RECORD COUNTS
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

-- 2. EXPERIMENT INFORMATION

SELECT *
FROM experiments
ORDER BY experiment_id;

-- 3. REPORTED METRICS


SELECT
    experiment_id,
    metric_name,
    metric_value
FROM reported_metrics
ORDER BY
    experiment_id,
    metric_name;



-- 4. DUPLICATED PREDICTIONS
-- Expected result: zero rows

SELECT
    experiment_id,
    customer_id,
    COUNT(*) AS prediction_count
FROM predictions
GROUP BY
    experiment_id,
    customer_id
HAVING COUNT(*) > 1;



-- 5. INVALID PROBABILITIES
-- Expected result: zero rows

SELECT *
FROM predictions
WHERE churn_probability IS NULL
   OR churn_probability < 0
   OR churn_probability > 1;



-- 6. INVALID LABELS
-- Expected result: zero rows


SELECT *
FROM predictions
WHERE y_true IS NULL
   OR y_pred IS NULL
   OR y_true NOT IN (0, 1)
   OR y_pred NOT IN (0, 1);



-- 7. PREDICTIONS WITHOUT A CUSTOMER
-- Expected result: zero rows


SELECT
    p.experiment_id,
    p.customer_id
FROM predictions AS p

LEFT JOIN customers AS c
    ON p.customer_id = c.customer_id

WHERE c.customer_id IS NULL;



-- 8. LABEL CONSISTENCY
-- y_true must match customers.churn
-- Expected result: zero rows


SELECT
    p.experiment_id,
    p.customer_id,
    p.y_true,
    c.churn
FROM predictions AS p

INNER JOIN customers AS c
    ON p.customer_id = c.customer_id

WHERE p.y_true <> c.churn;



-- 9. CONFUSION MATRIX


SELECT
    experiment_id,

    SUM(
        CASE
            WHEN y_true = 1 AND y_pred = 1
            THEN 1
            ELSE 0
        END
    ) AS true_positive,

    SUM(
        CASE
            WHEN y_true = 0 AND y_pred = 0
            THEN 1
            ELSE 0
        END
    ) AS true_negative,

    SUM(
        CASE
            WHEN y_true = 0 AND y_pred = 1
            THEN 1
            ELSE 0
        END
    ) AS false_positive,

    SUM(
        CASE
            WHEN y_true = 1 AND y_pred = 0
            THEN 1
            ELSE 0
        END
    ) AS false_negative

FROM predictions
GROUP BY experiment_id;



-- 10. RECOMPUTED CLASSIFICATION METRICS

WITH confusion AS (
    SELECT
        experiment_id,

        SUM(
            CASE
                WHEN y_true = 1 AND y_pred = 1
                THEN 1
                ELSE 0
            END
        ) AS tp,

        SUM(
            CASE
                WHEN y_true = 0 AND y_pred = 0
                THEN 1
                ELSE 0
            END
        ) AS tn,

        SUM(
            CASE
                WHEN y_true = 0 AND y_pred = 1
                THEN 1
                ELSE 0
            END
        ) AS fp,

        SUM(
            CASE
                WHEN y_true = 1 AND y_pred = 0
                THEN 1
                ELSE 0
            END
        ) AS fn

    FROM predictions
    GROUP BY experiment_id
),

base_metrics AS (
    SELECT
        experiment_id,
        tp,
        tn,
        fp,
        fn,

        (tp + tn) * 1.0
            / NULLIF(tp + tn + fp + fn, 0)
            AS accuracy,

        tp * 1.0
            / NULLIF(tp + fp, 0)
            AS precision_value,

        tp * 1.0
            / NULLIF(tp + fn, 0)
            AS recall_value,

        tn * 1.0
            / NULLIF(tn + fp, 0)
            AS specificity

    FROM confusion
)

SELECT
    experiment_id,
    tp,
    tn,
    fp,
    fn,
    accuracy,
    precision_value AS precision_score,
    recall_value AS recall_score,
    specificity,

    2.0 * precision_value * recall_value
        / NULLIF(
            precision_value + recall_value,
            0
        ) AS f1_score

FROM base_metrics
ORDER BY experiment_id;



-- 11. LOG LOSS


SELECT
    experiment_id,

    -AVG(
        y_true
        * LN(
            GREATEST(
                LEAST(
                    churn_probability,
                    0.999999999999
                ),
                0.000000000001
            )
        )
        +
        (1 - y_true)
        * LN(
            1 -
            GREATEST(
                LEAST(
                    churn_probability,
                    0.999999999999
                ),
                0.000000000001
            )
        )
    ) AS recomputed_log_loss

FROM predictions
GROUP BY experiment_id;



-- 12. ERROR-TYPE DISTRIBUTION
-- Organize the predictions count in the experiment 

SELECT
    experiment_id,
    error_type,
    COUNT(*) AS prediction_count,
    ROUND(
        COUNT(*) * 100.0
        / SUM(COUNT(*)) OVER (
            PARTITION BY experiment_id
        ),
        2
    ) AS percentage

FROM predictions
GROUP BY
    experiment_id,
    error_type

ORDER BY
    experiment_id,
    prediction_count DESC;



-- 13. MOST CONFIDENT INCORRECT PREDICTIONS

SELECT
    p.experiment_id,
    p.customer_id,
    p.y_true,
    p.y_pred,
    p.churn_probability,
    p.error_type,

    CASE
        WHEN p.y_pred = 1
        THEN p.churn_probability
        ELSE 1 - p.churn_probability
    END AS prediction_confidence,

    c.age,
    c.region,
    c.plan,
    c.monthly_fee,
    c.months_active,
    c.usage_hours,
    c.support_tickets,
    c.failed_payments

FROM predictions AS p

INNER JOIN customers AS c
    ON p.customer_id = c.customer_id

WHERE p.y_true <> p.y_pred

ORDER BY prediction_confidence DESC

LIMIT 20;



-- 14. PERFORMANCE BY SUBSCRIPTION PLAN

WITH plan_confusion AS (
    SELECT
        p.experiment_id,
        c.plan,
        COUNT(*) AS sample_count,

        SUM(
            CASE
                WHEN p.y_true = 1
                 AND p.y_pred = 1
                THEN 1
                ELSE 0
            END
        ) AS tp,

        SUM(
            CASE
                WHEN p.y_true = 0
                 AND p.y_pred = 0
                THEN 1
                ELSE 0
            END
        ) AS tn,

        SUM(
            CASE
                WHEN p.y_true = 0
                 AND p.y_pred = 1
                THEN 1
                ELSE 0
            END
        ) AS fp,

        SUM(
            CASE
                WHEN p.y_true = 1
                 AND p.y_pred = 0
                THEN 1
                ELSE 0
            END
        ) AS fn

    FROM predictions AS p

    INNER JOIN customers AS c
        ON p.customer_id = c.customer_id

    GROUP BY
        p.experiment_id,
        c.plan
),

plan_metrics AS (
    SELECT
        experiment_id,
        plan,
        sample_count,
        tp,
        tn,
        fp,
        fn,

        (tp + tn) * 1.0
            / NULLIF(sample_count, 0)
            AS accuracy,

        tp * 1.0
            / NULLIF(tp + fp, 0)
            AS precision_value,

        tp * 1.0
            / NULLIF(tp + fn, 0)
            AS recall_value

    FROM plan_confusion
)

SELECT
    experiment_id,
    plan,
    sample_count,
    tp,
    tn,
    fp,
    fn,
    accuracy,
    precision_value AS precision_score,
    recall_value AS recall_score,

    2.0 * precision_value * recall_value
        / NULLIF(
            precision_value + recall_value,
            0
        ) AS f1_score

FROM plan_metrics

ORDER BY
    experiment_id,
    f1_score ASC;


-- 15. PERFORMANCE BY REGION

SELECT
    p.experiment_id,
    c.region,

    COUNT(*) AS sample_count,

    AVG(
        CASE
            WHEN p.y_true = p.y_pred
            THEN 1.0
            ELSE 0.0
        END
    ) AS accuracy,

    SUM(
        CASE
            WHEN p.y_true = 1
             AND p.y_pred = 0
            THEN 1
            ELSE 0
        END
    ) AS false_negatives,

    SUM(
        CASE
            WHEN p.y_true = 0
             AND p.y_pred = 1
            THEN 1
            ELSE 0
        END
    ) AS false_positives

FROM predictions AS p

INNER JOIN customers AS c
    ON p.customer_id = c.customer_id

GROUP BY
    p.experiment_id,
    c.region

ORDER BY
    p.experiment_id,
    accuracy ASC;

-- 16. THRESHOLD ANALYSIS

WITH thresholds AS (
    SELECT 0.20 AS threshold_value
    UNION ALL SELECT 0.30
    UNION ALL SELECT 0.40
    UNION ALL SELECT 0.50
    UNION ALL SELECT 0.60
    UNION ALL SELECT 0.70
    UNION ALL SELECT 0.80
),

threshold_predictions AS (
    SELECT
        p.experiment_id,
        t.threshold_value,
        p.y_true,

        CASE
            WHEN p.churn_probability
                 >= t.threshold_value
            THEN 1
            ELSE 0
        END AS threshold_prediction

    FROM predictions AS p

    CROSS JOIN thresholds AS t
),

threshold_confusion AS (
    SELECT
        experiment_id,
        threshold_value,

        SUM(
            CASE
                WHEN y_true = 1
                 AND threshold_prediction = 1
                THEN 1
                ELSE 0
            END
        ) AS tp,

        SUM(
            CASE
                WHEN y_true = 0
                 AND threshold_prediction = 0
                THEN 1
                ELSE 0
            END
        ) AS tn,

        SUM(
            CASE
                WHEN y_true = 0
                 AND threshold_prediction = 1
                THEN 1
                ELSE 0
            END
        ) AS fp,

        SUM(
            CASE
                WHEN y_true = 1
                 AND threshold_prediction = 0
                THEN 1
                ELSE 0
            END
        ) AS fn

    FROM threshold_predictions

    GROUP BY
        experiment_id,
        threshold_value
)

SELECT
    experiment_id,
    threshold_value,
    tp,
    tn,
    fp,
    fn,

    (tp + tn) * 1.0
        / NULLIF(tp + tn + fp + fn, 0)
        AS accuracy,

    tp * 1.0
        / NULLIF(tp + fp, 0)
        AS precision_score,

    tp * 1.0
        / NULLIF(tp + fn, 0)
        AS recall_score,

    500 * fn + 30 * fp
        AS estimated_business_cost

FROM threshold_confusion

ORDER BY
    experiment_id,
    threshold_value;

