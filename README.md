mls
===

Multi-line strings like support for Erlang

Install
=======

add to `rebar.config`:

    {mls, "0.1.0"}

Build
-----

    $ rebar3 compile

Usage
-----

- use `"` or `"""` as delimters.

_Note:_ Extra `""` in Erlang are just empty sting concaternated. We can use `"""` to be consistent
with other implementations, but we don't have to.

### Options

    function  | parameters
    ----------+----------------
    text/1    | (Text)           | equivalent to mls:text(binary)
    text/2    | (Options, Text)

    Option can be one of

    Options  | Default | Note
    ---------+---------+---------------------------
     list    |         | return as list
     escaped |         | escape ouptut - replace 'with \"; replace  \'" with \\\""
     flat    |         | remove formatting; no escape
     binary  |   x     | return as binary


- Note: `ml:text(<text>)` is equivalent to `ml:text([], <text>)`, default option being `binary`

### Examples

    1> mls:text("
    1>   line1
    1>     line2
    1>   ").
    <<"line1\n  line2\n">>

    2> mls: text("""
    2>   line1
    2>     line2
    2>   """).
    <<"line1\n  line2\n">>

    3> mls:text(
    3>   "
    3>   line1
    3>     line2
    3>   ").
    <<"line1\n  line2\n">>

    4> mls: text(
    4>   """
    4>   line1
    4>     line2
    4>   """).
    <<"line1\n  line2\n">>

- generic multiline text

    5> M2 = mls:text(
    5>   "
    5>   ----------
    5>   line_1
    5>     line_2
    5>       line_3
    5>   line_4
    5>   ----------
    5>   ").
    <<"----------\nline_1\n  line_2\n    line_3\nline_4\n----------\n">>

    6> io:format("~s~n", [M2]).
    ----------
    line_1
      line_2
        line_3
    line_4
    ----------
    ok

- JSON as multiline text


    7> Json_template = mls:text(binary_escaped,
    7>    """
    7>    {
    7>     'key1': 'value1',
    7>     'key2': '{{value2}}'
    7>    }
    7>    """
    7>    ).
    <<"{\n \"key1\": \"value1\",\n \"key2\": \"{{value2}}\"\n}\n">>

    8> bbmustache:render(Json_template, #{"value2" => "value 2"}).
    <<"{\n \"key1\": \"value1\",\n \"key2\": \"value 2\"\n}\n">>

- example epgsql query - use the `list_flat` option to connvert multi-line string to a long string.

    9> Query = mls:text(list_flat,
    9>   """
    9>   SELECT * FROM Customers
    9>   WHERE
    9>     NOT Country='Germany'
    9>     AND NOT Country=$1;
    9>   """).
    "SELECT * FROM Customers WHERE NOT Country='Germany' AND NOT Country=$1;"
