# Online Food Ordering and Delivery Database

> **Course Project — Database Management Systems**
> Group 6 | MySQL

---

## Group Members

| Name | Role |
|------|------|
| Hussain Shah | Admin / Group Lead |
| Aqsa Aslam | Member |
| Malik Abdul Rahman | Member |
| Muhammad Talal | Member |
| Muhammad Huzaifa | Member |

---

## Project Overview

This project implements a fully normalized relational database for an **Online Food Ordering and Delivery System**. The system models the complete lifecycle of a food order — from a customer browsing a restaurant's menu, placing an order, having it prepared and delivered, through to submitting feedback.

The database is built entirely in **MySQL** and includes tables, indexes, views, and stored procedures as required by the project brief.

---

## Database: `online_food_ordering`

- **Character Set:** `utf8mb4`
- **Collation:** `utf8mb4_unicode_ci`
- **Total Tables:** 8
- **Total Views:** 4
- **Total Stored Procedures:** 8
- **Total Indexes:** 9

---

## Schema — Tables

### 1. `customers`
Stores registered customer accounts.

| Column | Type | Description |
|--------|------|-------------|
| `customer_id` | INT (PK) | Auto-increment primary key |
| `full_name` | VARCHAR(100) | Customer's full name |
| `email` | VARCHAR(150) | Unique email address |
| `phone` | VARCHAR(20) | Contact number |
| `address` | VARCHAR(255) | Delivery address |
| `city` | VARCHAR(80) | City |
| `password_hash` | VARCHAR(255) | SHA-256 hashed password |
| `is_active` | TINYINT(1) | Account status (1 = active) |
| `created_at` | DATETIME | Registration timestamp |

---

### 2. `restaurants`
Stores restaurant profiles and operating details.

| Column | Type | Description |
|--------|------|-------------|
| `restaurant_id` | INT (PK) | Auto-increment primary key |
| `name` | VARCHAR(150) | Restaurant name |
| `cuisine_type` | VARCHAR(80) | Type of cuisine |
| `address` | VARCHAR(255) | Physical address |
| `city` | VARCHAR(80) | City |
| `phone` | VARCHAR(20) | Contact number |
| `email` | VARCHAR(150) | Unique email |
| `opening_time` | TIME | Daily opening time |
| `closing_time` | TIME | Daily closing time |
| `is_active` | TINYINT(1) | Active status |
| `rating` | DECIMAL(3,2) | Average customer rating |
| `created_at` | DATETIME | Registration timestamp |

---

### 3. `menu_categories`
Groups menu items into categories per restaurant (e.g., Burgers, Biryani, Desserts).

| Column | Type | Description |
|--------|------|-------------|
| `category_id` | INT (PK) | Auto-increment primary key |
| `restaurant_id` | INT (FK) | References `restaurants` |
| `name` | VARCHAR(100) | Category name |
| `description` | VARCHAR(255) | Optional description |

---

### 4. `menu_items`
Individual food/drink items offered by a restaurant.

| Column | Type | Description |
|--------|------|-------------|
| `item_id` | INT (PK) | Auto-increment primary key |
| `restaurant_id` | INT (FK) | References `restaurants` |
| `category_id` | INT (FK) | References `menu_categories` |
| `name` | VARCHAR(150) | Item name |
| `description` | VARCHAR(500) | Item description |
| `price` | DECIMAL(8,2) | Price (must be ≥ 0) |
| `is_available` | TINYINT(1) | Availability flag |
| `image_url` | VARCHAR(300) | Optional image URL |
| `created_at` | DATETIME | Date added |

---

### 5. `delivery_personnel`
Riders and drivers who fulfill deliveries.

| Column | Type | Description |
|--------|------|-------------|
| `personnel_id` | INT (PK) | Auto-increment primary key |
| `full_name` | VARCHAR(100) | Full name |
| `phone` | VARCHAR(20) | Unique contact number |
| `email` | VARCHAR(150) | Unique email |
| `vehicle_type` | ENUM | `bike`, `bicycle`, `car`, `scooter` |
| `vehicle_no` | VARCHAR(30) | Vehicle registration number |
| `is_available` | TINYINT(1) | Availability for new deliveries |
| `rating` | DECIMAL(3,2) | Average delivery rating |
| `created_at` | DATETIME | Registration timestamp |

---

### 6. `orders`
Master record for every order placed on the platform.

