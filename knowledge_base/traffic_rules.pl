/*
    traffic_rules.pl
    Knowledge Base — Adaptive Traffic Signal Control Expert System
    DCIT 313 Group Project | ThinkBot Circle

    Knowledge authored by:
        Bilson Priscilla Essirifua  (Knowledge Engineer)
        Adu Selina Odoi             (Knowledge Engineer, Pseudo-code)

    This file contains:
        1. Production Rules  — 20 IF-THEN rules (Sections A–G)
        2. Inference Engine  — Forward chaining with conflict resolution
        3. Query Interface   — evaluate/7, called from Python via pyswip
*/

:- use_module(library(apply)).   % include/3, exclude/3, foldl/4
:- dynamic wm/1.                 % Working memory facts: wm(key=value)


/* ══════════════════════════════════════════════════════════════════════════════
   SECTION 1 — PRODUCTION RULES
   Format: rule(ID, Priority, [Conditions], Action)

   Priority levels (ascending): basic < density < time < weather < pedestrian < combined < emergency
   Conditions: list of Key=Value pairs matched against working memory.

   Additive actions — always fired, no conflict:
       give_emergency_priority, activate_pedestrian_crossing, display_warning(_)
   Signal-timing actions — conflict-resolved; highest priority wins.
   Tie-break: more conditions (specificity) > lower rule ID.
══════════════════════════════════════════════════════════════════════════════ */

% ── A. Basic Signal Operation ─────────────────────────────────────────────────

% IF green light AND low traffic density THEN maintain green for 30 seconds
rule(1, basic, [light=green, density=low], maintain_green(30)).

% IF red light AND low traffic density THEN maintain red for 30 seconds
rule(2, basic, [light=red, density=low], maintain_red(30)).

% IF yellow light THEN switch to red (default yellow behaviour)
rule(3, basic, [light=yellow], switch_to_red).


% ── B. Traffic Density Adaptation ─────────────────────────────────────────────

% IF medium density AND green light THEN extend green by 15 seconds
rule(4, density, [density=medium, light=green], extend_green(15)).

% IF high density AND green light THEN extend green by 20 seconds
rule(5, density, [density=high, light=green], extend_green(20)).

% IF high density AND red light THEN switch to green (relieve congestion)
rule(6, density, [density=high, light=red], switch_to_green).


% ── C. Weather-Based Adjustments ──────────────────────────────────────────────

% IF light rain AND yellow light THEN extend yellow by 5 seconds (driver reaction time)
rule(7, weather, [weather=light_rain, light=yellow], extend_yellow(5)).

% IF heavy rain AND high density AND green light THEN extend green by 25 seconds
rule(8, weather, [weather=heavy_rain, density=high, light=green], extend_green(25)).

% IF heavy rain (any conditions) THEN warn drivers  [ADDITIVE — always fires]
rule(9, weather, [weather=heavy_rain], display_warning('Slippery road; Drive carefully')).

% IF cloudy AND medium density AND green light THEN maintain green for 30 seconds
rule(10, weather, [weather=cloudy, density=medium, light=green], maintain_green(30)).


% ── D. Time-Based Safety ──────────────────────────────────────────────────────

% IF night AND low density AND green light THEN maintain green (quiet night traffic)
rule(11, time, [time=night, density=low, light=green], maintain_green(30)).

% IF night AND pedestrian present AND red light THEN extend red by 10 seconds
rule(12, time, [time=night, pedestrian=yes, light=red], extend_red(10)).


% ── E. Pedestrian Protection ──────────────────────────────────────────────────

% IF pedestrian present AND red light THEN activate pedestrian crossing  [ADDITIVE]
rule(13, pedestrian, [pedestrian=yes, light=red], activate_pedestrian_crossing).

% IF pedestrian present AND heavy rain AND red light THEN extend red by 15 seconds
rule(14, pedestrian, [pedestrian=yes, weather=heavy_rain, light=red], extend_red(15)).


% ── F. Emergency Vehicle Priority ─────────────────────────────────────────────

% IF emergency vehicle present THEN alert system  [ADDITIVE — always fires]
rule(15, emergency, [emergency=yes], give_emergency_priority).

% IF emergency vehicle present AND red light THEN switch to green immediately
rule(16, emergency, [emergency=yes, light=red], switch_to_green).


% ── G. Combined Intelligent Rules ─────────────────────────────────────────────

% IF heavy rain AND high density AND daytime AND green light THEN extend green by 35 s
% (More specific than Rule 8 — wins when time=day is also known)
rule(17, weather, [weather=heavy_rain, density=high, time=day, light=green], extend_green(35)).

% IF low density AND daytime AND green light THEN maintain green (quiet daytime)
rule(18, basic, [density=low, time=day, light=green], maintain_green(30)).

% IF dry weather AND medium density AND green light THEN maintain green
rule(19, weather, [weather=dry, density=medium, light=green], maintain_green(30)).

% IF heavy rain AND pedestrian present AND red light THEN extend red by 25 seconds
% Uses 'combined' priority so it beats Rule 14 (pedestrian) when both conditions hold
rule(20, combined, [weather=heavy_rain, pedestrian=yes, light=red], extend_red(25)).


/* ══════════════════════════════════════════════════════════════════════════════
   SECTION 2 — INFERENCE ENGINE
   Forward chaining: assert inputs → fire all matching rules → resolve conflicts.
══════════════════════════════════════════════════════════════════════════════ */

% ── Priority Values ───────────────────────────────────────────────────────────

