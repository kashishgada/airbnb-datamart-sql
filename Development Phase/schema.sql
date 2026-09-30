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
