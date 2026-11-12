-- Ski Resort Database (SQLite)
PRAGMA foreign_keys = ON;

-- ===== Staff =====
-- role PATROL = ski patrol (slope safety / rescue staff)
CREATE TABLE facility (
    facility_id   INTEGER PRIMARY KEY,
    name          TEXT NOT NULL,
    type          TEXT NOT NULL CHECK (type IN ('LODGING','RESTAURANT','LOCKER','PARKING','TICKET_OFFICE','RENTAL_SHOP')),
    location      TEXT,
    open_time     TEXT,            -- 'HH:MM'
    close_time    TEXT,
    capacity      INTEGER CHECK (capacity >= 0),
    status        TEXT NOT NULL DEFAULT 'OPEN' CHECK (status IN ('OPEN','CLOSED','MAINTENANCE'))
);

CREATE TABLE staff (
    staff_id      INTEGER PRIMARY KEY,
    name          TEXT NOT NULL,
    role          TEXT NOT NULL CHECK (role IN ('ADMIN','TICKET','RENTAL','PATROL','FACILITY','INSTRUCTOR')),
    phone         TEXT NOT NULL,
    hire_date     TEXT NOT NULL,   -- 'YYYY-MM-DD'
    login_id      TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,   -- never store plain passwords
    facility_id   INTEGER REFERENCES facility(facility_id)   -- workplace, NULL = on slopes etc.
);

-- ===== Customers =====
CREATE TABLE membership_grade (
    grade_id      INTEGER PRIMARY KEY,
    name          TEXT NOT NULL UNIQUE,     -- BASIC / SILVER / GOLD
    discount_rate REAL NOT NULL CHECK (discount_rate BETWEEN 0 AND 1)
);

-- MEMBER: has login + grade. GUEST (non-member): no login, no grade.
-- Season pass ownership is NOT a column: it is looked up in season_pass.
CREATE TABLE customer (
    customer_id   INTEGER PRIMARY KEY,
    customer_type TEXT NOT NULL CHECK (customer_type IN ('MEMBER','GUEST')),
    name          TEXT NOT NULL,
    phone         TEXT NOT NULL,
    birth_date    TEXT,
    email         TEXT,
    login_id      TEXT UNIQUE,
    password_hash TEXT,
    grade_id      INTEGER REFERENCES membership_grade(grade_id),
    created_at    TEXT NOT NULL DEFAULT (datetime('now','localtime')),
    CHECK (
        (customer_type = 'MEMBER' AND login_id IS NOT NULL AND password_hash IS NOT NULL AND grade_id IS NOT NULL)
     OR (customer_type = 'GUEST'  AND login_id IS NULL     AND password_hash IS NULL     AND grade_id IS NULL)
    )
);

-- ===== Lift tickets (price varies by season + weekday/weekend) =====
CREATE TABLE season (
    season_id     INTEGER PRIMARY KEY,
    name          TEXT NOT NULL,                       -- e.g. '2026-27 Peak'
    season_type   TEXT NOT NULL CHECK (season_type IN ('PEAK','OFF_PEAK')),
    start_date    TEXT NOT NULL,
    end_date      TEXT NOT NULL,
    CHECK (start_date <= end_date)
);

CREATE TABLE ticket_type (
    ticket_type_id INTEGER PRIMARY KEY,
    name           TEXT NOT NULL UNIQUE,               -- MORNING / AFTERNOON / FULL_DAY / NIGHT
    start_time     TEXT NOT NULL,
    end_time       TEXT NOT NULL
);

-- shortcut: public holidays are not modelled, staff pick WEEKEND manually; add a holiday table if needed.
CREATE TABLE lift_price (
    season_id      INTEGER NOT NULL REFERENCES season(season_id),
    ticket_type_id INTEGER NOT NULL REFERENCES ticket_type(ticket_type_id),
    day_type       TEXT NOT NULL CHECK (day_type IN ('WEEKDAY','WEEKEND')),
    price          INTEGER NOT NULL CHECK (price >= 0),
    PRIMARY KEY (season_id, ticket_type_id, day_type)
);

