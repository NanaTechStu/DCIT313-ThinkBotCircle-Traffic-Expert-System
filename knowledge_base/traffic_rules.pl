/*
    traffic_rules.pl
    Knowledge Base — Adaptive Traffic Signal Control Expert System
    DCIT 313 Group Project | ThinkBot Circle

    Rules authored by : Bilson Priscilla Essirifua (Knowledge Engineer)
    Pseudo-code by    : Adu Selina Odoi             (Knowledge Engineer)
    Prolog code by    : Stephen Edem Kwame Doe-lawson (Programmer – Prolog Owner)

    Source document   : "Expert System for Adaptive Traffic Signal Control"
                        DCIT 313 Knowledge Base Document

    ─────────────────────────────────────────────────────────────────────────────
    CONTENTS
      Section 1 — Production Rules  (20 IF-THEN rules, Sections A–G)
      Section 2 — Inference Engine  (Forward chaining + conflict resolution)
      Section 3 — Query Interface   (evaluate/7, entry point for Python/pyswip)
    ─────────────────────────────────────────────────────────────────────────────
*/

:- use_module(library(apply)).   % include/3, exclude/3, foldl/4
:- dynamic wm/1.                 % Working memory  —  wm(key=value)


/* ═════════════════════════════════════════════════════════════════════════════
   SECTION 1 — PRODUCTION RULES
   ─────────────────────────────────────────────────────────────────────────────
   Format  :  rule(+ID, +Priority, +Conditions, +Action)

   Priority levels (ascending):
       basic < density < time < weather < pedestrian < combined < emergency

   Additive actions — always fired, never in conflict:
       give_emergency_priority
       activate_pedestrian_crossing
       display_warning(_)

   Signal-timing actions — conflict-resolved; one winner per evaluation:
       Winner = highest priority category.
       Tie  →  more conditions (specificity) wins.
       Tie  →  lower rule ID wins.

   Note: Where the KB document does not specify a light state but the action
   only makes sense for one (e.g. extend_green requires light=green), the
   implied condition has been added as an explicit Prolog condition.
═════════════════════════════════════════════════════════════════════════════ */

% ── A. Basic Signal Operation ─────────────────────────────────────────────────

% Rule 1 — Green light, low density → keep green at default timing.
rule(1, basic, [light=green, density=low], maintain_green(30)).

% Rule 2 — Red light, low density → keep red at default timing.
rule(2, basic, [light=red, density=low], maintain_red(30)).

% Rule 3 — Yellow light → switch to red (standard yellow behaviour).
rule(3, basic, [light=yellow], switch_to_red).


% ── B. Traffic Density Adaptation ─────────────────────────────────────────────

% Rule 4 — Medium density + green → extend green slightly.
rule(4, density, [density=medium, light=green], extend_green(15)).

% Rule 5 — High density + green → extend green significantly.
rule(5, density, [density=high, light=green], extend_green(20)).

% Rule 6 — High density + red → switch to green to relieve congestion.
rule(6, density, [density=high, light=red], switch_to_green).


% ── C. Weather-Based Adjustments ──────────────────────────────────────────────

% Rule 7 — Light rain + yellow → delay transition for driver reaction time.
rule(7, weather, [weather=light_rain, light=yellow], extend_yellow(5)).

% Rule 8 — Heavy rain + high density + green → extend green (longer stopping distance).
%          light=green added: extend_green only applies when green is active.
rule(8, weather, [weather=heavy_rain, density=high, light=green], extend_green(25)).

% Rule 9 — Heavy rain (any state) → always warn drivers.  [ADDITIVE]
rule(9, weather, [weather=heavy_rain], display_warning('Slippery road; Drive carefully')).

% Rule 10 — Cloudy + medium density + green → maintain standard green timing.
%           light=green added: maintain_green only applies when green is active.
rule(10, weather, [weather=cloudy, density=medium, light=green], maintain_green(30)).


% ── D. Time-Based Safety ──────────────────────────────────────────────────────

% Rule 11 — Night + low density + green → no need to rush; standard green.
%           light=green added: maintain_green only applies when green is active.
rule(11, time, [time=night, density=low, light=green], maintain_green(30)).

% Rule 12 — Night + pedestrian present + red → extend red for safe crossing.
%           light=red added: extend_red only applies when red is active.
rule(12, time, [time=night, pedestrian=yes, light=red], extend_red(10)).


% ── E. Pedestrian Protection ──────────────────────────────────────────────────

% Rule 13 — Pedestrian at red light → activate crossing signal.  [ADDITIVE]
rule(13, pedestrian, [pedestrian=yes, light=red], activate_pedestrian_crossing).

% Rule 14 — Pedestrian + heavy rain + red → extra red time for safe crossing.
%           light=red added: extend_red only applies when red is active.
rule(14, pedestrian, [pedestrian=yes, weather=heavy_rain, light=red], extend_red(15)).


% ── F. Emergency Vehicle Priority ─────────────────────────────────────────────

% Rule 15 — Emergency vehicle present → alert system.  [ADDITIVE]
rule(15, emergency, [emergency=yes], give_emergency_priority).

% Rule 16 — Emergency vehicle + red → switch to green immediately.
rule(16, emergency, [emergency=yes, light=red], switch_to_green).


