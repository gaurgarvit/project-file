-- 1. Calculating Partners' Payout (Revenue)
UPDATE payouts_table
SET 
    payout = kg_delivered * per_kg_rate;

-- Verifying the updated payouts
SELECT 
    bp_id,
    bp_name,
    branch_name,
    kg_delivered,
    per_kg_rate,
    payout AS revenue
FROM 
    payouts_table;



-- 2.1 Calculating Fuel Cost
SELECT 
    bp.bp_id,
    bp.bp_name,
    vd.vehicle_type,
    vd.vehicle_mileage,
    1600 / vd.vehicle_mileage * 72 AS fuel_cost
FROM 
    business_partners bp
JOIN 
    vehicle_details vd ON bp.vehicle_type_id = vd.vehicle_type_id;



-- 2.2 Calculating Maintenance Cost
SELECT 
    bp.bp_id,
    bp.bp_name,
    1600 * 0.3 AS tyre_cost,
    1600 * 1 AS service_charge,
    1600 * 0.3 + 1600 * 1 + m.driver_expenses AS maintenance_cost
FROM 
    business_partners bp
JOIN 
    maintenance m ON bp.vehicle_type_id = m.vehicle_type_id;



-- 2.3.1 Calculate Principal Amount
SELECT 
    bp.bp_id,
    bp.bp_name,
    vd.ex_showroom_price + vd.insurance_rto AS on_road_price,
    (vd.ex_showroom_price + vd.insurance_rto) * 0.8 AS principal_amount
FROM 
    business_partners bp
JOIN 
    vehicle_details vd ON bp.vehicle_type_id = vd.vehicle_type_id
WHERE 
    bp.ownership_type LIKE 'EMI%';

-- 2.3.2 Calculate EMI Payments using PMT function
SELECT 
    bp.bp_id,
    bp.bp_name,
    (vd.ex_showroom_price + vd.insurance_rto) * 0.8 AS principal_amount,
    1600 / vd.vehicle_mileage * 72 AS fuel_cost,
    -- EMI Calculation with 10.5% interest over the duration left
    ROUND(PMT(0.105/12, emi_duration * 12, -((vd.ex_showroom_price + vd.insurance_rto) * 0.8)), 2) AS emi_payment
FROM 
    business_partners bp
JOIN 
    vehicle_details vd ON bp.vehicle_type_id = vd.vehicle_type_id
JOIN
    (SELECT bp_id, YEAR(NOW()) - vehicle_purchase_year AS emi_duration 
     FROM business_partners
     WHERE ownership_type LIKE 'EMI%') AS emi_duration_data
ON bp.bp_id = emi_duration_data.bp_id;




-- 3. Final Total Cost Calculation
WITH Fuel_Cost AS (
    SELECT 
        bp.bp_id,
        1600 / vd.vehicle_mileage * 72 AS fuel_cost
    FROM 
        business_partners bp
    JOIN 
        vehicle_details vd ON bp.vehicle_type_id = vd.vehicle_type_id
),
Maintenance_Cost AS (
    SELECT 
        bp.bp_id,
        1600 * 0.3 + 1600 * 1 + m.driver_expenses AS maintenance_cost
    FROM 
        business_partners bp
    JOIN 
        maintenance m ON bp.vehicle_type_id = m.vehicle_type_id
),
EMI_Cost AS (
    SELECT 
        bp.bp_id,
        -- EMI Calculation with 10.5% interest over the duration left
        ROUND(PMT(0.105/12, emi_duration * 12, -((vd.ex_showroom_price + vd.insurance_rto) * 0.8)), 2) AS emi_payment
    FROM 
        business_partners bp
    JOIN 
        vehicle_details vd ON bp.vehicle_type_id = vd.vehicle_type_id
    JOIN
        (SELECT bp_id, YEAR(NOW()) - vehicle_purchase_year AS emi_duration 
         FROM business_partners
         WHERE ownership_type LIKE 'EMI%') AS emi_duration_data
    ON bp.bp_id = emi_duration_data.bp_id
),
Manpower_Cost AS (
    SELECT 
        bp.bp_id,
        13000 + CASE 
                    WHEN vd.vehicle_capacity_tons < 2 THEN 1 * 11900 
                    ELSE 2 * 11900
                END AS manpower_cost
    FROM 
        business_partners bp
    JOIN 
        vehicle_details vd ON bp.vehicle_type_id = vd.vehicle_type_id
)



-- Combine all costs to get total cost
SELECT 
    bp.bp_id,
    bp.bp_name,
    Fuel_Cost.fuel_cost,
    Maintenance_Cost.maintenance_cost,
    IFNULL(EMI_Cost.emi_payment, 0) AS emi_payment,
    Manpower_Cost.manpower_cost,
    IFNULL(EMI_Cost.emi_payment, 0) + Fuel_Cost.fuel_cost + Maintenance_Cost.maintenance_cost + Manpower_Cost.manpower_cost AS total_cost
FROM 
    business_partners bp
LEFT JOIN 
    Fuel_Cost ON bp.bp_id = Fuel_Cost.bp_id
LEFT JOIN 
    Maintenance_Cost ON bp.bp_id = Maintenance_Cost.bp_id
LEFT JOIN 
    EMI_Cost ON bp.bp_id = EMI_Cost.bp_id
LEFT JOIN 
    Manpower_Cost ON bp.bp_id = Manpower_Cost.bp_id;
