# Enhanced Database Features for Cruise Bar Crawl App

Based on industry best practices and user needs, here are additional features to enhance the cruise bar crawl app database:

## New Tables

### 1. user_reviews
- id (primary key)
- user_id
- bar_id
- rating (1-5 stars)
- review_text
- date_visited
- crowd_level (empty, moderate, crowded)
- wait_time (minutes)
- photo_urls (array)

### 2. bar_events
- id (primary key)
- bar_id
- ship_id
- event_name
- description
- start_time
- end_time
- recurring (boolean)
- recurring_pattern (daily, specific days, etc.)
- special_pricing

### 3. drink_packages
- id (primary key)
- cruise_line_id
- name
- description
- price_range
- included_bars (array of bar_ids)
- included_drinks (array of drink types)
- limitations
- value_rating

### 4. happy_hours
- id (primary key)
- bar_id
- ship_id
- start_time
- end_time
- days_available
- special_pricing
- featured_drinks

### 5. bartenders
- id (primary key)
- name
- bar_id
- ship_id
- specialty_drinks
- bio
- photo_url
- schedule

### 6. bar_themes
- id (primary key)
- bar_id
- theme_name
- description
- atmosphere
- music_type
- typical_crowd
- dress_recommendations

### 7. bar_photos
- id (primary key)
- bar_id
- photo_url
- caption
- user_submitted (boolean)
- featured (boolean)
- date_taken

### 8. accessibility_info
- id (primary key)
- bar_id
- wheelchair_accessible (boolean)
- seating_options
- noise_level
- lighting_level
- special_accommodations

### 9. social_features
- id (primary key)
- bar_id
- meetup_friendly (boolean)
- singles_friendly (boolean)
- group_friendly (boolean)
- family_friendly (boolean)
- typical_age_range
- social_events

### 10. achievements
- id (primary key)
- name
- description
- requirements
- badge_image_url
- points_value
- difficulty_level

### 11. user_achievements
- id (primary key)
- user_id
- achievement_id
- date_earned
- ships_completed
- bars_visited

### 12. drink_challenges
- id (primary key)
- name
- description
- drinks_required (array of drink_ids)
- time_limit
- reward_description
- difficulty_level
- participating_ships (array of ship_ids)

## Enhanced Existing Tables

### bars (additional fields)
- average_rating
- price_level ($ to $$$$$)
- specialty (cocktails, beer, wine, etc.)
- entertainment_options
- food_available (boolean)
- outdoor_seating (boolean)
- reservation_required (boolean)
- peak_hours
- quiet_hours
- instagram_hashtag
- virtual_tour_url

### bar_drinks (additional fields)
- popularity_ranking
- alcohol_content
- calories
- allergens
- photo_url
- is_signature (boolean)
- available_non_alcoholic (boolean)
- seasonal_availability

### ships (additional fields)
- bar_crawl_map_url
- recommended_crawl_days
- specialty_drink_theme
- exclusive_bars
- bar_package_options

This enhanced database structure will support features that make the app more engaging, informative, and useful for cruise bar enthusiasts.
