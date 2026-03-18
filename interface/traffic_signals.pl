% ============================================================
% KNOWLEDGE BASE: Expert System for Adaptive Traffic Signal Control
% File: knowledge_base/traffic_signals.pl
% Knowledge Engineer: Bilson Priscilla Essirifua
% DCIT 313 – Expert Systems Project
% ============================================================

#The Prolog file contains the knowledge base and rules that control the behavior of the traffic signals.
#This file contains the rules and knowledge about how traffic signals behave.

#What it does:
 #• Stores facts and rules about traffic lights.
 #• Determines when lights should change (red, yellow, green).
 #• Applies logical reasoning to traffic situations.


% ── Declare dynamic predicates so Python can assert/retract facts
:- dynamic traffic_density/1.
:- dynamic current_light/1.
:- dynamic emergency_vehicle/1.
:- dynamic pedestrian_presence/1.
:- dynamic weather/1.
:- dynamic time_of_day/1.
:- dynamic signal_action/2.

% ── DEFAULT TIMING CONSTANTS ────────────────────────────────
% default_green = 30 seconds
% default_yellow = 5 seconds
% default_red = 30 seconds

% ============================================================
% SECTION G: COMBINED INTELLIGENT RULES (Most specific first)
% ============================================================

% Rule 20: Heavy rain + Pedestrians + Red → Extend red 25s
signal_action(extend_red(25), rule_20) :-
    weather(heavy_rain),
    pedestrian_presence(yes),
    current_light(red).

% Rule 17: Heavy rain + High traffic + Day → Extend green 35s
signal_action(extend_green(35), rule_17) :-
    weather(heavy_rain),
    traffic_density(high),
    time_of_day(day).

% ============================================================
% SECTION C: WEATHER-BASED ADJUSTMENT RULES
% ============================================================

% Rule 8: Heavy rain + High traffic → Extend green 25s
signal_action(extend_green(25), rule_8) :-
    weather(heavy_rain),
    traffic_density(high).

% Rule 9: Heavy rain → Display warning message
signal_action(display_warning('Slippery road; Drive carefully'), rule_9) :-
    weather(heavy_rain).

% Rule 7: Light rain + Yellow → Extend yellow 5s
signal_action(extend_yellow(5), rule_7) :-
    weather(light_rain),
    current_light(yellow).

% Rule 10: Cloudy + Medium traffic → Maintain green 30s
signal_action(maintain_green(30), rule_10) :-
    weather(cloudy),
    traffic_density(medium).

% Rule 19: Dry weather + Medium traffic → Maintain green 30s
signal_action(maintain_green(30), rule_19) :-
    weather(dry),
    traffic_density(medium).

% ============================================================
% SECTION F: EMERGENCY VEHICLE PRIORITY RULES
% ============================================================

% Rule 15: Emergency vehicle → Give emergency priority
signal_action(give_emergency_priority, rule_15) :-
    emergency_vehicle(yes).

% Rule 16: Emergency vehicle + Red → Switch to green
signal_action(switch_to_green, rule_16) :-
    emergency_vehicle(yes),
    current_light(red).

% ============================================================
% SECTION B: TRAFFIC DENSITY ADAPTATION RULES
% ============================================================

% Rule 6: High traffic + Red → Switch to green
signal_action(switch_to_green, rule_6) :-
    traffic_density(high),
    current_light(red).

% Rule 5: High traffic + Green → Extend green 20s
signal_action(extend_green(20), rule_5) :-
    traffic_density(high),
    current_light(green).

% Rule 4: Medium traffic + Green → Extend green 15s
signal_action(extend_green(15), rule_4) :-
    traffic_density(medium),
    current_light(green).

% ============================================================
% SECTION D: TIME-BASED SAFETY RULES
% ============================================================

% Rule 12: Night + Pedestrians → Extend red 10s
signal_action(extend_red(10), rule_12) :-
    time_of_day(night),
    pedestrian_presence(yes).

% Rule 11: Night + Low traffic → Maintain green 30s
signal_action(maintain_green(30), rule_11) :-
    time_of_day(night),
    traffic_density(low).

% ============================================================
% SECTION E: PEDESTRIAN PROTECTION RULES
% ============================================================

% Rule 14: Pedestrians + Heavy rain → Extend red 15s
signal_action(extend_red(15), rule_14) :-
    pedestrian_presence(yes),
    weather(heavy_rain).

% Rule 13: Pedestrians + Red → Activate pedestrian crossing
signal_action(activate_pedestrian_crossing, rule_13) :-
    pedestrian_presence(yes),
    current_light(red).

% ============================================================
% SECTION A: BASIC SIGNAL OPERATION RULES
% ============================================================

% Rule 3: Yellow → Switch to red
signal_action(switch_to_red, rule_3) :-
    current_light(yellow).

% Rule 2: Red + Low traffic → Maintain red 30s
signal_action(maintain_red(30), rule_2) :-
    current_light(red),
    traffic_density(low).

% Rule 1: Green + Low traffic → Maintain green 30s
signal_action(maintain_green(30), rule_1) :-
    current_light(green),
    traffic_density(low).

% Rule 18: Low traffic + Day → Maintain green 30s
signal_action(maintain_green(30), rule_18) :-
    traffic_density(low),
    time_of_day(day).