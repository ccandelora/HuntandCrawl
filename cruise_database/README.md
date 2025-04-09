# Cruise Bar Crawl App Database

## Overview
This database provides comprehensive information about bars, lounges, and drinking establishments on major cruise ships to power a cruise bar crawl application. The database includes details about cruise lines, ships, bars, signature drinks, bar crawl routes, and numerous enhanced features to create an engaging and useful app experience.

## Database Structure

### Core Tables
1. **cruise_lines.json** - Information about major cruise lines
2. **ships.json** - Details about cruise ships in each cruise line's fleet
3. **bars.json** - Information about different types of bars found on cruise ships
4. **ship_bars.json** - Maps specific bars to specific ships with location information
5. **bar_drinks.json** - Details about signature drinks available at each bar
6. **bar_crawl_routes.json** - Predefined bar crawl routes on specific ships
7. **route_stops.json** - Individual stops on each bar crawl route

### Enhanced Feature Tables
8. **user_reviews.json** - Sample user reviews of bars
9. **bar_events.json** - Special events held at bars (mixology classes, tastings, etc.)
10. **drink_packages.json** - Information about cruise line beverage packages
11. **happy_hours.json** - Details about happy hour specials at various bars
12. **bartenders.json** - Information about notable bartenders
13. **bar_themes.json** - Thematic information about each bar's atmosphere and style
14. **accessibility_info.json** - Accessibility details for bars
15. **social_features.json** - Information about the social aspects of each bar
16. **achievements.json** - Gamification achievements for the app
17. **user_achievements.json** - Sample user achievement data
18. **drink_challenges.json** - Special drinking challenges for users to complete
19. **bar_photos.json** - Photos of bars with captions and metadata

## Implementation Guide

### Database Integration
This database is provided as a collection of JSON files that can be integrated into your app in several ways:

1. **Direct JSON Import**: For simple implementations, the JSON files can be directly imported into your app's assets folder and loaded at runtime.

2. **SQL Database Conversion**: The JSON files can be converted to SQL using the following approach:
   ```python
   import json
   import sqlite3
   
   # Create a connection to your SQLite database
   conn = sqlite3.connect('cruise_bar_crawl.db')
   cursor = conn.cursor()
   
   # Example: Create and populate cruise_lines table
   cursor.execute('''
   CREATE TABLE cruise_lines (
       id INTEGER PRIMARY KEY,
       name TEXT,
       description TEXT,
       website TEXT
   )
   ''')
   
   # Load JSON data
   with open('cruise_lines.json', 'r') as f:
       data = json.load(f)
       
   # Insert data into table
   for line in data['cruise_lines']:
       cursor.execute(
           'INSERT INTO cruise_lines VALUES (?, ?, ?, ?)',
           (line['id'], line['name'], line['description'], line['website'])
       )
   
   # Commit changes and close connection
   conn.commit()
   conn.close()
   ```

3. **NoSQL Database Import**: For NoSQL databases like MongoDB:
   ```javascript
   const { MongoClient } = require('mongodb');
   const fs = require('fs');
   
   async function importData() {
     const client = new MongoClient('mongodb://localhost:27017');
     await client.connect();
     
     const db = client.db('cruise_bar_crawl');
     
     // Import cruise lines
     const cruiseLines = JSON.parse(fs.readFileSync('cruise_lines.json', 'utf8'));
     await db.collection('cruise_lines').insertMany(cruiseLines.cruise_lines);
     
     // Repeat for other collections
     
     await client.close();
   }
   
   importData();
   ```

### Recommended App Features

Based on the database structure, your app could include:

1. **Bar Discovery**: Allow users to browse bars by ship, type, or theme
2. **Bar Crawl Routes**: Offer predefined routes or let users create custom routes
3. **Drink Tracking**: Let users log drinks they've tried and earn achievements
4. **Social Planning**: Help users find bars that match their social preferences
5. **Accessibility Information**: Help users with specific needs find suitable venues
6. **Event Calendar**: Show special bar events during a cruise
7. **Drink Package Value Calculator**: Help users determine if a drink package is worth it
8. **Happy Hour Alerts**: Notify users of upcoming happy hours
9. **Gamification**: Implement achievements and challenges to engage users
10. **User Reviews**: Allow users to read and submit reviews

## Data Maintenance

To keep the database current:

1. **Cruise Line Updates**: Monitor cruise line websites for new ships and bar concepts
2. **User Contributions**: Implement a system for users to submit updates or corrections
3. **Periodic Validation**: Regularly validate the data against official sources
4. **Version Control**: Maintain version history of database changes

## Expansion Opportunities

The database can be expanded to include:

1. **Additional Cruise Lines**: Add smaller or regional cruise lines
2. **Food Pairing Information**: Add food and drink pairing suggestions
3. **Seasonal Specials**: Track seasonal or limited-time offerings
4. **Loyalty Program Integration**: Add information about how bar purchases tie into loyalty programs
5. **Price Tracking**: Add more detailed pricing information

## Technical Notes

- All IDs are integers and serve as primary keys
- Foreign keys maintain relationships between tables
- Arrays are used for multi-value fields
- All text is in English but can be expanded for internationalization

## License and Usage

This database is provided for your cruise bar crawl app development. While the structure is fixed, you're encouraged to expand and update the content to keep it current with cruise line offerings.

## Support

For questions or support regarding this database, please contact the database creator.

Happy cruising and responsible drinking!
