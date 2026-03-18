"""
EXPERT SYSTEM: Adaptive Traffic Signal Control
File: interface/traffic_interface.py
Author: Elliot — Output Formatting, Explanation & Testing
Knowledge Base by: Bilson Priscilla Essirifua
DCIT 313 – Expert Systems Project

HOW TO INSTALL (run once in your terminal):
1. Install SWI-Prolog → https://www.swi-prolog.org/Download.html
2. pip install pyswip
"""
#The Python interface connects the user to the traffic control logic. It sends requests to the Prolog system and returns the results so they can be displayed or used by the application.
#This file acts as the bridge between the user and the traffic logic system.

#What it does:
 #• Takes input or commands from the user or program.
 #• Sends queries to the Prolog traffic logic file.
 #• Receives the results from Prolog.
 #• Displays or processes the output.

from pyswip import Prolog
import os

# ── Load the Prolog Knowledge Base ──────────────────────────
prolog = Prolog()
KB_PATH = os.path.join(os.path.dirname(__file__), "traffic_signals.pl")
prolog.consult(KB_PATH)

# ════════════════════════════════════════════════════════════
# SECTION 1 — RULE EXPLANATION LIBRARY
# Every rule from the KB has a plain-English explanation.
# Maps each rule ID to a plain-English description of why it fired
# Used later by format_output() to explain decisions to the user
# ════════════════════════════════════════════════════════════
RULE_EXPLANATIONS = {
    "rule_1": "Rule 1 fired because: Current light is GREEN and traffic density is LOW. "
              "No congestion detected — the system maintains the green signal for the default 30 seconds.",
    "rule_2": "Rule 2 fired because: Current light is RED and traffic density is LOW. "
              "Traffic is sparse — no reason to switch yet, so the system maintains red for 30 seconds.",
    "rule_3": "Rule 3 fired because: Current light is YELLOW. "
              "Yellow always transitions to red — this is a basic safety rule with no exceptions.",
    "rule_4": "Rule 4 fired because: Traffic density is MEDIUM and the light is GREEN. "
              "Moderate congestion is building — the system extends green by 15 seconds to ease the traffic.",
    "rule_5": "Rule 5 fired because: Traffic density is HIGH and the light is GREEN. "
              "Heavy congestion detected — the system extends green by 20 seconds to clear the backlog.",
    "rule_6": "Rule 6 fired because: Traffic density is HIGH and the light is RED. "
              "Vehicles are heavily queued on a red light — the system immediately switches to green.",
    "rule_7": "Rule 7 fired because: Weather is LIGHT RAIN and the light is YELLOW. "
              "Wet roads increase stopping distance — the system extends yellow by 5 seconds for safety.",
    "rule_8": "Rule 8 fired because: Weather is HEAVY RAIN and traffic density is HIGH. "
              "Poor visibility combined with congestion — the system extends green by 25 seconds "
              "to allow vehicles to clear safely.",
    "rule_9": "Rule 9 fired because: Weather is HEAVY RAIN. "
              "Hazardous road conditions detected — the system displays a warning message: "
              "'Slippery road; Drive carefully'.",
    "rule_10": "Rule 10 fired because: Weather is CLOUDY and traffic density is MEDIUM. "
               "Reduced visibility but manageable traffic — the system maintains green for 30 seconds.",
    "rule_11": "Rule 11 fired because: It is NIGHT TIME and traffic density is LOW. "
               "Late-night low traffic — the system maintains the default green cycle of 30 seconds.",
    "rule_12": "Rule 12 fired because: It is NIGHT TIME and pedestrians are PRESENT. "
               "Pedestrians are harder to see at night — the system extends red by 10 seconds "
               "to give them safe crossing time.",
    "rule_13": "Rule 13 fired because: Pedestrians are PRESENT and the light is RED. "
               "Pedestrians are waiting to cross — the system activates the pedestrian crossing signal.",
    "rule_14": "Rule 14 fired because: Pedestrians are PRESENT and weather is HEAVY RAIN. "
               "Pedestrians in heavy rain need extra time to cross safely — the system extends red by 20 seconds.",
    "rule_15": "Rule 15 fired because: An EMERGENCY VEHICLE is present. "
               "Emergency vehicles always take highest priority — the system activates emergency priority.",
    "rule_16": "Rule 16 fired because: An EMERGENCY VEHICLE is present and the light is RED. "
               "The red light must not block an emergency vehicle — the system immediately switches to green.",
    "rule_17": "Rule 17 fired because: Weather is HEAVY RAIN, traffic is HIGH, and it is DAYTIME. "
               "This is a combined worst-case scenario — the system extends green by 35 seconds "
               "to manage dangerous high-traffic wet-road conditions.",
    "rule_18": "Rule 18 fired because: Traffic density is LOW and it is DAYTIME. "
               "Light daytime traffic — the system maintains the standard 30-second green cycle.",
    "rule_19": "Rule 19 fired because: Weather is DRY and traffic density is MEDIUM. "
               "Good conditions with moderate traffic — the system maintains green for the default 30 seconds.",
    "rule_20": "Rule 20 fired because: Weather is HEAVY RAIN, pedestrians are PRESENT, and the light is RED. "
               "This is the most vulnerable combination — pedestrians crossing in heavy rain. "
               "The system extends red by 25 seconds to ensure complete pedestrian safety.",
}

