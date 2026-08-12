-- ============================================================
-- PROJECT: Netherlands 3PL Procurement Optimisation Model
-- Author:  Saquib Raza | IIT Mandi | Supply Chain Analytics
-- Purpose: Evaluate and select logistics providers based on
--          cost, reliability, and lead time across key EU corridors
-- Routes:  AMS→Frankfurt | Rotterdam→Paris | Eindhoven→Warsaw
-- Tools:   SQL (MySQL 8.0+ compatible) | Excel | Power BI
-- NOTE: This is the MySQL port of the original PostgreSQL file.
--       Logic and numbers are identical; only syntax changed.
-- ============================================================

CREATE DATABASE IF NOT EXISTS netherlands_3pl;
USE netherlands_3pl;

-- ============================================================
-- SECTION 1: SCHEMA CREATION
-- ============================================================

DROP TABLE IF EXISTS performance_history;
DROP TABLE IF EXISTS quotes;
DROP TABLE IF EXISTS shipments;
DROP TABLE IF EXISTS routes;
DROP TABLE IF EXISTS providers;

-- ----------------------------
-- TABLE 1: providers
-- ----------------------------
CREATE TABLE providers (
    provider_id     INT AUTO_INCREMENT PRIMARY KEY,
    provider_name   VARCHAR(100) NOT NULL,
    country_hq      VARCHAR(50),
    provider_type   VARCHAR(50),
    founded_year    INT,
    eu_presence     BOOLEAN DEFAULT TRUE,
    sla_threshold   DECIMAL(5,2),
    notes           TEXT
);

-- ----------------------------
-- TABLE 2: routes
-- ----------------------------
CREATE TABLE routes (
    route_id        INT AUTO_INCREMENT PRIMARY KEY,
    origin_city     VARCHAR(100) NOT NULL,
    origin_country  VARCHAR(50)  NOT NULL,
    dest_city       VARCHAR(100) NOT NULL,
    dest_country    VARCHAR(50)  NOT NULL,
    distance_km     INT,
    route_type      VARCHAR(50),
    avg_lead_days   DECIMAL(4,1)
);

-- ----------------------------
-- TABLE 3: quotes
-- ----------------------------
CREATE TABLE quotes (
    quote_id            INT AUTO_INCREMENT PRIMARY KEY,
    provider_id         INT,
    route_id            INT,
    weight_band_kg      VARCHAR(20),
    base_rate_eur_per_kg DECIMAL(8,4),
    fuel_surcharge_pct  DECIMAL(5,2),
    volume_discount_pct DECIMAL(5,2),
    min_shipment_kg     DECIMAL(8,2),
    effective_date      DATE,
    expiry_date         DATE,
    quote_source        VARCHAR(100),
    FOREIGN KEY (provider_id) REFERENCES providers(provider_id),
    FOREIGN KEY (route_id) REFERENCES routes(route_id)
);

-- ----------------------------
-- TABLE 4: shipments
-- ----------------------------
CREATE TABLE shipments (
    shipment_id         INT AUTO_INCREMENT PRIMARY KEY,
    provider_id         INT,
    route_id            INT,
    shipment_date       DATE NOT NULL,
    weight_kg           DECIMAL(10,2),
    volume_cbm          DECIMAL(8,3),
    commodity_type      VARCHAR(100),
    promised_delivery   DATE,
    actual_delivery     DATE,
    freight_cost_eur    DECIMAL(10,2),
    fuel_surcharge_eur  DECIMAL(8,2),
    total_cost_eur      DECIMAL(10,2),
    status              VARCHAR(30),
    delay_reason        VARCHAR(200),
    customer_complaint  BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (provider_id) REFERENCES providers(provider_id),
    FOREIGN KEY (route_id) REFERENCES routes(route_id)
);

-- ----------------------------
-- TABLE 5: performance_history
-- ----------------------------
CREATE TABLE performance_history (
    perf_id             INT AUTO_INCREMENT PRIMARY KEY,
    provider_id         INT,
    route_id            INT,
    month_year          DATE,
    total_shipments     INT,
    on_time_count       INT,
    delayed_count       INT,
    damaged_count       INT,
    avg_lead_time_days  DECIMAL(5,2),
    avg_cost_per_kg     DECIMAL(8,4),
    total_revenue_eur   DECIMAL(12,2),
    sla_breached        BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (provider_id) REFERENCES providers(provider_id),
    FOREIGN KEY (route_id) REFERENCES routes(route_id)
);

-- ============================================================
-- SECTION 2: SEED DATA
-- ============================================================

