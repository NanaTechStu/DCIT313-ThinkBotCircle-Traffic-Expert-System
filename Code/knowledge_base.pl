%% knowledge_base.pl
%% Production rules for the Adaptive Traffic Signal Control Expert System.
%%
%% rule(+ID, +Priority, +Conditions, +Action)
%%
%% Priority levels (ascending): basic < density < time < weather < pedestrian < emergency
%%
%% Additive actions — always included in output, never conflict-resolved:
%%   give_emergency_priority, activate_pedestrian_crossing, display_warning(_)
%%
%% Signal-timing actions — conflict-resolved; highest priority wins.
%% Ties broken by specificity (more conditions wins), then lower rule ID.

:- module(knowledge_base, [rule/4]).


% ─── A. Basic Signal Operation ───────────────────────────────────────────────
% Rule 1: Green light, low traffic → keep green as-is.
rule(1, basic, [light=green, density=low], maintain_green(30)).

% Rule 2: Red light, low traffic → keep red as-is.
rule(2, basic, [light=red, density=low], maintain_red(30)).

% Rule 3: Yellow light (default) → move to red.
rule(3, basic, [light=yellow], switch_to_red).


% ─── B. Traffic Density Adaptation ───────────────────────────────────────────
% Rule 4: Medium density + green → give vehicles a bit more time.
rule(4, density, [density=medium, light=green], extend_green(15)).

% Rule 5: High density + green → give vehicles significantly more time.
rule(5, density, [density=high, light=green], extend_green(20)).

% Rule 6: High density waiting at red → switch to green to relieve congestion.
rule(6, density, [density=high, light=red], switch_to_green).


% ─── C. Weather-Based Adjustments ────────────────────────────────────────────
% Rule 7: Light rain + yellow → delay the switch to give drivers reaction time.
rule(7, weather, [weather=light_rain, light=yellow], extend_yellow(5)).

% Rule 8: Heavy rain + high density + green light → extra green time (longer reaction times).
%          light=green added: extend_green only applies when green is active.
rule(8, weather, [weather=heavy_rain, density=high, light=green], extend_green(25)).

% Rule 9: Heavy rain (any conditions) → always warn drivers. [ADDITIVE]
rule(9, weather, [weather=heavy_rain], display_warning('Slippery road; Drive carefully')).

% Rule 10: Cloudy weather + medium density + green light → standard green timing.
rule(10, weather, [weather=cloudy, density=medium, light=green], maintain_green(30)).


% ─── D. Time-Based Safety ─────────────────────────────────────────────────────
% Rule 11: Night + low density + green light → standard green (quiet night traffic).
rule(11, time, [time=night, density=low, light=green], maintain_green(30)).

% Rule 12: Night + pedestrian present + red light → extend red for safe crossing.
rule(12, time, [time=night, pedestrian=yes, light=red], extend_red(10)).


% ─── E. Pedestrian Protection ────────────────────────────────────────────────
% Rule 13: Pedestrian at red light → activate crossing signal. [ADDITIVE]
rule(13, pedestrian, [pedestrian=yes, light=red], activate_pedestrian_crossing).

% Rule 14: Pedestrian + heavy rain + red light → extra red time for safe crossing.
rule(14, pedestrian, [pedestrian=yes, weather=heavy_rain, light=red], extend_red(15)).


% ─── F. Emergency Vehicle Priority ───────────────────────────────────────────
% Rule 15: Emergency vehicle present → always alert system. [ADDITIVE]
rule(15, emergency, [emergency=yes], give_emergency_priority).

% Rule 16: Emergency vehicle + red light → immediately switch to green to clear path.
rule(16, emergency, [emergency=yes, light=red], switch_to_green).


% ─── G. Combined Intelligent Rules ───────────────────────────────────────────
% Rule 17: Heavy rain + high density + daytime + green light → maximum green extension.
%          More specific than Rule 8 (4 vs 3 conditions); wins over it when all hold.
rule(17, weather, [weather=heavy_rain, density=high, time=day, light=green], extend_green(35)).

% Rule 18: Low density + daytime + green light → standard green (quiet daytime traffic).
rule(18, basic, [density=low, time=day, light=green], maintain_green(30)).

% Rule 19: Dry weather + medium density + green light → standard green (no adverse conditions).
rule(19, weather, [weather=dry, density=medium, light=green], maintain_green(30)).

% Rule 20: Heavy rain + pedestrian + red → significant red extension for safety.
%          Uses 'combined' priority (above pedestrian) so it beats Rule 14 when
%          all three conditions hold, since both rules now have 3 conditions.
rule(20, combined, [weather=heavy_rain, pedestrian=yes, light=red], extend_red(25)).
