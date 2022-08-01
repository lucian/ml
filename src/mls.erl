-module(mls).

-export([text/1, text/2]).

text(T) when is_list(T) ->
  text([], T).

%% Erlang multi-line strings like support
%% based on the ideas from Elixir multi-line strings
%%
%% example:
%%
%% > text(list,
%% >   "
%% >   {
%% >     'a': 1,
%% >     'b': 2
%% >   }
%% >   ").
%% "{\n  \"a\": 1,\n  \"b\": 2\n}\n"
%%
%%  OR
%% > text(list,
%% >   """
%% >   {
%% >     'a': 1,
%% >     'b': 2
%% >   }
%% >   """).
%% "{\n  \"a\": 1,\n  \"b\": 2\n}\n"
text(Options, T) when is_list(T) ->
  {Type, Is_flat, Is_escaped} = parse_options(Options),
  text_parse(Type, Is_flat, Is_escaped, T).

% Thpe, Is_flat, Is_escaped
text_parse(list, false, true, T) ->
  text(list, false, true, T);

text_parse(list, true, false, T) ->
  %% remove the end of line space
  re:replace(text(list, true, false, T), "\\s$", "", [{return,list}]);

text_parse(list, true, true, T) ->
  %% remove the end of line space
  re:replace(text(list, true, true, T), "\\s$", "", [{return,list}]);

text_parse(binary, false, false, T) when is_list(T) ->
  list_to_binary(text(list, false, false, T));

text_parse(binary, false, true, T) when is_list(T) ->
  list_to_binary(text(list, false, true, T));

text_parse(binary, true, false, T) when is_list(T) ->
  list_to_binary(text(list, true, false, T));

text_parse(binary, true, true, T) when is_list(T) ->
  list_to_binary(text(list, true, true, T)).

%% specify End_line: "\n" or " "
text(list, Is_flat, Is_escaped, T)  when is_list(T) ->

  %% split the lines
  %% [[],"  {","    'a': 1,","    'b': 2","  }","  "]
  [Head|Lines] = re:split(T, "\n", [{return, list}]),

  case Head of
    [] ->  %% after " there is a new line then skip the first element
      %% Lines = ["  {","    'a': 1,","    'b': 2","  }","  "]

      %% reverse
      %% ["  ","  }","    'b': 2","    'a': 1,","  {"]
      Reversed_lines = lists:reverse(Lines),

      %% get the Last line ... now the first in the list after reverse to count the
      %% empty spaces and to strip them from the rest of the lines
      [Last|Rest] = Reversed_lines,

      Strip_length = length(Last),

      %% skip the empty line and strip the first characters from the other lines
      %% ["}","  \"b\": 2","  \"a\": 1,","{"]
      Strip_list = lists:map(fun(S) -> string:slice(S,Strip_length) end, Rest),

      Strip_list2 = case Is_flat of
                       false ->
                         %% fold and add new line (end of line character)
                         %% "{\n  \"a\": 1,\n  \"b\": 2\n}\n"
                         lists:foldl(fun(S, AccIn) ->
                                         string:concat(string:concat(S, "\n"), AccIn)
                                     end,
                                     "", Strip_list);
                       true ->
                         lists:foldl(fun(S, AccIn) ->
                                         string:concat(
                                           string:concat(
                                             re:replace(S, "^\\s+", "", [{return, list}]), " "),
                                           AccIn)
                                     end,
                                     "", Strip_list)
                     end,

      case Is_escaped of
        true ->
          %% replace \ with \\
          Replace_1 = re:replace(Strip_list2, "\\'", "\\\"", [{return,list}, global]),

          %% replace ' with \"
          re:replace(Replace_1, "'", "\\\"", [{return,list}, global]);
        false ->
          Strip_list2
      end
  end.


%% parse the options
%% options can be one or more of binary | list, flat, escaped
%%  [binary]
%%  [binary, flat, escaped]
%%
parse_options(Options) when is_list(Options) ->
  Is_binary = lists:member(binary, Options),
  Is_list = lists:member(list, Options),
  Is_flat = lists:member(flat, Options),
  Is_escaped = lists:member(escaped, Options),

  case {Is_binary, Is_list, Is_flat, Is_escaped} of
    {true, _, _, _} -> {binary, Is_flat, Is_escaped};  %% if binary set, ignore list option
    {false, true, _, _} -> {list, Is_flat, Is_escaped};
    {false, false, _, _} -> {binary, Is_flat, Is_escaped} %% default binary if nothing set
  end.
