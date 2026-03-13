CREATE DATABASE air_tracker;

USE air_tracker;

CREATE TABLE airport (
    airport_id INT AUTO_INCREMENT PRIMARY KEY,
    icao_code VARCHAR(10) UNIQUE,
    iata_code VARCHAR(10) UNIQUE,
    name VARCHAR(100),
    city VARCHAR(100),
    country VARCHAR(100),
    continent VARCHAR(50),
    latitude DOUBLE,
    longitude DOUBLE,
    timezone VARCHAR(50)
);

CREATE TABLE airports (
    iata VARCHAR(10) PRIMARY KEY,
    name VARCHAR(100),
    city VARCHAR(100),
    country VARCHAR(100)
);

INSERT INTO airports (iata, name, city, country) VALUES
('DXB','Dubai International Airport','Dubai','UAE'),
('SIN','Singapore Changi Airport','Singapore','Singapore'),
('LAX','Los Angeles International Airport','Los Angeles','USA'),
('LHR','Heathrow Airport','London','United Kingdom'),
('DEL','Indira Gandhi International Airport','Delhi','India'),
('BOM','Chhatrapati Shivaji Maharaj International Airport','Mumbai','India'),
('CCU','Netaji Subhas Chandra Bose International Airport','Kolkata','India'),
('BLR','Kempegowda International Airport','Bangalore','India'),
('HYD','Rajiv Gandhi International Airport','Hyderabad','India'),
('MAA','Chennai International Airport','Chennai','India');

CREATE TABLE aircraft (
    aircraft_id INT AUTO_INCREMENT PRIMARY KEY,
    registration VARCHAR(20) UNIQUE,
    model VARCHAR(100),
    manufacturer VARCHAR(100),
    icao_type_code VARCHAR(20),
    owner VARCHAR(100)
);

CREATE TABLE flights (
    flight_id VARCHAR(50) PRIMARY KEY,
    flight_number VARCHAR(20),
    aircraft_registration VARCHAR(20),
    origin_iata VARCHAR(10),
    destination_iata VARCHAR(10),
    scheduled_departure DATETIME,
    actual_departure DATETIME,
    scheduled_arrival DATETIME,
    actual_arrival DATETIME,
    status VARCHAR(20),
    airline_code VARCHAR(20)
);

CREATE TABLE airport_delays (
    delay_id INT AUTO_INCREMENT PRIMARY KEY,
    airport_iata VARCHAR(10),
    delay_date DATE,
    total_flights INT,
    delayed_flights INT,
    avg_delay_min INT,
    median_delay_min INT,
    canceled_flights INT
);

select * from airport;
select iata_code from airport;
TRUNCATE TABLE airport;
select * from flights;
select * from aircraft;
select * from airport_delays;

SHOW COLUMNS FROM flights;

SHOW COLUMNS FROM flights LIKE 'status';

/*Question 1....
Show the total number of flights for each aircraft model, listing the model and its count.
*/
SELECT aircraft_registration, COUNT(*) AS total_flights
FROM flights
GROUP BY aircraft_registration
ORDER BY total_flights DESC;

/*Question 2...
List all aircraft (registration, model) that have been assigned to more than 5 flights.
*/
SELECT aircraft_registration, COUNT(*) AS total_flights
FROM flights
GROUP BY aircraft_registration
HAVING COUNT(*) > 5;

/*Question 3....
For each airport, display its name and the number of outbound flights, but only for airports with more than 5 flights.
*/
SELECT origin_iata AS airport, COUNT(*) AS outbound_flights
FROM flights
GROUP BY origin_iata
HAVING COUNT(*) > 5
ORDER BY outbound_flights DESC;

/*Question 4....
Find the top 3 destination airports (name, city) by number of arriving flights, sorted by count descending.
*/
SELECT a.name, a.city, COUNT(*) AS arriving_flights
FROM flights f
JOIN airports a
ON f.destination_iata = a.iata
GROUP BY a.name, a.city
ORDER BY arriving_flights DESC
LIMIT 3;

/*Question 5...
Show for each flight: number, origin, destination, and a label 'Domestic' or 'International' using CASE WHEN on country match.
*/
SELECT 
    f.flight_number,
    o.iata AS origin,
    d.iata AS destination,
    CASE 
        WHEN o.country = d.country THEN 'Domestic'
        ELSE 'International'
    END AS flight_type
FROM flights f
JOIN airports o ON f.origin_iata = o.iata
JOIN airports d ON f.destination_iata = d.iata;

/*Question 6....
Show the 5 most recent arrivals at “DEL” airport including flight number, aircraft, departure airport name, and arrival time, ordered by latest arrival.
*/
SELECT 
    f.flight_number,
    f.aircraft_registration AS aircraft,
    a.name AS departure_airport,
    f.actual_arrival
FROM flights f
JOIN airports a 
ON f.origin_iata = a.iata
WHERE f.destination_iata = 'DEL'
ORDER BY f.actual_arrival DESC
LIMIT 5;

/*Question 7....
 Find all airports with no arriving flights (never used as a destination in flights table)
 */
 SELECT a.iata, a.name, a.city
FROM airports a
LEFT JOIN flights f
ON a.iata = f.destination_iata
WHERE f.destination_iata IS NULL;

/*Question 8....
For each airline, count the number of flights by status (e.g., 'On Time', 'Delayed', 'Cancelled') using CASE WHEN.
*/

ALTER TABLE flights ADD airline VARCHAR(50);

SELECT 
    airline_code,
    SUM(CASE WHEN status = 'OnTime' THEN 1 ELSE 0 END) AS on_time_flights,
    SUM(CASE WHEN status = 'Delayed' THEN 1 ELSE 0 END) AS delayed_flights,
    SUM(CASE WHEN status = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled_flights
FROM flights
GROUP BY airline_code;

/*Question 9....
Show all cancelled flights, with aircraft and both airports, ordered by departure time descending.
*/
SELECT 
    f.flight_number,
    f.aircraft_registration,
    ao.name AS origin_airport,
    ad.name AS destination_airport,
    f.scheduled_departure
FROM flights f
JOIN airports ao ON f.origin_iata = ao.iata
JOIN airports ad ON f.destination_iata = ad.iata
WHERE f.status = 'Canceled'
ORDER BY f.scheduled_departure DESC;

/*Question 10...
 List all city pairs (origin-destination) that have more than 2 different aircraft models operating flights between them.
 */
 SELECT 
    f.origin_iata,
    f.destination_iata,
    COUNT(DISTINCT a.model) AS aircraft_models
FROM flights f
JOIN aircraft a 
    ON f.aircraft_registration = a.registration
GROUP BY f.origin_iata, f.destination_iata
HAVING COUNT(DISTINCT a.model) > 2;

/*Question 11....
For each destination airport, compute the % of delayed flights (status='Delayed') among all arrivals, sorted by highest percentage. 
*/
SELECT 
    destination_iata,
    COUNT(*) AS total_arrivals,
    SUM(CASE WHEN status = 'Delayed' THEN 1 ELSE 0 END) AS delayed_flights,
    ROUND(
        (SUM(CASE WHEN status = 'Delayed' THEN 1 ELSE 0 END) * 100.0) / COUNT(*),
        2
    ) AS delayed_percentage
FROM flights
GROUP BY destination_iata
ORDER BY delayed_percentage DESC;