-- Providers
INSERT INTO providers (provider_name, country_hq, provider_type, founded_year, eu_presence, sla_threshold, notes) VALUES
('DHL Freight',       'Germany',     'Multimodal', 1969, TRUE, 92.00, 'Market leader; strong NL-DE corridor; premium pricing'),
('DB Schenker',       'Germany',     'Road',       1872, TRUE, 90.00, 'Rail+road strength; excellent NL-PL corridor'),
('Kuehne+Nagel',      'Switzerland', 'Multimodal', 1890, TRUE, 91.00, 'Strong sea freight; competitive on NL-FR corridor');

-- Routes
INSERT INTO routes (origin_city, origin_country, dest_city, dest_country, distance_km, route_type, avg_lead_days) VALUES
('Amsterdam',  'Netherlands', 'Frankfurt',  'Germany', 420,  'Road',       1.5),
('Rotterdam',  'Netherlands', 'Paris',      'France',  500,  'Road',       2.0),
('Eindhoven',  'Netherlands', 'Warsaw',     'Poland',  1450, 'Multimodal', 3.5);

-- Quotes — DHL Freight (provider_id = 1)
INSERT INTO quotes (provider_id, route_id, weight_band_kg, base_rate_eur_per_kg, fuel_surcharge_pct, volume_discount_pct, min_shipment_kg, effective_date, expiry_date, quote_source) VALUES
(1, 1, '0-500',   0.38, 18.00, 0.00, 50,  '2024-01-01', '2024-12-31', 'Freightos Benchmark'),
(1, 1, '500-2000',0.31, 18.00, 5.00, 500, '2024-01-01', '2024-12-31', 'Freightos Benchmark'),
(1, 1, '2000+',   0.26, 18.00, 10.00,2000,'2024-01-01', '2024-12-31', 'Direct negotiation'),
(1, 2, '0-500',   0.42, 18.00, 0.00, 50,  '2024-01-01', '2024-12-31', 'Freightos Benchmark'),
(1, 2, '500-2000',0.35, 18.00, 5.00, 500, '2024-01-01', '2024-12-31', 'Freightos Benchmark'),
(1, 2, '2000+',   0.29, 18.00, 10.00,2000,'2024-01-01', '2024-12-31', 'Direct negotiation'),
(1, 3, '0-500',   0.55, 18.00, 0.00, 50,  '2024-01-01', '2024-12-31', 'Freightos Benchmark'),
(1, 3, '500-2000',0.46, 18.00, 5.00, 500, '2024-01-01', '2024-12-31', 'Freightos Benchmark'),
(1, 3, '2000+',   0.39, 18.00, 10.00,2000,'2024-01-01', '2024-12-31', 'Direct negotiation');

-- Quotes — DB Schenker (provider_id = 2)
INSERT INTO quotes (provider_id, route_id, weight_band_kg, base_rate_eur_per_kg, fuel_surcharge_pct, volume_discount_pct, min_shipment_kg, effective_date, expiry_date, quote_source) VALUES
(2, 1, '0-500',   0.35, 16.50, 0.00, 50,  '2024-01-01', '2024-12-31', 'Freightos Benchmark'),
(2, 1, '500-2000',0.29, 16.50, 4.00, 500, '2024-01-01', '2024-12-31', 'Freightos Benchmark'),
(2, 1, '2000+',   0.24, 16.50, 8.00, 2000,'2024-01-01', '2024-12-31', 'Direct negotiation'),
(2, 2, '0-500',   0.40, 16.50, 0.00, 50,  '2024-01-01', '2024-12-31', 'Freightos Benchmark'),
(2, 2, '500-2000',0.33, 16.50, 4.00, 500, '2024-01-01', '2024-12-31', 'Freightos Benchmark'),
(2, 2, '2000+',   0.27, 16.50, 8.00, 2000,'2024-01-01', '2024-12-31', 'Direct negotiation'),
(2, 3, '0-500',   0.48, 16.50, 0.00, 50,  '2024-01-01', '2024-12-31', 'Freightos Benchmark'),
(2, 3, '500-2000',0.40, 16.50, 6.00, 500, '2024-01-01', '2024-12-31', 'Freightos Benchmark'),
(2, 3, '2000+',   0.33, 16.50, 12.00,2000,'2024-01-01', '2024-12-31', 'Direct negotiation');