# Maps action terms to display-friendly strings with icons
ACTION_DISPLAY = {
    "maintain_green": " MAINTAIN GREEN",
    "extend_green": " EXTEND GREEN",
    "maintain_red": " MAINTAIN RED",
    "extend_red": " EXTEND RED",
    "extend_yellow": " EXTEND YELLOW",
    "switch_to_green": " SWITCH TO GREEN",
    "switch_to_red": " SWITCH TO RED",
    "activate_pedestrian_crossing": " ACTIVATE PEDESTRIAN CROSSING",
    "give_emergency_priority": " GIVE EMERGENCY PRIORITY",
    "display_warning": " DISPLAY WARNING MESSAGE",
}

# ════════════════════════════════════════════════════════════
# SECTION 2 — OUTPUT FORMATTER
# Handles parsing Prolog action terms and printing structured, 
# human-readable decision boxes to the console.
# ════════════════════════════════════════════════════════════

def parse_action(action_term):
    """Converts a Prolog action term into a display label and detail."""
    s = str(action_term)
    if "(" in s:
        name = s[:s.index("(")]
        arg = s[s.index("(")+1 : s.index(")")]
        detail = f"{arg} seconds" if arg.isdigit() else arg
    else:
        name = s
        detail = None
    return name, detail

def format_output(inputs, action_term, rule_key):
    """Prints a nicely formatted decision box for one signal query."""
    action_name, action_detail = parse_action(action_term)
    display_label = ACTION_DISPLAY.get(action_name, action_name.upper())
    explanation = RULE_EXPLANATIONS.get(str(rule_key), "No explanation available.")
    W = 62  # box width

    def wrap(text, indent=2):
        """Word-wrap text to fit inside the box."""
        words = text.split()
        lines_out, line = [], " " * indent
        for word in words:
            if len(line) + len(word) + 1 > W - 2:
                lines_out.append(line)
                line = " " * indent + word + " "
            else:
                line += word + " "
        if line.strip():
            lines_out.append(line)
        return lines_out

# Print the full formatted decision block: inputs, action, rule and explanation
    print("\n" + "═" * W)
    print(" ADAPTIVE TRAFFIC SIGNAL — DECISION OUTPUT")
    print("═" * W)
    print(" INPUT CONDITIONS:")
    for key, val in inputs.items():
        print(f" {key:<28} {val}")
    print("─" * W)
    print(" DECISION:")
    print(f" Action : {display_label}")
    if action_detail:
        print(f" Duration : {action_detail}")
    print(f" Rule : {rule_key.upper().replace('_', ' ')}")
    print("─" * W)
    print(" EXPLANATION:")
    for line in wrap(explanation):
        print(line)
    print("═" * W)

def query_signal(inputs: dict):
    """Asserts input facts, queries the KB, prints and returns result."""
    facts_asserted = []
    for key, value in inputs.items():
        fact = f"{key}({value})"
        prolog.assertz(fact)
        facts_asserted.append(fact)

    results = list(prolog.query("signal_action(Action, Rule)"))

    for fact in facts_asserted:
        try:
            prolog.retract(fact)
        except Exception:
            pass

    if not results:
        print("\n No rule matched for these inputs.")
        print(" Inputs were:", inputs)
        return None

    result = results[0]
    action = result["Action"]
    rule_key = result["Rule"]
    format_output(inputs, action, rule_key)
    return {"action": str(action), "rule": str(rule_key)}

