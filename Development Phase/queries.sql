-- =====================================================================
-- Project : Build a Data Mart in SQL (DLBDSPBDM01)
-- File    : queries.sql  
-- Test cases / validation queries
-- Run AFTER schema.sql and inserts.sql.
-- Each query is commented with what it validates and which relationships 
-- (incl. the ternary and recursive ones) it exercises.
-- =====================================================================
USE `airbnb_datamart`;

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