| Column | Type | Description |
|--------|------|-------------|
| `order_id` | INT (PK) | Auto-increment primary key |
| `customer_id` | INT (FK) | References `customers` |
| `restaurant_id` | INT (FK) | References `restaurants` |
| `personnel_id` | INT (FK, nullable) | References `delivery_personnel` |
| `order_date` | DATETIME | Timestamp of order placement |
| `delivery_address` | VARCHAR(255) | Delivery location |
| `delivery_city` | VARCHAR(80) | Delivery city |
| `subtotal` | DECIMAL(10,2) | Sum of all line items |
| `delivery_fee` | DECIMAL(6,2) | Fixed delivery charge |
| `tax_amount` | DECIMAL(6,2) | 5% tax on subtotal |
| `total_amount` | DECIMAL(10,2) | Grand total |
| `status` | ENUM | See order status flow below |
| `payment_method` | ENUM | `cash`, `card`, `online_wallet` |
| `payment_status` | ENUM | `unpaid`, `paid`, `refunded` |
| `special_notes` | VARCHAR(500) | Customer instructions |
| `estimated_delivery_time` | INT | Estimated time in minutes |
| `delivered_at` | DATETIME | Actual delivery timestamp |

**Order Status Flow:**
```
pending → confirmed → preparing → ready_for_pickup → out_for_delivery → delivered
                ↘ cancelled (allowed from pending or confirmed only)
```

---

### 7. `order_items`
Line items that belong to an order (one row per menu item per order).

| Column | Type | Description |
|--------|------|-------------|
| `order_item_id` | INT (PK) | Auto-increment primary key |
| `order_id` | INT (FK) | References `orders` |
| `item_id` | INT (FK) | References `menu_items` |
| `quantity` | INT | Must be > 0 |
| `unit_price` | DECIMAL(8,2) | Price at time of order |
| `line_total` | DECIMAL(10,2) | Generated: `quantity × unit_price` |
| `special_req` | VARCHAR(300) | Item-level special request |

---

### 8. `feedback`
Customer reviews submitted after a delivered order.

| Column | Type | Description |
|--------|------|-------------|
| `feedback_id` | INT (PK) | Auto-increment primary key |
| `order_id` | INT (FK, UNIQUE) | One review per order |
| `customer_id` | INT (FK) | References `customers` |
| `restaurant_id` | INT (FK) | References `restaurants` |
| `personnel_id` | INT (FK, nullable) | References `delivery_personnel` |
| `food_rating` | TINYINT | 1–5 stars |
| `delivery_rating` | TINYINT | 1–5 stars (optional) |
| `comment` | TEXT | Written review |
| `created_at` | DATETIME | Submission timestamp |

---

## Views

### `vw_customer_order_history`
Returns the complete order history for every customer, joined with restaurant and delivery personnel details. Useful for a customer's "My Orders" page.

```sql
SELECT * FROM vw_customer_order_history WHERE customer_id = 1;
```

---

### `vw_order_details`
Returns a fully itemized breakdown of every order — each row is one line item with its order, customer, restaurant, and item details.

```sql
SELECT * FROM vw_order_details WHERE order_id = 5;
```

---

### `vw_restaurant_ratings`
Aggregates total orders, total reviews, and average food/delivery ratings per restaurant.

```sql
SELECT * FROM vw_restaurant_ratings ORDER BY avg_food_rating DESC;
```

---

### `vw_delivery_performance`
Shows total deliveries, completed deliveries, and average rating per delivery person.

```sql
SELECT * FROM vw_delivery_performance ORDER BY total_deliveries DESC;
```

---

## Stored Procedures

### `sp_place_order`
Creates a new order record. Returns the new `order_id` via an OUT parameter.

```sql
CALL sp_place_order(
    1,                          -- customer_id
    2,                          -- restaurant_id
    'House 12, Gulshan',        -- delivery_address
    'Karachi',                  -- delivery_city
    'cash',                     -- payment_method
    'No onions please',         -- special_notes
    @new_order_id               -- OUT: new order id
);
SELECT @new_order_id;
```

---

### `sp_add_order_item`
Adds a menu item to an existing order and automatically recalculates the order totals. Only works on `pending` or `confirmed` orders.

```sql
CALL sp_add_order_item(@new_order_id, 5, 2, 'Extra spicy');
-- (order_id, item_id, quantity, special_req)
```

---

### `sp_recalculate_order_total`
Internal helper. Recomputes `subtotal`, `tax_amount` (5%), and `total_amount` for a given order. Called automatically by `sp_add_order_item`.

```sql
CALL sp_recalculate_order_total(10);
```

---

### `sp_update_order_status`
Advances an order through the status pipeline. Enforces valid transitions and automatically sets `delivered_at` when status becomes `delivered`.

```sql
CALL sp_update_order_status(10, 'confirmed');
CALL sp_update_order_status(10, 'preparing');
CALL sp_update_order_status(10, 'ready_for_pickup');
CALL sp_update_order_status(10, 'out_for_delivery');
CALL sp_update_order_status(10, 'delivered');
```

---

### `sp_assign_delivery`
Assigns an available delivery person to an order. Automatically marks the personnel as unavailable (`is_available = 0`).

```sql
CALL sp_assign_delivery(10, 3);  -- (order_id, personnel_id)
```

---

### `sp_submit_feedback`
Submits a customer review for a delivered order. Automatically updates the restaurant's average rating and the delivery person's average rating.

