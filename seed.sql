-- Sample data (run after schema.sql)
PRAGMA foreign_keys = ON;

INSERT INTO facility (facility_id, name, type, location, open_time, close_time, capacity, status) VALUES
 (1, 'Main Ticket Office', 'TICKET_OFFICE', 'Base Lodge 1F', '08:00', '22:00', NULL, 'OPEN'),
 (2, 'Rental Shop A',      'RENTAL_SHOP',   'Base Lodge B1', '08:00', '22:00', NULL, 'OPEN'),
 (3, 'Snow Valley Condo',  'LODGING',       'East Zone',     '00:00', '23:59', 120,  'OPEN'),
 (4, 'Summit Restaurant',  'RESTAURANT',    'Peak Station',  '10:00', '17:00', 80,   'OPEN'),
 (5, 'Locker Room',        'LOCKER',        'Base Lodge 1F', '08:00', '23:00', 300,  'OPEN'),
 (6, 'Parking Lot P1',     'PARKING',       'Main Gate',     '00:00', '23:59', 500,  'MAINTENANCE');

-- password_hash values are fake placeholders for the assignment
INSERT INTO staff (staff_id, name, role, phone, hire_date, login_id, password_hash, facility_id) VALUES
 (1, 'Kim Minjun',  'ADMIN',    '010-1111-0001', '2020-03-02', 'admin01',  'sha256$a1b2c3', NULL),
 (2, 'Lee Seoyeon', 'TICKET',   '010-1111-0002', '2023-11-15', 'ticket01', 'sha256$d4e5f6', 1),
 (3, 'Park Jihoon', 'RENTAL',   '010-1111-0003', '2024-12-01', 'rental01', 'sha256$g7h8i9', 2),
 (4, 'Choi Yuna',   'PATROL',   '010-1111-0004', '2022-12-10', 'patrol01', 'sha256$j1k2l3', NULL),
 (5, 'Jung Hyunwoo','FACILITY', '010-1111-0005', '2021-06-20', 'facil01',  'sha256$m4n5o6', 3);

INSERT INTO membership_grade (grade_id, name, discount_rate) VALUES
 (1, 'BASIC',  0.00),
 (2, 'SILVER', 0.05),
 (3, 'GOLD',   0.10);

INSERT INTO customer (customer_id, customer_type, name, phone, birth_date, email, login_id, password_hash, grade_id) VALUES
 (1, 'MEMBER', 'Han Jiwoo',   '010-2222-0001', '1998-04-12', 'jiwoo@example.com', 'jiwoo98', 'sha256$p1q2r3', 3),
 (2, 'MEMBER', 'Yoon Seojun', '010-2222-0002', '2001-09-30', 'seojun@example.com','seojun01','sha256$s4t5u6', 2),
 (3, 'MEMBER', 'Kang Minseo', '010-2222-0003', '1995-01-05', 'minseo@example.com','minseo95','sha256$v7w8x9', 1),
 (4, 'GUEST',  'Oh Taeyang',  '010-2222-0004', NULL, NULL, NULL, NULL, NULL),
 (5, 'GUEST',  'Seo Haeun',   '010-2222-0005', '2010-07-22', NULL, NULL, NULL, NULL);

INSERT INTO season (season_id, name, season_type, start_date, end_date) VALUES
 (1, '2026-27 Early',  'OFF_PEAK', '2026-12-01', '2026-12-19'),
 (2, '2026-27 Peak',   'PEAK',     '2026-12-20', '2027-02-15'),
 (3, '2026-27 Late',   'OFF_PEAK', '2027-02-16', '2027-03-15');

INSERT INTO ticket_type (ticket_type_id, name, start_time, end_time) VALUES
 (1, 'MORNING',   '08:30', '12:30'),
 (2, 'AFTERNOON', '12:30', '16:30'),
 (3, 'FULL_DAY',  '08:30', '16:30'),
 (4, 'NIGHT',     '18:30', '22:30');

-- prices: (season, ticket type, day type) -> KRW
INSERT INTO lift_price (season_id, ticket_type_id, day_type, price) VALUES
 (1,1,'WEEKDAY',40000),(1,1,'WEEKEND',48000),(1,2,'WEEKDAY',40000),(1,2,'WEEKEND',48000),
 (1,3,'WEEKDAY',60000),(1,3,'WEEKEND',72000),(1,4,'WEEKDAY',35000),(1,4,'WEEKEND',42000),
 (2,1,'WEEKDAY',55000),(2,1,'WEEKEND',65000),(2,2,'WEEKDAY',55000),(2,2,'WEEKEND',65000),
 (2,3,'WEEKDAY',80000),(2,3,'WEEKEND',95000),(2,4,'WEEKDAY',45000),(2,4,'WEEKEND',55000),
 (3,1,'WEEKDAY',40000),(3,1,'WEEKEND',48000),(3,2,'WEEKDAY',40000),(3,2,'WEEKEND',48000),
 (3,3,'WEEKDAY',60000),(3,3,'WEEKEND',72000),(3,4,'WEEKDAY',35000),(3,4,'WEEKEND',42000);

-- price_paid = lift_price * (1 - member discount)
INSERT INTO lift_ticket (ticket_id, customer_id, ticket_type_id, use_date, price_paid, sold_by, sold_at) VALUES
 (1, 1, 3, '2026-12-26', 85500, NULL, '2026-12-20 21:10:00'),  -- GOLD, peak weekend full day 95000 -10%
 (2, 2, 4, '2026-12-23', 42750, 2,    '2026-12-23 18:05:00'),  -- SILVER, peak weekday night 45000 -5%
 (3, 4, 3, '2026-12-23', 80000, 2,    '2026-12-23 08:20:00'),  -- guest, peak weekday full day
 (4, 5, 1, '2026-12-05', 48000, 2,    '2026-12-05 08:10:00');  -- guest, early weekend morning

INSERT INTO season_pass (pass_id, customer_id, season_year, price_paid, issued_at) VALUES
 (1, 1, '2026-27', 450000, '2026-10-01 10:00:00'),
 (2, 3, '2026-27', 500000, '2026-10-15 14:30:00');

INSERT INTO equipment (equipment_id, category, size, daily_price, total_qty) VALUES
 (1, 'SKI',      '160cm', 30000, 20),
 (2, 'SKI',      '170cm', 30000, 20),
 (3, 'BOARD',    '150cm', 35000, 15),
 (4, 'BOOTS',    '260mm', 10000, 30),
 (5, 'BOOTS',    '270mm', 10000, 30),
 (6, 'HELMET',   'M',      5000, 40),
 (7, 'CLOTHING', 'L',     20000, 25),
 (8, 'GOGGLES',  'FREE',   5000, 30);

INSERT INTO rental (rental_id, customer_id, staff_id, rented_at, returned_at, total_price) VALUES
 (1, 4, 3, '2026-12-23 08:30:00', '2026-12-23 16:40:00', 45000),
 (2, 5, 3, '2026-12-05 08:20:00', NULL,                  70000),
 (3, 2, 3, '2026-12-23 18:10:00', NULL,                  40000);

INSERT INTO rental_item (rental_id, equipment_id, qty) VALUES
 (1, 2, 1), (1, 5, 1), (1, 6, 1),               -- ski + boots + helmet
 (2, 3, 1), (2, 4, 1), (2, 7, 1), (2, 8, 1),   -- board + boots + clothing + goggles
 (3, 1, 1), (3, 4, 1);                          -- ski + boots
