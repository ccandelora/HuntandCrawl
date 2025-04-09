# Cruise Bar Crawl App Database Structure

This document outlines the database structure for the cruise bar crawl app. The database is organized to allow users to easily find bars on specific cruise ships and plan their bar crawls accordingly.

## Database Tables

### 1. cruise_lines
- id (primary key)
- name
- description
- website
- logo_url

### 2. ships
- id (primary key)
- cruise_line_id (foreign key)
- name
- class
- year_built
- passenger_capacity
- number_of_bars
- image_url

### 3. bars
- id (primary key)
- name
- description
- bar_type
- signature_drinks
- atmosphere
- dress_code
- hours
- cost_category (included, additional cost, etc.)
- image_url

### 4. ship_bars (junction table)
- id (primary key)
- ship_id (foreign key)
- bar_id (foreign key)
- location_on_ship (deck number, area)
- special_notes

### 5. bar_drinks
- id (primary key)
- bar_id (foreign key)
- name
- description
- price_range
- ingredients
- image_url

### 6. bar_crawl_routes
- id (primary key)
- ship_id (foreign key)
- name
- description
- estimated_duration
- difficulty_level (easy, moderate, challenging)
- number_of_stops

### 7. route_stops
- id (primary key)
- route_id (foreign key)
- bar_id (foreign key)
- stop_order
- recommended_drink
- time_to_spend

This structure allows for flexible queries that can support various app features such as:
- Browsing bars by ship
- Finding ships with specific types of bars
- Planning bar crawl routes
- Discovering signature drinks
- Filtering by included vs. additional cost venues
