-module(mls_tests).

-include_lib("eunit/include/eunit.hrl").



text_test() ->
  %% test 1
  Text =
    "
    {
      'a': 1,
      'b': 2
    }
    ",
  Expected = "{\n  \"a\": 1,\n  \"b\": 2\n}\n",

  Output = mls:text([list, escaped], Text),

  ?assertEqual(Expected, Output).

text_binary_test() ->
  %% test 1
  Text =
    "
    {
      'a': 1,
      'b': 2
    }
    ",
  Expected = <<"{\n  \"a\": 1,\n  \"b\": 2\n}\n">>,

  Output = mls:text([escaped], Text),

  ?assertEqual(Expected, Output).

json_test() ->

  JSON_1 = mls:text([binary, escaped],
    "
    {
      'a': 1,
      'b': 2
    }
    "),

  JSON_2 = mls:text([escaped], "
    {
      'a': 1,
      'b': 2
    }
    "),

  Output_json1_decoded_map = jsx:decode(JSON_1, [return_maps]),
  Output_json2_decoded_map = jsx:decode(JSON_2, [return_maps]),

  Expected_output_map = #{<<"a">> => 1,<<"b">> => 2},

  ?assertEqual(Expected_output_map, Output_json1_decoded_map),
  ?assertEqual(Expected_output_map, Output_json2_decoded_map).


nested_json_test() ->

  %% use \\' instead of \"
  JSON =
    "
    {
      'a': 1,
      'b': '{\\'c\\': 3}'
    }
    ",

  Output_json = mls:text([escaped], JSON),

  Expected_output_json =  <<"{\n  \"a\": 1,\n  \"b\": \"{\\\"c\\\": 3}\"\n}\n">>,

  Expected_output_json_map = #{<<"a">> => 1,<<"b">> => <<"{\"c\": 3}">>},
  Output_json_map = jsx:decode(mls:text([escaped], JSON), [return_maps]),

  ?assertEqual(Expected_output_json, Output_json),
  ?assertEqual(Expected_output_json_map, Output_json_map).


mustache_template_test() ->
  Template =
    "
    {
      'a': 1,
      'b': {{n}}
    }
    ",

  Output = mls:text([escaped], Template),

  %% mustach transform
  Output_render = bbmustache:render(Output, #{"n" => 2}),

  Template_filled =
    "
    {
      'a': 1,
      'b': 2
    }
    ",

  Output_filled = mls:text([escaped], Template_filled),

  ?assertEqual(Output_filled, Output_render).

text_alternative_test() ->

  MLS = mls:text("""
      1
      2
      3
    """
               ),

  Output =  <<"  1\n  2\n  3\n">>,

  ?assertEqual(Output, MLS).

texts_alternative_test() ->

  MLS = mls:text("""
                1
                2
                3
                """
               ),

  Output =  <<"1\n2\n3\n">>,

  ?assertEqual(Output, MLS).

markdown_test() ->

  Template = mls:text(
     """
     Header 1
     ====
     - _Key 1:_ **{{value1}}**
     - _Key 2:_ **{{value2}}**
     """
     ),

  Data   = #{"value1" => "Value 1", "value2" => "Value 2"},


  Template_output = bbmustache:render(Template, Data),

  Expected_template_output = <<"Header 1\n====\n- _Key 1:_ **Value 1**\n- _Key 2:_ **Value 2**\n">>,

  ?assertEqual(Expected_template_output, Template_output).

sql_pgsql_query_test() ->
  Query = mls:text([list,flat],
            """
            SELECT * FROM Customers
            WHERE
               NOT Country='Germany'
               AND NOT Country=$1;
            """
                  ),

  Expected_query = "SELECT * FROM Customers WHERE NOT Country='Germany' AND NOT Country=$1;",
  ?assertEqual(Expected_query, Query).


list_no_flat_no_escape_test() ->
  Query = mls:text([list],
            """
            SELECT * FROM Customers
            WHERE
               NOT Country='Germany'
               AND NOT Country=$1;
            """
                  ),

  Expected_query = "SELECT * FROM Customers\nWHERE\n   NOT Country='Germany'\n   AND NOT Country=$1;\n",
  ?assertEqual(Expected_query, Query).
