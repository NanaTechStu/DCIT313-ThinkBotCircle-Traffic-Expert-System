from input_collection import collect_inputs, display_summary
from traffic_inference_fixed import run_query


def main():
    print("=== ADAPTIVE TRAFFIC CONTROL SYSTEM ===\n")

    while True:
        inputs = collect_inputs()
        display_summary(inputs)
        print("\nProcessing decision...\n")

        results = run_query(
            inputs["traffic_density"],
            inputs["weather_condition"],
            inputs["time_of_day"],
            inputs["current_traffic_light"],
            inputs["pedestrian_presence"],
            inputs["emergency_vehicle_presence"]
        )

        print("\n=== SYSTEM DECISION ===")

        for r in results:
            print("→", r)

        again = input("\nRun again? (y/n): ").lower()
        if again != "y":
            break

    print("\nSystem Closed.")


if __name__ == "__main__":
    main()