-- Quotes — Kuehne+Nagel (provider_id = 3)
INSERT INTO quotes (provider_id, route_id, weight_band_kg, base_rate_eur_per_kg, fuel_surcharge_pct, volume_discount_pct, min_shipment_kg, effective_date, expiry_date, quote_source) VALUES
(3, 1, '0-500',   0.36, 17.00, 0.00, 50,  '2024-01-01', '2024-12-31', 'Freightos Benchmark'),
(3, 1, '500-2000',0.30, 17.00, 5.00, 500, '2024-01-01', '2024-12-31', 'Freightos Benchmark'),
(3, 1, '2000+',   0.25, 17.00, 9.00, 2000,'2024-01-01', '2024-12-31', 'Direct negotiation'),
(3, 2, '0-500',   0.39, 17.00, 0.00, 50,  '2024-01-01', '2024-12-31', 'Freightos Benchmark'),
(3, 2, '500-2000',0.32, 17.00, 5.00, 500, '2024-01-01', '2024-12-31', 'Freightos Benchmark'),
(3, 2, '2000+',   0.26, 17.00, 9.00, 2000,'2024-01-01', '2024-12-31', 'Direct negotiation'),
(3, 3, '0-500',   0.51, 17.00, 0.00, 50,  '2024-01-01', '2024-12-31', 'Freightos Benchmark'),
(3, 3, '500-2000',0.43, 17.00, 5.50, 500, '2024-01-01', '2024-12-31', 'Freightos Benchmark'),
(3, 3, '2000+',   0.36, 17.00, 11.00,2000,'2024-01-01', '2024-12-31', 'Direct negotiation');