# ════════════════════════════════════════════════════════════
# SECTION 3 — INTERACTIVE DEMO
# Runs three hand-picked scenarios to showcase key system behaviours:
# emergency override, worst-case weather/traffic, and pesdestrian safety.
# ════════════════════════════════════════════════════════════

def run_demo():
    print("\n" + "█" * 62)
    print(" ADAPTIVE TRAFFIC SIGNAL CONTROL — EXPERT SYSTEM DEMO")
    print(" DCIT 313 | Knowledge Base by Bilson Priscilla Essirifua")
    print("█" * 62)

    # Demo scenarios
    query_signal({"emergency_vehicle": "yes", "current_light": "red"})
    query_signal({"weather": "heavy_rain", "traffic_density": "high", "time_of_day": "day", "current_light": "green"})
    query_signal({"pedestrian_presence": "yes", "weather": "heavy_rain", "current_light": "red"})

# ════════════════════════════════════════════════════════════
# SECTION 4 — TEST SCENARIOS
# Runs 8 targeted unit tests, each  verifying that a specific rule
# produces the correct action. Prints a pass/fail summary at the end.
# ════════════════════════════════════════════════════════════

def run_tests():
    passed, failed = 0, 0
    log = []

    def test(name, inputs, expected_action, expected_rule):
        #asserts inputs, queries the KB, and checks the result against expectations.
        nonlocal passed, failed
        facts = []
        for key, value in inputs.items():
            fact = f"{key}({value})"
            prolog.assertz(fact)
            facts.append(fact)
        results = list(prolog.query("signal_action(Action, Rule)"))
        for fact in facts:
            try:
                prolog.retract(fact)
            except Exception:
                pass

        got_action = str(results[0]["Action"]) if results else "NO RESULT"
        got_rule = str(results[0]["Rule"]) if results else "NO RESULT"
        ok = (got_action == expected_action and got_rule == expected_rule)
        status = "PASS" if ok else "FAIL"
        if ok:
            passed += 1
        else:
            failed += 1
        log.append((status, name))
        print(f"\n {status} {name}")
        if not ok:
            print(f" Expected action : {expected_action}")
            print(f" Got action : {got_action}")
            print(f" Expected rule : {expected_rule}")
            print(f" Got rule : {got_rule}")

# one test per rule being verified - covers safety, weather pesdestrian and emergency cases.
    # Define all 8 test scenarios
    test("Rule 3 | Yellow light → switch_to_red", {"current_light": "yellow"}, "switch_to_red", "rule_3")
    test("Rule 6 | High traffic + Red → switch_to_green", {"traffic_density": "high", "current_light": "red"}, "switch_to_green", "rule_6")
    test("Rule 8 | Heavy rain + High traffic → extend_green(25)", {"weather": "heavy_rain", "traffic_density": "high"}, "extend_green(25)", "rule_8")
    test("Rule 9 | Heavy rain → display_warning message", {"weather": "heavy_rain"}, "display_warning(Slippery road; Drive carefully)", "rule_9")
    test("Rule 12 | Night + Pedestrians → extend_red(10)", {"time_of_day": "night", "pedestrian_presence": "yes"}, "extend_red(10)", "rule_12")
    test("Rule 15 | Emergency vehicle → give_emergency_priority", {"emergency_vehicle": "yes"}, "give_emergency_priority", "rule_15")
    test("Rule 17 | Heavy rain + High + Day → extend_green(35)", {"weather": "heavy_rain", "traffic_density": "high", "time_of_day": "day"}, "extend_green(35)", "rule_17")
    test("Rule 20 | Heavy rain + Pedestrians + Red → extend_red(25)", {"weather": "heavy_rain", "pedestrian_presence": "yes", "current_light": "red"}, "extend_red(25)", "rule_20")

    # Summary
    # print the final pass/fail tally and a per-test status log
    print("\n" + "═" * 62)
    print(f" RESULTS: {passed} passed {failed} failed 8 total")
    print("═" * 62)
    for status, name in log:
        print(f" {status} {name}")
    print("═" * 62 + "\n")

# ════════════════════════════════════════════════════════════
# ENTRY POINT
# Runs the demo first to show xample decisions, then the test
# suite to verify all rules behave as expected.
# ════════════════════════════════════════════════════════════
if __name__ == "__main__":
    run_demo()
    run_tests()