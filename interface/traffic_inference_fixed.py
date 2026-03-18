from pyswip import Prolog

prolog = Prolog()
prolog.consult("./knowledge_base/traffic_rules.pl")

def normalize(value):
    return str(value).strip().lower().replace(" ", "_")

def run_query(density, weather, time_of_day, light, pedestrian, emergency):
    density = normalize(density)
    weather = normalize(weather)
    time_of_day = normalize(time_of_day)
    light = normalize(light)
    pedestrian = normalize(pedestrian)
    emergency = normalize(emergency)

    query = f"evaluate({density},{weather},{time_of_day},{light},{pedestrian},{emergency},Action)"

    results = []
    for sol in prolog.query(query):
        results.append(sol["Action"])

    return results
