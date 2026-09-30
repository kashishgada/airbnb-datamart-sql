# Installation Manual
## Airbnb Accommodation Booking Platform - Data Mart in SQL
**Course:** DLBDSPBDM01 – Build a Data Mart in SQL  
**Student:** Kashish Paresh Gada | Matriculation No.: 102202657
**DBMS:** MySQL 8.0.16 or newer (InnoDB, CHECK constraint enforcement required)

---

## 1. Prerequisites

Before running any SQL files, ensure the following are installed on your machine:

| Software | Version | Download |
|---|---|---|
| MySQL Community Server | 8.0.16 or newer | https://dev.mysql.com/downloads/ |
| MySQL Workbench | 8.0 or newer | https://dev.mysql.com/downloads/workbench/ |

> **Important:** MySQL 8.0.16 is the minimum version required. CHECK constraints
> are silently ignored on older versions (including MySQL 5.7 and MariaDB), which
> means business rules such as `check_out > check_in` and `rating BETWEEN 1 AND 5`
> will not be enforced.

---

## 2. Files Included

| File | Description |
|---|---|
| [`schema.sql`](Development%20Phase/schema.sql) | Creates the `airbnb_datamart` database and all 29 tables with PK, FK, UNIQUE and CHECK constraints |
| [`inserts.sql`](Development%20Phase/inserts.sql) | Inserts at least 20 rows per table (29 tables, consistent end-to-end business scenarios) |
| [`queries.sql`](Development%20Phase/queries.sql) | 13 validation test-case queries covering the full business flow |
| [`complete_scenario.sql`](Development%20Phase/complete_scenario.sql) | All three files combined in one runnable script (schema + inserts + queries) |
| [`README.md`](README.md) | Project overview and quick-start guide |

---

## 3. Database Overview

| Property | Value |
|---|---|
| Database name | `airbnb_datamart` |
| Total tables | 29 (25 entities + 4 junction tables) |
| Engine | InnoDB |
| Character set | utf8mb4 |
| PRIMARY KEY constraints | 29 |
| FOREIGN KEY constraints | 37 |
| UNIQUE constraints | 16 |
| CHECK constraints | 19 |
| Rows per table | Minimum 20 |

---

## 4. Installation – Option A: Run the Combined File (Recommended)

This is the easiest method. One file runs everything top-to-bottom.

### Step 1 – Open MySQL Workbench
Launch MySQL Workbench and connect to your local server using your root credentials.

### Step 2 – Open the combined file
Go to **File → Open SQL Script** and select
`Development Phase/complete_scenario.sql`.

### Step 3 – Execute
Click the **lightning-bolt icon** (Execute entire script) or press **Ctrl + Shift + Enter**.

### Step 4 – Verify
In the left panel, click **Schemas → Refresh All**. You should see `airbnb_datamart` with 29 tables listed under **Tables**.

---

## 5. Installation – Option B: Run the Three Files Separately

Use this option if you want to inspect each stage individually.

### Step 1 – Run schema.sql
**File → Open SQL Script → `Development Phase/schema.sql`** → Execute
(Ctrl + Shift + Enter).

This will:
- Drop and recreate the `airbnb_datamart` database
- Create all 29 tables in parent-first dependency order
- Apply all PK, FK, UNIQUE and CHECK constraints

**Expected output:** 32 green checkmarks in the Output panel, no errors.

### Step 2 – Run inserts.sql
**File → Open SQL Script → `Development Phase/inserts.sql`** → Execute.

This will:
- Insert at least 20 rows into every table
- Populate consistent business scenarios (bookings wired to payments, payouts, fees, reviews and messages)

**Expected output:** All green checkmarks, no errors.

### Step 3 – Run queries.sql
**File → Open SQL Script → `Development Phase/queries.sql`** → Execute.

This runs 13 test-case queries. To run them one at a time (recommended for screenshots):
1. Highlight one query (from `SELECT` to its `;`)
2. Press **Ctrl + Enter** to execute only the selected statement
3. The result grid appears below

---

## 6. Test Cases Overview

| # | Query | Relationships exercised |
|---|---|---|
| 1 | End-to-end booking trace | 8-table join: guest, user, listing, host, payment, payout |
| 2 | Fee breakdown (12% guest + 3% host) | booking, fee |
| 3 | Revenue per host | host, listing, booking, payout |
| 4 | Bookings by country and city | booking, listing, address, city, country |
| 5 | Top guests by amount paid | payment, booking, guest, user |
| 6 | Ternary – review links booking + reviewer + reviewee | review, booking, user (×2) |
| 7 | Average score per review category | reviewrating, reviewcategory |
| 8 | Average rating per listing | review, booking, listing |
| 9 | Most-wishlisted listings (M:N) | wishlistitem, listing |
| 10 | Amenity popularity (M:N) | listingamenity, amenity |
| 11 | Recursive – user social connections | userconnection, user (×2) |
| 12 | Users who are both host and guest | user, host, guest |
| 13 | Payment status summary | payment |

---

## 7. Verifying the Installation

After running the files, run the following quick checks in Workbench:

```sql
-- Confirm database exists and table count
SELECT COUNT(*) AS table_count
FROM information_schema.tables
WHERE table_schema = 'airbnb_datamart';
-- Expected: 29

-- Confirm data loaded
SELECT 'booking' AS tbl, COUNT(*) AS row FROM airbnb_datamart.booking
UNION ALL
SELECT 'payment', COUNT(*) FROM airbnb_datamart.payment
UNION ALL
SELECT 'review',  COUNT(*) FROM airbnb_datamart.review;
-- Expected: 24 / 24 / 30

-- Confirm CHECK constraints are enforced (this INSERT must FAIL)
INSERT INTO airbnb_datamart.country VALUES ('X','Test','TL');
INSERT INTO airbnb_datamart.city VALUES ('C1','X','Town');
INSERT INTO airbnb_datamart.address VALUES ('A1','C1','Street','1000',200,0);
-- Expected error: Check constraint 'chk_address_lat' is violated.
```

---

## 8. Troubleshooting

| Problem | Cause | Fix |
|---|---|---|
| `CHECK constraint is violated` error when loading | You have rows that break a business rule | Check the inserted values match the constraint (e.g. ratings 1–5, check_out after check_in) |
| `Cannot add foreign key constraint` | Running inserts before schema | Always run `schema.sql` first |
| `ERROR 3823` on schema load | MySQL version below 8.0.16 | Upgrade to MySQL 8.0.16 or newer |
| Tables not visible after load | Schemas panel not refreshed | Right-click Schemas panel → Refresh All |
| `CHECK` constraints not enforced | Using MySQL 5.7 or MariaDB | Must use MySQL 8.0.16+ (InnoDB engine) |

---

## 9. Re-running from Scratch

The [`schema.sql`](Development%20Phase/schema.sql) file begins with:
```sql
DROP DATABASE IF EXISTS `airbnb_datamart`;
CREATE DATABASE `airbnb_datamart`;
```

This means the script is **re-runnable** — executing it again drops and rebuilds the entire database cleanly. You do not need to manually drop any tables before re-running.

---

*End of Installation Manual*