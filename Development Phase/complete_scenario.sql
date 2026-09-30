-- =====================================================================
-- Project : Build a Data Mart in SQL (DLBDSPBDM01)
-- File    : complete_scenario.sql
-- Purpose : Full end-to-end build in ONE runnable file.
--           Runs top-to-bottom: creates the database + 29 tables,
--           loads 20+ rows per table, then runs the 13 test queries.
-- DBMS    : MySQL 8.0.16 or newer (CHECK constraints enforced).
-- Usage   : Open in MySQL Workbench and click Execute (whole script).
--
-- This file simply combines schema.sql + inserts.sql + queries.sql
-- in the correct order. The three files are also submitted separately.
-- =====================================================================


-- =====================================================================
-- =====================================================================
-- ##  PART 1 of 3 : SCHEMA (Data Definition - 29 tables)
-- =====================================================================

-- =====================================================================
-- Project : Build a Data Mart in SQL (DLBDSPBDM01)
-- Use case: Airbnb Accommodation Booking Platform
-- File    : schema.sql  
-- Data Definition (DDL): 29 tables
-- DBMS    : MySQL 8.0.16 or newer (required so CHECK constraints
--           are ENFORCED, not just parsed)
-- Engine  : InnoDB (required for FOREIGN KEY enforcement)
--
-- Notes
--   * 25 entities + 4 junction tables (ListingAmenity, ReviewRating,
--     WishlistItem, UserConnection) = 29 tables, matching the ERD.
--   * Tables are created parent-first so foreign keys always resolve.
--   * Constraints are named with prefixes: pk_ (primary key),
--     fk_ (foreign key), uq_ (unique), chk_ (check).
-- =====================================================================

DROP DATABASE IF EXISTS `airbnb_datamart`;
CREATE DATABASE `airbnb_datamart`
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;
USE `airbnb_datamart`;


