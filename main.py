import psycopg2 
import pandas as pd






print(psycopg2.__version__)

def connect_to_database():
    try:
        conn = psycopg2.connect( 
            host="localhost",
            database="airport_db",
            user="postgres",
            password="farida",  
            port="5432"
        )
        print()
        return conn
    except Exception as e:
        print(f"Ошибка подключения: {e}")
        return None

def execute_query(conn, query, description):
    try:
        with conn.cursor() as cursor:
            print(f"\n{description}")
            print("-" * 50)

            cursor.execute(query)
            results = cursor.fetchall()
            columns = [desc[0] for desc in cursor.description]

            df = pd.DataFrame(results, columns=columns)
            print(df.to_string(index=False))

            filename = f"{description.replace(' ', '_').lower()}.csv"
            df.to_csv(filename, index=False, encoding='utf-8')
            print(f"Результаты сохранены в: {filename}")

            return df
    except Exception as e:
        print(f"Ошибка выполнения запроса: {e}")
        return None

def main():
    conn = connect_to_database()
    if not conn:
        return
    try:
        query1 = """
        SELECT 
            a.airport_name,
            a.city,
            a.country,
            COUNT(f.flight_id) AS total_flights
        FROM airport a
        LEFT JOIN flights f 
          ON a.airport_id = f.departure_airport_id 
          OR a.airport_id = f.arrival_airport_id
        GROUP BY a.airport_id, a.airport_name, a.city, a.country
        ORDER BY total_flights DESC
        LIMIT 10;
        """
        execute_query(conn, query1, "ТОП 10 аэропортов по загруженности")

        query2 = """
        SELECT 
            al.airline_name,
            al.airline_country,
            COUNT(f.flight_id) AS total_flights,
            MIN(f.actual_departure) AS first_flight,
            MAX(f.actual_departure) AS last_flight
        FROM flights f
        JOIN airline al ON f.airline_id = al.airline_id
        GROUP BY al.airline_id, al.airline_name, al.airline_country
        ORDER BY total_flights DESC;
        """
        execute_query(conn, query2, "Статистика по авиакомпаниям")

        query3 = """
        SELECT 
            p.passenger_id,
            p.first_name,
            p.last_name,
            p.country_of_residence,
            COUNT(b.booking_id) AS total_bookings
        FROM passengers p
        JOIN booking b ON p.passenger_id = b.passenger_id
        GROUP BY p.passenger_id, p.first_name, p.last_name, p.country_of_residence
        ORDER BY total_bookings DESC
        LIMIT 15;
        """
        execute_query(conn, query3, "Самые активные пассажиры")

        query4 = """
        SELECT 
            status,
            COUNT(flight_id) AS flights_count,
            ROUND(
              (COUNT(flight_id) * 100.0 / (SELECT COUNT(*) FROM flights))::numeric
            , 2) AS percentage
        FROM flights
        GROUP BY status
        ORDER BY flights_count DESC;
        """
        execute_query(conn, query4, "Статусы рейсов")
    finally:
        conn.close()

if __name__ == "__main__":
    main()
