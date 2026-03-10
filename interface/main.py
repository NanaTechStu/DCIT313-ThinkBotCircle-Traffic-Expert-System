"""
main.py
Inference Interface — Adaptive Traffic Signal Control Expert System
DCIT 313 Group Project | ThinkBot Circle

Programmers:
    Adwoa Pokua          (22235277) — Input Collector
    Aryee Emerald        (22033619) — Inference Engine
    Elliot Elorm Nutsuakor (22170217) — Output / Testing

Bridges the user and the Prolog Knowledge Base via pyswip.
All intelligence (rules + inference) lives in:
    knowledge_base/traffic_rules.pl
"""

import os
import sys

try:
    from pyswip import Prolog
except ImportError:
    print("ERROR: pyswip is not installed.")
    print("Run:   pip install pyswip")
    sys.exit(1)


# ── Path to Knowledge Base ────────────────────────────────────────────────────

SCRIPT_DIR   = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(SCRIPT_DIR)
KB_PATH      = os.path.join(PROJECT_ROOT, "knowledge_base", "traffic_rules.pl")
KB_PATH_PROLOG = KB_PATH.replace("\\", "/")   # Prolog requires forward slashes


# ── Input Menus ───────────────────────────────────────────────────────────────

INPUTS = [
    {
        "key":   "density",
        "label": "Traffic Density",
        "options": [
            ("low",    "Low    — few vehicles, free flow"),
            ("medium", "Medium — moderate volume, some queuing"),
            ("high",   "High   — heavy congestion"),
        ],
    },
    {
        "key":   "weather",
        "label": "Weather Condition",
        "options": [
            ("dry",        "Dry         — clear conditions"),
            ("light_rain", "Light Rain  — slight drizzle"),
            ("heavy_rain", "Heavy Rain  — poor visibility, wet roads"),
            ("cloudy",     "Cloudy      — overcast, no rain"),
        ],
    },
    {
        "key":   "time",
        "label": "Time of Day",
        "options": [
            ("day",   "Day   — daylight hours"),
            ("night", "Night — reduced visibility"),
        ],
    },
    {
        "key":   "light",
        "label": "Current Traffic Light State",
        "options": [
            ("red",    "Red    — vehicles stopped"),
            ("yellow", "Yellow — transitioning"),
            ("green",  "Green  — vehicles moving"),
        ],
    },
    {
        "key":   "pedestrian",
        "label": "Pedestrian Present at Crossing?",
        "options": [
            ("yes", "Yes"),
            ("no",  "No"),
        ],
    },
    {
        "key":   "emergency",
        "label": "Emergency Vehicle Approaching?",
        "options": [
            ("yes", "Yes — ambulance / fire truck / police"),
            ("no",  "No"),
        ],
    },
]


# ── Helpers ───────────────────────────────────────────────────────────────────

def divider(char="─", width=60):
    print(char * width)

def header():
    divider("═")
    print("  DCIT 313 — Adaptive Traffic Signal Control")
    print("  Expert System   |   ThinkBot Circle")
    divider("═")
    print()

def prompt_choice(field):
    """Prompt the user to pick one option. Returns the atom string."""
    print(f"\n  {field['label']}")
    divider()
    for i, (value, description) in enumerate(field["options"], start=1):
        print(f"    {i}. {description}")
    divider()
    while True:
        raw = input("  Enter number: ").strip()
        if raw.isdigit():
            idx = int(raw) - 1
            if 0 <= idx < len(field["options"]):
                return field["options"][idx][0]
        print("  Invalid choice — please enter a number from the list.")

def collect_inputs():
    """Interactively collect all 6 traffic condition inputs."""
    print("\n  Fill in the current intersection conditions:\n")
    return {field["key"]: prompt_choice(field) for field in INPUTS}

def decode(term):
    """Convert a pyswip term (bytes or str) to a plain Python string."""
    return term.decode("utf-8") if isinstance(term, bytes) else str(term)

def run_query(prolog, inputs):
    """
    Call Prolog:  evaluate(Density, Weather, Time, Light, Pedestrian, Emergency, Descriptions)
    Returns a list of human-readable description strings.
    """
    query = (
        f"evaluate("
        f"{inputs['density']}, "
        f"{inputs['weather']}, "
        f"{inputs['time']}, "
        f"{inputs['light']}, "
        f"{inputs['pedestrian']}, "
        f"{inputs['emergency']}, "
        f"Descriptions)"
    )
    results = list(prolog.query(query))
    if not results:
        return ["No result returned from the inference engine."]
    return [decode(d) for d in results[0]["Descriptions"]]

def display_inputs(inputs):
    labels = {f["key"]: f["label"] for f in INPUTS}
    print()
    divider()
    print("  Inputs submitted to the Expert System:")
    divider()
    for key, value in inputs.items():
        print(f"    {labels[key]:<34} {value}")
    divider()

def display_results(descriptions):
    print()
    divider("═")
    print("  RECOMMENDED SIGNAL ACTIONS")
    divider("═")
    for i, desc in enumerate(descriptions, start=1):
        print(f"  {i}. {desc}")
    divider("═")
    print()


# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    header()

    prolog = Prolog()
    try:
        prolog.consult(KB_PATH_PROLOG)
    except Exception as e:
        print(f"ERROR: Could not load knowledge base.")
        print(f"  Path: {KB_PATH_PROLOG}")
        print(f"  {e}")
        sys.exit(1)

    print("  Knowledge base loaded successfully.")
    print(f"  File: knowledge_base/traffic_rules.pl\n")

    while True:
        inputs = collect_inputs()
        display_inputs(inputs)

        try:
            descriptions = run_query(prolog, inputs)
        except Exception as e:
            print(f"\n  ERROR during inference: {e}")
            descriptions = []

        display_results(descriptions)

        again = input("  Evaluate another scenario? (y/n): ").strip().lower()
        if again != "y":
            break
        print()

    print("\n  System closed. Goodbye.\n")


if __name__ == "__main__":
    main()
