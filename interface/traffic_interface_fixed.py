from pyswip import Prolog

prolog = Prolog()
prolog.consult("traffic_rules.pl")

def normalize(value):
    return str(value).strip().lower().replace(" ", "_")

def process_input(data):
    density = normalize(data.get("traffic_density"))
    weather = normalize(data.get("weather_condition"))
    time_of_day = normalize(data.get("time_of_day"))
    light = normalize(data.get("current_traffic_light"))
    pedestrian = normalize(data.get("pedestrian_presence"))
    emergency = normalize(data.get("emergency_vehicle_presence"))

    query = f"evaluate({density},{weather},{time_of_day},{light},{pedestrian},{emergency},Action)"

    results = []
    for sol in prolog.query(query):
        results.append(sol["Action"])

    return results
