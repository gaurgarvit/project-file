-- 1. Classify Partners as Underpaid, Normal, or Overpaid

SELECT 
    bp_id,
    bp_name,
    branch_name,
    pl_percent,
    CASE 
        WHEN pl_percent < 0 THEN 'Underpaid'
        WHEN pl_percent >= 0 AND pl_percent < 25 THEN 'Normal'
        ELSE 'Overpaid'
    END AS payment_status
FROM 
    partner_profit;



-- 2. Analyze Profit/Loss Based on Utilization and Per Kg Rates

SELECT 
    bp_id,
    bp_name,
    branch_name,
    kg_delivered,
    per_kg_rate,
    profit,
    pl_percent,
    CASE 
        WHEN pl_percent < 0 THEN 'Underpaid'
        WHEN pl_percent >= 0 AND pl_percent < 25 THEN 'Normal'
        ELSE 'Overpaid'
    END AS payment_status
FROM 
    partner_profit
ORDER BY 
    pl_percent DESC;



-- 3. Analyze Profit/Loss Across Branches

-- 3.1. Calculate Utilization and Profit/Loss Percentages Across Branches
SELECT 
    branch_name,
    SUM(kg_delivered) AS total_kg_delivered,
    AVG(pl_percent) AS avg_pl_percent,
    SUM(CASE WHEN pl_percent < 0 THEN 1 ELSE 0 END) AS underpaid_count,
    SUM(CASE WHEN pl_percent >= 25 THEN 1 ELSE 0 END) AS overpaid_count
FROM 
    partner_profit
GROUP BY 
    branch_name
ORDER BY 
    avg_pl_percent DESC;

-- 3.2. Identify the Partner with the Highest Profit Percentage in Each Branch
SELECT 
    branch_name,
    bp_id,
    bp_name,
    MAX(pl_percent) AS max_profit_percent
FROM 
    partner_profit
GROUP BY 
    branch_name, bp_id, bp_name
ORDER BY 
    max_profit_percent DESC;

-- 3.3. Identify the Most Underpaid Partners Across All Branches
SELECT 
    branch_name,
    bp_id,
    bp_name,
    pl_percent
FROM 
    partner_profit
WHERE 
    pl_percent < 0
ORDER BY 
    pl_percent ASC;
