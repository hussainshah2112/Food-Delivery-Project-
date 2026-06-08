--  Online Food Ordering and Delivery Database
--  Group 6: Hussain Shah, Aqsa Aslam, Malik Abdul Rahman,
--            Muhammad Talal, Muhammad Huzaifa
DROP DATABASE IF EXISTS online_food_ordering;
CREATE DATABASE online_food_ordering
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;
USE online_food_ordering;
-- 1. Customers
CREATE TABLE customers (
    customer_id   INT            NOT NULL AUTO_INCREMENT,
    full_name     VARCHAR(100)   NOT NULL,
    email         VARCHAR(150)   NOT NULL UNIQUE,
    phone         VARCHAR(20)    NOT NULL,
    address       VARCHAR(255)   NOT NULL,
    city          VARCHAR(80)    NOT NULL,
    password_hash VARCHAR(255)   NOT NULL,
    is_active     TINYINT(1)     NOT NULL DEFAULT 1,
    created_at    DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (customer_id)
);

-- 2. Restaurants
CREATE TABLE restaurants (
    restaurant_id   INT            NOT NULL AUTO_INCREMENT,
    name            VARCHAR(150)   NOT NULL,
    cuisine_type    VARCHAR(80)    NOT NULL,
    address         VARCHAR(255)   NOT NULL,
    city            VARCHAR(80)    NOT NULL,
    phone           VARCHAR(20)    NOT NULL,
    email           VARCHAR(150)   NOT NULL UNIQUE,
    opening_time    TIME           NOT NULL,
    closing_time    TIME           NOT NULL,
    is_active       TINYINT(1)     NOT NULL DEFAULT 1,
    rating          DECIMAL(3,2)   NOT NULL DEFAULT 0.00,
    created_at      DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (restaurant_id)
);

