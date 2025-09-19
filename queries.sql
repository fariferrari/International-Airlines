1 - Загруженность аэропортов - выявляет самые активные аэропорты

2 - Статистика по авиакомпаниям - сравнивает производительность перевозчиков

3 - Активные пассажиры - находит самых частых flyers

4 - Сезонность перевозок - анализирует monthly load

5 - Статусы рейсов - показывает % canceled, delayed, on-time рейсов

6 - Популярные маршруты - определяет самые востребованные направления

7 - География пассажиров - анализирует по странам

8 - Самые длительные рейсы - находит long-haul flights

9 - Время бронирований - показывает пиковые часы продаж

10 - Пунктуальность авиакомпаний - сравнивает on-time performance




-- 1. ТОП-10 самых загруженных аэропортов по количеству рейсов
SELECT 
    a.airport_name,
    a.city,
    a.country,
    COUNT(f.flight_id) as total_flights
FROM airport a
LEFT JOIN flights f ON a.airport_id = f.departure_airport_id 
                   OR a.airport_id = f.arrival_airport_id
GROUP BY a.airport_id, a.airport_name, a.city, a.country
ORDER BY total_flights DESC
LIMIT 10;

-- 2. Статистика рейсов по авиакомпаниям
SELECT 
    al.airline_name,
    al.airline_country,
    COUNT(f.flight_id) as total_flights,
    MIN(f.actual_departure) as first_flight,
    MAX(f.actual_departure) as last_flight
FROM flights f
JOIN airline al ON f.airline_id = al.airline_id
WHERE f.actual_departure IS NOT NULL
GROUP BY al.airline_id, al.airline_name, al.airline_country
ORDER BY total_flights DESC;

-- 3. Пассажиры с наибольшим количеством бронирований
SELECT 
    p.passenger_id,
    p.first_name,
    p.last_name,
    p.country_of_residence,
    COUNT(b.booking_id) as total_bookings,
    COUNT(DISTINCT bf.flight_id) as unique_flights
FROM passengers p
JOIN booking b ON p.passenger_id = b.passenger_id
JOIN booking_flight bf ON b.booking_id = bf.booking_id
GROUP BY p.passenger_id, p.first_name, p.last_name, p.country_of_residence
ORDER BY total_bookings DESC
LIMIT 15;

-- 4. Загрузка рейсов по месяцам (сезонность)
SELECT 
    EXTRACT(YEAR FROM actual_departure::date) as year,
    EXTRACT(MONTH FROM actual_departure::date) as month,
    COUNT(flight_id) as flights_count
FROM flights
WHERE actual_departure IS NOT NULL
GROUP BY year, month
ORDER BY year, month;

-- 5. Статусы рейсов и их распределение
SELECT 
    status,
    COUNT(flight_id) as flights_count,
    ROUND(COUNT(flight_id) * 100.0 / (SELECT COUNT(*) FROM flights), 2) as percentage
FROM flights
GROUP BY status
ORDER BY flights_count DESC;

-- 6. Самые популярные направления (маршруты)
SELECT 
    dep.airport_name as departure_airport,
    arr.airport_name as arrival_airport,
    COUNT(f.flight_id) as flights_count
FROM flights f
JOIN airport dep ON f.departure_airport_id = dep.airport_id
JOIN airport arr ON f.arrival_airport_id = arr.airport_id
GROUP BY dep.airport_name, arr.airport_name
HAVING COUNT(f.flight_id) > 5
ORDER BY flights_count DESC
LIMIT 10;

-- 7. Активность пассажиров по странам
SELECT 
    p.country_of_residence as country,
    COUNT(DISTINCT p.passenger_id) as passengers_count,
    COUNT(b.booking_id) as total_bookings,
    ROUND(COUNT(b.booking_id) * 1.0 / COUNT(DISTINCT p.passenger_id), 2) as avg_bookings_per_passenger
FROM passengers p
LEFT JOIN booking b ON p.passenger_id = b.passenger_id
GROUP BY p.country_of_residence
HAVING COUNT(DISTINCT p.passenger_id) > 5
ORDER BY total_bookings DESC;

-- 8. Рейсы с наибольшей продолжительностью
SELECT 
    f.flight_id,
    f.flight_no,
    al.airline_name,
    dep.airport_name as departure_airport,
    arr.airport_name as arrival_airport,
    f.actual_departure,
    f.actual_arrival,
    (f.actual_arrival::date - f.actual_departure::date) as duration_days
FROM flights f
JOIN airline al ON f.airline_id = al.airline_id
JOIN airport dep ON f.departure_airport_id = dep.airport_id
JOIN airport arr ON f.arrival_airport_id = arr.airport_id
WHERE f.actual_departure IS NOT NULL AND f.actual_arrival IS NOT NULL
ORDER BY duration_days DESC
LIMIT 10;

-- 9. Распределение бронирований по времени суток
SELECT 
    created_at::date as booking_date,
    COUNT(booking_id) as bookings_count
FROM booking
WHERE created_at IS NOT NULL
GROUP BY created_at::date
ORDER BY booking_date
LIMIT 10;

-- 10. Эффективность авиакомпаний по punctuality
SELECT 
    al.airline_name,
    COUNT(f.flight_id) as total_flights,
    SUM(CASE WHEN f.status = 'On Time' THEN 1 ELSE 0 END) as on_time_flights,
    ROUND(SUM(CASE WHEN f.status = 'On Time' THEN 1 ELSE 0 END) * 100.0 / COUNT(f.flight_id), 2) as on_time_percentage
FROM flights f
JOIN airline al ON f.airline_id = al.airline_id
WHERE f.status IS NOT NULL
GROUP BY al.airline_name
HAVING COUNT(f.flight_id) > 10
ORDER BY on_time_percentage DESC;