-- Shipments
INSERT INTO shipments (provider_id, route_id, shipment_date, weight_kg, volume_cbm, commodity_type, promised_delivery, actual_delivery, freight_cost_eur, fuel_surcharge_eur, total_cost_eur, status, delay_reason, customer_complaint) VALUES
(1,1,'2024-01-08',320,2.1,'Electronics','2024-01-10','2024-01-10',121.60,21.89,143.49,'Delivered',NULL,FALSE),
(1,1,'2024-01-22',750,4.8,'Auto Parts','2024-01-24','2024-01-25',232.50,41.85,274.35,'Delayed','Traffic congestion',FALSE),
(1,1,'2024-02-05',1200,7.2,'Machinery','2024-02-07','2024-02-07',372.00,66.96,438.96,'Delivered',NULL,FALSE),
(1,1,'2024-02-19',85,0.6,'Pharmaceuticals','2024-02-21','2024-02-21',32.30,5.81,38.11,'Delivered',NULL,FALSE),
(1,1,'2024-03-12',2500,15.0,'Consumer Goods','2024-03-14','2024-03-15',650.00,117.00,767.00,'Delayed','Customs delay',TRUE),
(1,1,'2024-03-28',420,2.8,'Textiles','2024-03-30','2024-03-30',130.20,23.44,153.64,'Delivered',NULL,FALSE),
(1,1,'2024-04-10',980,6.1,'Chemical Products','2024-04-12','2024-04-12',303.80,54.68,358.48,'Delivered',NULL,FALSE),
(1,1,'2024-04-24',150,1.0,'Food Products','2024-04-26','2024-04-27',57.00,10.26,67.26,'Delayed','Driver shortage',FALSE),
(1,2,'2024-01-15',600,3.8,'Electronics','2024-01-17','2024-01-17',210.00,37.80,247.80,'Delivered',NULL,FALSE),
(1,2,'2024-02-08',1800,11.0,'Machinery','2024-02-11','2024-02-11',630.00,113.40,743.40,'Delivered',NULL,FALSE),
(1,2,'2024-03-05',250,1.6,'Pharmaceuticals','2024-03-07','2024-03-08',87.50,15.75,103.25,'Delayed','Customs inspection',FALSE),
(1,2,'2024-04-18',3200,20.0,'Consumer Goods','2024-04-21','2024-04-21',928.00,167.04,1095.04,'Delivered',NULL,FALSE),
(1,3,'2024-01-20',800,5.0,'Auto Parts','2024-01-24','2024-01-24',368.00,66.24,434.24,'Delivered',NULL,FALSE),
(1,3,'2024-02-14',2200,13.5,'Machinery','2024-02-18','2024-02-20',1012.00,182.16,1194.16,'Delayed','Border control',TRUE),
(1,3,'2024-03-25',400,2.5,'Textiles','2024-03-29','2024-03-29',184.00,33.12,217.12,'Delivered',NULL,FALSE),
(1,3,'2024-04-30',1100,7.0,'Electronics','2024-05-04','2024-05-04',506.00,91.08,597.08,'Delivered',NULL,FALSE),
(2,1,'2024-01-10',400,2.5,'Consumer Goods','2024-01-12','2024-01-12',116.00,19.14,135.14,'Delivered',NULL,FALSE),
(2,1,'2024-01-25',900,5.5,'Auto Parts','2024-01-27','2024-01-27',261.00,43.07,304.07,'Delivered',NULL,FALSE),
(2,1,'2024-02-12',180,1.2,'Pharmaceuticals','2024-02-14','2024-02-14',52.20,8.61,60.81,'Delivered',NULL,FALSE),
(2,1,'2024-02-28',2800,17.0,'Machinery','2024-03-02','2024-03-02',672.00,110.88,782.88,'Delivered',NULL,FALSE),
(2,1,'2024-03-15',650,4.1,'Electronics','2024-03-17','2024-03-18',188.50,31.10,219.60,'Delayed','Vehicle breakdown',FALSE),
(2,1,'2024-04-05',350,2.2,'Textiles','2024-04-07','2024-04-07',101.50,16.75,118.25,'Delivered',NULL,FALSE),
(2,1,'2024-04-20',1500,9.2,'Chemical Products','2024-04-22','2024-04-22',435.00,71.78,506.78,'Delivered',NULL,FALSE),
(2,1,'2024-05-03',75,0.5,'Food Products','2024-05-05','2024-05-05',26.25,4.33,30.58,'Delivered',NULL,FALSE),
(2,2,'2024-01-18',500,3.2,'Electronics','2024-01-21','2024-01-21',165.00,27.23,192.23,'Delivered',NULL,FALSE),
(2,2,'2024-02-22',2400,14.5,'Machinery','2024-02-26','2024-02-26',648.00,106.92,754.92,'Delivered',NULL,FALSE),
(2,2,'2024-03-10',300,1.9,'Pharmaceuticals','2024-03-13','2024-03-14',99.00,16.34,115.34,'Delayed','Driver illness',FALSE),
(2,2,'2024-04-25',1000,6.3,'Consumer Goods','2024-04-28','2024-04-28',330.00,54.45,384.45,'Delivered',NULL,FALSE),
(2,3,'2024-01-12',700,4.4,'Auto Parts','2024-01-16','2024-01-16',280.00,46.20,326.20,'Delivered',NULL,FALSE),
(2,3,'2024-02-05',2600,16.0,'Machinery','2024-02-10','2024-02-10',858.00,141.57,999.57,'Delivered',NULL,FALSE),
(2,3,'2024-03-18',450,2.8,'Textiles','2024-03-22','2024-03-22',180.00,29.70,209.70,'Delivered',NULL,FALSE),
(2,3,'2024-04-12',1300,8.0,'Electronics','2024-04-16','2024-04-17',520.00,85.80,605.80,'Delayed','Road closure',FALSE),
(2,3,'2024-05-08',3100,19.0,'Consumer Goods','2024-05-13','2024-05-13',1023.00,168.80,1191.80,'Delivered',NULL,FALSE),
(3,1,'2024-01-14',280,1.8,'Pharmaceuticals','2024-01-16','2024-01-16',100.80,17.14,117.94,'Delivered',NULL,FALSE),
(3,1,'2024-01-30',850,5.3,'Consumer Goods','2024-02-01','2024-02-01',255.00,43.35,298.35,'Delivered',NULL,FALSE),
(3,1,'2024-02-16',1600,9.8,'Machinery','2024-02-18','2024-02-19',480.00,81.60,561.60,'Delayed','Port congestion',FALSE),
(3,1,'2024-03-02',120,0.8,'Electronics','2024-03-04','2024-03-04',43.20,7.34,50.54,'Delivered',NULL,FALSE),
(3,1,'2024-03-22',2100,13.0,'Auto Parts','2024-03-25','2024-03-25',525.00,89.25,614.25,'Delivered',NULL,FALSE),
(3,1,'2024-04-08',550,3.5,'Textiles','2024-04-10','2024-04-10',165.00,28.05,193.05,'Delivered',NULL,FALSE),
(3,1,'2024-04-28',1900,11.8,'Chemical Products','2024-04-30','2024-04-30',475.00,80.75,555.75,'Delivered',NULL,FALSE),
(3,2,'2024-01-09',700,4.4,'Electronics','2024-01-11','2024-01-11',224.00,38.08,262.08,'Delivered',NULL,FALSE),
(3,2,'2024-02-03',2000,12.3,'Machinery','2024-02-07','2024-02-07',520.00,88.40,608.40,'Delivered',NULL,FALSE),
(3,2,'2024-03-14',380,2.4,'Pharmaceuticals','2024-03-16','2024-03-16',121.60,20.67,142.27,'Delivered',NULL,FALSE),
(3,2,'2024-04-02',1400,8.6,'Consumer Goods','2024-04-05','2024-04-06',364.00,61.88,425.88,'Delayed','Strike action',TRUE),
(3,2,'2024-04-22',4000,24.5,'Machinery','2024-04-26','2024-04-26',1040.00,176.80,1216.80,'Delivered',NULL,FALSE),
(3,3,'2024-01-16',950,5.9,'Auto Parts','2024-01-20','2024-01-20',408.50,69.45,477.95,'Delivered',NULL,FALSE),
(3,3,'2024-02-10',1700,10.5,'Machinery','2024-02-15','2024-02-15',731.00,124.27,855.27,'Delivered',NULL,FALSE),
(3,3,'2024-03-08',550,3.4,'Electronics','2024-03-12','2024-03-13',236.50,40.21,276.71,'Delayed','Customs delay',FALSE),
(3,3,'2024-04-14',2300,14.2,'Consumer Goods','2024-04-19','2024-04-19',828.00,140.76,968.76,'Delivered',NULL,FALSE),
(3,3,'2024-05-01',600,3.8,'Textiles','2024-05-05','2024-05-07',258.00,43.86,301.86,'Delayed','Road works',FALSE);

