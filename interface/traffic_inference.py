#The traffic inference module connects Python to Prolog and evaluates the traffic situation using rule-based reasoning.
#What this file does

#This file is the reasoning engine of the system.

#It:
 #1. Takes user inputs
 #2. Sends them to Prolog
 #3. Uses rules from the knowledge base
 #4. Returns a traffic signal recommendation

#It uses the Python library pyswip to communicate with Prolog.


from pyswip import Prolog
prolog = Prolog()
prolog.consult("../knowledge_base/traffic_rules.pl")  

#Input Helper
# Displays a numbered menu and loops until the user picks a valid option.
# Returns the selected option as a plain string (e.g. "high", "yes")
def ask(question, options):
    print(f"\n{question}")
    for i, opt in enumerate(options, 1):
        print(f"  {i}. {opt}")
    while True:
        choice = input("Enter number: ").strip()
        if choice.isdigit() and 1 <= int(choice) <= len(options):
            return options[int(choice) - 1]
        print("  Please enter a valid number.")

#Scenario Collector
#Walks the user through 6 questions to capture all the input
#-conditions the prolog KB needs to fire the right rules.
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

#INFERENCE ENGINE CALLER
#Bulds a prolog query string from the 6 imputs and fires it aagaints the KB.
#Prints each recommended action returned in the descriptions list, or a fallback message if no rule matched. 
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

#MAIN LOOP
# Repeatedly collects a scenario and runs inference until the user chooses to exit.
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