-- =========================================================
-- 01. COUNTRY  -- reference/lookup table of countries
-- =========================================================
CREATE TABLE `country` (
    `country_id`   VARCHAR(50)  NOT NULL,               -- PK, e.g. 'CTR001'
    `country_name` VARCHAR(100) NOT NULL,               -- full country name
    `country_code` CHAR(2)      NOT NULL,               -- ISO 3166-1 alpha-2

    CONSTRAINT `pk_country`      PRIMARY KEY (`country_id`),
    CONSTRAINT `uq_country_name` UNIQUE (`country_name`),
    CONSTRAINT `uq_country_code` UNIQUE (`country_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 02. CITY  -- each city belongs to exactly one country
-- =========================================================
CREATE TABLE `city` (
    `city_id`    VARCHAR(50)  NOT NULL,                 -- PK
    `country_id` VARCHAR(50)  NOT NULL,                 -- FK -> country
    `city_name`  VARCHAR(100) NOT NULL,

    CONSTRAINT `pk_city` PRIMARY KEY (`city_id`),
    CONSTRAINT `uq_city_country_name` UNIQUE (`country_id`, `city_name`),
    CONSTRAINT `fk_city_country`
        FOREIGN KEY (`country_id`) REFERENCES `country` (`country_id`)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 03. ADDRESS  -- physical address, linked to a city
-- =========================================================
CREATE TABLE `address` (
    `address_id` VARCHAR(50)   NOT NULL,                -- PK
    `city_id`    VARCHAR(50)   NOT NULL,                -- FK -> city
    `street`     VARCHAR(150)  NOT NULL,
    `zip_code`   VARCHAR(20)   NOT NULL,
    `latitude`   DECIMAL(9,6)  NULL,
    `longitude`  DECIMAL(9,6)  NULL,

    CONSTRAINT `pk_address` PRIMARY KEY (`address_id`),
    CONSTRAINT `fk_address_city`
        FOREIGN KEY (`city_id`) REFERENCES `city` (`city_id`)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT `chk_address_lat` CHECK (`latitude`  BETWEEN -90  AND 90),
    CONSTRAINT `chk_address_lng` CHECK (`longitude` BETWEEN -180 AND 180)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 04. USER  -- base account (specialised into Host / Guest)
-- =========================================================
CREATE TABLE `user` (
    `user_id`       VARCHAR(50)  NOT NULL,              -- PK
    `username`      VARCHAR(50)  NOT NULL,              -- unique login/display
    `email`         VARCHAR(100) NOT NULL,              -- unique contact e-mail
    `password_hash` VARCHAR(255) NOT NULL,
    `phone`         VARCHAR(20)  NULL,
    `profile_pic`   VARCHAR(255) NULL,
    `joined_date`   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `role`          ENUM('GUEST','HOST','BOTH') NOT NULL DEFAULT 'GUEST',

    CONSTRAINT `pk_user`          PRIMARY KEY (`user_id`),
    CONSTRAINT `uq_user_username` UNIQUE (`username`),
    CONSTRAINT `uq_user_email`    UNIQUE (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 05. HOST  -- 1:1 specialisation of user
-- =========================================================
CREATE TABLE `host` (
    `host_id`      VARCHAR(50) NOT NULL,                -- PK
    `user_id`      VARCHAR(50) NOT NULL,                -- FK -> user (unique = 1:1)
    `bio`          TEXT        NULL,
    `host_since`   DATE        NULL,
    `is_superhost` BOOLEAN     NOT NULL DEFAULT FALSE,

    CONSTRAINT `pk_host`      PRIMARY KEY (`host_id`),
    CONSTRAINT `uq_host_user` UNIQUE (`user_id`),
    CONSTRAINT `fk_host_user`
        FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 06. GUEST  -- 1:1 specialisation of user
-- =========================================================
CREATE TABLE `guest` (
    `guest_id`         VARCHAR(50) NOT NULL,            -- PK
    `user_id`          VARCHAR(50) NOT NULL,            -- FK -> user (unique = 1:1)
    `verified`         BOOLEAN     NOT NULL DEFAULT FALSE,
    `govt_id_verified` BOOLEAN     NOT NULL DEFAULT FALSE,

    CONSTRAINT `pk_guest`      PRIMARY KEY (`guest_id`),
    CONSTRAINT `uq_guest_user` UNIQUE (`user_id`),
    CONSTRAINT `fk_guest_user`
        FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 07. SOCIALACCOUNT  -- linked social profiles (Facebook, etc.)
-- =========================================================
CREATE TABLE `socialaccount` (
    `social_id` VARCHAR(50)  NOT NULL,                  -- PK
    `user_id`   VARCHAR(50)  NOT NULL,                  -- FK -> user
    `network`   VARCHAR(50)  NOT NULL,
    `handle`    VARCHAR(100) NULL,

    CONSTRAINT `pk_socialaccount` PRIMARY KEY (`social_id`),
    CONSTRAINT `uq_social_user_network` UNIQUE (`user_id`, `network`),
    CONSTRAINT `fk_social_user`
        FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 08. PAYMENTMETHOD  -- a guest's stored means of payment
-- =========================================================
CREATE TABLE `paymentmethod` (
    `pm_id`    VARCHAR(50) NOT NULL,                    -- PK
    `guest_id` VARCHAR(50) NOT NULL,                    -- FK -> guest
    `type`     VARCHAR(30) NOT NULL,                    -- e.g. credit card, PayPal
    `last4`    CHAR(4)     NULL,                       -- display only
    `expiry`   DATE        NULL,

    CONSTRAINT `pk_paymentmethod` PRIMARY KEY (`pm_id`),
    CONSTRAINT `fk_pm_guest`
        FOREIGN KEY (`guest_id`) REFERENCES `guest` (`guest_id`)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 09. PAYOUTMETHOD  -- a host's account for receiving payouts
-- =========================================================
CREATE TABLE `payoutmethod` (
    `po_id`   VARCHAR(50)  NOT NULL,                    -- PK
    `host_id` VARCHAR(50)  NOT NULL,                    -- FK -> host
    `po_type` VARCHAR(30)  NOT NULL,                    -- e.g. bank transfer
    `details` VARCHAR(255) NULL,                         -- masked account details

    CONSTRAINT `pk_payoutmethod` PRIMARY KEY (`po_id`),
    CONSTRAINT `fk_po_host`
        FOREIGN KEY (`host_id`) REFERENCES `host` (`host_id`)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 10. PROPERTYTYPE  -- lookup (apartment, house, loft, ...)
-- =========================================================
CREATE TABLE `propertytype` (
    `property_type_id` VARCHAR(50) NOT NULL,            -- PK
    `type_name`        VARCHAR(50) NOT NULL,

    CONSTRAINT `pk_propertytype`      PRIMARY KEY (`property_type_id`),
    CONSTRAINT `uq_property_type_name` UNIQUE (`type_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 11. ROOMTYPE  -- lookup (entire place, private, shared)
-- =========================================================
CREATE TABLE `roomtype` (
    `room_type_id`   VARCHAR(50) NOT NULL,                 -- PK
    `room_type_name` VARCHAR(50) NOT NULL,

    CONSTRAINT `pk_roomtype`       PRIMARY KEY (`room_type_id`),
    CONSTRAINT `uq_room_type_name` UNIQUE (`room_type_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 12. CANCELLATIONPOLICY  -- refund rules referenced by listings
-- =========================================================
CREATE TABLE `cancellationpolicy` (
    `policy_id`   VARCHAR(50) NOT NULL,                 -- PK
    `policy_name` VARCHAR(50) NOT NULL,                 -- Flexible / Moderate / Strict
    `refund_days` INT         NOT NULL DEFAULT 0,       -- days before check-in for refund
    `description` TEXT        NULL,

    CONSTRAINT `pk_cancellationpolicy` PRIMARY KEY (`policy_id`),
    CONSTRAINT `uq_policy_name`        UNIQUE (`policy_name`),
    CONSTRAINT `chk_policy_refunddays` CHECK (`refund_days` >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 13. AMENITY  -- catalogue (Wi-Fi, pool, kitchen, ...)
-- =========================================================
CREATE TABLE `amenity` (
    `amenity_id`   VARCHAR(50)  NOT NULL,               -- PK
    `amenity_name` VARCHAR(100) NOT NULL,
    `category`     VARCHAR(50)  NULL,                    -- e.g. Safety, Kitchen

    CONSTRAINT `pk_amenity`      PRIMARY KEY (`amenity_id`),
    CONSTRAINT `uq_amenity_name` UNIQUE (`amenity_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 14. REVIEWCATEGORY  -- lookup (cleanliness, communication, ...)
-- =========================================================
CREATE TABLE `reviewcategory` (
    `cat_id`   VARCHAR(50) NOT NULL,             -- PK
    `cat_name` VARCHAR(50) NOT NULL,

    CONSTRAINT `pk_reviewcategory` PRIMARY KEY (`cat_id`),
    CONSTRAINT `uq_cat_name`       UNIQUE (`cat_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 15. LISTING  -- accommodation offered by a host (central entity)
-- =========================================================
CREATE TABLE `listing` (
    `listing_id`       VARCHAR(50)   NOT NULL,          -- PK
    `host_id`          VARCHAR(50)   NOT NULL,          -- FK -> host
    `address_id`       VARCHAR(50)   NOT NULL,          -- FK -> address
    `property_type_id` VARCHAR(50)   NOT NULL,          -- FK -> propertytype
    `room_type_id`     VARCHAR(50)   NOT NULL,          -- FK -> roomtype
    `policy_id`        VARCHAR(50)   NOT NULL,          -- FK -> cancellationpolicy
    `title`            VARCHAR(150)  NOT NULL,
    `description`      TEXT          NULL,
    `price_per_night`  DECIMAL(10,2) NOT NULL,
    `max_guests`       INT           NOT NULL DEFAULT 1,
    `avg_rating`       DECIMAL(2,1)  NULL,                   -- aggregated from reviews
    `status`           ENUM('ACTIVE','INACTIVE') NOT NULL DEFAULT 'ACTIVE',

    CONSTRAINT `pk_listing` PRIMARY KEY (`listing_id`),
    CONSTRAINT `fk_listing_host`
        FOREIGN KEY (`host_id`) REFERENCES `host` (`host_id`)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT `fk_listing_address`
        FOREIGN KEY (`address_id`) REFERENCES `address` (`address_id`)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT `fk_listing_propertytype`
        FOREIGN KEY (`property_type_id`) REFERENCES `propertytype` (`property_type_id`)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT `fk_listing_roomtype`
        FOREIGN KEY (`room_type_id`) REFERENCES `roomtype` (`room_type_id`)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT `fk_listing_policy`
        FOREIGN KEY (`policy_id`) REFERENCES `cancellationpolicy` (`policy_id`)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT `chk_listing_price`  CHECK (`price_per_night` >= 0),
    CONSTRAINT `chk_listing_guests` CHECK (`max_guests` > 0),
    CONSTRAINT `chk_listing_rating` CHECK (`avg_rating` BETWEEN 0 AND 5)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 16. PHOTO  -- photographs attached to a listing
-- =========================================================
CREATE TABLE `photo` (
    `photo_id`   VARCHAR(50)  NOT NULL,                 -- PK
    `listing_id` VARCHAR(50)  NOT NULL,                 -- FK -> listing
    `url`        VARCHAR(255) NOT NULL,
    `caption`    VARCHAR(255) NULL,
    `is_cover`   BOOLEAN      NOT NULL DEFAULT FALSE,

    CONSTRAINT `pk_photo` PRIMARY KEY (`photo_id`),
    CONSTRAINT `fk_photo_listing`
        FOREIGN KEY (`listing_id`) REFERENCES `listing` (`listing_id`)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 17. HOUSERULE  -- house rules defined per listing
-- =========================================================
CREATE TABLE `houserule` (
    `rule_id`    VARCHAR(50) NOT NULL,                  -- PK
    `listing_id` VARCHAR(50) NOT NULL,                  -- FK -> listing
    `rule_text`  TEXT        NOT NULL,

    CONSTRAINT `pk_houserule` PRIMARY KEY (`rule_id`),
    CONSTRAINT `fk_houserule_listing`
        FOREIGN KEY (`listing_id`) REFERENCES `listing` (`listing_id`)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 18. AVAILABILITYCALENDAR  -- per-date availability / price
-- =========================================================
CREATE TABLE `availabilitycalendar` (
    `cal_id`       VARCHAR(50)   NOT NULL,              -- PK
    `listing_id`   VARCHAR(50)   NOT NULL,              -- FK -> listing
    `date`         DATE          NOT NULL,
    `is_available` BOOLEAN       NOT NULL DEFAULT TRUE,
    `custom_price` DECIMAL(10,2) NULL,                   -- optional price override

    CONSTRAINT `pk_availabilitycalendar` PRIMARY KEY (`cal_id`),
    CONSTRAINT `uq_calendar_listing_date` UNIQUE (`listing_id`, `date`),
    CONSTRAINT `fk_calendar_listing`
        FOREIGN KEY (`listing_id`) REFERENCES `listing` (`listing_id`)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT `chk_calendar_price` CHECK (`custom_price` >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 19. LISTINGAMENITY  -- junction: listing <-> amenity (M:N)
-- =========================================================
CREATE TABLE `listingamenity` (
    `listing_id` VARCHAR(50) NOT NULL,                  -- PK, FK -> listing
    `amenity_id` VARCHAR(50) NOT NULL,                  -- PK, FK -> amenity

    CONSTRAINT `pk_listingamenity` PRIMARY KEY (`listing_id`, `amenity_id`),
    CONSTRAINT `fk_la_listing`
        FOREIGN KEY (`listing_id`) REFERENCES `listing` (`listing_id`)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT `fk_la_amenity`
        FOREIGN KEY (`amenity_id`) REFERENCES `amenity` (`amenity_id`)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 20. BOOKING  -- reservation of a listing by a guest
-- =========================================================
CREATE TABLE `booking` (
    `booking_id`   VARCHAR(50)   NOT NULL,              -- PK
    `guest_id`     VARCHAR(50)   NOT NULL,              -- FK -> guest
    `listing_id`   VARCHAR(50)   NOT NULL,              -- FK -> listing
    `check_in`     DATE          NOT NULL,
    `check_out`    DATE          NOT NULL,
    `num_guests`   INT           NOT NULL DEFAULT 1,
    `total_price`  DECIMAL(10,2) NOT NULL,
    `status`       ENUM('PENDING','CONFIRMED','CANCELLED','COMPLETED')
                                 NOT NULL DEFAULT 'PENDING',
    `booking_date` DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT `pk_booking` PRIMARY KEY (`booking_id`),
    CONSTRAINT `fk_booking_guest`
        FOREIGN KEY (`guest_id`) REFERENCES `guest` (`guest_id`)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT `fk_booking_listing`
        FOREIGN KEY (`listing_id`) REFERENCES `listing` (`listing_id`)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT `chk_booking_dates`  CHECK (`check_out` > `check_in`),
    CONSTRAINT `chk_booking_guests` CHECK (`num_guests` > 0),
    CONSTRAINT `chk_booking_total`  CHECK (`total_price` >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 21. PAYMENT  -- guest payment for a booking
-- =========================================================
CREATE TABLE `payment` (
    `payment_id`   VARCHAR(50)   NOT NULL,              -- PK
    `booking_id`   VARCHAR(50)   NOT NULL,              -- FK -> booking
    `pm_id`        VARCHAR(50)   NOT NULL,              -- FK -> paymentmethod
    `amount`       DECIMAL(10,2) NOT NULL,
    `payment_date` DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `status`       ENUM('PAID','REFUNDED','FAILED') NOT NULL DEFAULT 'PAID',

    CONSTRAINT `pk_payment` PRIMARY KEY (`payment_id`),
    CONSTRAINT `fk_payment_booking`
        FOREIGN KEY (`booking_id`) REFERENCES `booking` (`booking_id`)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT `fk_payment_method`
        FOREIGN KEY (`pm_id`) REFERENCES `paymentmethod` (`pm_id`)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT `chk_payment_amount` CHECK (`amount` >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 22. PAYOUT  -- disbursement to the host (1:1 with booking)
-- =========================================================
CREATE TABLE `payout` (
    `payout_id`   VARCHAR(50)   NOT NULL,               -- PK
    `booking_id`  VARCHAR(50)   NOT NULL,               -- FK -> booking (unique = 1:1)
    `po_id`       VARCHAR(50)   NOT NULL,               -- FK -> payoutmethod
    `amount`      DECIMAL(10,2) NOT NULL,
    `payout_date` DATETIME      NULL,                    -- NULL while pending
    `status`      ENUM('PENDING','RELEASED') NOT NULL DEFAULT 'PENDING',

    CONSTRAINT `pk_payout`         PRIMARY KEY (`payout_id`),
    CONSTRAINT `uq_payout_booking` UNIQUE (`booking_id`),
    CONSTRAINT `fk_payout_booking`
        FOREIGN KEY (`booking_id`) REFERENCES `booking` (`booking_id`)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT `fk_payout_method`
        FOREIGN KEY (`po_id`) REFERENCES `payoutmethod` (`po_id`)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT `chk_payout_amount` CHECK (`amount` >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 23. FEE  -- commission / fee lines on a booking
-- =========================================================
CREATE TABLE `fee` (
    `fee_id`     VARCHAR(50)   NOT NULL,                -- PK
    `booking_id` VARCHAR(50)   NOT NULL,                -- FK -> booking
    `fee_type`   VARCHAR(30)   NOT NULL,                -- guest service / host service / cleaning
    `amount`     DECIMAL(10,2) NOT NULL,
    `percentage` DECIMAL(5,2)  NULL,

    CONSTRAINT `pk_fee` PRIMARY KEY (`fee_id`),
    CONSTRAINT `fk_fee_booking`
        FOREIGN KEY (`booking_id`) REFERENCES `booking` (`booking_id`)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT `chk_fee_amount`     CHECK (`amount` >= 0),
    CONSTRAINT `chk_fee_percentage` CHECK (`percentage` BETWEEN 0 AND 100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 24. REVIEW  -- review about a stay; links two users
--     (ternary: booking + reviewer + reviewee)
-- =========================================================
CREATE TABLE `review` (
    `review_id`      VARCHAR(50)  NOT NULL,             -- PK
    `booking_id`     VARCHAR(50)  NOT NULL,             -- FK -> booking
    `reviewer_id`    VARCHAR(50)  NOT NULL,             -- FK -> user (author)
    `reviewee_id`    VARCHAR(50)  NOT NULL,             -- FK -> user (subject)
    `overall_rating` DECIMAL(2,1) NOT NULL,
    `review_text`    TEXT         NULL,
    `review_date`    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT `pk_review` PRIMARY KEY (`review_id`),
    CONSTRAINT `uq_review_booking_reviewer` UNIQUE (`booking_id`, `reviewer_id`),
    CONSTRAINT `fk_review_booking`
        FOREIGN KEY (`booking_id`) REFERENCES `booking` (`booking_id`)
        ON UPDATE CASCADE ON DELETE CASCADE,
    -- ON UPDATE RESTRICT below: MySQL 8 forbids a CASCADE update action on a
    -- column that also appears in a CHECK constraint (here chk_review_self).
    CONSTRAINT `fk_review_reviewer`
        FOREIGN KEY (`reviewer_id`) REFERENCES `user` (`user_id`)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT `fk_review_reviewee`
        FOREIGN KEY (`reviewee_id`) REFERENCES `user` (`user_id`)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT `chk_review_rating` CHECK (`overall_rating` BETWEEN 1 AND 5),
    CONSTRAINT `chk_review_self`   CHECK (`reviewer_id` <> `reviewee_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 25. REVIEWRATING  -- junction: review <-> reviewcategory (M:N, scored)
-- =========================================================
CREATE TABLE `reviewrating` (
    `review_id` VARCHAR(50) NOT NULL,                   -- PK, FK -> review
    `cat_id`    VARCHAR(50) NOT NULL,                   -- PK, FK -> reviewcategory
    `score`     TINYINT     NOT NULL,

    CONSTRAINT `pk_reviewrating` PRIMARY KEY (`review_id`, `cat_id`),
    CONSTRAINT `fk_rr_review`
        FOREIGN KEY (`review_id`) REFERENCES `review` (`review_id`)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT `fk_rr_category`
        FOREIGN KEY (`cat_id`) REFERENCES `reviewcategory` (`cat_id`)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT `chk_rr_score` CHECK (`score` BETWEEN 1 AND 5)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 26. MESSAGE  -- direct message between two users
-- =========================================================
CREATE TABLE `message` (
    `msg_id`      VARCHAR(50) NOT NULL,                 -- PK
    `sender_id`   VARCHAR(50) NOT NULL,                 -- FK -> user
    `receiver_id` VARCHAR(50) NOT NULL,                 -- FK -> user
    `booking_id`  VARCHAR(50) NULL,                      -- FK -> booking (optional)
    `body`        TEXT        NOT NULL,
    `sent_at`     DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `is_read`     BOOLEAN     NOT NULL DEFAULT FALSE,

    CONSTRAINT `pk_message` PRIMARY KEY (`msg_id`),
    -- ON UPDATE RESTRICT: required so sender/receiver may appear in chk_message_self.
    CONSTRAINT `fk_message_sender`
        FOREIGN KEY (`sender_id`) REFERENCES `user` (`user_id`)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT `fk_message_receiver`
        FOREIGN KEY (`receiver_id`) REFERENCES `user` (`user_id`)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT `fk_message_booking`
        FOREIGN KEY (`booking_id`) REFERENCES `booking` (`booking_id`)
        ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT `chk_message_self` CHECK (`sender_id` <> `receiver_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 27. WISHLIST  -- a guest's saved collection of listings
-- =========================================================
CREATE TABLE `wishlist` (
    `wishlist_id` VARCHAR(50)  NOT NULL,                -- PK
    `guest_id`    VARCHAR(50)  NOT NULL,                -- FK -> guest
    `name`        VARCHAR(100) NOT NULL,
    `created_at`  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT `pk_wishlist` PRIMARY KEY (`wishlist_id`),
    CONSTRAINT `fk_wishlist_guest`
        FOREIGN KEY (`guest_id`) REFERENCES `guest` (`guest_id`)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 28. WISHLISTITEM  -- junction: wishlist <-> listing (M:N)
-- =========================================================
CREATE TABLE `wishlistitem` (
    `wishlist_id` VARCHAR(50) NOT NULL,                 -- PK, FK -> wishlist
    `listing_id`  VARCHAR(50) NOT NULL,                 -- PK, FK -> listing
    `added_at`    DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT `pk_wishlistitem` PRIMARY KEY (`wishlist_id`, `listing_id`),
    CONSTRAINT `fk_wi_wishlist`
        FOREIGN KEY (`wishlist_id`) REFERENCES `wishlist` (`wishlist_id`)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT `fk_wi_listing`
        FOREIGN KEY (`listing_id`) REFERENCES `listing` (`listing_id`)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 29. USERCONNECTION  -- recursive junction: user <-> user
--     (social contacts; M:N of user with itself)
-- =========================================================
CREATE TABLE `userconnection` (
    `user_id`           VARCHAR(50) NOT NULL,           -- PK, FK -> user
    `connected_user_id` VARCHAR(50) NOT NULL,           -- PK, FK -> user
    `connected_since`   DATE        NOT NULL,

    CONSTRAINT `pk_userconnection` PRIMARY KEY (`user_id`, `connected_user_id`),
    -- ON UPDATE RESTRICT: required so the columns may appear in chk_uc_self.
    CONSTRAINT `fk_uc_user`
        FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT `fk_uc_connected_user`
        FOREIGN KEY (`connected_user_id`) REFERENCES `user` (`user_id`)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT `chk_uc_self` CHECK (`user_id` <> `connected_user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =====================================================================
-- End of schema.sql  --  29 tables created.
-- =====================================================================


-- =====================================================================
-- =====================================================================
-- ##  PART 2 of 3 : INSERTS (test data, >= 20 rows per table)        
-- =====================================================================
-- =====================================================================

-- 20 rows
INSERT INTO `country` (`country_id`, `country_name`, `country_code`) VALUES
('CTR001', 'Netherlands', 'NL'),
('CTR002', 'Germany', 'DE'),
('CTR003', 'France', 'FR'),
('CTR004', 'Spain', 'ES'),
('CTR005', 'Italy', 'IT'),
('CTR006', 'Portugal', 'PT'),
('CTR007', 'United Kingdom', 'GB'),
('CTR008', 'Ireland', 'IE'),
('CTR009', 'Belgium', 'BE'),
('CTR010', 'Austria', 'AT'),
('CTR011', 'Switzerland', 'CH'),
('CTR012', 'Sweden', 'SE'),
('CTR013', 'Norway', 'NO'),
('CTR014', 'Denmark', 'DK'),
('CTR015', 'Finland', 'FI'),
('CTR016', 'Poland', 'PL'),
('CTR017', 'Czechia', 'CZ'),
('CTR018', 'Greece', 'GR'),
('CTR019', 'Croatia', 'HR'),
('CTR020', 'United States', 'US');

-- 24 rows
INSERT INTO `city` (`city_id`, `country_id`, `city_name`) VALUES
('CTY001', 'CTR001', 'Amsterdam'),
('CTY002', 'CTR001', 'Rotterdam'),
('CTY003', 'CTR002', 'Berlin'),
('CTY004', 'CTR002', 'Munich'),
('CTY005', 'CTR003', 'Paris'),
('CTY006', 'CTR003', 'Lyon'),
('CTY007', 'CTR004', 'Madrid'),
('CTY008', 'CTR004', 'Barcelona'),
('CTY009', 'CTR005', 'Rome'),
('CTY010', 'CTR005', 'Milan'),
('CTY011', 'CTR006', 'Lisbon'),
('CTY012', 'CTR006', 'Porto'),
('CTY013', 'CTR007', 'London'),
('CTY014', 'CTR007', 'Manchester'),
('CTY015', 'CTR008', 'Dublin'),
('CTY016', 'CTR009', 'Brussels'),
('CTY017', 'CTR010', 'Vienna'),
('CTY018', 'CTR011', 'Zurich'),
('CTY019', 'CTR012', 'Stockholm'),
('CTY020', 'CTR013', 'Oslo'),
('CTY021', 'CTR014', 'Copenhagen'),
('CTY022', 'CTR015', 'Helsinki'),
('CTY023', 'CTR018', 'Athens'),
('CTY024', 'CTR020', 'New York');

-- 30 rows
INSERT INTO `address` (`address_id`, `city_id`, `street`, `zip_code`, `latitude`, `longitude`) VALUES
('ADR001', 'CTY001', 'Kerkstraat 1', '1007', 51.346243, -8.149634),
('ADR002', 'CTY002', 'Hauptstrasse 2', '1014', 42.600704, -1.410835),
('ADR003', 'CTY003', 'Rue de Rivoli 3', '1021', 53.675309, 14.007783),
('ADR004', 'CTY004', 'Gran Via 4', '1028', 57.41231, -6.04408),
('ADR005', 'CTY005', 'Via Roma 5', '1035', 46.126124, -7.986895),
('ADR006', 'CTY006', 'Rua Augusta 6', '1042', 41.247311, 8.18208),
('ADR007', 'CTY007', 'Baker Street 7', '1049', 36.636863, -2.23952),
('ADR008', 'CTY008', 'O''Connell Street 8', '1056', 51.597227, 9.52801),
('ADR009', 'CTY009', 'Rue Neuve 9', '1063', 41.290575, 11.035033),
('ADR010', 'CTY010', 'Kärntner Strasse 10', '1070', 55.426331, -8.779042),
('ADR011', 'CTY011', 'Bahnhofstrasse 11', '1077', 55.339662, 14.736739),
('ADR012', 'CTY012', 'Drottninggatan 12', '1084', 44.166012, -3.713697),
('ADR013', 'CTY013', 'Karl Johans gate 13', '1091', 58.973114, 2.444215),
('ADR014', 'CTY014', 'Stroget 14', '1098', 38.2259, -5.711643),
('ADR015', 'CTY015', 'Aleksanterinkatu 15', '1105', 56.339865, 11.526685),
('ADR016', 'CTY016', 'Nowy Swiat 16', '1112', 55.371079, 15.810881),
('ADR017', 'CTY017', 'Wenceslas Square 17', '1119', 48.869474, 24.085936),
('ADR018', 'CTY018', 'Ermou Street 18', '1126', 45.084825, 9.769381),
('ADR019', 'CTY019', 'Ilica 19', '1133', 55.905712, 12.029672),
('ADR020', 'CTY020', 'Broadway 20', '1140', 56.680966, 10.629973),
('ADR021', 'CTY021', 'Kerkstraat 21', '1147', 52.909724, -7.441971),
('ADR022', 'CTY022', 'Hauptstrasse 22', '1154', 41.469559, 0.839191),
('ADR023', 'CTY023', 'Rue de Rivoli 23', '1161', 37.915007, -1.08511),
('ADR024', 'CTY024', 'Gran Via 24', '1168', 38.424034, 0.451103),
('ADR025', 'CTY001', 'Via Roma 25', '1175', 51.256427, 3.404294),
('ADR026', 'CTY002', 'Rua Augusta 26', '1182', 44.884343, -1.876761),
('ADR027', 'CTY003', 'Baker Street 27', '1189', 42.407468, 22.846256),
('ADR028', 'CTY004', 'O''Connell Street 28', '1196', 51.552849, 11.710454),
('ADR029', 'CTY005', 'Rue Neuve 29', '1203', 40.107328, 15.790311),
('ADR030', 'CTY006', 'Kärntner Strasse 30', '1210', 39.92166, 3.901485);

-- 43 rows
INSERT INTO `user` (`user_id`, `username`, `email`, `password_hash`, `phone`, `profile_pic`, `joined_date`, `role`) VALUES
('USR001', 'liam.jansen1', 'liam.jansen1@example.com', '$2y$10$hash001abcdefghijklmnopqrstuv', '+31 6 95899313', '/img/users/u1.jpg', '2025-09-08 18:20:00', 'HOST'),
('USR002', 'emma.muller2', 'emma.muller2@example.com', '$2y$10$hash002abcdefghijklmnopqrstuv', '+31 6 17507864', '/img/users/u2.jpg', '2023-01-26 13:25:00', 'HOST'),
('USR003', 'noah.dubois3', 'noah.dubois3@example.com', '$2y$10$hash003abcdefghijklmnopqrstuv', '+31 6 45935572', '/img/users/u3.jpg', '2023-04-19 19:20:00', 'HOST'),
('USR004', 'olivia.garcia4', 'olivia.garcia4@example.com', '$2y$10$hash004abcdefghijklmnopqrstuv', '+31 6 38538251', NULL, '2025-08-13 18:29:00', 'HOST'),
('USR005', 'ava.rossi5', 'ava.rossi5@example.com', '$2y$10$hash005abcdefghijklmnopqrstuv', '+31 6 29175900', '/img/users/u5.jpg', '2024-03-08 19:35:00', 'HOST'),
('USR006', 'elijah.silva6', 'elijah.silva6@example.com', '$2y$10$hash006abcdefghijklmnopqrstuv', '+31 6 82340307', '/img/users/u6.jpg', '2024-12-19 14:57:00', 'HOST'),
('USR007', 'sophia.smith7', 'sophia.smith7@example.com', '$2y$10$hash007abcdefghijklmnopqrstuv', '+31 6 88320463', '/img/users/u7.jpg', '2024-06-08 10:32:00', 'HOST'),
('USR008', 'lucas.byrne8', 'lucas.byrne8@example.com', '$2y$10$hash008abcdefghijklmnopqrstuv', '+31 6 76238574', NULL, '2023-01-28 09:09:00', 'HOST'),
('USR009', 'mia.peeters9', 'mia.peeters9@example.com', '$2y$10$hash009abcdefghijklmnopqrstuv', '+31 6 94214382', '/img/users/u9.jpg', '2023-11-14 17:04:00', 'HOST'),
('USR010', 'mason.gruber10', 'mason.gruber10@example.com', '$2y$10$hash010abcdefghijklmnopqrstuv', '+31 6 61642594', '/img/users/u10.jpg', '2024-10-15 16:16:00', 'HOST'),
('USR011', 'isabella.meier11', 'isabella.meier11@example.com', '$2y$10$hash011abcdefghijklmnopqrstuv', '+31 6 84252722', '/img/users/u11.jpg', '2023-11-24 09:43:00', 'HOST'),
('USR012', 'ethan.andersson12', 'ethan.andersson12@example.com', '$2y$10$hash012abcdefghijklmnopqrstuv', '+31 6 82070937', NULL, '2024-11-11 09:18:00', 'HOST'),
('USR013', 'amelia.hansen13', 'amelia.hansen13@example.com', '$2y$10$hash013abcdefghijklmnopqrstuv', '+31 6 68353204', '/img/users/u13.jpg', '2023-08-01 19:56:00', 'HOST'),
('USR014', 'leo.nielsen14', 'leo.nielsen14@example.com', '$2y$10$hash014abcdefghijklmnopqrstuv', '+31 6 45351479', '/img/users/u14.jpg', '2025-03-17 09:55:00', 'HOST'),
('USR015', 'charlotte.korhonen15', 'charlotte.korhonen15@example.com', '$2y$10$hash015abcdefghijklmnopqrstuv', '+31 6 93926371', '/img/users/u15.jpg', '2024-11-17 17:12:00', 'HOST'),
('USR016', 'finn.kowalski16', 'finn.kowalski16@example.com', '$2y$10$hash016abcdefghijklmnopqrstuv', '+31 6 30513739', NULL, '2024-03-18 20:59:00', 'HOST'),
('USR017', 'harper.novak17', 'harper.novak17@example.com', '$2y$10$hash017abcdefghijklmnopqrstuv', '+31 6 81182864', '/img/users/u17.jpg', '2023-10-11 15:01:00', 'HOST'),
('USR018', 'jonas.papadopoulos18', 'jonas.papadopoulos18@example.com', '$2y$10$hash018abcdefghijklmnopqrstuv', '+31 6 25014631', '/img/users/u18.jpg', '2024-05-08 08:15:00', 'HOST'),
('USR019', 'nora.horvat19', 'nora.horvat19@example.com', '$2y$10$hash019abcdefghijklmnopqrstuv', '+31 6 86149359', '/img/users/u19.jpg', '2023-02-24 15:52:00', 'HOST'),
('USR020', 'kaan.johnson20', 'kaan.johnson20@example.com', '$2y$10$hash020abcdefghijklmnopqrstuv', '+31 6 19289546', NULL, '2025-03-05 18:30:00', 'HOST'),
('USR021', 'ines.bakker21', 'ines.bakker21@example.com', '$2y$10$hash021abcdefghijklmnopqrstuv', '+31 6 83793389', '/img/users/u21.jpg', '2023-05-17 17:27:00', 'GUEST'),
('USR022', 'marta.weber22', 'marta.weber22@example.com', '$2y$10$hash022abcdefghijklmnopqrstuv', '+31 6 38427073', '/img/users/u22.jpg', '2025-12-23 11:45:00', 'GUEST'),
('USR023', 'pavel.bernard23', 'pavel.bernard23@example.com', '$2y$10$hash023abcdefghijklmnopqrstuv', '+31 6 51837852', '/img/users/u23.jpg', '2024-11-21 13:28:00', 'GUEST'),
('USR024', 'sofia.lopez24', 'sofia.lopez24@example.com', '$2y$10$hash024abcdefghijklmnopqrstuv', '+31 6 79467853', NULL, '2024-02-08 11:04:00', 'GUEST'),
('USR025', 'hugo.bianchi25', 'hugo.bianchi25@example.com', '$2y$10$hash025abcdefghijklmnopqrstuv', '+31 6 55377076', '/img/users/u25.jpg', '2023-10-18 11:37:00', 'GUEST'),
('USR026', 'elena.costa26', 'elena.costa26@example.com', '$2y$10$hash026abcdefghijklmnopqrstuv', '+31 6 39557077', '/img/users/u26.jpg', '2023-02-23 18:03:00', 'GUEST'),
('USR027', 'anton.brown27', 'anton.brown27@example.com', '$2y$10$hash027abcdefghijklmnopqrstuv', '+31 6 40728046', '/img/users/u27.jpg', '2023-01-28 13:04:00', 'GUEST'),
('USR028', 'klara.kelly28', 'klara.kelly28@example.com', '$2y$10$hash028abcdefghijklmnopqrstuv', '+31 6 79008866', NULL, '2023-05-22 15:13:00', 'GUEST'),
('USR029', 'bjorn.wouters29', 'bjorn.wouters29@example.com', '$2y$10$hash029abcdefghijklmnopqrstuv', '+31 6 82374753', '/img/users/u29.jpg', '2023-12-19 17:30:00', 'GUEST'),
('USR030', 'aoife.berger30', 'aoife.berger30@example.com', '$2y$10$hash030abcdefghijklmnopqrstuv', '+31 6 42614537', '/img/users/u30.jpg', '2024-07-07 09:06:00', 'GUEST'),
('USR031', 'sven.karlsson31', 'sven.karlsson31@example.com', '$2y$10$hash031abcdefghijklmnopqrstuv', '+31 6 98447167', '/img/users/u31.jpg', '2024-06-14 14:29:00', 'GUEST'),
('USR032', 'lea.olsen32', 'lea.olsen32@example.com', '$2y$10$hash032abcdefghijklmnopqrstuv', '+31 6 17270733', NULL, '2025-11-21 09:03:00', 'GUEST'),
('USR033', 'milan.larsen33', 'milan.larsen33@example.com', '$2y$10$hash033abcdefghijklmnopqrstuv', '+31 6 64038913', '/img/users/u33.jpg', '2025-06-26 09:15:00', 'GUEST'),
('USR034', 'freya.virtanen34', 'freya.virtanen34@example.com', '$2y$10$hash034abcdefghijklmnopqrstuv', '+31 6 35714784', '/img/users/u34.jpg', '2023-09-15 10:27:00', 'GUEST'),
('USR035', 'diego.nowak35', 'diego.nowak35@example.com', '$2y$10$hash035abcdefghijklmnopqrstuv', '+31 6 34627347', '/img/users/u35.jpg', '2024-08-08 09:28:00', 'GUEST'),
('USR036', 'petra.svoboda36', 'petra.svoboda36@example.com', '$2y$10$hash036abcdefghijklmnopqrstuv', '+31 6 83863413', NULL, '2023-01-21 16:53:00', 'GUEST'),
('USR037', 'timo.nikolaou37', 'timo.nikolaou37@example.com', '$2y$10$hash037abcdefghijklmnopqrstuv', '+31 6 11980765', '/img/users/u37.jpg', '2023-04-06 14:31:00', 'GUEST'),
('USR038', 'alma.maric38', 'alma.maric38@example.com', '$2y$10$hash038abcdefghijklmnopqrstuv', '+31 6 74606833', '/img/users/u38.jpg', '2023-07-02 10:24:00', 'GUEST'),
('USR039', 'rasmus.miller39', 'rasmus.miller39@example.com', '$2y$10$hash039abcdefghijklmnopqrstuv', '+31 6 10289289', '/img/users/u39.jpg', '2024-05-26 20:29:00', 'GUEST'),
('USR040', 'zoe.vermeulen40', 'zoe.vermeulen40@example.com', '$2y$10$hash040abcdefghijklmnopqrstuv', '+31 6 48285503', NULL, '2024-12-24 20:35:00', 'GUEST'),
('USR041', 'nikola.fischer41', 'nikola.fischer41@example.com', '$2y$10$hash041abcdefghijklmnopqrstuv', '+31 6 98834863', '/img/users/u41.jpg', '2025-08-05 11:18:00', 'BOTH'),
('USR042', 'sara.moreau42', 'sara.moreau42@example.com', '$2y$10$hash042abcdefghijklmnopqrstuv', '+31 6 39219319', '/img/users/u42.jpg', '2023-10-24 16:03:00', 'BOTH'),
('USR043', 'tom.ricci43', 'tom.ricci43@example.com', '$2y$10$hash043abcdefghijklmnopqrstuv', '+31 6 52091325', '/img/users/u43.jpg', '2023-01-19 15:32:00', 'BOTH');

-- 23 rows
INSERT INTO `host` (`host_id`, `user_id`, `bio`, `host_since`, `is_superhost`) VALUES
('HST001', 'USR001', 'Experienced host, love meeting travellers (1).', '2023-03-02', 0),
('HST002', 'USR002', 'Experienced host, love meeting travellers (2).', '2023-02-28', 0),
('HST003', 'USR003', 'Experienced host, love meeting travellers (3).', '2021-02-20', 1),
('HST004', 'USR004', 'Experienced host, love meeting travellers (4).', '2021-11-28', 0),
('HST005', 'USR005', 'Experienced host, love meeting travellers (5).', '2021-07-04', 0),
('HST006', 'USR006', 'Experienced host, love meeting travellers (6).', '2023-04-19', 1),
('HST007', 'USR007', 'Experienced host, love meeting travellers (7).', '2023-01-20', 0),
('HST008', 'USR008', 'Experienced host, love meeting travellers (8).', '2021-07-22', 0),
('HST009', 'USR009', 'Experienced host, love meeting travellers (9).', '2023-10-17', 1),
('HST010', 'USR010', 'Experienced host, love meeting travellers (10).', '2022-05-07', 0),
('HST011', 'USR011', 'Experienced host, love meeting travellers (11).', '2023-12-11', 0),
('HST012', 'USR012', 'Experienced host, love meeting travellers (12).', '2021-05-13', 1),
('HST013', 'USR013', 'Experienced host, love meeting travellers (13).', '2021-11-21', 0),
('HST014', 'USR014', 'Experienced host, love meeting travellers (14).', '2022-08-11', 0),
('HST015', 'USR015', 'Experienced host, love meeting travellers (15).', '2021-01-15', 1),
('HST016', 'USR016', 'Experienced host, love meeting travellers (16).', '2023-10-04', 0),
('HST017', 'USR017', 'Experienced host, love meeting travellers (17).', '2021-09-07', 0),
('HST018', 'USR018', 'Experienced host, love meeting travellers (18).', '2023-05-05', 1),
('HST019', 'USR019', 'Experienced host, love meeting travellers (19).', '2022-02-08', 0),
('HST020', 'USR020', 'Experienced host, love meeting travellers (20).', '2022-05-06', 0),
('HST021', 'USR041', 'Experienced host, love meeting travellers (21).', '2022-09-23', 1),
('HST022', 'USR042', 'Experienced host, love meeting travellers (22).', '2022-10-26', 0),
('HST023', 'USR043', 'Experienced host, love meeting travellers (23).', '2023-09-01', 0);

-- 23 rows
INSERT INTO `guest` (`guest_id`, `user_id`, `verified`, `govt_id_verified`) VALUES
('GST001', 'USR021', 0, 0),
('GST002', 'USR022', 1, 0),
('GST003', 'USR023', 0, 1),
('GST004', 'USR024', 1, 0),
('GST005', 'USR025', 0, 0),
('GST006', 'USR026', 1, 1),
('GST007', 'USR027', 0, 0),
('GST008', 'USR028', 1, 0),
('GST009', 'USR029', 0, 1),
('GST010', 'USR030', 1, 0),
('GST011', 'USR031', 0, 0),
('GST012', 'USR032', 1, 1),
('GST013', 'USR033', 0, 0),
('GST014', 'USR034', 1, 0),
('GST015', 'USR035', 0, 1),
('GST016', 'USR036', 1, 0),
('GST017', 'USR037', 0, 0),
('GST018', 'USR038', 1, 1),
('GST019', 'USR039', 0, 0),
('GST020', 'USR040', 1, 0),
('GST021', 'USR041', 0, 1),
('GST022', 'USR042', 1, 0),
('GST023', 'USR043', 0, 0);

-- 26 rows
INSERT INTO `socialaccount` (`social_id`, `user_id`, `network`, `handle`) VALUES
('SOC001', 'USR001', 'Facebook', '@usr001_fa'),
('SOC002', 'USR002', 'Facebook', '@usr002_fa'),
('SOC003', 'USR003', 'Facebook', '@usr003_fa'),
('SOC004', 'USR004', 'Facebook', '@usr004_fa'),
('SOC005', 'USR005', 'Facebook', '@usr005_fa'),
('SOC006', 'USR006', 'Facebook', '@usr006_fa'),
('SOC007', 'USR007', 'Facebook', '@usr007_fa'),
('SOC008', 'USR008', 'Facebook', '@usr008_fa'),
('SOC009', 'USR009', 'Facebook', '@usr009_fa'),
('SOC010', 'USR010', 'Facebook', '@usr010_fa'),
('SOC011', 'USR011', 'Facebook', '@usr011_fa'),
('SOC012', 'USR012', 'Facebook', '@usr012_fa'),
('SOC013', 'USR013', 'Facebook', '@usr013_fa'),
('SOC014', 'USR014', 'Facebook', '@usr014_fa'),
('SOC015', 'USR015', 'Facebook', '@usr015_fa'),
('SOC016', 'USR016', 'Facebook', '@usr016_fa'),
('SOC017', 'USR017', 'Facebook', '@usr017_fa'),
('SOC018', 'USR018', 'Facebook', '@usr018_fa'),
('SOC019', 'USR019', 'Facebook', '@usr019_fa'),
('SOC020', 'USR020', 'Facebook', '@usr020_fa'),
('SOC021', 'USR021', 'Facebook', '@usr021_fa'),
('SOC022', 'USR022', 'Facebook', '@usr022_fa'),
('SOC023', 'USR023', 'Facebook', '@usr023_fa'),
('SOC024', 'USR024', 'Facebook', '@usr024_fa'),
('SOC025', 'USR025', 'Facebook', '@usr025_fa'),
('SOC026', 'USR026', 'Facebook', '@usr026_fa');

-- 26 rows
INSERT INTO `paymentmethod` (`pm_id`, `guest_id`, `type`, `last4`, `expiry`) VALUES
('PM001', 'GST001', 'Visa credit card', '9086', '2028-11-01'),
('PM002', 'GST002', 'Mastercard', '1697', '2027-05-01'),
('PM003', 'GST003', 'PayPal', '1891', '2026-12-01'),
('PM004', 'GST004', 'American Express', '9064', '2027-05-01'),
('PM005', 'GST005', 'Debit card', '4616', '2027-12-01'),
('PM006', 'GST006', 'Visa credit card', '5617', '2027-11-01'),
('PM007', 'GST007', 'Mastercard', '4325', '2029-05-01'),
('PM008', 'GST008', 'PayPal', '0832', '2026-11-01'),
('PM009', 'GST009', 'American Express', '6939', '2028-01-01'),
('PM010', 'GST010', 'Debit card', '0058', '2028-03-01'),
('PM011', 'GST011', 'Visa credit card', '4291', '2027-12-01'),
('PM012', 'GST012', 'Mastercard', '7239', '2029-09-01'),
('PM013', 'GST013', 'PayPal', '0158', '2026-02-01'),
('PM014', 'GST014', 'American Express', '2442', '2026-06-01'),
('PM015', 'GST015', 'Debit card', '9543', '2027-07-01'),
('PM016', 'GST016', 'Visa credit card', '2088', '2026-05-01'),
('PM017', 'GST017', 'Mastercard', '5974', '2026-06-01'),
('PM018', 'GST018', 'PayPal', '3441', '2027-11-01'),
('PM019', 'GST019', 'American Express', '1684', '2028-09-01'),
('PM020', 'GST020', 'Debit card', '6658', '2027-04-01'),
('PM021', 'GST021', 'Visa credit card', '2662', '2027-07-01'),
('PM022', 'GST022', 'Mastercard', '0406', '2027-12-01'),
('PM023', 'GST023', 'PayPal', '5442', '2029-11-01'),
('PM024', 'GST001', 'American Express', '4065', '2028-03-01'),
('PM025', 'GST002', 'Debit card', '1771', '2029-01-01'),
('PM026', 'GST003', 'Visa credit card', '7711', '2027-04-01');

-- 26 rows
INSERT INTO `payoutmethod` (`po_id`, `host_id`, `po_type`, `details`) VALUES
('PO001', 'HST001', 'Bank transfer (SEPA)', 'IBAN NL68 BANK 6728 6000 XX'),
('PO002', 'HST002', 'PayPal', 'IBAN NL39 BANK 4652 1387 XX'),
('PO003', 'HST003', 'Wise transfer', 'IBAN NL94 BANK 4164 7528 XX'),
('PO004', 'HST004', 'Bank transfer (SEPA)', 'IBAN NL52 BANK 5564 2137 XX'),
('PO005', 'HST005', 'PayPal', 'IBAN NL45 BANK 6753 9346 XX'),
('PO006', 'HST006', 'Wise transfer', 'IBAN NL61 BANK 9785 6425 XX'),
('PO007', 'HST007', 'Bank transfer (SEPA)', 'IBAN NL13 BANK 2889 5279 XX'),
('PO008', 'HST008', 'PayPal', 'IBAN NL32 BANK 5349 1626 XX'),
('PO009', 'HST009', 'Wise transfer', 'IBAN NL23 BANK 8119 6663 XX'),
('PO010', 'HST010', 'Bank transfer (SEPA)', 'IBAN NL50 BANK 8149 9379 XX'),
('PO011', 'HST011', 'PayPal', 'IBAN NL24 BANK 7311 4114 XX'),
('PO012', 'HST012', 'Wise transfer', 'IBAN NL42 BANK 1727 8144 XX'),
('PO013', 'HST013', 'Bank transfer (SEPA)', 'IBAN NL10 BANK 9518 9821 XX'),
('PO014', 'HST014', 'PayPal', 'IBAN NL97 BANK 4228 6967 XX'),
('PO015', 'HST015', 'Wise transfer', 'IBAN NL65 BANK 2146 6409 XX'),
('PO016', 'HST016', 'Bank transfer (SEPA)', 'IBAN NL89 BANK 6143 3041 XX'),
('PO017', 'HST017', 'PayPal', 'IBAN NL48 BANK 9308 6067 XX'),
('PO018', 'HST018', 'Wise transfer', 'IBAN NL95 BANK 7691 6344 XX'),
('PO019', 'HST019', 'Bank transfer (SEPA)', 'IBAN NL61 BANK 5844 3085 XX'),
('PO020', 'HST020', 'PayPal', 'IBAN NL34 BANK 7888 7211 XX'),
('PO021', 'HST021', 'Wise transfer', 'IBAN NL96 BANK 3851 5930 XX'),
('PO022', 'HST022', 'Bank transfer (SEPA)', 'IBAN NL61 BANK 9977 1006 XX'),
('PO023', 'HST023', 'PayPal', 'IBAN NL48 BANK 5700 4443 XX'),
('PO024', 'HST001', 'Wise transfer', 'IBAN NL65 BANK 6279 8618 XX'),
('PO025', 'HST002', 'Bank transfer (SEPA)', 'IBAN NL66 BANK 8244 4501 XX'),
('PO026', 'HST003', 'PayPal', 'IBAN NL75 BANK 8752 3780 XX');

-- 24 rows
INSERT INTO `propertytype` (`property_type_id`, `type_name`) VALUES
('PT001', 'Apartment'),
('PT002', 'House'),
('PT003', 'Loft'),
('PT004', 'Villa'),
('PT005', 'Cabin'),
('PT006', 'Studio'),
('PT007', 'Condominium'),
('PT008', 'Townhouse'),
('PT009', 'Bungalow'),
('PT010', 'Cottage'),
('PT011', 'Guesthouse'),
('PT012', 'Chalet'),
('PT013', 'Farmhouse'),
('PT014', 'Penthouse'),
('PT015', 'Duplex'),
('PT016', 'Houseboat'),
('PT017', 'Treehouse'),
('PT018', 'Tiny house'),
('PT019', 'Serviced apartment'),
('PT020', 'Hostel'),
('PT021', 'Castle'),
('PT022', 'Barn'),
('PT023', 'Camper/RV'),
('PT024', 'Dome');

-- 20 rows
INSERT INTO `roomtype` (`room_type_id`, `room_type_name`) VALUES
('RT001', 'Entire place'),
('RT002', 'Private room'),
('RT003', 'Shared room'),
('RT004', 'Hotel room'),
('RT005', 'Private room with ensuite'),
('RT006', 'Shared dormitory'),
('RT007', 'Master bedroom'),
('RT008', 'Guest bedroom'),
('RT009', 'Studio space'),
('RT010', 'Loft space'),
('RT011', 'Basement suite'),
('RT012', 'Attic room'),
('RT013', 'Garden room'),
('RT014', 'Pool house'),
('RT015', 'Annexe'),
('RT016', 'Bunk bed in dorm'),
('RT017', 'Single private room'),
('RT018', 'Double private room'),
('RT019', 'Twin shared room'),
('RT020', 'Family room');

-- 20 rows
INSERT INTO `cancellationpolicy` (`policy_id`, `policy_name`, `refund_days`, `description`) VALUES
('CP001', 'Flexible', 1, 'Flexible: full refund up to 1 day(s) before check-in.'),
('CP002', 'Moderate', 5, 'Moderate: full refund up to 5 day(s) before check-in.'),
('CP003', 'Strict', 7, 'Strict: full refund up to 7 day(s) before check-in.'),
('CP004', 'Firm', 14, 'Firm: full refund up to 14 day(s) before check-in.'),
('CP005', 'Non-refundable', 0, 'Non-refundable: full refund up to 0 day(s) before check-in.'),
('CP006', 'Super Strict 30 Days', 30, 'Super Strict 30 Days: full refund up to 30 day(s) before check-in.'),
('CP007', 'Super Strict 60 Days', 60, 'Super Strict 60 Days: full refund up to 60 day(s) before check-in.'),
('CP008', 'Long Term', 30, 'Long Term: full refund up to 30 day(s) before check-in.'),
('CP009', 'Grace Period 24h', 1, 'Grace Period 24h: full refund up to 1 day(s) before check-in.'),
('CP010', 'Grace Period 48h', 2, 'Grace Period 48h: full refund up to 2 day(s) before check-in.'),
('CP011', 'Partial Refund 50%', 7, 'Partial Refund 50%: full refund up to 7 day(s) before check-in.'),
('CP012', 'Partial Refund 75%', 5, 'Partial Refund 75%: full refund up to 5 day(s) before check-in.'),
('CP013', 'Seasonal Flexible', 3, 'Seasonal Flexible: full refund up to 3 day(s) before check-in.'),
('CP014', 'Seasonal Strict', 10, 'Seasonal Strict: full refund up to 10 day(s) before check-in.'),
('CP015', 'Weekly Discounted', 7, 'Weekly Discounted: full refund up to 7 day(s) before check-in.'),
('CP016', 'Monthly Discounted', 30, 'Monthly Discounted: full refund up to 30 day(s) before check-in.'),
('CP017', 'Holiday Strict', 21, 'Holiday Strict: full refund up to 21 day(s) before check-in.'),
('CP018', 'Business Flexible', 1, 'Business Flexible: full refund up to 1 day(s) before check-in.'),
('CP019', 'Last Minute', 1, 'Last Minute: full refund up to 1 day(s) before check-in.'),
('CP020', 'Standard', 7, 'Standard: full refund up to 7 day(s) before check-in.');

-- 25 rows
INSERT INTO `amenity` (`amenity_id`, `amenity_name`, `category`) VALUES
('AMN001', 'Wi-Fi', 'Internet'),
('AMN002', 'Kitchen', 'Kitchen'),
('AMN003', 'Free parking', 'Parking'),
('AMN004', 'Air conditioning', 'Climate'),
('AMN005', 'Heating', 'Climate'),
('AMN006', 'Washer', 'Laundry'),
('AMN007', 'Dryer', 'Laundry'),
('AMN008', 'Swimming pool', 'Outdoor'),
('AMN009', 'Hot tub', 'Outdoor'),
('AMN010', 'TV', 'Entertainment'),
('AMN011', 'Iron', 'Essentials'),
('AMN012', 'Hair dryer', 'Bathroom'),
('AMN013', 'Smoke alarm', 'Safety'),
('AMN014', 'Carbon monoxide alarm', 'Safety'),
('AMN015', 'First aid kit', 'Safety'),
('AMN016', 'Fire extinguisher', 'Safety'),
('AMN017', 'Coffee maker', 'Kitchen'),
('AMN018', 'Microwave', 'Kitchen'),
('AMN019', 'Refrigerator', 'Kitchen'),
('AMN020', 'Dishwasher', 'Kitchen'),
('AMN021', 'Balcony', 'Outdoor'),
('AMN022', 'Private garden', 'Outdoor'),
('AMN023', 'Gym', 'Facilities'),
('AMN024', 'Elevator', 'Facilities'),
('AMN025', 'Dedicated workspace', 'Facilities');

-- 20 rows
INSERT INTO `reviewcategory` (`cat_id`, `cat_name`) VALUES
('RC001', 'Cleanliness'),
('RC002', 'Communication'),
('RC003', 'Check-in'),
('RC004', 'Accuracy'),
('RC005', 'Location'),
('RC006', 'Value'),
('RC007', 'Amenities'),
('RC008', 'Hospitality'),
('RC009', 'Comfort'),
('RC010', 'Safety'),
('RC011', 'Responsiveness'),
('RC012', 'Neighbourhood'),
('RC013', 'Facilities'),
('RC014', 'Ambience'),
('RC015', 'Bathroom cleanliness'),
('RC016', 'Wi-Fi quality'),
('RC017', 'Noise level'),
('RC018', 'Parking'),
('RC019', 'Kitchen quality'),
('RC020', 'Overall experience');

-- 24 rows
INSERT INTO `listing` (`listing_id`, `host_id`, `address_id`, `property_type_id`, `room_type_id`, `policy_id`, `title`, `description`, `price_per_night`, `max_guests`, `avg_rating`, `status`) VALUES
('LST001', 'HST001', 'ADR001', 'PT001', 'RT001', 'CP001', 'Cosy city-centre apartment', 'A wonderful place to stay. Fully equipped and close to public transport. Listing #1.', 226.18, 3, 4.5, 'ACTIVE'),
('LST002', 'HST002', 'ADR002', 'PT002', 'RT002', 'CP002', 'Bright loft with skyline view', 'A wonderful place to stay. Fully equipped and close to public transport. Listing #2.', 219.06, 3, 4.1, 'ACTIVE'),
('LST003', 'HST003', 'ADR003', 'PT003', 'RT003', 'CP003', 'Charming canal house', 'A wonderful place to stay. Fully equipped and close to public transport. Listing #3.', 306.8, 2, 4.7, 'ACTIVE'),
('LST004', 'HST004', 'ADR004', 'PT004', 'RT004', 'CP004', 'Modern studio near park', 'A wonderful place to stay. Fully equipped and close to public transport. Listing #4.', 106.78, 2, 4.1, 'ACTIVE'),
('LST005', 'HST005', 'ADR005', 'PT005', 'RT005', 'CP005', 'Spacious family villa', 'A wonderful place to stay. Fully equipped and close to public transport. Listing #5.', 57.71, 4, 4.6, 'ACTIVE'),
('LST006', 'HST006', 'ADR006', 'PT006', 'RT006', 'CP006', 'Quiet garden retreat', 'A wonderful place to stay. Fully equipped and close to public transport. Listing #6.', 256.33, 4, NULL, 'ACTIVE'),
('LST007', 'HST007', 'ADR007', 'PT007', 'RT007', 'CP007', 'Stylish penthouse suite', 'A wonderful place to stay. Fully equipped and close to public transport. Listing #7.', 158.97, 6, 4.6, 'ACTIVE'),
('LST008', 'HST008', 'ADR008', 'PT008', 'RT008', 'CP008', 'Rustic countryside cottage', 'A wonderful place to stay. Fully equipped and close to public transport. Listing #8.', 242.55, 4, 4.5, 'INACTIVE'),
('LST009', 'HST009', 'ADR009', 'PT009', 'RT009', 'CP009', 'Sunny balcony flat', 'A wonderful place to stay. Fully equipped and close to public transport. Listing #9.', 112.1, 6, 4.7, 'ACTIVE'),
('LST010', 'HST010', 'ADR010', 'PT010', 'RT010', 'CP010', 'Designer duplex downtown', 'A wonderful place to stay. Fully equipped and close to public transport. Listing #10.', 290.48, 2, 4.8, 'ACTIVE'),
('LST011', 'HST011', 'ADR011', 'PT011', 'RT011', 'CP011', 'Seaside bungalow escape', 'A wonderful place to stay. Fully equipped and close to public transport. Listing #11.', 105.18, 6, 4.5, 'ACTIVE'),
('LST012', 'HST012', 'ADR012', 'PT012', 'RT012', 'CP012', 'Historic townhouse gem', 'A wonderful place to stay. Fully equipped and close to public transport. Listing #12.', 58.81, 2, NULL, 'ACTIVE'),
('LST013', 'HST013', 'ADR013', 'PT013', 'RT013', 'CP013', 'Minimalist artist loft', 'A wonderful place to stay. Fully equipped and close to public transport. Listing #13.', 297.3, 2, 4.5, 'ACTIVE'),
('LST014', 'HST014', 'ADR014', 'PT014', 'RT014', 'CP014', 'Riverside serviced apartment', 'A wonderful place to stay. Fully equipped and close to public transport. Listing #14.', 265.39, 6, 4.5, 'ACTIVE'),
('LST015', 'HST015', 'ADR015', 'PT015', 'RT015', 'CP015', 'Boutique guest suite', 'A wonderful place to stay. Fully equipped and close to public transport. Listing #15.', 198.7, 3, 5.0, 'ACTIVE'),
('LST016', 'HST016', 'ADR016', 'PT016', 'RT016', 'CP016', 'Green rooftop hideaway', 'A wonderful place to stay. Fully equipped and close to public transport. Listing #16.', 290.14, 4, 4.8, 'INACTIVE'),
('LST017', 'HST017', 'ADR017', 'PT017', 'RT017', 'CP017', 'Elegant old-town flat', 'A wonderful place to stay. Fully equipped and close to public transport. Listing #17.', 290.31, 4, 4.8, 'ACTIVE'),
('LST018', 'HST018', 'ADR018', 'PT018', 'RT018', 'CP018', 'Comfy budget room', 'A wonderful place to stay. Fully equipped and close to public transport. Listing #18.', 195.66, 2, NULL, 'ACTIVE'),
('LST019', 'HST019', 'ADR019', 'PT019', 'RT019', 'CP019', 'Luxury chalet with hot tub', 'A wonderful place to stay. Fully equipped and close to public transport. Listing #19.', 249.51, 4, 4.5, 'ACTIVE'),
('LST020', 'HST020', 'ADR020', 'PT020', 'RT020', 'CP020', 'Trendy warehouse conversion', 'A wonderful place to stay. Fully equipped and close to public transport. Listing #20.', 251.74, 6, 4.3, 'ACTIVE'),
('LST021', 'HST021', 'ADR021', 'PT021', 'RT001', 'CP001', 'Peaceful lakeside cabin', 'A wonderful place to stay. Fully equipped and close to public transport. Listing #21.', 258.86, 4, 4.6, 'ACTIVE'),
('LST022', 'HST022', 'ADR022', 'PT022', 'RT002', 'CP002', 'Central business studio', 'A wonderful place to stay. Fully equipped and close to public transport. Listing #22.', 120.51, 2, 4.7, 'ACTIVE'),
('LST023', 'HST023', 'ADR023', 'PT023', 'RT003', 'CP003', 'Family-friendly duplex', 'A wonderful place to stay. Fully equipped and close to public transport. Listing #23.', 109.49, 3, 4.3, 'ACTIVE'),
('LST024', 'HST001', 'ADR024', 'PT024', 'RT004', 'CP004', 'Romantic attic nest', 'A wonderful place to stay. Fully equipped and close to public transport. Listing #24.', 193.54, 2, NULL, 'INACTIVE');

-- 48 rows
INSERT INTO `photo` (`photo_id`, `listing_id`, `url`, `caption`, `is_cover`) VALUES
('PHO001', 'LST001', '/img/listings/lst001_1.jpg', 'Cover photo', 1),
('PHO002', 'LST001', '/img/listings/lst001_2.jpg', 'Interior view', 0),
('PHO003', 'LST002', '/img/listings/lst002_1.jpg', 'Cover photo', 1),
('PHO004', 'LST002', '/img/listings/lst002_2.jpg', 'Interior view', 0),
('PHO005', 'LST003', '/img/listings/lst003_1.jpg', 'Cover photo', 1),
('PHO006', 'LST003', '/img/listings/lst003_2.jpg', 'Interior view', 0),
('PHO007', 'LST004', '/img/listings/lst004_1.jpg', 'Cover photo', 1),
('PHO008', 'LST004', '/img/listings/lst004_2.jpg', 'Interior view', 0),
('PHO009', 'LST005', '/img/listings/lst005_1.jpg', 'Cover photo', 1),
('PHO010', 'LST005', '/img/listings/lst005_2.jpg', 'Interior view', 0),
('PHO011', 'LST006', '/img/listings/lst006_1.jpg', 'Cover photo', 1),
('PHO012', 'LST006', '/img/listings/lst006_2.jpg', 'Interior view', 0),
('PHO013', 'LST007', '/img/listings/lst007_1.jpg', 'Cover photo', 1),
('PHO014', 'LST007', '/img/listings/lst007_2.jpg', 'Interior view', 0),
('PHO015', 'LST008', '/img/listings/lst008_1.jpg', 'Cover photo', 1),
('PHO016', 'LST008', '/img/listings/lst008_2.jpg', 'Interior view', 0),
('PHO017', 'LST009', '/img/listings/lst009_1.jpg', 'Cover photo', 1),
('PHO018', 'LST009', '/img/listings/lst009_2.jpg', 'Interior view', 0),
('PHO019', 'LST010', '/img/listings/lst010_1.jpg', 'Cover photo', 1),
('PHO020', 'LST010', '/img/listings/lst010_2.jpg', 'Interior view', 0),
('PHO021', 'LST011', '/img/listings/lst011_1.jpg', 'Cover photo', 1),
('PHO022', 'LST011', '/img/listings/lst011_2.jpg', 'Interior view', 0),
('PHO023', 'LST012', '/img/listings/lst012_1.jpg', 'Cover photo', 1),
('PHO024', 'LST012', '/img/listings/lst012_2.jpg', 'Interior view', 0),
('PHO025', 'LST013', '/img/listings/lst013_1.jpg', 'Cover photo', 1),
('PHO026', 'LST013', '/img/listings/lst013_2.jpg', 'Interior view', 0),
('PHO027', 'LST014', '/img/listings/lst014_1.jpg', 'Cover photo', 1),
('PHO028', 'LST014', '/img/listings/lst014_2.jpg', 'Interior view', 0),
('PHO029', 'LST015', '/img/listings/lst015_1.jpg', 'Cover photo', 1),
('PHO030', 'LST015', '/img/listings/lst015_2.jpg', 'Interior view', 0),
('PHO031', 'LST016', '/img/listings/lst016_1.jpg', 'Cover photo', 1),
('PHO032', 'LST016', '/img/listings/lst016_2.jpg', 'Interior view', 0),
('PHO033', 'LST017', '/img/listings/lst017_1.jpg', 'Cover photo', 1),
('PHO034', 'LST017', '/img/listings/lst017_2.jpg', 'Interior view', 0),
('PHO035', 'LST018', '/img/listings/lst018_1.jpg', 'Cover photo', 1),
('PHO036', 'LST018', '/img/listings/lst018_2.jpg', 'Interior view', 0),
('PHO037', 'LST019', '/img/listings/lst019_1.jpg', 'Cover photo', 1),
('PHO038', 'LST019', '/img/listings/lst019_2.jpg', 'Interior view', 0),
('PHO039', 'LST020', '/img/listings/lst020_1.jpg', 'Cover photo', 1),
('PHO040', 'LST020', '/img/listings/lst020_2.jpg', 'Interior view', 0),
('PHO041', 'LST021', '/img/listings/lst021_1.jpg', 'Cover photo', 1),
('PHO042', 'LST021', '/img/listings/lst021_2.jpg', 'Interior view', 0),
('PHO043', 'LST022', '/img/listings/lst022_1.jpg', 'Cover photo', 1),
('PHO044', 'LST022', '/img/listings/lst022_2.jpg', 'Interior view', 0),
('PHO045', 'LST023', '/img/listings/lst023_1.jpg', 'Cover photo', 1),
('PHO046', 'LST023', '/img/listings/lst023_2.jpg', 'Interior view', 0),
('PHO047', 'LST024', '/img/listings/lst024_1.jpg', 'Cover photo', 1),
('PHO048', 'LST024', '/img/listings/lst024_2.jpg', 'Interior view', 0);

-- 30 rows
INSERT INTO `houserule` (`rule_id`, `listing_id`, `rule_text`) VALUES
('HR001', 'LST001', 'No smoking indoors'),
('HR002', 'LST001', 'No parties or events'),
('HR003', 'LST002', 'Quiet hours after 22:00'),
('HR004', 'LST002', 'No pets allowed'),
('HR005', 'LST003', 'Check-in after 15:00'),
('HR006', 'LST003', 'Check-out before 11:00'),
('HR007', 'LST004', 'Please remove shoes indoors'),
('HR008', 'LST004', 'No unregistered guests'),
('HR009', 'LST005', 'No smoking indoors'),
('HR010', 'LST005', 'No parties or events'),
('HR011', 'LST006', 'Quiet hours after 22:00'),
('HR012', 'LST006', 'No pets allowed'),
('HR013', 'LST007', 'Check-in after 15:00'),
('HR014', 'LST008', 'Check-out before 11:00'),
('HR015', 'LST009', 'Please remove shoes indoors'),
('HR016', 'LST010', 'No unregistered guests'),
('HR017', 'LST011', 'No smoking indoors'),
('HR018', 'LST012', 'No parties or events'),
('HR019', 'LST013', 'Quiet hours after 22:00'),
('HR020', 'LST014', 'No pets allowed'),
('HR021', 'LST015', 'Check-in after 15:00'),
('HR022', 'LST016', 'Check-out before 11:00'),
('HR023', 'LST017', 'Please remove shoes indoors'),
('HR024', 'LST018', 'No unregistered guests'),
('HR025', 'LST019', 'No smoking indoors'),
('HR026', 'LST020', 'No parties or events'),
('HR027', 'LST021', 'Quiet hours after 22:00'),
('HR028', 'LST022', 'No pets allowed'),
('HR029', 'LST023', 'Check-in after 15:00'),
('HR030', 'LST024', 'Check-out before 11:00');

-- 48 rows
INSERT INTO `availabilitycalendar` (`cal_id`, `listing_id`, `date`, `is_available`, `custom_price`) VALUES
('CAL001', 'LST001', '2026-03-04', 1, NULL),
('CAL002', 'LST001', '2026-07-25', 1, NULL),
('CAL003', 'LST002', '2026-03-12', 1, 262.87),
('CAL004', 'LST002', '2026-04-15', 0, NULL),
('CAL005', 'LST003', '2026-07-07', 1, NULL),
('CAL006', 'LST003', '2026-06-22', 1, 368.16),
('CAL007', 'LST004', '2026-08-07', 1, NULL),
('CAL008', 'LST004', '2026-01-17', 0, NULL),
('CAL009', 'LST005', '2026-07-07', 1, 69.25),
('CAL010', 'LST005', '2026-10-25', 1, NULL),
('CAL011', 'LST006', '2026-01-14', 1, NULL),
('CAL012', 'LST006', '2026-10-20', 0, 307.6),
('CAL013', 'LST007', '2026-08-01', 1, NULL),
('CAL014', 'LST007', '2026-06-18', 1, NULL),
('CAL015', 'LST008', '2026-07-14', 1, 291.06),
('CAL016', 'LST008', '2026-07-22', 0, NULL),
('CAL017', 'LST009', '2026-12-12', 1, NULL),
('CAL018', 'LST009', '2026-09-26', 1, 134.52),
('CAL019', 'LST010', '2026-10-04', 1, NULL),
('CAL020', 'LST010', '2026-08-17', 0, NULL),
('CAL021', 'LST011', '2026-05-07', 1, 126.22),
('CAL022', 'LST011', '2026-08-14', 1, NULL),
('CAL023', 'LST012', '2026-07-06', 1, NULL),
('CAL024', 'LST012', '2026-11-24', 0, 70.57),
('CAL025', 'LST013', '2026-07-12', 1, NULL),
('CAL026', 'LST013', '2026-03-27', 1, NULL),
('CAL027', 'LST014', '2026-08-03', 1, 318.47),
('CAL028', 'LST014', '2026-10-22', 0, NULL),
('CAL029', 'LST015', '2026-01-07', 1, NULL),
('CAL030', 'LST015', '2026-10-23', 1, 238.44),
('CAL031', 'LST016', '2026-11-01', 1, NULL),
('CAL032', 'LST016', '2026-02-24', 0, NULL),
('CAL033', 'LST017', '2026-07-03', 1, 348.37),
('CAL034', 'LST017', '2026-08-16', 1, NULL),
('CAL035', 'LST018', '2026-01-05', 1, NULL),
('CAL036', 'LST018', '2026-07-19', 0, 234.79),
('CAL037', 'LST019', '2026-04-08', 1, NULL),
('CAL038', 'LST019', '2026-06-19', 1, NULL),
('CAL039', 'LST020', '2026-07-05', 1, 302.09),
('CAL040', 'LST020', '2026-07-18', 0, NULL),
('CAL041', 'LST021', '2026-02-08', 1, NULL),
('CAL042', 'LST021', '2026-01-25', 1, 310.63),
('CAL043', 'LST022', '2026-09-01', 1, NULL),
('CAL044', 'LST022', '2026-06-17', 0, NULL),
('CAL045', 'LST023', '2026-11-02', 1, 131.39),
('CAL046', 'LST023', '2026-11-14', 1, NULL),
('CAL047', 'LST024', '2026-01-04', 1, NULL),
('CAL048', 'LST024', '2026-04-27', 0, 232.25);

-- 72 rows
INSERT INTO `listingamenity` (`listing_id`, `amenity_id`) VALUES
('LST001', 'AMN001'),
('LST001', 'AMN008'),
('LST001', 'AMN015'),
('LST002', 'AMN002'),
('LST002', 'AMN009'),
('LST002', 'AMN016'),
('LST003', 'AMN003'),
('LST003', 'AMN010'),
('LST003', 'AMN017'),
('LST004', 'AMN004'),
('LST004', 'AMN011'),
('LST004', 'AMN018'),
('LST005', 'AMN005'),
('LST005', 'AMN012'),
('LST005', 'AMN019'),
('LST006', 'AMN006'),
('LST006', 'AMN013'),
('LST006', 'AMN020'),
('LST007', 'AMN007'),
('LST007', 'AMN014'),
('LST007', 'AMN021'),
('LST008', 'AMN008'),
('LST008', 'AMN015'),
('LST008', 'AMN022'),
('LST009', 'AMN009'),
('LST009', 'AMN016'),
('LST009', 'AMN023'),
('LST010', 'AMN010'),
('LST010', 'AMN017'),
('LST010', 'AMN024'),
('LST011', 'AMN011'),
('LST011', 'AMN018'),
('LST011', 'AMN025'),
('LST012', 'AMN012'),
('LST012', 'AMN019'),
('LST012', 'AMN001'),
('LST013', 'AMN013'),
('LST013', 'AMN020'),
('LST013', 'AMN002'),
('LST014', 'AMN014'),
('LST014', 'AMN021'),
('LST014', 'AMN003'),
('LST015', 'AMN015'),
('LST015', 'AMN022'),
('LST015', 'AMN004'),
('LST016', 'AMN016'),
('LST016', 'AMN023'),
('LST016', 'AMN005'),
('LST017', 'AMN017'),
('LST017', 'AMN024'),
('LST017', 'AMN006'),
('LST018', 'AMN018'),
('LST018', 'AMN025'),
('LST018', 'AMN007'),
('LST019', 'AMN019'),
('LST019', 'AMN001'),
('LST019', 'AMN008'),
('LST020', 'AMN020'),
('LST020', 'AMN002'),
('LST020', 'AMN009'),
('LST021', 'AMN021'),
('LST021', 'AMN003'),
('LST021', 'AMN010'),
('LST022', 'AMN022'),
('LST022', 'AMN004'),
('LST022', 'AMN011'),
('LST023', 'AMN023'),
('LST023', 'AMN005'),
('LST023', 'AMN012'),
('LST024', 'AMN024'),
('LST024', 'AMN006'),
('LST024', 'AMN013');

-- 24 rows
INSERT INTO `booking` (`booking_id`, `guest_id`, `listing_id`, `check_in`, `check_out`, `num_guests`, `total_price`, `status`, `booking_date`) VALUES
('BKG001', 'GST001', 'LST001', '2026-04-03', '2026-04-08', 1, 1130.9, 'COMPLETED', '2026-03-04 19:49:00'),
('BKG002', 'GST002', 'LST002', '2026-11-20', '2026-11-24', 1, 876.24, 'COMPLETED', '2026-10-19 20:02:00'),
('BKG003', 'GST003', 'LST003', '2026-09-14', '2026-09-18', 2, 1227.2, 'COMPLETED', '2026-08-03 16:41:00'),
('BKG004', 'GST004', 'LST004', '2026-01-14', '2026-01-18', 2, 427.12, 'CONFIRMED', '2026-01-04 14:23:00'),
('BKG005', 'GST005', 'LST005', '2026-08-05', '2026-08-12', 2, 403.97, 'COMPLETED', '2026-07-06 19:33:00'),
('BKG006', 'GST006', 'LST006', '2026-05-20', '2026-05-27', 2, 1794.31, 'PENDING', '2026-04-15 14:52:00'),
('BKG007', 'GST007', 'LST007', '2026-10-09', '2026-10-16', 2, 1112.79, 'CONFIRMED', '2026-09-08 09:17:00'),
('BKG008', 'GST008', 'LST008', '2026-04-15', '2026-04-20', 2, 1212.75, 'COMPLETED', '2026-03-11 08:31:00'),
('BKG009', 'GST009', 'LST009', '2026-03-16', '2026-03-20', 1, 448.4, 'COMPLETED', '2026-02-12 20:16:00'),
('BKG010', 'GST010', 'LST010', '2026-05-20', '2026-05-24', 2, 1161.92, 'COMPLETED', '2026-04-18 08:33:00'),
('BKG011', 'GST011', 'LST011', '2026-02-08', '2026-02-11', 2, 315.54, 'COMPLETED', '2026-01-16 16:48:00'),
('BKG012', 'GST012', 'LST012', '2026-08-16', '2026-08-19', 2, 176.43, 'COMPLETED', '2026-07-01 09:18:00'),
('BKG013', 'GST013', 'LST013', '2026-07-08', '2026-07-11', 2, 891.9, 'COMPLETED', '2026-06-22 17:23:00'),
('BKG014', 'GST014', 'LST014', '2026-09-17', '2026-09-22', 2, 1326.95, 'CANCELLED', '2026-08-14 19:35:00'),
('BKG015', 'GST015', 'LST015', '2026-06-15', '2026-06-19', 2, 794.8, 'COMPLETED', '2026-05-10 12:14:00'),
('BKG016', 'GST016', 'LST016', '2026-04-11', '2026-04-13', 1, 580.28, 'COMPLETED', '2026-03-24 16:48:00'),
('BKG017', 'GST017', 'LST017', '2026-03-07', '2026-03-14', 1, 2032.17, 'COMPLETED', '2026-02-24 15:17:00'),
('BKG018', 'GST018', 'LST018', '2026-10-17', '2026-10-24', 2, 1369.62, 'COMPLETED', '2026-09-04 11:18:00'),
('BKG019', 'GST019', 'LST019', '2026-06-06', '2026-06-09', 2, 748.53, 'COMPLETED', '2026-05-01 19:34:00'),
('BKG020', 'GST020', 'LST020', '2026-05-02', '2026-05-05', 1, 755.22, 'CANCELLED', '2026-04-18 12:44:00'),
('BKG021', 'GST021', 'LST022', '2026-11-16', '2026-11-19', 1, 361.53, 'COMPLETED', '2026-10-01 17:18:00'),
('BKG022', 'GST022', 'LST023', '2026-08-15', '2026-08-20', 2, 547.45, 'COMPLETED', '2026-07-06 08:16:00'),
('BKG023', 'GST023', 'LST024', '2026-02-03', '2026-02-08', 2, 967.7, 'CONFIRMED', '2026-01-16 09:36:00'),
('BKG024', 'GST001', 'LST024', '2026-11-02', '2026-11-09', 1, 1354.78, 'COMPLETED', '2026-10-05 20:36:00');

-- 24 rows
INSERT INTO `payment` (`payment_id`, `booking_id`, `pm_id`, `amount`, `payment_date`, `status`) VALUES
('PAY001', 'BKG001', 'PM001', 1266.61, '2026-05-03 11:07:00', 'PAID'),
('PAY002', 'BKG002', 'PM002', 981.39, '2026-09-25 14:38:00', 'PAID'),
('PAY003', 'BKG003', 'PM003', 1374.46, '2026-10-20 11:49:00', 'PAID'),
('PAY004', 'BKG004', 'PM004', 478.37, '2026-09-13 15:58:00', 'PAID'),
('PAY005', 'BKG005', 'PM005', 452.45, '2026-08-10 17:27:00', 'PAID'),
('PAY006', 'BKG006', 'PM006', 2009.63, '2026-05-19 17:03:00', 'FAILED'),
('PAY007', 'BKG007', 'PM007', 1246.32, '2026-10-24 09:48:00', 'PAID'),
('PAY008', 'BKG008', 'PM008', 1358.28, '2026-04-21 11:16:00', 'PAID'),
('PAY009', 'BKG009', 'PM009', 502.21, '2026-11-03 10:15:00', 'PAID'),
('PAY010', 'BKG010', 'PM010', 1301.35, '2026-03-18 09:10:00', 'PAID'),
('PAY011', 'BKG011', 'PM011', 353.4, '2026-01-14 15:44:00', 'PAID'),
('PAY012', 'BKG012', 'PM012', 197.6, '2026-10-16 12:02:00', 'PAID'),
('PAY013', 'BKG013', 'PM013', 998.93, '2026-04-10 19:18:00', 'PAID'),
('PAY014', 'BKG014', 'PM014', 1486.18, '2026-08-03 18:14:00', 'REFUNDED'),
('PAY015', 'BKG015', 'PM015', 890.18, '2026-05-21 17:42:00', 'PAID'),
('PAY016', 'BKG016', 'PM016', 649.91, '2026-04-14 09:34:00', 'PAID'),
('PAY017', 'BKG017', 'PM017', 2276.03, '2026-04-21 10:58:00', 'PAID'),
('PAY018', 'BKG018', 'PM018', 1533.97, '2026-05-05 09:03:00', 'PAID'),
('PAY019', 'BKG019', 'PM019', 838.35, '2026-03-10 17:47:00', 'PAID'),
('PAY020', 'BKG020', 'PM020', 845.85, '2026-10-10 15:07:00', 'REFUNDED'),
('PAY021', 'BKG021', 'PM021', 404.91, '2026-08-23 12:44:00', 'PAID'),
('PAY022', 'BKG022', 'PM022', 613.14, '2026-07-09 16:34:00', 'PAID'),
('PAY023', 'BKG023', 'PM023', 1083.82, '2026-08-15 09:38:00', 'PAID'),
('PAY024', 'BKG024', 'PM001', 1517.35, '2026-01-14 19:20:00', 'PAID');

-- 24 rows
INSERT INTO `payout` (`payout_id`, `booking_id`, `po_id`, `amount`, `payout_date`, `status`) VALUES
('POUT001', 'BKG001', 'PO001', 1096.97, '2026-10-09 12:00:00', 'RELEASED'),
('POUT002', 'BKG002', 'PO002', 849.95, '2026-01-03 12:00:00', 'RELEASED'),
('POUT003', 'BKG003', 'PO003', 1190.38, '2026-04-22 12:00:00', 'RELEASED'),
('POUT004', 'BKG004', 'PO004', 414.31, NULL, 'PENDING'),
('POUT005', 'BKG005', 'PO005', 391.85, '2026-10-19 12:00:00', 'RELEASED'),
('POUT006', 'BKG006', 'PO006', 1740.48, NULL, 'PENDING'),
('POUT007', 'BKG007', 'PO007', 1079.41, NULL, 'PENDING'),
('POUT008', 'BKG008', 'PO008', 1176.37, '2026-01-25 12:00:00', 'RELEASED'),
('POUT009', 'BKG009', 'PO009', 434.95, '2026-11-09 12:00:00', 'RELEASED'),
('POUT010', 'BKG010', 'PO010', 1127.06, '2026-10-02 12:00:00', 'RELEASED'),
('POUT011', 'BKG011', 'PO011', 306.07, '2026-03-16 12:00:00', 'RELEASED'),
('POUT012', 'BKG012', 'PO012', 171.14, '2026-09-21 12:00:00', 'RELEASED'),
('POUT013', 'BKG013', 'PO013', 865.14, '2026-08-09 12:00:00', 'RELEASED'),
('POUT014', 'BKG014', 'PO014', 0.0, NULL, 'PENDING'),
('POUT015', 'BKG015', 'PO015', 770.96, '2026-03-19 12:00:00', 'RELEASED'),
('POUT016', 'BKG016', 'PO016', 562.87, '2026-07-21 12:00:00', 'RELEASED'),
('POUT017', 'BKG017', 'PO017', 1971.2, '2026-08-03 12:00:00', 'RELEASED'),
('POUT018', 'BKG018', 'PO018', 1328.53, '2026-08-12 12:00:00', 'RELEASED'),
('POUT019', 'BKG019', 'PO019', 726.07, '2026-07-11 12:00:00', 'RELEASED'),
('POUT020', 'BKG020', 'PO020', 0.0, NULL, 'PENDING'),
('POUT021', 'BKG021', 'PO022', 350.68, '2026-06-22 12:00:00', 'RELEASED'),
('POUT022', 'BKG022', 'PO023', 531.03, '2026-02-06 12:00:00', 'RELEASED'),
('POUT023', 'BKG023', 'PO001', 938.67, NULL, 'PENDING'),
('POUT024', 'BKG024', 'PO001', 1314.14, '2026-06-14 12:00:00', 'RELEASED');

-- 48 rows
INSERT INTO `fee` (`fee_id`, `booking_id`, `fee_type`, `amount`, `percentage`) VALUES
('FEE001', 'BKG001', 'Guest service fee', 135.71, 12.0),
('FEE002', 'BKG001', 'Host service fee', 33.93, 3.0),
('FEE003', 'BKG002', 'Guest service fee', 105.15, 12.0),
('FEE004', 'BKG002', 'Host service fee', 26.29, 3.0),
('FEE005', 'BKG003', 'Guest service fee', 147.26, 12.0),
('FEE006', 'BKG003', 'Host service fee', 36.82, 3.0),
('FEE007', 'BKG004', 'Guest service fee', 51.25, 12.0),
('FEE008', 'BKG004', 'Host service fee', 12.81, 3.0),
('FEE009', 'BKG005', 'Guest service fee', 48.48, 12.0),
('FEE010', 'BKG005', 'Host service fee', 12.12, 3.0),
('FEE011', 'BKG006', 'Guest service fee', 215.32, 12.0),
('FEE012', 'BKG006', 'Host service fee', 53.83, 3.0),
('FEE013', 'BKG007', 'Guest service fee', 133.53, 12.0),
('FEE014', 'BKG007', 'Host service fee', 33.38, 3.0),
('FEE015', 'BKG008', 'Guest service fee', 145.53, 12.0),
('FEE016', 'BKG008', 'Host service fee', 36.38, 3.0),
('FEE017', 'BKG009', 'Guest service fee', 53.81, 12.0),
('FEE018', 'BKG009', 'Host service fee', 13.45, 3.0),
('FEE019', 'BKG010', 'Guest service fee', 139.43, 12.0),
('FEE020', 'BKG010', 'Host service fee', 34.86, 3.0),
('FEE021', 'BKG011', 'Guest service fee', 37.86, 12.0),
('FEE022', 'BKG011', 'Host service fee', 9.47, 3.0),
('FEE023', 'BKG012', 'Guest service fee', 21.17, 12.0),
('FEE024', 'BKG012', 'Host service fee', 5.29, 3.0),
('FEE025', 'BKG013', 'Guest service fee', 107.03, 12.0),
('FEE026', 'BKG013', 'Host service fee', 26.76, 3.0),
('FEE027', 'BKG014', 'Guest service fee', 159.23, 12.0),
('FEE028', 'BKG014', 'Host service fee', 39.81, 3.0),
('FEE029', 'BKG015', 'Guest service fee', 95.38, 12.0),
('FEE030', 'BKG015', 'Host service fee', 23.84, 3.0),
('FEE031', 'BKG016', 'Guest service fee', 69.63, 12.0),
('FEE032', 'BKG016', 'Host service fee', 17.41, 3.0),
('FEE033', 'BKG017', 'Guest service fee', 243.86, 12.0),
('FEE034', 'BKG017', 'Host service fee', 60.97, 3.0),
('FEE035', 'BKG018', 'Guest service fee', 164.35, 12.0),
('FEE036', 'BKG018', 'Host service fee', 41.09, 3.0),
('FEE037', 'BKG019', 'Guest service fee', 89.82, 12.0),
('FEE038', 'BKG019', 'Host service fee', 22.46, 3.0),
('FEE039', 'BKG020', 'Guest service fee', 90.63, 12.0),
('FEE040', 'BKG020', 'Host service fee', 22.66, 3.0),
('FEE041', 'BKG021', 'Guest service fee', 43.38, 12.0),
('FEE042', 'BKG021', 'Host service fee', 10.85, 3.0),
('FEE043', 'BKG022', 'Guest service fee', 65.69, 12.0),
('FEE044', 'BKG022', 'Host service fee', 16.42, 3.0),
('FEE045', 'BKG023', 'Guest service fee', 116.12, 12.0),
('FEE046', 'BKG023', 'Host service fee', 29.03, 3.0),
('FEE047', 'BKG024', 'Guest service fee', 162.57, 12.0),
('FEE048', 'BKG024', 'Host service fee', 40.64, 3.0);

-- 30 rows
INSERT INTO `review` (`review_id`, `booking_id`, `reviewer_id`, `reviewee_id`, `overall_rating`, `review_text`, `review_date`) VALUES
('REV001', 'BKG001', 'USR021', 'USR001', 4.5, 'Host was responsive and helpful.', '2026-12-13 10:00:00'),
('REV002', 'BKG002', 'USR022', 'USR002', 4.5, 'Exactly as described, lovely place.', '2026-02-15 10:00:00'),
('REV003', 'BKG003', 'USR023', 'USR003', 3.5, 'Host was responsive and helpful.', '2026-07-04 10:00:00'),
('REV004', 'BKG005', 'USR025', 'USR005', 5.0, 'Comfortable and quiet, would book again.', '2026-10-01 10:00:00'),
('REV005', 'BKG008', 'USR028', 'USR008', 4.5, 'Exactly as described, lovely place.', '2026-09-14 10:00:00'),
('REV006', 'BKG009', 'USR029', 'USR009', 3.5, 'Exactly as described, lovely place.', '2026-07-20 10:00:00'),
('REV007', 'BKG010', 'USR030', 'USR010', 4.5, 'Smooth check-in, great value.', '2026-09-25 10:00:00'),
('REV008', 'BKG011', 'USR031', 'USR011', 3.5, 'Host was responsive and helpful.', '2026-10-05 10:00:00'),
('REV009', 'BKG012', 'USR032', 'USR012', 5.0, 'Comfortable and quiet, would book again.', '2026-09-04 10:00:00'),
('REV010', 'BKG013', 'USR033', 'USR013', 3.5, 'Smooth check-in, great value.', '2026-11-08 10:00:00'),
('REV011', 'BKG015', 'USR035', 'USR015', 4.5, 'Host was responsive and helpful.', '2026-10-01 10:00:00'),
('REV012', 'BKG016', 'USR036', 'USR016', 4.5, 'Fantastic stay, highly recommended!', '2026-05-04 10:00:00'),
('REV013', 'BKG017', 'USR037', 'USR017', 4.0, 'Fantastic stay, highly recommended!', '2026-12-05 10:00:00'),
('REV014', 'BKG018', 'USR038', 'USR018', 4.0, 'Smooth check-in, great value.', '2026-06-17 10:00:00'),
('REV015', 'BKG019', 'USR039', 'USR019', 4.5, 'Comfortable and quiet, would book again.', '2026-09-16 10:00:00'),
('REV016', 'BKG021', 'USR041', 'USR042', 4.0, 'Exactly as described, lovely place.', '2026-04-13 10:00:00'),
('REV017', 'BKG022', 'USR042', 'USR043', 4.0, 'Exactly as described, lovely place.', '2026-10-24 10:00:00'),
('REV018', 'BKG024', 'USR021', 'USR001', 5.0, 'Fantastic stay, highly recommended!', '2026-06-25 10:00:00'),
('REV019', 'BKG001', 'USR001', 'USR021', 5.0, 'Great guest, left the place tidy. Welcome back!', '2026-08-11 14:00:00'),
('REV020', 'BKG002', 'USR002', 'USR022', 5.0, 'Great guest, left the place tidy. Welcome back!', '2026-10-09 14:00:00'),
('REV021', 'BKG003', 'USR003', 'USR023', 5.0, 'Great guest, left the place tidy. Welcome back!', '2026-06-24 14:00:00'),
('REV022', 'BKG005', 'USR005', 'USR025', 4.5, 'Great guest, left the place tidy. Welcome back!', '2026-11-19 14:00:00'),
('REV023', 'BKG008', 'USR008', 'USR028', 5.0, 'Great guest, left the place tidy. Welcome back!', '2026-09-05 14:00:00'),
('REV024', 'BKG009', 'USR009', 'USR029', 4.5, 'Great guest, left the place tidy. Welcome back!', '2026-09-12 14:00:00'),
('REV025', 'BKG010', 'USR010', 'USR030', 4.5, 'Great guest, left the place tidy. Welcome back!', '2026-10-13 14:00:00'),
('REV026', 'BKG011', 'USR011', 'USR031', 4.5, 'Great guest, left the place tidy. Welcome back!', '2026-07-07 14:00:00'),
('REV027', 'BKG012', 'USR012', 'USR032', 5.0, 'Great guest, left the place tidy. Welcome back!', '2026-05-19 14:00:00'),
('REV028', 'BKG013', 'USR013', 'USR033', 4.5, 'Great guest, left the place tidy. Welcome back!', '2026-08-02 14:00:00'),
('REV029', 'BKG015', 'USR015', 'USR035', 4.5, 'Great guest, left the place tidy. Welcome back!', '2026-09-23 14:00:00'),
('REV030', 'BKG016', 'USR016', 'USR036', 5.0, 'Great guest, left the place tidy. Welcome back!', '2026-08-13 14:00:00');

-- 90 rows
INSERT INTO `reviewrating` (`review_id`, `cat_id`, `score`) VALUES
('REV001', 'RC005', 3),
('REV001', 'RC016', 5),
('REV001', 'RC002', 5),
('REV002', 'RC011', 3),
('REV002', 'RC004', 5),
('REV002', 'RC015', 4),
('REV003', 'RC001', 5),
('REV003', 'RC005', 3),
('REV003', 'RC014', 3),
('REV004', 'RC016', 5),
('REV004', 'RC009', 5),
('REV004', 'RC011', 4),
('REV005', 'RC003', 4),
('REV005', 'RC011', 4),
('REV005', 'RC018', 5),
('REV006', 'RC016', 5),
('REV006', 'RC018', 3),
('REV006', 'RC002', 3),
('REV007', 'RC010', 4),
('REV007', 'RC008', 3),
('REV007', 'RC003', 5),
('REV008', 'RC004', 5),
('REV008', 'RC015', 4),
('REV008', 'RC006', 3),
('REV009', 'RC002', 4),
('REV009', 'RC011', 4),
('REV009', 'RC020', 4),
('REV010', 'RC014', 5),
('REV010', 'RC005', 4),
('REV010', 'RC008', 5),
('REV011', 'RC006', 3),
('REV011', 'RC020', 5),
('REV011', 'RC019', 4),
('REV012', 'RC020', 5),
('REV012', 'RC008', 3),
('REV012', 'RC016', 3),
('REV013', 'RC015', 4),
('REV013', 'RC009', 5),
('REV013', 'RC020', 3),
('REV014', 'RC015', 3),
('REV014', 'RC010', 3),
('REV014', 'RC018', 4),
('REV015', 'RC012', 5),
('REV015', 'RC019', 4),
('REV015', 'RC010', 5),
('REV016', 'RC009', 3),
('REV016', 'RC015', 4),
('REV016', 'RC010', 4),
('REV017', 'RC004', 5),
('REV017', 'RC008', 4),
('REV017', 'RC013', 5),
('REV018', 'RC010', 5),
('REV018', 'RC020', 4),
('REV018', 'RC001', 4),
('REV019', 'RC001', 5),
('REV019', 'RC019', 5),
('REV019', 'RC002', 4),
('REV020', 'RC010', 3),
('REV020', 'RC008', 5),
('REV020', 'RC012', 3),
('REV021', 'RC020', 5),
('REV021', 'RC009', 3),
('REV021', 'RC005', 5),
('REV022', 'RC002', 3),
('REV022', 'RC010', 5),
('REV022', 'RC015', 4),
('REV023', 'RC005', 4),
('REV023', 'RC003', 5),
('REV023', 'RC010', 4),
('REV024', 'RC006', 5),
('REV024', 'RC007', 4),
('REV024', 'RC005', 5),
('REV025', 'RC017', 4),
('REV025', 'RC009', 4),
('REV025', 'RC006', 4),
('REV026', 'RC011', 3),
('REV026', 'RC004', 3),
('REV026', 'RC015', 3),
('REV027', 'RC013', 3),
('REV027', 'RC018', 4),
('REV027', 'RC012', 3),
('REV028', 'RC009', 4),
('REV028', 'RC018', 4),
('REV028', 'RC004', 5),
('REV029', 'RC009', 5),
('REV029', 'RC019', 4),
('REV029', 'RC013', 3),
('REV030', 'RC008', 5),
('REV030', 'RC016', 5),
('REV030', 'RC001', 4);

-- 30 rows
INSERT INTO `message` (`msg_id`, `sender_id`, `receiver_id`, `booking_id`, `body`, `sent_at`, `is_read`) VALUES
('MSG001', 'USR021', 'USR001', NULL, 'Hi! Is the place available for my dates?', '2026-10-08 18:04:00', 1),
('MSG002', 'USR002', 'USR022', 'BKG002', 'Yes, it is available. Looking forward to hosting you!', '2026-11-15 19:19:00', 0),
('MSG003', 'USR023', 'USR003', 'BKG003', 'What time can I check in?', '2026-11-14 09:08:00', 1),
('MSG004', 'USR004', 'USR024', NULL, 'Check-in is from 3 PM, I''ll send the key details.', '2026-01-02 12:31:00', 0),
('MSG005', 'USR025', 'USR005', 'BKG005', 'Thank you, see you soon!', '2026-02-04 11:56:00', 1),
('MSG006', 'USR006', 'USR026', 'BKG006', 'Could you recommend places to eat nearby?', '2026-09-05 14:29:00', 0),
('MSG007', 'USR027', 'USR007', NULL, 'Hi! Is the place available for my dates?', '2026-06-22 19:44:00', 1),
('MSG008', 'USR008', 'USR028', 'BKG008', 'Yes, it is available. Looking forward to hosting you!', '2026-09-14 17:47:00', 0),
('MSG009', 'USR029', 'USR009', 'BKG009', 'What time can I check in?', '2026-03-14 18:06:00', 1),
('MSG010', 'USR010', 'USR030', NULL, 'Check-in is from 3 PM, I''ll send the key details.', '2026-08-20 14:17:00', 0),
('MSG011', 'USR031', 'USR011', 'BKG011', 'Thank you, see you soon!', '2026-01-23 13:13:00', 1),
('MSG012', 'USR012', 'USR032', 'BKG012', 'Could you recommend places to eat nearby?', '2026-08-15 11:54:00', 0),
('MSG013', 'USR033', 'USR013', NULL, 'Hi! Is the place available for my dates?', '2026-06-04 18:23:00', 1),
('MSG014', 'USR014', 'USR034', 'BKG014', 'Yes, it is available. Looking forward to hosting you!', '2026-09-21 13:03:00', 0),
('MSG015', 'USR035', 'USR015', 'BKG015', 'What time can I check in?', '2026-07-09 11:07:00', 1),
('MSG016', 'USR016', 'USR036', NULL, 'Check-in is from 3 PM, I''ll send the key details.', '2026-08-03 18:13:00', 0),
('MSG017', 'USR037', 'USR017', 'BKG017', 'Thank you, see you soon!', '2026-11-21 17:01:00', 1),
('MSG018', 'USR018', 'USR038', 'BKG018', 'Could you recommend places to eat nearby?', '2026-01-11 11:08:00', 0),
('MSG019', 'USR039', 'USR019', NULL, 'Hi! Is the place available for my dates?', '2026-10-07 09:53:00', 1),
('MSG020', 'USR020', 'USR040', 'BKG020', 'Yes, it is available. Looking forward to hosting you!', '2026-09-07 17:13:00', 0),
('MSG021', 'USR041', 'USR042', 'BKG021', 'What time can I check in?', '2026-04-11 20:09:00', 1),
('MSG022', 'USR043', 'USR042', NULL, 'Check-in is from 3 PM, I''ll send the key details.', '2026-10-01 12:54:00', 0),
('MSG023', 'USR043', 'USR001', 'BKG023', 'Thank you, see you soon!', '2026-03-05 16:16:00', 1),
('MSG024', 'USR001', 'USR021', 'BKG024', 'Could you recommend places to eat nearby?', '2026-03-04 18:55:00', 0),
('MSG025', 'USR021', 'USR001', NULL, 'Hi! Is the place available for my dates?', '2026-01-05 08:22:00', 1),
('MSG026', 'USR002', 'USR022', 'BKG002', 'Yes, it is available. Looking forward to hosting you!', '2026-04-19 13:01:00', 0),
('MSG027', 'USR023', 'USR003', 'BKG003', 'What time can I check in?', '2026-03-09 08:08:00', 1),
('MSG028', 'USR004', 'USR024', NULL, 'Check-in is from 3 PM, I''ll send the key details.', '2026-07-17 09:47:00', 0),
('MSG029', 'USR025', 'USR005', 'BKG005', 'Thank you, see you soon!', '2026-02-16 15:49:00', 1),
('MSG030', 'USR006', 'USR026', 'BKG006', 'Could you recommend places to eat nearby?', '2026-06-17 17:06:00', 0);

-- 24 rows
INSERT INTO `wishlist` (`wishlist_id`, `guest_id`, `name`, `created_at`) VALUES
('WL001', 'GST001', 'Summer trip', '2025-08-17 09:00:00'),
('WL002', 'GST002', 'Weekend getaways', '2025-04-20 09:00:00'),
('WL003', 'GST003', 'Dream stays', '2025-01-24 09:00:00'),
('WL004', 'GST004', 'City breaks', '2025-11-17 09:00:00'),
('WL005', 'GST005', 'Bucket list', '2025-05-15 09:00:00'),
('WL006', 'GST006', 'Family holiday', '2025-11-01 09:00:00'),
('WL007', 'GST007', 'Summer trip', '2025-01-16 09:00:00'),
('WL008', 'GST008', 'Weekend getaways', '2025-07-14 09:00:00'),
('WL009', 'GST009', 'Dream stays', '2025-11-04 09:00:00'),
('WL010', 'GST010', 'City breaks', '2025-08-23 09:00:00'),
('WL011', 'GST011', 'Bucket list', '2025-08-03 09:00:00'),
('WL012', 'GST012', 'Family holiday', '2025-02-11 09:00:00'),
('WL013', 'GST013', 'Summer trip', '2025-10-05 09:00:00'),
('WL014', 'GST014', 'Weekend getaways', '2025-02-05 09:00:00'),
('WL015', 'GST015', 'Dream stays', '2025-05-20 09:00:00'),
('WL016', 'GST016', 'City breaks', '2025-11-19 09:00:00'),
('WL017', 'GST017', 'Bucket list', '2025-09-23 09:00:00'),
('WL018', 'GST018', 'Family holiday', '2025-06-13 09:00:00'),
('WL019', 'GST019', 'Summer trip', '2025-10-17 09:00:00'),
('WL020', 'GST020', 'Weekend getaways', '2025-05-15 09:00:00'),
('WL021', 'GST021', 'Dream stays', '2025-09-20 09:00:00'),
('WL022', 'GST022', 'City breaks', '2025-07-04 09:00:00'),
('WL023', 'GST023', 'Bucket list', '2025-12-04 09:00:00'),
('WL024', 'GST001', 'Family holiday', '2025-11-21 09:00:00');

-- 48 rows
INSERT INTO `wishlistitem` (`wishlist_id`, `listing_id`, `added_at`) VALUES
('WL001', 'LST001', '2025-09-24 09:30:00'),
('WL001', 'LST002', '2025-04-14 09:30:00'),
('WL002', 'LST003', '2025-08-08 09:30:00'),
('WL002', 'LST004', '2025-07-11 09:30:00'),
('WL003', 'LST005', '2025-08-13 09:30:00'),
('WL003', 'LST006', '2025-07-24 09:30:00'),
('WL004', 'LST007', '2025-02-11 09:30:00'),
('WL004', 'LST008', '2025-07-11 09:30:00'),
('WL005', 'LST009', '2025-11-09 09:30:00'),
('WL005', 'LST010', '2025-06-05 09:30:00'),
('WL006', 'LST011', '2025-11-16 09:30:00'),
('WL006', 'LST012', '2025-02-03 09:30:00'),
('WL007', 'LST013', '2025-02-03 09:30:00'),
('WL007', 'LST014', '2025-07-04 09:30:00'),
('WL008', 'LST015', '2025-12-24 09:30:00'),
('WL008', 'LST016', '2025-06-26 09:30:00'),
('WL009', 'LST017', '2025-03-18 09:30:00'),
('WL009', 'LST018', '2025-01-19 09:30:00'),
('WL010', 'LST019', '2025-09-18 09:30:00'),
('WL010', 'LST020', '2025-06-22 09:30:00'),
('WL011', 'LST021', '2025-02-14 09:30:00'),
('WL011', 'LST022', '2025-06-28 09:30:00'),
('WL012', 'LST023', '2025-11-25 09:30:00'),
('WL012', 'LST024', '2025-07-28 09:30:00'),
('WL013', 'LST001', '2025-12-02 09:30:00'),
('WL013', 'LST002', '2025-05-20 09:30:00'),
('WL014', 'LST003', '2025-05-12 09:30:00'),
('WL014', 'LST004', '2025-02-19 09:30:00'),
('WL015', 'LST005', '2025-09-07 09:30:00'),
('WL015', 'LST006', '2025-03-22 09:30:00'),
('WL016', 'LST007', '2025-08-08 09:30:00'),
('WL016', 'LST008', '2025-02-12 09:30:00'),
('WL017', 'LST009', '2025-09-12 09:30:00'),
('WL017', 'LST010', '2025-02-25 09:30:00'),
('WL018', 'LST011', '2025-05-19 09:30:00'),
('WL018', 'LST012', '2025-04-26 09:30:00'),
('WL019', 'LST013', '2025-07-28 09:30:00'),
('WL019', 'LST014', '2025-09-25 09:30:00'),
('WL020', 'LST015', '2025-10-20 09:30:00'),
('WL020', 'LST016', '2025-11-21 09:30:00'),
('WL021', 'LST017', '2025-09-01 09:30:00'),
('WL021', 'LST018', '2025-10-22 09:30:00'),
('WL022', 'LST019', '2025-12-09 09:30:00'),
('WL022', 'LST020', '2025-01-06 09:30:00'),
('WL023', 'LST021', '2025-05-23 09:30:00'),
('WL023', 'LST022', '2025-05-11 09:30:00'),
('WL024', 'LST023', '2025-06-01 09:30:00'),
('WL024', 'LST024', '2025-03-28 09:30:00');

-- 30 rows
INSERT INTO `userconnection` (`user_id`, `connected_user_id`, `connected_since`) VALUES
('USR010', 'USR037', '2025-11-13'),
('USR005', 'USR010', '2025-12-21'),
('USR002', 'USR006', '2025-12-17'),
('USR014', 'USR025', '2025-07-15'),
('USR022', 'USR011', '2025-06-10'),
('USR021', 'USR037', '2025-10-03'),
('USR004', 'USR010', '2025-03-25'),
('USR040', 'USR004', '2025-11-03'),
('USR018', 'USR029', '2025-11-14'),
('USR032', 'USR039', '2025-08-14'),
('USR018', 'USR014', '2025-09-04'),
('USR023', 'USR028', '2025-02-10'),
('USR038', 'USR032', '2025-09-22'),
('USR020', 'USR003', '2025-04-13'),
('USR039', 'USR004', '2025-01-07'),
('USR020', 'USR014', '2025-03-25'),
('USR017', 'USR019', '2025-06-04'),
('USR001', 'USR032', '2025-12-14'),
('USR012', 'USR009', '2025-07-18'),
('USR015', 'USR033', '2025-09-27'),
('USR043', 'USR023', '2025-02-13'),
('USR003', 'USR028', '2025-01-15'),
('USR005', 'USR021', '2025-10-14'),
('USR037', 'USR026', '2025-12-21'),
('USR027', 'USR019', '2025-02-13'),
('USR002', 'USR021', '2025-03-26'),
('USR040', 'USR030', '2025-12-12'),
('USR006', 'USR028', '2025-02-08'),
('USR028', 'USR038', '2025-07-17'),
('USR006', 'USR026', '2025-05-24');

-- End of inserts.sql


-- =====================================================================
-- =====================================================================
-- ##  PART 3 of 3 : QUERIES (13 validation / test-case queries)      
-- =====================================================================
-- =====================================================================

-- ---------------------------------------------------------------------
-- TEST CASE 1 (primary): end-to-end booking scenario.
-- Traces a booking across guest -> user, listing -> host -> user,
-- payment and payout.  Proves the core business flow is consistent.
-- Joins 8 tables.
-- ---------------------------------------------------------------------
SELECT b.booking_id,
       gu.username         AS guest,
       l.title             AS listing,
       hu.username         AS host,
       b.check_in, b.check_out, b.total_price,
       b.status            AS booking_status,
       pay.amount          AS amount_paid,
       pay.status          AS payment_status,
       po.amount           AS host_payout,
       po.status           AS payout_status
FROM booking b
JOIN guest   g  ON b.guest_id   = g.guest_id
JOIN `user`  gu ON g.user_id    = gu.user_id
JOIN listing l  ON b.listing_id = l.listing_id
JOIN host    h  ON l.host_id    = h.host_id
JOIN `user`  hu ON h.user_id    = hu.user_id
LEFT JOIN payment pay ON pay.booking_id = b.booking_id
LEFT JOIN payout  po  ON po.booking_id  = b.booking_id
ORDER BY b.booking_id
LIMIT 10;

-- ---------------------------------------------------------------------
-- TEST CASE 2: fee breakdown per booking (guest 12% + host 3%),
-- reconciling what the guest paid vs. what the host receives.
-- ---------------------------------------------------------------------
SELECT b.booking_id, b.total_price,
       MAX(CASE WHEN f.fee_type='Guest service fee' THEN f.amount END) AS guest_fee,
       MAX(CASE WHEN f.fee_type='Host service fee'  THEN f.amount END) AS host_fee,
       ROUND(b.total_price + MAX(CASE WHEN f.fee_type='Guest service fee' THEN f.amount END),2) AS guest_pays,
       ROUND(b.total_price - MAX(CASE WHEN f.fee_type='Host service fee'  THEN f.amount END),2) AS host_gets
FROM booking b
JOIN fee f ON f.booking_id = b.booking_id
GROUP BY b.booking_id, b.total_price
ORDER BY b.booking_id
LIMIT 10;

-- ---------------------------------------------------------------------
-- TEST CASE 3: revenue per host (released payouts only).
-- ---------------------------------------------------------------------
SELECT hu.username AS host,
       COUNT(DISTINCT b.booking_id) AS bookings,
       ROUND(SUM(CASE WHEN po.status='RELEASED' THEN po.amount ELSE 0 END),2) AS released_payout
FROM host h
JOIN `user`  hu ON h.user_id    = hu.user_id
JOIN listing l  ON l.host_id    = h.host_id
JOIN booking b  ON b.listing_id = l.listing_id
JOIN payout  po ON po.booking_id= b.booking_id
GROUP BY h.host_id, hu.username
ORDER BY released_payout DESC
LIMIT 10;

-- ---------------------------------------------------------------------
-- TEST CASE 4: bookings and revenue by country and city
-- (booking -> listing -> address -> city -> country).
-- ---------------------------------------------------------------------
SELECT co.country_name, ci.city_name,
       COUNT(b.booking_id) AS bookings,
       ROUND(SUM(b.total_price),2) AS revenue
FROM booking b
JOIN listing l  ON b.listing_id = l.listing_id
JOIN address a  ON l.address_id = a.address_id
JOIN city    ci ON a.city_id    = ci.city_id
JOIN country co ON ci.country_id = co.country_id
GROUP BY co.country_id, ci.city_id
ORDER BY revenue DESC
LIMIT 10;

-- ---------------------------------------------------------------------
-- TEST CASE 5: top guests by total amount actually paid.
-- ---------------------------------------------------------------------
SELECT gu.username AS guest,
       COUNT(p.payment_id) AS payments,
       ROUND(SUM(p.amount),2) AS total_paid
FROM payment p
JOIN booking b  ON p.booking_id = b.booking_id
JOIN guest   g  ON b.guest_id   = g.guest_id
JOIN `user`  gu ON g.user_id    = gu.user_id
WHERE p.status = 'PAID'
GROUP BY g.guest_id, gu.username
ORDER BY total_paid DESC
LIMIT 10;

-- ---------------------------------------------------------------------
-- TEST CASE 6: TERNARY relationship - Review links a Booking to a
-- reviewer (User) and a reviewee (User). Joins review + booking + user twice.
-- ---------------------------------------------------------------------
SELECT r.review_id, b.booking_id,
       ru.username AS reviewer, re.username AS reviewee,
       r.overall_rating, r.review_text
FROM review r
JOIN booking b ON r.booking_id  = b.booking_id
JOIN `user` ru ON r.reviewer_id = ru.user_id
JOIN `user` re ON r.reviewee_id = re.user_id
ORDER BY r.review_id
LIMIT 10;

-- ---------------------------------------------------------------------
-- TEST CASE 7: average score per review category (review -> reviewrating
-- -> reviewcategory).
-- ---------------------------------------------------------------------
SELECT rc.cat_name,
       ROUND(AVG(rr.score),2) AS avg_score,
       COUNT(*) AS num_ratings
FROM reviewrating rr
JOIN reviewcategory rc ON rr.cat_id = rc.cat_id
GROUP BY rc.cat_id, rc.cat_name
ORDER BY avg_score DESC
LIMIT 10;

-- ---------------------------------------------------------------------
-- TEST CASE 8: average guest rating per listing (from reviews).
-- ---------------------------------------------------------------------
SELECT l.title,
       ROUND(AVG(r.overall_rating),2) AS avg_rating,
       COUNT(r.review_id) AS reviews
FROM review r
JOIN booking b ON r.booking_id = b.booking_id
JOIN listing l ON b.listing_id = l.listing_id
GROUP BY l.listing_id, l.title
ORDER BY avg_rating DESC
LIMIT 10;

-- ---------------------------------------------------------------------
-- TEST CASE 9: most-wishlisted listings (M:N wishlist <-> listing).
-- ---------------------------------------------------------------------
SELECT l.title, COUNT(wi.wishlist_id) AS times_wishlisted
FROM wishlistitem wi
JOIN listing l ON wi.listing_id = l.listing_id
GROUP BY l.listing_id, l.title
ORDER BY times_wishlisted DESC
LIMIT 10;

-- ---------------------------------------------------------------------
-- TEST CASE 10: amenity popularity (M:N listing <-> amenity).
-- ---------------------------------------------------------------------
SELECT am.amenity_name, COUNT(la.listing_id) AS listings_offering
FROM listingamenity la
JOIN amenity am ON la.amenity_id = am.amenity_id
GROUP BY am.amenity_id, am.amenity_name
ORDER BY listings_offering DESC
LIMIT 10;

-- ---------------------------------------------------------------------
-- TEST CASE 11: RECURSIVE relationship - a user's social connections
-- (userconnection joins user to user).
-- ---------------------------------------------------------------------
SELECT u1.username AS user, u2.username AS connected_to, uc.connected_since
FROM userconnection uc
JOIN `user` u1 ON uc.user_id           = u1.user_id
JOIN `user` u2 ON uc.connected_user_id = u2.user_id
ORDER BY u1.username
LIMIT 10;

-- ---------------------------------------------------------------------
-- TEST CASE 12: users who act as BOTH host and guest
-- (a user having a row in host AND in guest).
-- ---------------------------------------------------------------------
SELECT u.user_id, u.username, u.role
FROM `user` u
JOIN host  h ON h.user_id = u.user_id
JOIN guest g ON g.user_id = u.user_id
ORDER BY u.user_id;

-- ---------------------------------------------------------------------
-- TEST CASE 13: payment status summary (data-quality overview).
-- ---------------------------------------------------------------------
SELECT status, COUNT(*) AS num_payments, ROUND(SUM(amount),2) AS total_amount
FROM payment
GROUP BY status
ORDER BY num_payments DESC;

-- End of queries.sql
-- =====================================================================
-- =====================================================================
-- End of complete_scenario.sql