%% server.pl
%% HTTP server for the Traffic Expert System.
%% Run from the project root:  swipl Code/server.pl
%% Then open:                  http://localhost:8080

:- use_module(library(http/thread_httpd)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/http_parameters)).
:- use_module(library(http/html_write)).
:- use_module(library(http/http_files)).
:- use_module(inference).

% Compute the static-files directory relative to this source file.
:- prolog_load_context(directory, SrcDir),
   atomic_list_concat([SrcDir, '/static'], StaticDir),
   assert(app_static_dir(StaticDir)).


% ─── Route Registration ───────────────────────────────────────────────────────

:- http_handler(root(.),        serve_index,    []).
:- http_handler(root(evaluate), handle_evaluate, [method(post)]).
:- http_handler(root(static),   serve_static,   [prefix]).


% ─── Static File Handlers ─────────────────────────────────────────────────────

serve_index(Request) :-
    app_static_dir(Static),
    atomic_list_concat([Static, '/index.html'], IndexFile),
    http_reply_file(IndexFile, [], Request).

serve_static(Request) :-
    app_static_dir(Static),
    http_reply_from_files(Static, [], Request).


% ─── Evaluate Handler ─────────────────────────────────────────────────────────

handle_evaluate(Request) :-
    http_parameters(Request, [
        density(  Density,   [atom]),
        weather(  Weather,   [atom]),
        time(     Time,      [atom]),
        pedestrian(Pedestrian,[atom]),
        emergency(Emergency, [atom]),
        light(    Light,     [atom])
    ]),
    Inputs = [ density=Density, weather=Weather, time=Time,
               pedestrian=Pedestrian, emergency=Emergency, light=Light ],
    forward_chain(Inputs, Actions),
    maplist(input_to_row,   Inputs,  InputRows),
    maplist(action_to_item, Actions, ActionItems),
    reply_html_page(
        [ title('Traffic Expert System'),
          link([rel=stylesheet, type='text/css', href='/static/style.css'])
        ],
        [ div([class='container'],
              [ p(a([href='/'], '← New Evaluation')),
                h1('Traffic Signal Decision'),
                div([class='section'],
                    [ h2('Input Conditions'),
                      table([class='input-table'],
                            [ tr([th('Variable'), th('Value')]) | InputRows ])
                    ]),
                div([class='section'],
                    [ h2('Recommended Actions'),
                      ul([class='action-list'], ActionItems)
                    ])
              ])
        ]
    ).


% ─── HTML Term Helpers ────────────────────────────────────────────────────────

input_to_row(K=V, tr([td(K), td(V)])).

action_to_item(Action, li([class=Class], Label)) :-
    action_label(Action, Label),
    action_css_class(Action, Class).

%% action_label(+Action, -Label)
action_label(maintain_green(N),           L) :- format(atom(L), 'Maintain Green for ~w seconds (default)', [N]).
action_label(maintain_red(N),             L) :- format(atom(L), 'Maintain Red for ~w seconds (default)', [N]).
action_label(extend_green(N),             L) :- format(atom(L), 'Extend Green by +~w seconds', [N]).
action_label(extend_red(N),               L) :- format(atom(L), 'Extend Red by +~w seconds', [N]).
action_label(extend_yellow(N),            L) :- format(atom(L), 'Extend Yellow by +~w seconds', [N]).
action_label(switch_to_green,             'Switch signal to Green').
action_label(switch_to_red,               'Switch signal to Red').
action_label(give_emergency_priority,     'Give Emergency Vehicle Priority').
action_label(activate_pedestrian_crossing,'Activate Pedestrian Crossing').
action_label(display_warning(Msg),        L) :- format(atom(L), 'Display Warning: ~w', [Msg]).
action_label(no_action,                   'No matching rules — maintain current signal state').

%% action_css_class(+Action, -CSSClass)
action_css_class(give_emergency_priority,      emergency).
action_css_class(activate_pedestrian_crossing, pedestrian).
action_css_class(display_warning(_),           warning).
action_css_class(no_action,                    neutral).
action_css_class(_,                            signal).


% ─── Server Startup ───────────────────────────────────────────────────────────

start_server :-
    Port = 8080,
    http_server(http_dispatch, [port(Port)]),
    format('~n=== Traffic Expert System ===~n'),
    format('Server running at http://localhost:~w~n', [Port]),
    format('Press Ctrl+C to stop.~n~n').

:- initialization(start_server, main).