-- 3. Menu Categories
CREATE TABLE menu_categories (
    category_id   INT           NOT NULL AUTO_INCREMENT,
    restaurant_id INT           NOT NULL,
    name          VARCHAR(100)  NOT NULL,
    description   VARCHAR(255)  NULL,
    PRIMARY KEY (category_id),
    CONSTRAINT fk_cat_restaurant
        FOREIGN KEY (restaurant_id) REFERENCES restaurants(restaurant_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- 4. Menu Items
CREATE TABLE menu_items (
    item_id       INT             NOT NULL AUTO_INCREMENT,
    restaurant_id INT             NOT NULL,
    category_id   INT             NOT NULL,
    name          VARCHAR(150)    NOT NULL,
    description   VARCHAR(500)    NULL,
    price         DECIMAL(8,2)    NOT NULL,
    is_available  TINYINT(1)      NOT NULL DEFAULT 1,
    image_url     VARCHAR(300)    NULL,
    created_at    DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (item_id),
    CONSTRAINT fk_item_restaurant
        FOREIGN KEY (restaurant_id) REFERENCES restaurants(restaurant_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_item_category
        FOREIGN KEY (category_id) REFERENCES menu_categories(category_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_item_price CHECK (price >= 0)
);

-- 5. Delivery Personnel
CREATE TABLE delivery_personnel (
    personnel_id  INT            NOT NULL AUTO_INCREMENT,
    full_name     VARCHAR(100)   NOT NULL,
    phone         VARCHAR(20)    NOT NULL UNIQUE,
    email         VARCHAR(150)   NOT NULL UNIQUE,
    vehicle_type  ENUM('bike','bicycle','car','scooter') NOT NULL DEFAULT 'bike',
    vehicle_no    VARCHAR(30)    NOT NULL,
    is_available  TINYINT(1)     NOT NULL DEFAULT 1,
    rating        DECIMAL(3,2)   NOT NULL DEFAULT 0.00,
    created_at    DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (personnel_id)
);

-- 6. Orders
CREATE TABLE orders (
    order_id         INT            NOT NULL AUTO_INCREMENT,
    customer_id      INT            NOT NULL,
    restaurant_id    INT            NOT NULL,
    personnel_id     INT            NULL,
    order_date       DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    delivery_address VARCHAR(255)   NOT NULL,
    delivery_city    VARCHAR(80)    NOT NULL,
    subtotal         DECIMAL(10,2)  NOT NULL DEFAULT 0.00,
    delivery_fee     DECIMAL(6,2)   NOT NULL DEFAULT 0.00,
    tax_amount       DECIMAL(6,2)   NOT NULL DEFAULT 0.00,
    total_amount     DECIMAL(10,2)  NOT NULL DEFAULT 0.00,
    status           ENUM(
                         'pending',
                         'confirmed',
                         'preparing',
                         'ready_for_pickup',
                         'out_for_delivery',
                         'delivered',
                         'cancelled'
                     ) NOT NULL DEFAULT 'pending',
    payment_method   ENUM('cash','card','online_wallet') NOT NULL DEFAULT 'cash',
    payment_status   ENUM('unpaid','paid','refunded') NOT NULL DEFAULT 'unpaid',
    special_notes    VARCHAR(500)   NULL,
    estimated_delivery_time INT     NULL COMMENT 'minutes',
    delivered_at     DATETIME       NULL,
    PRIMARY KEY (order_id),
    CONSTRAINT fk_order_customer
        FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_order_restaurant
        FOREIGN KEY (restaurant_id) REFERENCES restaurants(restaurant_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_order_personnel
        FOREIGN KEY (personnel_id) REFERENCES delivery_personnel(personnel_id)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT chk_order_subtotal  CHECK (subtotal  >= 0),
    CONSTRAINT chk_order_total     CHECK (total_amount >= 0)
);

-- 7. Order Items (line items)
CREATE TABLE order_items (
    order_item_id INT            NOT NULL AUTO_INCREMENT,
    order_id      INT            NOT NULL,
    item_id       INT            NOT NULL,
    quantity      INT            NOT NULL DEFAULT 1,
    unit_price    DECIMAL(8,2)   NOT NULL,
    line_total    DECIMAL(10,2)  GENERATED ALWAYS AS (quantity * unit_price) STORED,
    special_req   VARCHAR(300)   NULL,
    PRIMARY KEY (order_item_id),
    CONSTRAINT fk_oi_order
        FOREIGN KEY (order_id) REFERENCES orders(order_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_oi_item
        FOREIGN KEY (item_id) REFERENCES menu_items(item_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_oi_qty   CHECK (quantity > 0),
    CONSTRAINT chk_oi_price CHECK (unit_price >= 0)
);

-- 8. Feedback / Reviews
CREATE TABLE feedback (
    feedback_id   INT            NOT NULL AUTO_INCREMENT,
    order_id      INT            NOT NULL UNIQUE,
    customer_id   INT            NOT NULL,
    restaurant_id INT            NOT NULL,
    personnel_id  INT            NULL,
    food_rating   TINYINT        NOT NULL,
    delivery_rating TINYINT      NULL,
    comment       TEXT           NULL,
    created_at    DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (feedback_id),
    CONSTRAINT fk_fb_order
        FOREIGN KEY (order_id) REFERENCES orders(order_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_fb_customer
        FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_fb_restaurant
        FOREIGN KEY (restaurant_id) REFERENCES restaurants(restaurant_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_fb_personnel
        FOREIGN KEY (personnel_id) REFERENCES delivery_personnel(personnel_id)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT chk_food_rating
        CHECK (food_rating BETWEEN 1 AND 5),
    CONSTRAINT chk_delivery_rating
        CHECK (delivery_rating IS NULL OR delivery_rating BETWEEN 1 AND 5)
);
-- INDEXES
CREATE INDEX idx_orders_customer    ON orders(customer_id);
CREATE INDEX idx_orders_restaurant  ON orders(restaurant_id);
CREATE INDEX idx_orders_personnel   ON orders(personnel_id);
CREATE INDEX idx_orders_status      ON orders(status);
CREATE INDEX idx_orders_date        ON orders(order_date);
CREATE INDEX idx_menu_items_rest    ON menu_items(restaurant_id);
CREATE INDEX idx_menu_items_cat     ON menu_items(category_id);
CREATE INDEX idx_feedback_rest      ON feedback(restaurant_id);
CREATE INDEX idx_order_items_order  ON order_items(order_id);
-- View 1: Full Customer Order History
CREATE VIEW vw_customer_order_history AS
SELECT
    c.customer_id,
    c.full_name                          AS customer_name,
    c.email                              AS customer_email,
    o.order_id,
    o.order_date,
    r.name                               AS restaurant_name,
    r.cuisine_type,
    o.subtotal,
    o.delivery_fee,
    o.tax_amount,
    o.total_amount,
    o.status                             AS order_status,
    o.payment_method,
    o.payment_status,
    o.delivery_address,
    dp.full_name                         AS delivery_person,
    o.delivered_at,
    o.special_notes
FROM orders o
JOIN customers    c  ON c.customer_id   = o.customer_id
JOIN restaurants  r  ON r.restaurant_id = o.restaurant_id
LEFT JOIN delivery_personnel dp ON dp.personnel_id = o.personnel_id;

-- View 2: Order Details with Items
CREATE VIEW vw_order_details AS
SELECT
    o.order_id,
    o.order_date,
    c.full_name   AS customer_name,
    r.name        AS restaurant_name,
    mi.name       AS item_name,
    oi.quantity,
    oi.unit_price,
    oi.line_total,
    oi.special_req,
    o.status,
    o.total_amount,
    o.delivery_address
FROM order_items oi
JOIN orders      o  ON o.order_id     = oi.order_id
JOIN menu_items  mi ON mi.item_id     = oi.item_id
JOIN customers   c  ON c.customer_id  = o.customer_id
JOIN restaurants r  ON r.restaurant_id= o.restaurant_id;

-- View 3: Restaurant Ratings Summary
CREATE VIEW vw_restaurant_ratings AS
SELECT
    r.restaurant_id,
    r.name                              AS restaurant_name,
    r.cuisine_type,
    COUNT(DISTINCT o.order_id)          AS total_orders,
    COUNT(f.feedback_id)                AS total_reviews,
    ROUND(AVG(f.food_rating), 2)        AS avg_food_rating,
    ROUND(AVG(f.delivery_rating), 2)    AS avg_delivery_rating
FROM restaurants r
LEFT JOIN orders   o ON o.restaurant_id = r.restaurant_id
LEFT JOIN feedback f ON f.restaurant_id = r.restaurant_id
GROUP BY r.restaurant_id, r.name, r.cuisine_type;

-- View 4: Delivery Personnel Performance
CREATE VIEW vw_delivery_performance AS
SELECT
    dp.personnel_id,
    dp.full_name                        AS personnel_name,
    dp.vehicle_type,
    COUNT(o.order_id)                   AS total_deliveries,
    ROUND(AVG(f.delivery_rating), 2)    AS avg_rating,
    SUM(CASE WHEN o.status = 'delivered' THEN 1 ELSE 0 END) AS completed
FROM delivery_personnel dp
LEFT JOIN orders   o ON o.personnel_id  = dp.personnel_id
LEFT JOIN feedback f ON f.personnel_id  = dp.personnel_id
GROUP BY dp.personnel_id, dp.full_name, dp.vehicle_type;
-- STORED PROCEDURES
DELIMITER $$

-- SP 1: Place a new order
CREATE PROCEDURE sp_place_order(
    IN  p_customer_id       INT,
    IN  p_restaurant_id     INT,
    IN  p_delivery_address  VARCHAR(255),
    IN  p_delivery_city     VARCHAR(80),
    IN  p_payment_method    VARCHAR(20),
    IN  p_special_notes     VARCHAR(500),
    OUT p_order_id          INT
)
BEGIN
    DECLARE v_delivery_fee DECIMAL(6,2) DEFAULT 50.00;

    INSERT INTO orders (
        customer_id, restaurant_id, delivery_address,
        delivery_city, delivery_fee, payment_method, special_notes, status
    ) VALUES (
        p_customer_id, p_restaurant_id, p_delivery_address,
        p_delivery_city, v_delivery_fee, p_payment_method, p_special_notes, 'pending'
    );

    SET p_order_id = LAST_INSERT_ID();
END$$

-- SP 2: Add item to an order
CREATE PROCEDURE sp_add_order_item(
    IN p_order_id   INT,
    IN p_item_id    INT,
    IN p_quantity   INT,
    IN p_special_req VARCHAR(300)
)
BEGIN
    DECLARE v_price  DECIMAL(8,2);
    DECLARE v_status VARCHAR(30);

    SELECT status INTO v_status FROM orders WHERE order_id = p_order_id;

    IF v_status NOT IN ('pending','confirmed') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot add items to an order that is not pending or confirmed.';
    END IF;

    SELECT price INTO v_price FROM menu_items WHERE item_id = p_item_id AND is_available = 1;

    IF v_price IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Menu item not found or not available.';
    END IF;

    INSERT INTO order_items (order_id, item_id, quantity, unit_price, special_req)
    VALUES (p_order_id, p_item_id, p_quantity, v_price, p_special_req);

    -- Recalculate order totals
    CALL sp_recalculate_order_total(p_order_id);
END$$

-- SP 3: Recalculate order total (internal helper)
CREATE PROCEDURE sp_recalculate_order_total(IN p_order_id INT)
BEGIN
    DECLARE v_subtotal    DECIMAL(10,2);
    DECLARE v_delivery    DECIMAL(6,2);
    DECLARE v_tax         DECIMAL(6,2);
    DECLARE v_total       DECIMAL(10,2);

    SELECT SUM(line_total)
    INTO   v_subtotal
    FROM   order_items
    WHERE  order_id = p_order_id;

    SET v_subtotal = COALESCE(v_subtotal, 0);

    SELECT delivery_fee INTO v_delivery FROM orders WHERE order_id = p_order_id;

    SET v_tax   = ROUND(v_subtotal * 0.05, 2);   -- 5% tax
    SET v_total = v_subtotal + v_delivery + v_tax;

    UPDATE orders
    SET subtotal     = v_subtotal,
        tax_amount   = v_tax,
        total_amount = v_total
    WHERE order_id   = p_order_id;
END$$

-- SP 4: Update order status
CREATE PROCEDURE sp_update_order_status(
    IN p_order_id  INT,
    IN p_new_status VARCHAR(30)
)
BEGIN
    DECLARE v_current VARCHAR(30);

    SELECT status INTO v_current FROM orders WHERE order_id = p_order_id;

    IF v_current IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Order not found.';
    END IF;

    -- Validate allowed transitions
    IF (v_current = 'pending'           AND p_new_status NOT IN ('confirmed','cancelled'))
    OR (v_current = 'confirmed'         AND p_new_status NOT IN ('preparing','cancelled'))
    OR (v_current = 'preparing'         AND p_new_status NOT IN ('ready_for_pickup','cancelled'))
    OR (v_current = 'ready_for_pickup'  AND p_new_status NOT IN ('out_for_delivery'))
    OR (v_current = 'out_for_delivery'  AND p_new_status NOT IN ('delivered'))
    OR (v_current IN ('delivered','cancelled'))
    THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Invalid order status transition.';
    END IF;

    UPDATE orders
    SET status       = p_new_status,
        delivered_at = CASE WHEN p_new_status = 'delivered' THEN NOW() ELSE delivered_at END
    WHERE order_id   = p_order_id;
END$$

-- SP 5: Assign delivery personnel to an order
CREATE PROCEDURE sp_assign_delivery(
    IN p_order_id     INT,
    IN p_personnel_id INT
)
BEGIN
    DECLARE v_avail TINYINT;

    SELECT is_available INTO v_avail
    FROM delivery_personnel WHERE personnel_id = p_personnel_id;

    IF v_avail IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Delivery personnel not found.';
    END IF;

    IF v_avail = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Delivery personnel is not available.';
    END IF;

    UPDATE orders
    SET personnel_id = p_personnel_id
    WHERE order_id   = p_order_id;

    UPDATE delivery_personnel
    SET is_available = 0
    WHERE personnel_id = p_personnel_id;
END$$

-- SP 6: Submit feedback
CREATE PROCEDURE sp_submit_feedback(
    IN p_order_id        INT,
    IN p_customer_id     INT,
    IN p_food_rating     TINYINT,
    IN p_delivery_rating TINYINT,
    IN p_comment         TEXT
)
BEGIN
    DECLARE v_restaurant_id INT;
    DECLARE v_personnel_id  INT;
    DECLARE v_status        VARCHAR(30);

    SELECT restaurant_id, personnel_id, status
    INTO   v_restaurant_id, v_personnel_id, v_status
    FROM   orders
    WHERE  order_id    = p_order_id
      AND  customer_id = p_customer_id;

    IF v_restaurant_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Order not found or does not belong to this customer.';
    END IF;

    IF v_status <> 'delivered' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Feedback can only be submitted for delivered orders.';
    END IF;

    INSERT INTO feedback (
        order_id, customer_id, restaurant_id, personnel_id,
        food_rating, delivery_rating, comment
    ) VALUES (
        p_order_id, p_customer_id, v_restaurant_id, v_personnel_id,
        p_food_rating, p_delivery_rating, p_comment
    );

    -- Refresh restaurant average rating
    UPDATE restaurants r
    SET r.rating = (
        SELECT ROUND(AVG(f.food_rating), 2)
        FROM feedback f
        WHERE f.restaurant_id = r.restaurant_id
    )
    WHERE r.restaurant_id = v_restaurant_id;

    -- Refresh delivery personnel average rating
    IF v_personnel_id IS NOT NULL THEN
        UPDATE delivery_personnel dp
        SET dp.rating = (
            SELECT ROUND(AVG(f.delivery_rating), 2)
            FROM feedback f
            WHERE f.personnel_id = dp.personnel_id
              AND f.delivery_rating IS NOT NULL
        )
        WHERE dp.personnel_id = v_personnel_id;
    END IF;
END$$

-- SP 7: Get active menu for a restaurant
CREATE PROCEDURE sp_get_menu(IN p_restaurant_id INT)
BEGIN
    SELECT
        mc.name  AS category,
        mi.item_id,
        mi.name  AS item_name,
        mi.description,
        mi.price,
        mi.image_url
    FROM menu_items mi
    JOIN menu_categories mc ON mc.category_id = mi.category_id
    WHERE mi.restaurant_id = p_restaurant_id
      AND mi.is_available  = 1
    ORDER BY mc.name, mi.name;
END$$

-- SP 8: Cancel an order (customer)
CREATE PROCEDURE sp_cancel_order(
    IN p_order_id    INT,
    IN p_customer_id INT
)
BEGIN
    DECLARE v_status     VARCHAR(30);
    DECLARE v_personnel  INT;

    SELECT status, personnel_id
    INTO   v_status, v_personnel
    FROM   orders
    WHERE  order_id    = p_order_id
      AND  customer_id = p_customer_id;

    IF v_status IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Order not found.';
    END IF;

    IF v_status NOT IN ('pending','confirmed') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Order cannot be cancelled at this stage.';
    END IF;

    UPDATE orders
    SET status = 'cancelled'
    WHERE order_id = p_order_id;

    -- Free up delivery personnel if already assigned
    IF v_personnel IS NOT NULL THEN
        UPDATE delivery_personnel
        SET is_available = 1
        WHERE personnel_id = v_personnel;
    END IF;
END$$

DELIMITER ;
-- SAMPLE DATA
-- Customers
INSERT INTO customers (full_name, email, phone, address, city, password_hash) VALUES
('Ali Hassan',        'ali.hassan@gmail.com',    '0300-1234567', 'House 12, Block A, Gulshan',  'Karachi',   SHA2('pass1234', 256)),
('Sara Ahmed',        'sara.ahmed@gmail.com',    '0301-2345678', 'Flat 5, F-7/2',               'Islamabad', SHA2('pass1234', 256)),
('Usman Tariq',       'usman.tariq@yahoo.com',   '0302-3456789', 'Street 9, DHA Phase 3',       'Lahore',    SHA2('pass1234', 256)),
('Fatima Malik',      'fatima.malik@gmail.com',  '0303-4567890', 'Plot 44, Johar Town',         'Lahore',    SHA2('pass1234', 256)),
('Bilal Qureshi',     'bilal.q@hotmail.com',     '0304-5678901', 'House 7, Satellite Town',     'Rawalpindi',SHA2('pass1234', 256)),
('Nadia Siddiqui',    'nadia.s@gmail.com',       '0305-6789012', 'Flat 3B, Clifton Block 2',    'Karachi',   SHA2('pass1234', 256));

-- Restaurants
INSERT INTO restaurants (name, cuisine_type, address, city, phone, email, opening_time, closing_time) VALUES
('Burning Brownie',     'Fast Food',         '23 Main Blvd, Gulshan',       'Karachi',    '021-11122233', 'info@burningbrownie.com',  '09:00:00', '23:00:00'),
('Spice Garden',        'Pakistani/Desi',    '7 Mall Road',                 'Lahore',     '042-33344455', 'info@spicegarden.com',     '11:00:00', '24:00:00'),
('Pizza Point',         'Italian',           'F-10 Markaz',                 'Islamabad',  '051-55566677', 'info@pizzapoint.com',      '10:00:00', '23:30:00'),
('Wok Express',         'Chinese',           '18 Tariq Road',               'Karachi',    '021-99988877', 'info@wokexpress.com',      '12:00:00', '23:00:00'),
('Desi Delight',        'Pakistani/Desi',    '5 Cantt Road',                'Rawalpindi', '051-22233344', 'info@desidelight.com',     '11:30:00', '22:30:00');

-- Menu Categories
INSERT INTO menu_categories (restaurant_id, name, description) VALUES
(1, 'Burgers',      'Signature smash burgers'),
(1, 'Desserts',     'Brownies, shakes and more'),
(2, 'Karahi',       'Traditional karahi dishes'),
(2, 'Biryani',      'Dum-cooked rice dishes'),
(3, 'Pizzas',       'Wood-fired style pizzas'),
(3, 'Pasta',        'Classic Italian pasta'),
(4, 'Rice Dishes',  'Fried rice and noodles'),
(4, 'Soups',        'Hot and sour, corn soup'),
(5, 'Tikka & BBQ',  'Charcoal-grilled specialties'),
(5, 'Nihari',       'Slow-cooked stews');

-- Menu Items
INSERT INTO menu_items (restaurant_id, category_id, name, description, price) VALUES
-- Burning Brownie
(1, 1,  'Classic Smash Burger',      'Double patty, cheese, pickles',              350.00),
(1, 1,  'Crispy Chicken Burger',     'Crispy fried chicken fillet',                320.00),
(1, 2,  'Original Brownie',          'Warm chocolate fudge brownie',               180.00),
(1, 2,  'Nutella Shake',             'Thick milkshake with Nutella',               250.00),
-- Spice Garden
(2, 3,  'Chicken Karahi',            'Tomato-based karahi with naan',              650.00),
(2, 3,  'Mutton Karahi',             'Tender mutton in spiced gravy',              950.00),
(2, 4,  'Chicken Biryani (Full)',    'Aromatic dum biryani – serves 2',            700.00),
(2, 4,  'Beef Biryani (Half)',       'Slow-cooked beef biryani',                   450.00),
-- Pizza Point
(3, 5,  'Margherita Pizza (12")',    'Classic tomato and mozzarella',              800.00),
(3, 5,  'BBQ Chicken Pizza (12")',   'Smoky BBQ sauce, grilled chicken',           950.00),
(3, 6,  'Pasta Arrabbiata',         'Penne in spicy tomato sauce',                550.00),
(3, 6,  'Pasta Alfredo',            'Fettuccine in creamy white sauce',            600.00),
-- Wok Express
(4, 7,  'Chicken Fried Rice',        'Classic wok-tossed fried rice',              400.00),
(4, 7,  'Beef Chow Mein',           'Stir-fried noodles with beef',               450.00),
(4, 8,  'Hot & Sour Soup',          'Tangy spicy broth with egg',                 250.00),
-- Desi Delight
(5, 9,  'Chicken Tikka (6 pcs)',    'Char-grilled marinated tikka',               550.00),
(5, 9,  'Seekh Kabab (4 pcs)',      'Minced beef seekh on charcoal',              400.00),
(5, 10, 'Nihari (1 kg)',            'Slow-cooked beef nihari with naan',           750.00);

-- Delivery Personnel
INSERT INTO delivery_personnel (full_name, phone, email, vehicle_type, vehicle_no) VALUES
('Kamran Raza',   '0311-1111111', 'kamran@delivery.com',  'bike',   'KHI-ABC-111'),
('Shahid Nawaz',  '0312-2222222', 'shahid@delivery.com',  'bike',   'LHR-XYZ-222'),
('Imran Javed',   '0313-3333333', 'imran@delivery.com',   'scooter','ISB-DEF-333'),
('Asif Mehmood',  '0314-4444444', 'asif@delivery.com',    'bike',   'RWP-GHI-444'),
('Tariq Hussain', '0315-5555555', 'tariq@delivery.com',   'bicycle','KHI-JKL-555');

-- Orders (using direct inserts for sample data)
INSERT INTO orders (customer_id, restaurant_id, personnel_id, delivery_address, delivery_city,
                    subtotal, delivery_fee, tax_amount, total_amount, status, payment_method,
                    payment_status, delivered_at) VALUES
(1, 1, 1, 'House 12, Block A, Gulshan',  'Karachi',    670.00, 50.00, 33.50,  753.50, 'delivered',         'cash',           'paid',   NOW() - INTERVAL 5 DAY),
(2, 3, 3, 'Flat 5, F-7/2',               'Islamabad',  800.00, 50.00, 40.00,  890.00, 'delivered',         'online_wallet',  'paid',   NOW() - INTERVAL 3 DAY),
(3, 2, 2, 'Street 9, DHA Phase 3',       'Lahore',    1350.00, 50.00, 67.50, 1467.50, 'delivered',         'card',           'paid',   NOW() - INTERVAL 2 DAY),
(4, 2, 2, 'Plot 44, Johar Town',         'Lahore',    1150.00, 50.00, 57.50, 1257.50, 'out_for_delivery',  'cash',           'unpaid', NULL),
(5, 5, 4, 'House 7, Satellite Town',     'Rawalpindi',  950.00, 50.00, 47.50, 1047.50, 'preparing',        'cash',           'unpaid', NULL),
(6, 4, NULL,'Flat 3B, Clifton Block 2',  'Karachi',    850.00, 50.00, 42.50,  942.50, 'pending',           'card',           'unpaid', NULL);

-- Order Items
INSERT INTO order_items (order_id, item_id, quantity, unit_price, special_req) VALUES
(1, 1,  1, 350.00, NULL),
(1, 2,  1, 320.00, 'No pickles'),
(2, 9,  1, 800.00, 'Extra cheese'),
(3, 5,  1, 650.00, NULL),
(3, 7,  1, 700.00, 'Extra spicy'),
(4, 6,  1, 950.00, NULL),
(4, 8,  1, 450.00, 'Less rice'),
(5, 16, 1, 550.00, 'Well done'),
(5, 18, 1, 750.00, NULL),
(6, 13, 2, 400.00, 'Less soy sauce'),
(6, 15, 1, 250.00, NULL);

-- Feedback
INSERT INTO feedback (order_id, customer_id, restaurant_id, personnel_id, food_rating, delivery_rating, comment) VALUES
(1, 1, 1, 1, 5, 5, 'Burgers were amazing, fast delivery!'),
(2, 2, 3, 3, 4, 4, 'Good pizza, slightly late delivery.'),
(3, 3, 2, 2, 5, 5, 'Best karahi in Lahore, will order again.');
-- TEST / VERIFICATION QUERIES

-- Check all tables
SELECT 'customers'          AS tbl, COUNT(*) AS rows FROM customers
UNION ALL
SELECT 'restaurants',        COUNT(*) FROM restaurants
UNION ALL
SELECT 'menu_categories',    COUNT(*) FROM menu_categories
UNION ALL
SELECT 'menu_items',         COUNT(*) FROM menu_items
UNION ALL
SELECT 'delivery_personnel', COUNT(*) FROM delivery_personnel
UNION ALL
SELECT 'orders',             COUNT(*) FROM orders
UNION ALL
SELECT 'order_items',        COUNT(*) FROM order_items
UNION ALL
SELECT 'feedback',           COUNT(*) FROM feedback;

-- Test stored procedure: place a new order
CALL sp_place_order(1, 4, 'House 12, Gulshan, Karachi', 'Karachi', 'cash', 'Extra soy sauce', @new_order);
SELECT @new_order AS new_order_id;

CALL sp_add_order_item(@new_order, 14, 2, NULL);  -- 2x Beef Chow Mein
CALL sp_add_order_item(@new_order, 15, 1, NULL);  -- 1x Hot & Sour Soup

-- Check the new order
SELECT order_id, subtotal, delivery_fee, tax_amount, total_amount, status
FROM orders WHERE order_id = @new_order;

-- Update status flow
CALL sp_update_order_status(@new_order, 'confirmed');
CALL sp_assign_delivery(@new_order, 5);            -- Assign Tariq Hussain
CALL sp_update_order_status(@new_order, 'preparing');

-- Test views
SELECT * FROM vw_customer_order_history  WHERE customer_id = 1  LIMIT 5;
SELECT * FROM vw_order_details           WHERE order_id    = 1;
SELECT * FROM vw_restaurant_ratings      ORDER BY avg_food_rating DESC;
SELECT * FROM vw_delivery_performance    ORDER BY total_deliveries DESC;

-- Test menu procedure
CALL sp_get_menu(2);   -- Spice Garden menu

SELECT '=== Database setup complete ===' AS message;
