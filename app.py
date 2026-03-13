import streamlit as st
import pandas as pd
import plotly.express as px
from sqlalchemy import create_engine

# ---------------- DATABASE CONNECTION ---------------- #

engine = create_engine(
    "mysql+mysqlconnector://root:Prinsh%40778399@localhost/air_tracker"
)

@st.cache_data
def run_query(sql):
    return pd.read_sql(sql, engine)


# ---------------- PAGE SETTINGS ---------------- #

st.set_page_config(
    page_title="Air Tracker Dashboard",
    layout="wide"
)

st.title("✈ Air Tracker Dashboard")


# ---------------- SIDEBAR MENU ---------------- #

page = st.sidebar.radio(
    "Navigation",
    ["🏠 Home", "✈ Flights", "🛫 Airports", "⏱ Delays"]
)


# ================= HOME PAGE ================= #

if page == "🏠 Home":

    st.subheader("System Overview")

    col1, col2, col3, col4 = st.columns(4)

    airports = run_query("SELECT COUNT(*) AS c FROM airport").iloc[0,0]
    flights = run_query("SELECT COUNT(*) AS c FROM flights").iloc[0,0]
    aircraft = run_query("SELECT COUNT(*) AS c FROM aircraft").iloc[0,0]
    delays = run_query("SELECT COUNT(*) AS c FROM airport_delays").iloc[0,0]

    col1.metric("Airports", airports)
    col2.metric("Flights", flights)
    col3.metric("Aircraft", aircraft)
    col4.metric("Delay Records", delays)

    st.divider()

    # Flight Status Chart
    st.subheader("Flight Status Distribution")

    df = run_query("""
        SELECT status, COUNT(*) AS count
        FROM flights
        WHERE status IS NOT NULL
        GROUP BY status
    """)

    fig = px.pie(
        df,
        names="status",
        values="count",
        hole=0.4
    )

    st.plotly_chart(fig, use_container_width=True)


    # Flights per airport
    st.subheader("Flights per Airport")

    df2 = run_query("""
        SELECT origin_iata, COUNT(*) AS flights
        FROM flights
        GROUP BY origin_iata
        ORDER BY flights DESC
    """)

    fig2 = px.bar(
        df2,
        x="origin_iata",
        y="flights",
        color="flights"
    )

    st.plotly_chart(fig2, use_container_width=True)



# ================= FLIGHTS PAGE ================= #

elif page == "✈ Flights":

    st.subheader("Search Flights")

    col1, col2, col3 = st.columns(3)

    airline = col1.text_input("Airline Code")
    origin = col2.text_input("Origin Airport")
    status = col3.selectbox(
        "Status",
        ["All", "Departed", "Arrived", "Canceled", "Delayed"]
    )

    sql = "SELECT * FROM flights WHERE 1=1"

    if airline:
        sql += f" AND airline_code='{airline.upper()}'"

    if origin:
        sql += f" AND origin_iata='{origin.upper()}'"

    if status != "All":
        sql += f" AND status='{status}'"

    sql += " LIMIT 500"

    df = run_query(sql)

    st.success(f"{len(df)} flights found")

    st.dataframe(df, use_container_width=True)

    st.download_button(
        "Download CSV",
        df.to_csv(index=False),
        "flights.csv"
    )


# ================= AIRPORT PAGE ================= #

elif page == "🛫 Airports":

    st.subheader("Airport Explorer")

    airports = run_query("""
        SELECT iata_code,name,city,country,latitude,longitude
        FROM airport
    """)

    choice = st.selectbox(
        "Select Airport",
        airports["iata_code"] + " - " + airports["name"]
    )

    iata = choice.split(" - ")[0]

    airport_data = run_query(f"""
        SELECT *
        FROM airport
        WHERE iata_code='{iata}'
    """)

    st.dataframe(airport_data)

    st.subheader("Airport Location")

    map_df = airport_data[["latitude","longitude"]]
    map_df.columns = ["lat","lon"]

    st.map(map_df)


    st.subheader("Recent Flights")

    flights = run_query(f"""
        SELECT flight_number,
               origin_iata,
               destination_iata,
               scheduled_departure,
               status
        FROM flights
        WHERE origin_iata='{iata}'
        OR destination_iata='{iata}'
        ORDER BY scheduled_departure DESC
        LIMIT 100
    """)

    fig = px.histogram(
        flights,
        x="status",
        color="status"
    )

    st.plotly_chart(fig, use_container_width=True)

    st.dataframe(flights, use_container_width=True)



# ================= DELAY PAGE ================= #

elif page == "⏱ Delays":

    st.subheader("Airport Delay Analysis")

    df = run_query("""
        SELECT airport_iata,
               delay_date,
               SUM(total_flights) AS total_flights,
               SUM(delayed_flights) AS delayed_flights,
               AVG(median_delay_min) AS avg_delay
        FROM airport_delays
        GROUP BY airport_iata, delay_date
    """)

    st.dataframe(df)


    st.subheader("Delay Trend")

    fig = px.line(
        df,
        x="delay_date",
        y="avg_delay",
        color="airport_iata",
        markers=True
    )

    st.plotly_chart(fig, use_container_width=True)


    st.subheader("Cancelled Flights by Airport")

    df2 = run_query("""
        SELECT airport_iata,
        SUM(canceled_flights) AS total_cancelled
        FROM airport_delays
        GROUP BY airport_iata
        ORDER BY total_cancelled DESC
    """)

    fig2 = px.bar(
        df2,
        x="airport_iata",
        y="total_cancelled",
        color="total_cancelled"
    )

    st.plotly_chart(fig2, use_container_width=True)