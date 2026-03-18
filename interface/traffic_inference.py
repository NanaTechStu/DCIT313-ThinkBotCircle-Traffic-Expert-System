from pyswip import Prolog
prolog = Prolog()
prolog.consult("../knowledge_base/traffic_rules.pl")  

def ask(question, options):
    print(f"\n{question}")
    for i, opt in enumerate(options, 1):
        print(f"  {i}. {opt}")
    while True:
        choice = input("Enter number: ").strip()
        if choice.isdigit() and 1 <= int(choice) <= len(options):
            return options[int(choice) - 1]
        print("  Please enter a valid number.")

def get_inputs():
    print("\n" + "="*50)
    print(" Welcome to the Adaptive Traffic Signal Control Expert System ")
    print("  Built by ThinkBot Circle- DCIT 313")
    print("="*50)

    density    = ask("What's the traffic situation?",            ["low", "medium", "high"])
    weather    = ask("What's the weather like?",           ["dry", "light_rain", "heavy_rain", "cloudy"])
    time_      = ask("What part of the day is it?",                ["day", "night"])
    light      = ask("Is the light red,yellow,or green?",      ["red", "yellow", "green"])
    pedestrian = ask("Are there any pedestrians?",         ["yes", "no"])
    emergency  = ask("Are emergenccy vehicles approaching?",  ["yes", "no"])

    return density, weather, time_, light, pedestrian, emergency

def run_query(density, weather, time_, light, pedestrian, emergency):
    query = (
        f"evaluate({density}, {weather}, {time_}, "
        f"{light}, {pedestrian}, {emergency}, Descriptions)"
    )

    print("\n" + "-"*55)
    print("  Based on your input, here is what the system recommends:")
    print("-"*55)

    results = list(prolog.query(query))

    if not results:
        print("  No matching rules found. Maintaining current signal.")
    else:
        descriptions = results[0]["Descriptions"]
        for desc in descriptions:
            print(f"  → {desc}")

    print("-"*55)

def main():
    while True:
        inputs = get_inputs()
        run_query(*inputs)

        again = input("\nEvaluate another scenario? (yes/no): ").strip().lower()
        if again != "yes":
            print("\nThank you for using the traffic signal expert system.")
            break

if __name__ == "__main__":
    main()