% ── G. Combined Intelligent Rules ─────────────────────────────────────────────

% Rule 17 — Heavy rain + high density + daytime + green → maximum green extension.
%           More specific than Rule 8 (4 conditions vs 3); beats it when time=day.
rule(17, weather, [weather=heavy_rain, density=high, time=day, light=green], extend_green(35)).

% Rule 18 — Low density + daytime + green → standard green (quiet daytime traffic).
%           light=green added: maintain_green only applies when green is active.
rule(18, basic, [density=low, time=day, light=green], maintain_green(30)).

% Rule 19 — Dry weather + medium density + green → standard green (no adverse conditions).
%           light=green added: maintain_green only applies when green is active.
rule(19, weather, [weather=dry, density=medium, light=green], maintain_green(30)).

% Rule 20 — Heavy rain + pedestrian + red → significant red extension.
%           Uses 'combined' priority so it beats Rule 14 (pedestrian priority)
%           when all three conditions hold — both rules have 3 conditions at red,
%           so a higher priority tier is needed to select the larger extension (25 s).
rule(20, combined, [weather=heavy_rain, pedestrian=yes, light=red], extend_red(25)).


/* ═════════════════════════════════════════════════════════════════════════════
   SECTION 2 — INFERENCE ENGINE (Forward Chaining)
   ─────────────────────────────────────────────────────────────────────────────
   Implements the forward chaining strategy described in the KB document:
     1. Assert all user inputs into working memory.
     2. Evaluate every rule against working memory (fire_rules).
     3. Resolve conflicts among signal-timing actions (resolve_conflicts).
     4. Return the final set of actions.
═════════════════════════════════════════════════════════════════════════════ */

% ── Priority Values ───────────────────────────────────────────────────────────

priority_value(basic,      1).
priority_value(density,    2).
priority_value(time,       3).
priority_value(weather,    4).
priority_value(pedestrian, 5).
priority_value(combined,   6).
priority_value(emergency,  7).

% ── Additive Action Classification ───────────────────────────────────────────

is_additive_action(give_emergency_priority).
is_additive_action(activate_pedestrian_crossing).
is_additive_action(display_warning(_)).

% ── Working Memory ────────────────────────────────────────────────────────────

% assert_inputs(+Pairs)
% Clears working memory and loads new Key=Value input pairs.
assert_inputs(Pairs) :-
    retractall(wm(_)),
    forall(member(Pair, Pairs), assertz(wm(Pair))).

% conditions_met(+Conditions)
% Succeeds when every Key=Value in the list exists in working memory.
conditions_met([]).
conditions_met([K=V | Rest]) :-
    wm(K=V),
    conditions_met(Rest).

% ── Rule Firing ───────────────────────────────────────────────────────────────

% fire_rules(-Fired)
% Collects every rule whose conditions are satisfied in working memory.
% Result elements: fired(ID, Priority, NumConditions, Action)
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

% resolve_conflicts(+Fired, -FinalActions)
% Splits fired rules into additive (all kept) and signal-timing (one winner).
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

% best_signal(+Fired, -BestAction)
% Folds through competing signal rules to find the overall winner.
best_signal([First | Rest], BestAction) :-
    foldl(pick_higher_priority, Rest, First, fired(_, _, _, BestAction)).

% pick_higher_priority(+Candidate, +Current, -Winner)
% Selection criteria: priority category > specificity > lower rule ID.
pick_higher_priority(Candidate, Current, Winner) :-
    Candidate = fired(CandID, CandPri, CandLen, _),
    Current   = fired(CurID,  CurPri,  CurLen,  _),
    priority_value(CandPri, CandV),
    priority_value(CurPri,  CurV),
    (   CandV > CurV     -> Winner = Candidate
    ;   CandV < CurV     -> Winner = Current
    ;   CandLen > CurLen -> Winner = Candidate
    ;   CandLen < CurLen -> Winner = Current
    ;   CandID < CurID   -> Winner = Candidate
    ;                       Winner = Current
    ).

% ── Top-Level Entry Point ─────────────────────────────────────────────────────

% forward_chain(+Inputs, -Actions)
% Inputs  — list of Key=Value atoms, e.g. [density=high, weather=dry, ...]
% Actions — list of resulting action terms.
forward_chain(Inputs, Actions) :-
    assert_inputs(Inputs),
    fire_rules(Fired),
    (   Fired = []
    ->  Actions = [no_action]
    ;   resolve_conflicts(Fired, Actions)
    ).


/* ═════════════════════════════════════════════════════════════════════════════
   SECTION 3 — QUERY INTERFACE  (called from Python via pyswip)
═════════════════════════════════════════════════════════════════════════════ */

% evaluate(+Density, +Weather, +Time, +Light, +Pedestrian, +Emergency, -Descriptions)
% Main entry point. Returns a list of human-readable description atoms.
evaluate(Density, Weather, Time, Light, Pedestrian, Emergency, Descriptions) :-
    Inputs = [ density=Density, weather=Weather, time=Time,
               light=Light, pedestrian=Pedestrian, emergency=Emergency ],
    forward_chain(Inputs, Actions),
    maplist(action_description, Actions, Descriptions).

% action_description(+Action, -Description)
% Converts an action term to a readable atom for display in Python.
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