-- Performance history
INSERT INTO performance_history (provider_id, route_id, month_year, total_shipments, on_time_count, delayed_count, damaged_count, avg_lead_time_days, avg_cost_per_kg, total_revenue_eur, sla_breached) VALUES
(1,1,'2024-01-01',12,11,1,0,1.6,0.3220,2840.00,FALSE),
(1,1,'2024-02-01',14,13,1,0,1.5,0.3150,3420.00,FALSE),
(1,1,'2024-03-01',13,11,2,0,1.7,0.3280,3180.00,FALSE),
(1,1,'2024-04-01',15,13,2,0,1.6,0.3190,3650.00,FALSE),
(1,2,'2024-01-01',10,10,0,0,2.0,0.3620,2478.00,FALSE),
(1,2,'2024-02-01',11,11,0,0,1.9,0.3580,2940.00,FALSE),
(1,2,'2024-03-01',10,9,1,0,2.1,0.3650,2680.00,FALSE),
(1,2,'2024-04-01',12,12,0,0,2.0,0.3590,3210.00,FALSE),
(1,3,'2024-01-01',8,8,0,0,3.6,0.4180,1880.00,FALSE),
(1,3,'2024-02-01',9,7,2,0,3.9,0.4250,2340.00,FALSE),
(1,3,'2024-03-01',8,8,0,0,3.5,0.4140,1960.00,FALSE),
(1,3,'2024-04-01',10,10,0,0,3.4,0.4100,2480.00,FALSE),
(2,1,'2024-01-01',14,14,0,0,1.4,0.2960,3150.00,FALSE),
(2,1,'2024-02-01',15,15,0,0,1.3,0.2880,3820.00,FALSE),
(2,1,'2024-03-01',14,13,1,0,1.5,0.2940,3410.00,FALSE),
(2,1,'2024-04-01',16,16,0,0,1.4,0.2900,4020.00,FALSE),
(2,2,'2024-01-01',10,10,0,0,2.1,0.3340,2180.00,FALSE),
(2,2,'2024-02-01',11,11,0,0,2.0,0.3280,2760.00,FALSE),
(2,2,'2024-03-01',10,9,1,0,2.2,0.3390,2510.00,FALSE),
(2,2,'2024-04-01',12,12,0,0,2.0,0.3310,3050.00,FALSE),
(2,3,'2024-01-01',12,12,0,0,3.2,0.3840,2680.00,FALSE),
(2,3,'2024-02-01',13,13,0,0,3.1,0.3760,3210.00,FALSE),
(2,3,'2024-03-01',12,12,0,0,3.2,0.3800,2940.00,FALSE),
(2,3,'2024-04-01',14,13,1,0,3.3,0.3820,3580.00,FALSE),
(3,1,'2024-01-01',13,13,0,0,1.5,0.3080,2940.00,FALSE),
(3,1,'2024-02-01',14,13,1,0,1.6,0.3020,3480.00,FALSE),
(3,1,'2024-03-01',13,13,0,0,1.5,0.3050,3180.00,FALSE),
(3,1,'2024-04-01',15,15,0,0,1.4,0.2990,3760.00,FALSE),
(3,2,'2024-01-01',11,11,0,0,1.9,0.3360,2480.00,FALSE),
(3,2,'2024-02-01',12,12,0,0,1.8,0.3290,3080.00,FALSE),
(3,2,'2024-03-01',11,11,0,0,1.9,0.3330,2710.00,FALSE),
(3,2,'2024-04-01',13,12,1,0,2.0,0.3380,3420.00,FALSE),
(3,3,'2024-01-01',10,10,0,0,3.4,0.4010,2180.00,FALSE),
(3,3,'2024-02-01',11,11,0,0,3.3,0.3950,2680.00,FALSE),
(3,3,'2024-03-01',10,9,1,0,3.5,0.4020,2420.00,FALSE),
(3,3,'2024-04-01',12,12,0,0,3.3,0.3980,2950.00,FALSE);

