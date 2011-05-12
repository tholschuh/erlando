%% The contents of this file are subject to the Mozilla Public License
%% Version 1.1 (the "License"); you may not use this file except in
%% compliance with the License. You may obtain a copy of the License
%% at http://www.mozilla.org/MPL/
%%
%% Software distributed under the License is distributed on an "AS IS"
%% basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See
%% the License for the specific language governing rights and
%% limitations under the License.
%%
%% The Original Code is Erlando.
%%
%% The Initial Developer of the Original Code is VMware, Inc.
%% Copyright (c) 2011-2011 VMware, Inc.  All rights reserved.
%%

-module(test_m, [InnerMonad]).
-compile({parse_transform, do}).

-behaviour(monad).
-export(['>>='/2, return/1, fail/1, passed/0, run/1, run/2]).

-ifdef(use_specs).
%% test_m _ is a test outcome
-type(monad(_A) :: fun (() -> 'passed' | {'failed', any()})).
-include("monad_specs.hrl").
-endif.

'>>='(X, Fun) -> fun () -> do([InnerMonad || passed <- X(),
                                             (Fun(undefined))()]) end.

return(_A) -> fun () -> InnerMonad:return(passed) end.
fail(X)    -> fun () -> InnerMonad:return({failed, X}) end.

passed()   -> return(passed).

run(Monad, Options) ->
    Result = run(Monad),
    case proplists:get_bool(report, Options) of
        true ->
            Name = proplists:get_value(name, Options, anonymous),
            case Result of
                passed ->
                    io:format("Test suite '~p' passed.~n", [Name]);
                {failed, Reason} ->
                    io:format("Test suite '~p' failed with ~p.~n",
                              [Name, Reason])
            end;
        false ->
            ok
    end,
    Result.

run(Monad) ->
    try
        do([InnerMonad || passed <- Monad(),
                          return(passed)])
    catch
        Class:Reason ->
            (THIS:fail({Class, Reason}))()
    end.