```sql
CALL sp_submit_feedback(
    10,                      -- order_id
    1,                       -- customer_id
    5,                       -- food_rating (1-5)
    4,                       -- delivery_rating (1-5, optional)
    'Great food, fast!'      -- comment
);
```

---

### `sp_get_menu`
Returns all available menu items for a restaurant, grouped by category.

```sql
CALL sp_get_menu(2);  -- Get full menu for restaurant_id = 2
```

---

### `sp_cancel_order`
Cancels an order if it is still `pending` or `confirmed`. Frees up the assigned delivery person if one was already assigned.

```sql
CALL sp_cancel_order(10, 1);  -- (order_id, customer_id)
```

---

## Indexes

| Index Name | Table | Column(s) | Purpose |
|------------|-------|-----------|---------|
| `idx_orders_customer` | `orders` | `customer_id` | Fast customer order lookup |
| `idx_orders_restaurant` | `orders` | `restaurant_id` | Fast restaurant order lookup |
| `idx_orders_personnel` | `orders` | `personnel_id` | Fast rider order lookup |
| `idx_orders_status` | `orders` | `status` | Filter orders by status |
| `idx_orders_date` | `orders` | `order_date` | Sort/filter by date |
| `idx_menu_items_rest` | `menu_items` | `restaurant_id` | Fast menu fetch by restaurant |
| `idx_menu_items_cat` | `menu_items` | `category_id` | Fast menu fetch by category |
| `idx_feedback_rest` | `feedback` | `restaurant_id` | Fast rating aggregation |
| `idx_order_items_order` | `order_items` | `order_id` | Fast line-item lookup |

---

## Sample Data

The script includes realistic sample data for immediate testing:

| Entity | Records |
|--------|---------|
| Customers | 6 |
| Restaurants | 5 (Karachi, Lahore, Islamabad, Rawalpindi) |
| Menu Categories | 10 |
| Menu Items | 18 |
| Delivery Personnel | 5 |
| Orders | 6 (various statuses) |
| Order Items | 11 |
| Feedback | 3 |

---

## Setup Instructions

### Requirements
- MySQL 8.0 or later
- MySQL Workbench (recommended) or any MySQL client

### Steps

**1. Open MySQL Workbench** and connect to your local MySQL server.

**2. Run the SQL script:**

Via MySQL Workbench:
- Go to `File → Open SQL Script`
- Select `online_food_ordering.sql`
- Click the lightning bolt ⚡ (Execute) button

Via command line:
```bash
mysql -u root -p < online_food_ordering.sql
```

**3. Verify the setup** — the script prints a row count summary at the end:

```
+--------------------+------+
| tbl                | rows |
+--------------------+------+
| customers          |    6 |
| restaurants        |    5 |
| menu_categories    |   10 |
| menu_items         |   18 |
| delivery_personnel |    5 |
| orders             |    6 |
| order_items        |   11 |
| feedback           |    3 |
+--------------------+------+
```

**4. Switch to the database** for manual queries:
```sql
USE online_food_ordering;
```

---

## Business Rules & Constraints

- A customer can only submit **one feedback per order**
- Feedback can only be submitted on **delivered orders**
- Order items can only be added when the order is **pending or confirmed**
- An order can only be cancelled when **pending or confirmed**
- **Tax is fixed at 5%** of the subtotal; delivery fee is fixed at PKR 50
- Delivery personnel are automatically marked **unavailable** when assigned to an active order
- Restaurant and personnel ratings are **automatically recalculated** after every new feedback submission
- All order status transitions are **validated** — invalid jumps raise a SQL error
- Passwords are stored as **SHA-256 hashes** — never in plain text

---

## File Structure

```
Group6_OnlineFoodOrdering/
│
├── online_food_ordering.sql     ← Complete MySQL script (DDL + DML + sample data)
└── README.md                    ← This file
```

---

## ER Diagram

The Entity-Relationship diagram for this project shows all 8 entities, their attributes, and the 11 relationships between them with crow's-foot cardinality notation. Refer to the submitted ER diagram document for the full visual.

**Relationships summary:**

```
CUSTOMERS         ||--o{  ORDERS
RESTAURANTS       ||--o{  ORDERS
DELIVERY_PERSONNEL ||--o{  ORDERS
ORDERS            ||--|{  ORDER_ITEMS
MENU_ITEMS        ||--o{  ORDER_ITEMS
RESTAURANTS       ||--|{  MENU_CATEGORIES
RESTAURANTS       ||--o{  MENU_ITEMS
MENU_CATEGORIES   ||--o{  MENU_ITEMS
ORDERS            ||--o|  FEEDBACK
CUSTOMERS         ||--o{  FEEDBACK
RESTAURANTS       ||--o{  FEEDBACK
DELIVERY_PERSONNEL ||--o{  FEEDBACK
```

---

*Submitted for Database Management Systems — Group 6*
