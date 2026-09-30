# Airbnb Accommodation Data Mart

![MySQL](https://img.shields.io/badge/MySQL-8.0%2B-4479A1?logo=mysql&logoColor=white)
![Database](https://img.shields.io/badge/Database-29%20tables-2E7D32)
![License](https://img.shields.io/badge/License-Academic%20Project-6A1B9A)

A normalized MySQL data mart for an Airbnb-style accommodation booking
platform. The project models the complete booking lifecycle, from user
registration and listing management through reservations, payments, host
payouts, fees, reviews, wishlists, and user messaging.

This repository was developed for **Build a Data Mart in SQL**.

## Contents

- [Project overview](#project-overview)
- [Key capabilities](#key-capabilities)
- [Data model](#data-model)
- [Getting started](#getting-started)
- [Repository structure](#repository-structure)
- [Validation queries](#validation-queries)
- [Project documentation](#project-documentation)

## Project overview

The data mart provides a relational foundation for an accommodation booking
platform. It is designed to keep operational data consistent and traceable
across the major business domains:

- Users can act as guests, hosts, or both.
- Hosts can manage listings, amenities, photos, availability, house rules,
  and cancellation policies.
- Guests can create bookings, make payments, save listings, and leave reviews.
- The platform records host payouts and separates guest and host service fees.
- Users can communicate through booking-linked messages and social connections.

The database uses a normalized relational design with explicit primary keys,
foreign keys, unique constraints, and business-rule checks.

## Key capabilities

- **29 tables** covering 25 core entities and 4 junction tables
- **37 foreign-key relationships** with documented delete/update behavior
- **19 `CHECK` constraints** for business rules such as valid ratings,
  non-negative monetary values, and valid booking dates
- **End-to-end sample data** with at least 20 rows per table
- **13 validation queries** covering joins, aggregation, many-to-many
  relationships, recursive relationships, and role analysis
- **Re-runnable setup** through a schema script that recreates the database

## Data model

The model includes the following primary domains:

| Domain | Examples |
| --- | --- |
| Identity and roles | `user`, `host`, `guest`, `socialaccount` |
| Listings | `listing`, `address`, `propertytype`, `roomtype`, `photo` |
| Listing configuration | `amenity`, `houserule`, `cancellationpolicy`, `availabilitycalendar` |
| Booking and finance | `booking`, `payment`, `paymentmethod`, `payout`, `payoutmethod`, `fee` |
| Reviews and communication | `review`, `reviewrating`, `reviewcategory`, `message` |
| Engagement | `wishlist`, `wishlistitem`, `userconnection` |

[View the Airbnb entity relationship diagram](Conception%20Phase/Airbnb_ER_Diagram.pdf)

## Getting started

### Prerequisites

- MySQL Community Server **8.0.16 or newer**
- MySQL Workbench **8.0 or newer** (recommended)

MySQL 8.0.16 or newer is required because older MySQL versions and MariaDB
versions may not enforce `CHECK` constraints.

### Option 1: Run the complete scenario

1. Open MySQL Workbench and connect to your MySQL server.
2. Open [`complete_scenario.sql`](Development%20Phase/complete_scenario.sql).
3. Execute the complete script.
4. Refresh the Schemas panel and confirm that `airbnb_datamart` contains 29
   tables.

### Option 2: Run the scripts separately

Run the scripts in this order:

1. [`schema.sql`](Development%20Phase/schema.sql) - creates the database and
   tables.
2. [`inserts.sql`](Development%20Phase/inserts.sql) - loads the sample data.
3. [`queries.sql`](Development%20Phase/queries.sql) - runs validation queries.

For detailed installation and troubleshooting instructions, see the
[installation manual](Installation_Manual.md).

## Repository structure

```text
.
├── Conception Phase/
│   ├── Airbnb_ER_Diagram.pdf
│   └── Gada-Kashish_102202657_DLBDSPBDM01_P1_S.pdf
├── Development Phase/
│   ├── complete_scenario.sql
│   ├── inserts.sql
│   ├── queries.sql
│   ├── schema.sql
│   └── Gada-Kashish_102202657_DLBDSPBDM01_P2_S.pdf
├── Finalisation Phase/
│   ├── Gada-Kashish_102202657_DLBDSPBDM01_Abstract.pdf
│   └── Gada-Kashish_102202657_DLBDSPBDM01_P3_S.pdf
├── README.md
└── Installation_Manual.md
```

## Validation queries

The validation script demonstrates:

1. End-to-end booking tracing
2. Guest and host fee breakdowns
3. Revenue by host
4. Bookings by country and city
5. Top guests by amount paid
6. Ternary review relationships
7. Average scores by review category
8. Average listing ratings
9. Most-wishlisted listings
10. Amenity popularity
11. Recursive user connections
12. Users with both host and guest roles
13. Payment status summaries

## Project documentation

- [Installation manual](Installation_Manual.md)
- [Phase 1: Conception](Conception%20Phase/Gada-Kashish_102202657_DLBDSPBDM01_P1_S.pdf)
- [Phase 2: Development](Development%20Phase/Gada-Kashish_102202657_DLBDSPBDM01_P2_S.pdf)
- [Phase 3: Finalisation](Finalisation%20Phase/Gada-Kashish_102202657_DLBDSPBDM01_P3_S.pdf)
- [Finalisation abstract](Finalisation%20Phase/Gada-Kashish_102202657_DLBDSPBDM01_Abstract.pdf)

## Author

**Kashish Paresh Gada**  