-- ============================================================
-- SECTION 3: ANALYTICAL QUERIES
-- ============================================================

-- QUERY 1: Cost per kg per lane (effective rate after fuel surcharge)
SELECT
    p.provider_name,
    CONCAT(r.origin_city, ' → ', r.dest_city) AS lane,
    q.weight_band_kg,
    q.base_rate_eur_per_kg,
    q.fuel_surcharge_pct,
    ROUND(q.base_rate_eur_per_kg * (1 + q.fuel_surcharge_pct / 100), 4) AS effective_rate_incl_fuel,
    ROUND(q.base_rate_eur_per_kg * (1 + q.fuel_surcharge_pct / 100) * (1 - q.volume_discount_pct / 100), 4) AS best_negotiated_rate,
    q.quote_source
FROM quotes q
JOIN providers p ON q.provider_id = p.provider_id
JOIN routes    r ON q.route_id    = r.route_id
ORDER BY lane, q.weight_band_kg, effective_rate_incl_fuel;


-- QUERY 2: On-time delivery % per provider per route
SELECT
    p.provider_name,
    CONCAT(r.origin_city, ' → ', r.dest_city) AS lane,
    COUNT(s.shipment_id)                                              AS total_shipments,
    SUM(CASE WHEN s.status = 'Delivered' THEN 1 ELSE 0 END)          AS on_time,
    SUM(CASE WHEN s.status = 'Delayed'   THEN 1 ELSE 0 END)          AS delayed_count,
    ROUND(
        SUM(CASE WHEN s.status = 'Delivered' THEN 1 ELSE 0 END) * 100.0
        / NULLIF(COUNT(s.shipment_id), 0), 2
    )                                                                 AS on_time_pct,
    p.sla_threshold,
    CASE
        WHEN ROUND(SUM(CASE WHEN s.status = 'Delivered' THEN 1 ELSE 0 END) * 100.0
             / NULLIF(COUNT(s.shipment_id), 0), 2) >= p.sla_threshold
        THEN '✅ SLA Met'
        ELSE '🚨 SLA Breached'
    END AS sla_status
FROM shipments s
JOIN providers p ON s.provider_id = p.provider_id
JOIN routes    r ON s.route_id    = r.route_id
GROUP BY p.provider_name, lane, p.sla_threshold
ORDER BY lane, on_time_pct DESC;


-- QUERY 3: Quote variance analysis
SELECT
    CONCAT(r.origin_city, ' → ', r.dest_city) AS lane,
    q.weight_band_kg,
    ROUND(MIN(q.base_rate_eur_per_kg), 4)  AS cheapest_rate,
    ROUND(MAX(q.base_rate_eur_per_kg), 4)  AS priciest_rate,
    ROUND(AVG(q.base_rate_eur_per_kg), 4)  AS avg_rate,
    ROUND(MAX(q.base_rate_eur_per_kg) - MIN(q.base_rate_eur_per_kg), 4) AS rate_spread,
    ROUND((MAX(q.base_rate_eur_per_kg) - MIN(q.base_rate_eur_per_kg))
          / NULLIF(MIN(q.base_rate_eur_per_kg), 0) * 100, 2) AS spread_pct,
    GROUP_CONCAT(CONCAT(p.provider_name, ': €', q.base_rate_eur_per_kg) ORDER BY q.base_rate_eur_per_kg SEPARATOR ' | ') AS provider_rates
FROM quotes q
JOIN routes    r ON q.route_id    = r.route_id
JOIN providers p ON q.provider_id = p.provider_id
GROUP BY lane, q.weight_band_kg
ORDER BY lane, q.weight_band_kg;


-- QUERY 4: Volume discount threshold modelling
WITH scenarios AS (
    SELECT 500  AS scenario_kg, '500kg scenario'  AS scenario_label
    UNION ALL
    SELECT 2000 AS scenario_kg, '2000kg scenario' AS scenario_label
)
SELECT
    sc.scenario_label,
    p.provider_name,
    CONCAT(r.origin_city, ' → ', r.dest_city) AS lane,
    q.weight_band_kg,
    q.base_rate_eur_per_kg,
    q.fuel_surcharge_pct,
    q.volume_discount_pct,
    ROUND(sc.scenario_kg * q.base_rate_eur_per_kg
          * (1 + q.fuel_surcharge_pct / 100)
          * (1 - q.volume_discount_pct / 100), 2) AS total_cost_eur,
    RANK() OVER (
        PARTITION BY sc.scenario_label, r.route_id
        ORDER BY sc.scenario_kg * q.base_rate_eur_per_kg
                 * (1 + q.fuel_surcharge_pct / 100)
                 * (1 - q.volume_discount_pct / 100)
    ) AS cost_rank