priority_value(basic,      1).
priority_value(density,    2).
priority_value(time,       3).
priority_value(weather,    4).
priority_value(pedestrian, 5).
priority_value(combined,   6).  % multi-condition rules that override single-category ones
priority_value(emergency,  7).

% ── Additive Actions (always included, not subject to conflict resolution) ────

is_additive_action(give_emergency_priority).
is_additive_action(activate_pedestrian_crossing).
is_additive_action(display_warning(_)).

% ── Working Memory ────────────────────────────────────────────────────────────

%  assert_inputs(+Pairs)
%  Clears working memory and loads the new Key=Value input pairs.
assert_inputs(Pairs) :-
    retractall(wm(_)),
    forall(member(Pair, Pairs), assertz(wm(Pair))).

%  conditions_met(+Conditions)
%  Succeeds when every Key=Value in the list exists in working memory.
conditions_met([]).
conditions_met([K=V | Rest]) :-
    wm(K=V),
    conditions_met(Rest).

% ── Rule Firing ───────────────────────────────────────────────────────────────

%  fire_rules(-Fired)
%  Collects every rule whose conditions are satisfied.
%  Each result: fired(ID, Priority, NumConditions, Action)
fire_rules(Fired) :-
    findall(
        fired(ID, Priority, NumConds, Action),
        (   rule(ID, Priority, Conds, Action),
            conditions_met(Conds),
            length(Conds, NumConds)
        ),
        Fired
    ).

% ── Conflict Resolution ───────────────────────────────────────────────────────

%  resolve_conflicts(+Fired, -FinalActions)
%  Additive actions: all included.
%  Signal-timing actions: winner = highest priority; tie → most conditions; tie → lower ID.
resolve_conflicts(Fired, FinalActions) :-
    include(fired_is_additive, Fired, AdditiveFired),
    exclude(fired_is_additive, Fired, SignalFired),
    maplist(fired_action, AdditiveFired, AdditiveActions),
    (   SignalFired = []
    ->  SignalActions = []
    ;   best_signal(SignalFired, BestAction),
        SignalActions = [BestAction]
    ),
    append(AdditiveActions, SignalActions, FinalActions).

fired_is_additive(fired(_, _, _, Action)) :-
    is_additive_action(Action).

fired_action(fired(_, _, _, Action), Action).

%  best_signal(+Fired, -BestAction)
%  Folds through competing signal rules to find the overall winner.
best_signal([First | Rest], BestAction) :-
    foldl(pick_higher_priority, Rest, First, fired(_, _, _, BestAction)).

pick_higher_priority(Candidate, Current, Winner) :-
    Candidate = fired(CandID, CandPri, CandLen, _),
    Current   = fired(CurID,  CurPri,  CurLen,  _),
    priority_value(CandPri, CandV),
    priority_value(CurPri,  CurV),
    (   CandV > CurV     -> Winner = Candidate   % higher priority category
    ;   CandV < CurV     -> Winner = Current
    ;   CandLen > CurLen -> Winner = Candidate   % same priority, more specific
    ;   CandLen < CurLen -> Winner = Current
    ;   CandID < CurID   -> Winner = Candidate   % same specificity, lower rule ID
    ;                       Winner = Current
    ).

% ── Top-Level Entry Point ─────────────────────────────────────────────────────

%  forward_chain(+Inputs, -Actions)
%  Inputs: list of Key=Value atoms e.g. [density=high, weather=dry, ...]
%  Actions: list of resulting action terms.
forward_chain(Inputs, Actions) :-
    assert_inputs(Inputs),
    fire_rules(Fired),
    (   Fired = []
    ->  Actions = [no_action]
    ;   resolve_conflicts(Fired, Actions)
    ).


/* ══════════════════════════════════════════════════════════════════════════════
   SECTION 3 — QUERY INTERFACE  (called from Python via pyswip)
══════════════════════════════════════════════════════════════════════════════ */

%  evaluate(+Density, +Weather, +Time, +Light, +Pedestrian, +Emergency, -Descriptions)
%  Main entry point for the Python interface.
%  Returns a list of human-readable description atoms.
evaluate(Density, Weather, Time, Light, Pedestrian, Emergency, Descriptions) :-
    Inputs = [ density=Density, weather=Weather, time=Time,
               light=Light, pedestrian=Pedestrian, emergency=Emergency ],
    forward_chain(Inputs, Actions),
    maplist(action_description, Actions, Descriptions).

%  action_description(+Action, -Description)
%  Converts an action term to a readable atom for display in Python.
action_description(maintain_green(N), D) :-
    format(atom(D), 'Maintain Green for ~w seconds (default timing)', [N]).
action_description(maintain_red(N), D) :-
    format(atom(D), 'Maintain Red for ~w seconds (default timing)', [N]).
action_description(extend_green(N), D) :-
    format(atom(D), 'Extend Green by +~w seconds', [N]).
action_description(extend_red(N), D) :-
    format(atom(D), 'Extend Red by +~w seconds', [N]).
action_description(extend_yellow(N), D) :-
    format(atom(D), 'Extend Yellow by +~w seconds', [N]).
action_description(switch_to_green,
    'Switch signal to GREEN immediately').
action_description(switch_to_red,
    'Switch signal to RED immediately').
action_description(give_emergency_priority,
    '[PRIORITY] Give Emergency Vehicle Priority — clear path').
action_description(activate_pedestrian_crossing,
    '[SAFETY] Activate Pedestrian Crossing signal').
action_description(display_warning(Msg), D) :-
    format(atom(D), '[WARNING] ~w', [Msg]).
action_description(no_action,
    'No rules matched — maintain current signal state').
