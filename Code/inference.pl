%% inference.pl
%% Forward-chaining inference engine for the Traffic Expert System.
%%
%% Top-level call:
%%   forward_chain(+Inputs, -Actions)
%%   Inputs  = list of Key=Value atoms, e.g. [density=high, light=red, ...]
%%   Actions = list of action terms produced by fired rules
%%
%% Standalone test (from project root):
%%   swipl -g "use_module('Code/inference'), \
%%              forward_chain([density=high,weather=heavy_rain,time=day, \
%%                             pedestrian=no,emergency=no,light=green], A), \
%%              writeln(A), halt" -t halt
%%
%%   Or interactively:
%%   ?- use_module('Code/inference').
%%   ?- forward_chain([density=high, weather=heavy_rain, time=day,
%%                     pedestrian=no, emergency=no, light=green], Actions).

:- module(inference, [forward_chain/2]).

:- use_module(knowledge_base).
:- use_module(library(apply)).   % include/3, exclude/3, foldl/6

:- dynamic wm/1.


% ─── Priority Values ──────────────────────────────────────────────────────────
% Higher numeric value = higher importance in conflict resolution.

priority_value(basic,      1).
priority_value(density,    2).
priority_value(time,       3).
priority_value(weather,    4).
priority_value(pedestrian, 5).
priority_value(emergency,  6).


% ─── Additive Actions ─────────────────────────────────────────────────────────
% These actions are ALWAYS included in output regardless of other rules.
% They never compete with signal-timing actions.

is_additive_action(give_emergency_priority).
is_additive_action(activate_pedestrian_crossing).
is_additive_action(display_warning(_)).


% ─── Working Memory ───────────────────────────────────────────────────────────

%% assert_inputs(+Pairs)
%  Clears working memory and asserts each Key=Value pair as a wm/1 fact.
assert_inputs(Pairs) :-
    retractall(wm(_)),
    forall(member(Pair, Pairs), assertz(wm(Pair))).

%% conditions_met(+Conditions)
%  Succeeds when every Key=Value in Conditions is present in working memory.
conditions_met([]).
conditions_met([K=V | Rest]) :-
    wm(K=V),
    conditions_met(Rest).


% ─── Rule Firing ──────────────────────────────────────────────────────────────

%% fire_rules(-Fired)
%  Collects all rules whose conditions are satisfied in working memory.
%  Each element: fired(ID, Priority, NumConditions, Action)
%  NumConditions is used as a specificity score during conflict resolution.
fire_rules(Fired) :-
    findall(
        fired(ID, Priority, NumConds, Action),
        (   rule(ID, Priority, Conds, Action),
            conditions_met(Conds),
            length(Conds, NumConds)
        ),
        Fired
    ).


% ─── Conflict Resolution ──────────────────────────────────────────────────────

%% resolve_conflicts(+Fired, -FinalActions)
%  1. Additive actions: all of them are included.
%  2. Signal-timing actions: only the winner survives.
%     Winner = highest priority category.
%     Tie on priority → more conditions (specificity) wins.
%     Tie on specificity → lower rule ID wins.
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

%% best_signal(+SignalFired, -BestAction)
%  Folds through the fired signal rules to find the highest-priority winner.
best_signal([First | Rest], BestAction) :-
    foldl(pick_higher_priority, Rest, First, fired(_, _, _, BestAction)).

%% pick_higher_priority(+Candidate, +Current, -Winner)
%  Picks the better rule according to: priority > specificity > rule ID.
pick_higher_priority(Candidate, Current, Winner) :-
    Candidate = fired(CandID, CandPri, CandLen, _),
    Current   = fired(CurID,  CurPri,  CurLen,  _),
    priority_value(CandPri, CandV),
    priority_value(CurPri,  CurV),
    (   CandV > CurV     -> Winner = Candidate   % higher priority category
    ;   CandV < CurV     -> Winner = Current
    ;   CandLen > CurLen -> Winner = Candidate   % same priority, more specific
    ;   CandLen < CurLen -> Winner = Current
    ;   CandID < CurID   -> Winner = Candidate   % same specificity, lower ID
    ;                       Winner = Current
    ).


% ─── Top-Level Entry Point ────────────────────────────────────────────────────

%% forward_chain(+Inputs, -Actions)
%  Assert inputs into working memory, fire all matching rules, resolve conflicts.
%  Returns [no_action] when no rules match.
forward_chain(Inputs, Actions) :-
    assert_inputs(Inputs),
    fire_rules(Fired),
    (   Fired = []
    ->  Actions = [no_action]
    ;   resolve_conflicts(Fired, Actions)
    ).