FROM quotes q
JOIN providers p  ON q.provider_id = p.provider_id
JOIN routes    r  ON q.route_id    = r.route_id
JOIN scenarios sc ON sc.scenario_kg >= q.min_shipment_kg
WHERE (sc.scenario_kg <= 2000 AND q.weight_band_kg = '500-2000')
   OR (sc.scenario_kg >  2000 AND q.weight_band_kg = '2000+')
ORDER BY sc.scenario_label, lane, total_cost_eur;


-- QUERY 5: Delay reason analysis (Pareto of root causes)
SELECT
    COALESCE(s.delay_reason, 'No Delay') AS delay_reason,
    COUNT(*)                              AS frequency,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct_of_total,
    SUM(s.total_cost_eur)                 AS total_freight_affected_eur,
    SUM(CASE WHEN s.customer_complaint = TRUE THEN 1 ELSE 0 END) AS complaints
FROM shipments s
GROUP BY delay_reason
ORDER BY frequency DESC;


-- QUERY 6: Monthly trend
SELECT
    DATE_FORMAT(ph.month_year, '%Y-%m') AS month,
    p.provider_name,
    CONCAT(r.origin_city, ' → ', r.dest_city) AS lane,
    ph.total_shipments,
    ph.on_time_count,
    ph.delayed_count,
    ROUND(ph.on_time_count * 100.0 / NULLIF(ph.total_shipments, 0), 2) AS on_time_pct,
    ph.avg_lead_time_days,
    ph.avg_cost_per_kg,
    ph.total_revenue_eur,
    ph.sla_breached
FROM performance_history ph
JOIN providers p ON ph.provider_id = p.provider_id
JOIN routes    r ON ph.route_id    = r.route_id
ORDER BY ph.month_year, p.provider_name, lane;


-- QUERY 7: Provider scorecard — weighted ranking (Cost 40%, Reliability 35%, Lead Time 25%)
WITH provider_metrics AS (
    SELECT
        p.provider_id,
        p.provider_name,
        ROUND(AVG(ph.avg_cost_per_kg), 4)                                           AS avg_cost_per_kg,
        ROUND(AVG(ph.on_time_count * 100.0 / NULLIF(ph.total_shipments, 0)), 2)    AS avg_on_time_pct,
        ROUND(AVG(ph.avg_lead_time_days), 2)                                        AS avg_lead_days
    FROM performance_history ph
    JOIN providers p ON ph.provider_id = p.provider_id
    GROUP BY p.provider_id, p.provider_name
),
normalised AS (
    SELECT
        provider_id,
        provider_name,
        avg_cost_per_kg,
        avg_on_time_pct,
        avg_lead_days,
        ROUND((1 - (avg_cost_per_kg - MIN(avg_cost_per_kg) OVER())
              / NULLIF(MAX(avg_cost_per_kg) OVER() - MIN(avg_cost_per_kg) OVER(), 0)) * 100, 2) AS cost_score,
        ROUND((avg_on_time_pct - MIN(avg_on_time_pct) OVER())
              / NULLIF(MAX(avg_on_time_pct) OVER() - MIN(avg_on_time_pct) OVER(), 0) * 100, 2)  AS reliability_score,
        ROUND((1 - (avg_lead_days - MIN(avg_lead_days) OVER())
              / NULLIF(MAX(avg_lead_days) OVER() - MIN(avg_lead_days) OVER(), 0)) * 100, 2)     AS lead_time_score
    FROM provider_metrics
)
SELECT
    provider_name,
    avg_cost_per_kg,
    avg_on_time_pct,
    avg_lead_days,
    cost_score,
    reliability_score,
    lead_time_score,
    ROUND(cost_score * 0.40 + reliability_score * 0.35 + lead_time_score * 0.25, 2) AS weighted_total_score,
    RANK() OVER (ORDER BY (cost_score * 0.40 + reliability_score * 0.35 + lead_time_score * 0.25) DESC) AS final_rank
FROM normalised
ORDER BY weighted_total_score DESC;


-- ============================================================
-- SECTION 4: STORED PROCEDURE — SLA BREACH ALERT
-- (MySQL uses PROCEDURE + CALL, not a plpgsql RETURNS TABLE function)
-- ============================================================

DROP PROCEDURE IF EXISTS check_sla_breach_alerts;