-- Every ticket belongs to a customer (guests are customers too).
CREATE TABLE lift_ticket (
    ticket_id      INTEGER PRIMARY KEY,
    customer_id    INTEGER NOT NULL REFERENCES customer(customer_id),
    ticket_type_id INTEGER NOT NULL REFERENCES ticket_type(ticket_type_id),
    use_date       TEXT NOT NULL,
    price_paid     INTEGER NOT NULL CHECK (price_paid >= 0),  -- after member discount
    sold_by        INTEGER REFERENCES staff(staff_id),        -- NULL = bought online
    sold_at        TEXT NOT NULL DEFAULT (datetime('now','localtime'))
);

CREATE TABLE season_pass (
    pass_id        INTEGER PRIMARY KEY,
    customer_id    INTEGER NOT NULL REFERENCES customer(customer_id),
    season_year    TEXT NOT NULL,                      -- e.g. '2026-27'
    price_paid     INTEGER NOT NULL CHECK (price_paid >= 0),
    issued_at      TEXT NOT NULL DEFAULT (datetime('now','localtime')),
    UNIQUE (customer_id, season_year)
);

-- Season passes are for members only.
CREATE TRIGGER season_pass_member_only
BEFORE INSERT ON season_pass
WHEN (SELECT customer_type FROM customer WHERE customer_id = NEW.customer_id) <> 'MEMBER'
BEGIN
    SELECT RAISE(ABORT, 'season pass requires a MEMBER customer');
END;

-- ===== Equipment rental (quantity only, no serial numbers) =====
CREATE TABLE equipment (
    equipment_id   INTEGER PRIMARY KEY,
    category       TEXT NOT NULL CHECK (category IN ('SKI','BOARD','BOOTS','HELMET','CLOTHING','GOGGLES')),
    size           TEXT NOT NULL,
    daily_price    INTEGER NOT NULL CHECK (daily_price >= 0),
    total_qty      INTEGER NOT NULL CHECK (total_qty >= 0),
    UNIQUE (category, size)
);

CREATE TABLE rental (
    rental_id      INTEGER PRIMARY KEY,
    customer_id    INTEGER NOT NULL REFERENCES customer(customer_id),
    staff_id       INTEGER REFERENCES staff(staff_id),
    rented_at      TEXT NOT NULL DEFAULT (datetime('now','localtime')),
    returned_at    TEXT,                               -- NULL = not returned yet
    total_price    INTEGER NOT NULL CHECK (total_price >= 0)
);

CREATE TABLE rental_item (
    rental_id      INTEGER NOT NULL REFERENCES rental(rental_id) ON DELETE CASCADE,
    equipment_id   INTEGER NOT NULL REFERENCES equipment(equipment_id),
    qty            INTEGER NOT NULL CHECK (qty > 0),
    PRIMARY KEY (rental_id, equipment_id)
);

-- Stock = total - quantity currently out.
CREATE VIEW equipment_stock AS
SELECT e.equipment_id, e.category, e.size, e.total_qty,
       e.total_qty - COALESCE(SUM(CASE WHEN r.returned_at IS NULL THEN ri.qty END), 0) AS available_qty
FROM equipment e
LEFT JOIN rental_item ri ON ri.equipment_id = e.equipment_id
LEFT JOIN rental r       ON r.rental_id = ri.rental_id
GROUP BY e.equipment_id;

-- Block renting more than is in stock.
CREATE TRIGGER rental_item_stock_check
BEFORE INSERT ON rental_item
WHEN NEW.qty > (SELECT available_qty FROM equipment_stock WHERE equipment_id = NEW.equipment_id)
BEGIN
    SELECT RAISE(ABORT, 'not enough equipment in stock');
END;

-- ===== Privacy: masked customer view for general staff =====
-- SQLite has no user accounts/GRANT; the app must give non-admin staff only this view.
CREATE VIEW customer_masked AS
SELECT c.customer_id, c.customer_type,
       substr(c.name, 1, 1) || '**'                      AS name,
       substr(c.phone, 1, 4) || '****' || substr(c.phone, -4) AS phone,
       c.grade_id,
       EXISTS (SELECT 1 FROM season_pass p WHERE p.customer_id = c.customer_id) AS has_season_pass
FROM customer c;
