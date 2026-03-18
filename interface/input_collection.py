#The input collection module gathers information about the traffic environment such as weather conditions, traffic density, pedestrian presence, and emergency vehicles.
#Main responsibilities:
 #• Displays the system banner
 #• Shows menu options
 #• Lets the user choose traffic conditions
 #• Stores the inputs in a dictionary

def display_banner():
    print("=" * 60)
    print("  ADAPTIVE TRAFFIC SIGNAL CONTROL - EXPERT SYSTEM")
    print("  Input Collection Module")
    print("=" * 60)
    print()


def get_choice(prompt, options):
    print(prompt)
    for i, option in enumerate(options, start=1):
        print(f"  {i}. {option}")

    while True:
        try:
            choice = int(input("  Enter choice number: ").strip())
            if 1 <= choice <= len(options):
                selected = options[choice - 1]
                print(f"Selected: {selected}\n")
                return selected
        except ValueError:
            pass
        print(f"Invalid input. Please enter a number between 1 and {len(options)}.")


def collect_inputs():
    display_banner()
    print("Please provide the current intersection conditions:\n")

    #  1. Weather Condition
    weather_condition = get_choice(
        "1. Weather Condition:",
        ["Dry", "Light Rain", "Heavy Rain", "Cloudy"]
    )

    #  2. Traffic Density
    traffic_density = get_choice(
        "2. Traffic Density:",
        ["Low", "Medium", "High"]
    )

    # 3. Time of Day 
    time_of_day = get_choice(
        "3. Time of Day:",
        ["Day", "Night"]
    )

    # 4. Pedestrian Presence 
    pedestrian_presence = get_choice(
        "4. Pedestrian Presence:",
        ["Yes", "No"]
    )

    #  5. Emergency Vehicle Presence =
    emergency_vehicle_presence = get_choice(
        "5. Emergency Vehicle Presence:",
        ["Yes", "No"]
    )

    #  6. Current Traffic Light
    current_traffic_light = get_choice(
        "6. Current Traffic Light State:",
        ["Red", "Yellow", "Green"]
    )

    #  Build and return the inputs dictionary
    inputs = {
        "weather_condition":            weather_condition,
        "traffic_density":              traffic_density,
        "time_of_day":                  time_of_day,
        "pedestrian_presence":          pedestrian_presence,
        "emergency_vehicle_presence":   emergency_vehicle_presence,
        "current_traffic_light":        current_traffic_light,
    }

    return inputs


def display_summary(inputs):
    print("=" * 60)
    print("INPUT SUMMARY")
    print("=" * 60)
    for key, value in inputs.items():
        label = key.replace("_", " ").title()
        print(f"  {label:<35}: {value}")
    print("=" * 60)
    print()


if __name__ == "__main__":
    user_inputs = collect_inputs()
    display_summary(user_inputs)

    # The dictionary is ready to be passed to the inference engine
    print("Inputs dictionary (ready for inference engine):")
    print(user_inputs)