DELIMITER $$
CREATE PROCEDURE check_sla_breach_alerts()
BEGIN
    WITH rolling_otd AS (
        SELECT
            p.provider_name,
            CONCAT(r.origin_city, ' → ', r.dest_city) AS lane_label,
            p.sla_threshold,
            ROUND(
                AVG(ph.on_time_count * 100.0 / NULLIF(ph.total_shipments, 0))
                OVER (
                    PARTITION BY ph.provider_id, ph.route_id
                    ORDER BY ph.month_year
                    ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
                ), 2
            ) AS rolling_3m_pct,
            ph.month_year,
            ROW_NUMBER() OVER (PARTITION BY ph.provider_id, ph.route_id ORDER BY ph.month_year DESC) AS rn
        FROM performance_history ph
        JOIN providers p ON ph.provider_id = p.provider_id
        JOIN routes    r ON ph.route_id    = r.route_id
    )
    SELECT
        rolling_otd.provider_name,
        rolling_otd.lane_label,
        rolling_otd.rolling_3m_pct,
        rolling_otd.sla_threshold,
        CASE
            WHEN rolling_otd.rolling_3m_pct < rolling_otd.sla_threshold
            THEN '🚨 SLA BREACH — Immediate Review Required'
            WHEN rolling_otd.rolling_3m_pct < rolling_otd.sla_threshold + 3
            THEN '⚠️  AT RISK — Monitor Closely'
            ELSE '✅ Performing Within SLA'
        END AS breach_status,
        CASE
            WHEN rolling_otd.rolling_3m_pct < rolling_otd.sla_threshold
            THEN 'Escalate to account manager. Issue formal performance notice. Consider partial lane reallocation.'
            WHEN rolling_otd.rolling_3m_pct < rolling_otd.sla_threshold + 3
            THEN 'Schedule monthly review. Request improvement plan within 30 days.'
            ELSE 'Continue monitoring. Review at next quarterly business review.'
        END AS recommended_action
    FROM rolling_otd
    WHERE rolling_otd.rn = 1
    ORDER BY rolling_otd.rolling_3m_pct ASC;
END$$
DELIMITER ;

CALL check_sla_breach_alerts();


-- ============================================================
-- SECTION 5: VIEWS FOR POWER BI CONNECTIVITY
-- ============================================================

CREATE OR REPLACE VIEW vw_provider_scorecard AS
SELECT
    p.provider_name,
    CONCAT(r.origin_city, ' → ', r.dest_city) AS lane,
    ROUND(AVG(ph.avg_cost_per_kg), 4)     AS avg_cost_per_kg,
    ROUND(AVG(ph.on_time_count * 100.0 / NULLIF(ph.total_shipments, 0)), 2) AS avg_on_time_pct,
    ROUND(AVG(ph.avg_lead_time_days), 2)  AS avg_lead_time_days,
    SUM(ph.total_shipments)               AS total_shipments_ytd,
    SUM(ph.total_revenue_eur)             AS total_spend_eur,
    SUM(CAST(ph.sla_breached AS SIGNED))  AS sla_breach_months
FROM performance_history ph
JOIN providers p ON ph.provider_id = p.provider_id
JOIN routes    r ON ph.route_id    = r.route_id
GROUP BY p.provider_name, lane;

CREATE OR REPLACE VIEW vw_monthly_trend AS
SELECT
    DATE_FORMAT(ph.month_year, '%Y-%m')  AS month,
    ph.month_year,
    p.provider_name,
    CONCAT(r.origin_city, ' → ', r.dest_city) AS lane,
    ph.on_time_count * 100.0 / NULLIF(ph.total_shipments, 0) AS on_time_pct,
    ph.avg_cost_per_kg,
    ph.avg_lead_time_days,
    ph.total_revenue_eur
FROM performance_history ph
JOIN providers p ON ph.provider_id = p.provider_id
JOIN routes    r ON ph.route_id    = r.route_id;

CREATE OR REPLACE VIEW vw_shipment_detail AS
SELECT
    s.shipment_id,
    s.shipment_date,
    p.provider_name,
    CONCAT(r.origin_city, ' → ', r.dest_city) AS lane,
    s.weight_kg,
    s.commodity_type,
    s.promised_delivery,
    s.actual_delivery,
    DATEDIFF(s.actual_delivery, s.promised_delivery) AS delay_days,
    s.total_cost_eur,
    ROUND(s.total_cost_eur / NULLIF(s.weight_kg, 0), 4) AS actual_cost_per_kg,
    s.status,
    s.delay_reason,
    s.customer_complaint
FROM shipments s
JOIN providers p ON s.provider_id = p.provider_id
JOIN routes    r ON s.route_id    = r.route_id;

-- ============================================================
-- END OF FILE
-- To use: Run in MySQL Workbench (or `mysql -u root -p < this_file.sql`)
-- Export views to CSV → import into Power BI
-- ============================================================
