# frozen_string_literal: true

require "test_helper"

class ErrorsTest < Test::Unit::TestCase
  include YARP::DSL

  def test_constant_path_with_invalid_token_after
    assert_error_messages "A::$b", [
      "Expected identifier or constant after '::'",
      "Expected a newline or semicolon after statement."
    ]
  end

  def test_module_name_recoverable
    expected = ModuleNode(
      [],
      KEYWORD_MODULE("module"),
      ConstantReadNode(),
      StatementsNode(
        [ModuleNode(
           [],
           KEYWORD_MODULE("module"),
           MissingNode(),
           nil,
           MISSING("")
         )]
      ),
      KEYWORD_END("end")
    )

    assert_errors expected, "module Parent module end", [
      "Expected to find a module name after `module`."
    ]
  end

  def test_for_loops_index_missing
    expected = ForNode(
      MissingNode(),
      expression("1..10"),
      StatementsNode([expression("i")]),
      Location(),
      Location(),
      nil,
      Location()
    )

    assert_errors expected, "for in 1..10\ni\nend", ["Expected index after for."]
  end

  def test_for_loops_only_end
    expected = ForNode(
      MissingNode(),
      MissingNode(),
      nil,
      Location(),
      Location(),
      nil,
      Location()
    )

    assert_errors expected, "for end", ["Expected index after for.", "Expected keyword in.", "Expected collection."]
  end

  def test_pre_execution_missing_brace
    expected = PreExecutionNode(
      StatementsNode([expression("1")]),
      Location(),
      Location(),
      Location()
    )

    assert_errors expected, "BEGIN 1 }", ["Expected '{' after 'BEGIN'."]
  end

  def test_pre_execution_context
    expected = PreExecutionNode(
      StatementsNode([
        CallNode(
          expression("1"),
          nil,
          PLUS("+"),
          nil,
          ArgumentsNode([MissingNode()]),
          nil,
          nil,
          "+"
        )
      ]),
      Location(),
      Location(),
      Location()
    )

    assert_errors expected, "BEGIN { 1 + }", ["Expected a value after the operator."]
  end

  def test_unterminated_embdoc
    assert_errors expression("1"), "1\n=begin\n", ["Unterminated embdoc"]
  end

  def test_unterminated_i_list
    assert_errors expression("%i["), "%i[", ["Expected a closing delimiter for a `%i` list."]
  end

  def test_unterminated_w_list
    assert_errors expression("%w["), "%w[", ["Expected a closing delimiter for a `%w` list."]
  end

  def test_unterminated_W_list
    assert_errors expression("%W["), "%W[", ["Expected a closing delimiter for a `%W` list."]
  end

  def test_unterminated_regular_expression
    assert_errors expression("/hello"), "/hello", ["Expected a closing delimiter for a regular expression."]
  end

  def test_unterminated_xstring
    assert_errors expression("`hello"), "`hello", ["Expected a closing delimiter for an xstring."]
  end

  def test_unterminated_string
    assert_errors expression('"hello'), '"hello', ["Expected a closing delimiter for an interpolated string."]
  end

  def test_unterminated_s_symbol
    assert_errors expression("%s[abc"), "%s[abc", ["Expected a closing delimiter for a dynamic symbol."]
  end

  def test_unterminated_parenthesized_expression
    assert_errors expression('(1 + 2'), '(1 + 2', ["Expected to be able to parse an expression.", "Expected a closing parenthesis."]
  end

  def test_1_2_3
    assert_errors expression("(1, 2, 3)"), "(1, 2, 3)", [
      "Expected to be able to parse an expression.",
      "Expected a closing parenthesis.",
      "Expected a newline or semicolon after statement.",
      "Expected to be able to parse an expression.",
      "Expected a newline or semicolon after statement.",
      "Expected to be able to parse an expression.",
      "Expected a newline or semicolon after statement.",
      "Expected to be able to parse an expression."
    ]
  end

  def test_return_1_2_3
    assert_error_messages "return(1, 2, 3)", [
      "Expected to be able to parse an expression.",
      "Expected a closing parenthesis.",
      "Expected a newline or semicolon after statement.",
      "Expected to be able to parse an expression."
    ]
  end

  def test_return_1
    assert_errors expression("return 1,;"), "return 1,;", ["Expected to be able to parse an argument."]
  end

  def test_next_1_2_3
    assert_errors expression("next(1, 2, 3)"), "next(1, 2, 3)", [
      "Expected to be able to parse an expression.",
      "Expected a closing parenthesis.",
      "Expected a newline or semicolon after statement.",
      "Expected to be able to parse an expression."
    ]
  end

  def test_next_1
    assert_errors expression("next 1,;"), "next 1,;", ["Expected to be able to parse an argument."]
  end

  def test_break_1_2_3
    errors = [
      "Expected to be able to parse an expression.",
      "Expected a closing parenthesis.",
      "Expected a newline or semicolon after statement.",
      "Expected to be able to parse an expression."
    ]

    assert_errors expression("break(1, 2, 3)"), "break(1, 2, 3)", errors
  end

  def test_break_1
    assert_errors expression("break 1,;"), "break 1,;", ["Expected to be able to parse an argument."]
  end

  def test_argument_forwarding_when_parent_is_not_forwarding
    assert_errors expression('def a(x, y, z); b(...); end'), 'def a(x, y, z); b(...); end', ["unexpected ... when parent method is not forwarding."]
  end

  def test_argument_forwarding_only_effects_its_own_internals
    assert_errors expression('def a(...); b(...); end; def c(x, y, z); b(...); end'), 'def a(...); b(...); end; def c(x, y, z); b(...); end', ["unexpected ... when parent method is not forwarding."]
  end

  def test_top_level_constant_with_downcased_identifier
    assert_error_messages "::foo", [
      "Expected a constant after ::.",
      "Expected a newline or semicolon after statement."
    ]
  end

  def test_top_level_constant_starting_with_downcased_identifier
    assert_error_messages "::foo::A", [
      "Expected a constant after ::.",
      "Expected a newline or semicolon after statement."
    ]
  end

  def test_aliasing_global_variable_with_non_global_variable
    assert_errors expression("alias $a b"), "alias $a b", ["Expected a global variable."]
  end

  def test_aliasing_non_global_variable_with_global_variable
    assert_errors expression("alias a $b"), "alias a $b", ["Expected a bare word or symbol argument."]
  end

  def test_aliasing_global_variable_with_global_number_variable
    assert_errors expression("alias $a $1"), "alias $a $1", ["Can't make alias for number variables."]
  end

  def test_def_with_expression_receiver_and_no_identifier
    assert_errors expression("def (a); end"), "def (a); end", [
      "Expected '.' or '::' after receiver"
    ]
  end

  def test_def_with_multiple_statements_receiver
    assert_errors expression("def (\na\nb\n).c; end"), "def (\na\nb\n).c; end", [
      "Expected closing ')' for receiver.",
      "Expected '.' or '::' after receiver",
      "Expected to be able to parse an expression.",
      "Expected to be able to parse an expression."
    ]
  end

  def test_def_with_empty_expression_receiver
    assert_errors expression("def ().a; end"), "def ().a; end", ["Expected to be able to parse receiver."]
  end

  def test_block_beginning_with_brace_and_ending_with_end
    assert_error_messages "x.each { x end", [
      "Expected a newline or semicolon after statement.",
      "Expected to be able to parse an expression.",
      "Expected to be able to parse an expression.",
      "Expected block beginning with '{' to end with '}'."
    ]
  end

  def test_double_splat_followed_by_splat_argument
    expected = CallNode(
      nil,
      nil,
      IDENTIFIER("a"),
      PARENTHESIS_LEFT("("),
      ArgumentsNode(
        [KeywordHashNode(
           [AssocSplatNode(
              CallNode(
                nil,
                nil,
                IDENTIFIER("kwargs"),
                nil,
                nil,
                nil,
                nil,
                "kwargs"
              ),
              Location()
            )]
         ),
         SplatNode(
           USTAR("*"),
           CallNode(nil, nil, IDENTIFIER("args"), nil, nil, nil, nil, "args")
         )]
      ),
      PARENTHESIS_RIGHT(")"),
      nil,
      "a"
    )

    assert_errors expected, "a(**kwargs, *args)", ["Unexpected splat argument after double splat."]
  end

  def test_arguments_after_block
    expected = CallNode(
      nil,
      nil,
      IDENTIFIER("a"),
      PARENTHESIS_LEFT("("),
      ArgumentsNode([
        BlockArgumentNode(expression("block"), Location()),
        expression("foo")
      ]),
      PARENTHESIS_RIGHT(")"),
      nil,
      "a"
    )

    assert_errors expected, "a(&block, foo)", ["Unexpected argument after block argument."]
  end

  def test_arguments_binding_power_for_and
    assert_error_messages "foo(*bar and baz)", [
      "Expected a ')' to close the argument list.",
      "Expected a newline or semicolon after statement.",
      "Expected to be able to parse an expression."
    ]
  end

  def test_splat_argument_after_keyword_argument
    expected = CallNode(
      nil,
      nil,
      IDENTIFIER("a"),
      PARENTHESIS_LEFT("("),
      ArgumentsNode(
        [KeywordHashNode(
           [AssocNode(
              SymbolNode(nil, LABEL("foo"), LABEL_END(":"), "foo"),
              CallNode(nil, nil, IDENTIFIER("bar"), nil, nil, nil, nil, "bar"),
              nil
            )]
         ),
         SplatNode(
           USTAR("*"),
           CallNode(nil, nil, IDENTIFIER("args"), nil, nil, nil, nil, "args")
         )]
      ),
      PARENTHESIS_RIGHT(")"),
      nil,
      "a"
    )

    assert_errors expected, "a(foo: bar, *args)", ["Unexpected splat argument after double splat."]
  end

  def test_module_definition_in_method_body
    expected = DefNode(
      IDENTIFIER("foo"),
      nil,
      nil,
      StatementsNode(
        [ModuleNode(
           [],
           KEYWORD_MODULE("module"),
           ConstantReadNode(),
           nil,
           KEYWORD_END("end")
         )]
      ),
      [],
      Location(),
      nil,
      nil,
      nil,
      nil,
      Location()
    )

    assert_errors expected, "def foo;module A;end;end", ["Module definition in method body"]
  end

  def test_module_definition_in_method_body_within_block
    expected = DefNode(
      IDENTIFIER("foo"),
      nil,
      nil,
      StatementsNode(
        [CallNode(
           nil,
           nil,
           IDENTIFIER("bar"),
           nil,
           nil,
           nil,
           BlockNode(
             [],
             nil,
             StatementsNode(
               [ModuleNode(
                  [],
                  KEYWORD_MODULE("module"),
                  ConstantReadNode(),
                  nil,
                  KEYWORD_END("end")
                )]
             ),
             Location(),
             Location()
           ),
           "bar"
         )]
      ),
      [],
      Location(),
      nil,
      nil,
      nil,
      nil,
      Location()
    )

    assert_errors expected, "
      def foo
        bar do
          module Foo;end
        end
      end
    ", ["Module definition in method body"]
  end

  def test_class_definition_in_method_body
    expected = DefNode(
      IDENTIFIER("foo"),
      nil,
      nil,
      StatementsNode(
        [ClassNode(
           [],
           KEYWORD_CLASS("class"),
           ConstantReadNode(),
           nil,
           nil,
           nil,
           KEYWORD_END("end")
         )]
      ),
      [],
      Location(),
      nil,
      nil,
      nil,
      nil,
      Location()
    )

    assert_errors expected, "def foo;class A;end;end", ["Class definition in method body"]
  end

  def test_bad_arguments
    expected = DefNode(
      IDENTIFIER("foo"),
      nil,
      ParametersNode([], [], [], nil, [], nil, nil),
      nil,
      [],
      Location(),
      nil,
      Location(),
      Location(),
      nil,
      Location()
    )

    assert_errors expected, "def foo(A, @a, $A, @@a);end", [
      "Formal argument cannot be a constant",
      "Formal argument cannot be an instance variable",
      "Formal argument cannot be a global variable",
      "Formal argument cannot be a class variable",
    ]
  end

  def test_cannot_assign_to_a_reserved_numbered_parameter
    expected = BeginNode(
      KEYWORD_BEGIN("begin"),
      StatementsNode(
        [LocalVariableWriteNode(
           Location(),
           SymbolNode(SYMBOL_BEGIN(":"), IDENTIFIER("a"), nil, "a"),
           Location(),
           0
         ),
         LocalVariableWriteNode(
           Location(),
           SymbolNode(SYMBOL_BEGIN(":"), IDENTIFIER("a"), nil, "a"),
           Location(),
           0
         ),
         LocalVariableWriteNode(
           Location(),
           SymbolNode(SYMBOL_BEGIN(":"), IDENTIFIER("a"), nil, "a"),
           Location(),
           0
         ),
         LocalVariableWriteNode(
           Location(),
           SymbolNode(SYMBOL_BEGIN(":"), IDENTIFIER("a"), nil, "a"),
           Location(),
           0
         ),
         LocalVariableWriteNode(
           Location(),
           SymbolNode(SYMBOL_BEGIN(":"), IDENTIFIER("a"), nil, "a"),
           Location(),
           0
         ),
         LocalVariableWriteNode(
           Location(),
           SymbolNode(SYMBOL_BEGIN(":"), IDENTIFIER("a"), nil, "a"),
           Location(),
           0
         ),
         LocalVariableWriteNode(
           Location(),
           SymbolNode(SYMBOL_BEGIN(":"), IDENTIFIER("a"), nil, "a"),
           Location(),
           0
         ),
         LocalVariableWriteNode(
           Location(),
           SymbolNode(SYMBOL_BEGIN(":"), IDENTIFIER("a"), nil, "a"),
           Location(),
           0
         ),
         LocalVariableWriteNode(
           Location(),
           SymbolNode(SYMBOL_BEGIN(":"), IDENTIFIER("a"), nil, "a"),
           Location(),
           0
         ),
         LocalVariableWriteNode(
           Location(),
           SymbolNode(SYMBOL_BEGIN(":"), IDENTIFIER("a"), nil, "a"),
           Location(),
           0
         )]
      ),
      nil,
      nil,
      nil,
      KEYWORD_END("end")
    )
    assert_errors expected, "
    begin
      _1=:a;_2=:a;_3=:a;_4=:a;_5=:a
      _6=:a;_7=:a;_8=:a;_9=:a;_10=:a
    end
    ", Array.new(9, "reserved for numbered parameter")
  end

  def test_do_not_allow_trailing_commas_in_method_parameters
    expected = DefNode(
      IDENTIFIER("foo"),
      nil,
      ParametersNode(
        [RequiredParameterNode(), RequiredParameterNode(), RequiredParameterNode()],
        [],
        [],
        nil,
        [],
        nil,
        nil
      ),
      nil,
      [IDENTIFIER("a"), IDENTIFIER("b"), IDENTIFIER("c")],
      Location(),
      nil,
      Location(),
      Location(),
      nil,
      Location()
    )

    assert_errors expected, "def foo(a,b,c,);end", [
      "Unexpected ','."
    ]
  end

  def test_do_not_allow_trailing_commas_in_lambda_parameters
    expected = LambdaNode(
      [IDENTIFIER("a"), IDENTIFIER("b")],
      MINUS_GREATER("->"),
      BlockParametersNode(
        ParametersNode([RequiredParameterNode(), RequiredParameterNode()], [], [], nil, [], nil, nil),
        [],
        Location(),
        Location()
      ),
      nil
    )
    assert_errors expected, "-> (a, b, ) {}", [
      "Unexpected ','."
    ]
  end

  def test_do_not_allow_multiple_codepoints_in_a_single_character_literal
    expected = StringNode(
      STRING_BEGIN("?"),
      STRING_CONTENT('\u{0001 0002}'),
      nil,
      "\u0001\u0002"
    )
    assert_errors expected, '?\u{0001 0002}', [
      "Multiple codepoints at single character literal"
    ]
  end

  def test_do_not_allow_more_than_6_hexadecimal_digits_in_u_Unicode_character_notation
    expected = StringNode(
      STRING_BEGIN('"'),
      STRING_CONTENT('\u{0000001}'),
      STRING_END('"'),
      "\u0001"
    )
    assert_errors expected, '"\u{0000001}"', [
      "invalid Unicode escape.",
      "invalid Unicode escape."
    ]
  end

  def test_do_not_allow_characters_other_than_0_9_a_f_and_A_F_in_u_Unicode_character_notation
    expected = StringNode(
      STRING_BEGIN('"'),
      STRING_CONTENT('\u{000z}'),
      STRING_END('"'),
      "\u0000z}"
    )
    assert_errors expected, '"\u{000z}"', [
      "unterminated Unicode escape",
      "unterminated Unicode escape"
    ]
  end

  def test_method_parameters_after_block
    expected = DefNode(
      IDENTIFIER("foo"),
      nil,
      ParametersNode(
        [],
        [],
        [RequiredParameterNode()],
        nil,
        [],
        nil,
        BlockParameterNode(IDENTIFIER("block"), Location())
      ),
      nil,
      [IDENTIFIER("block"), IDENTIFIER("a")],
      Location(),
      nil,
      Location(),
      Location(),
      nil,
      Location()
    )
    assert_errors expected, "def foo(&block, a)\nend", ["Unexpected parameter order"]
  end

  def test_method_with_arguments_after_anonamous_block
    expected = DefNode(
      IDENTIFIER("foo"),
      nil,
      ParametersNode([], [], [RequiredParameterNode()], nil, [], nil, BlockParameterNode(nil, Location())),
      nil,
      [AMPERSAND("&"), IDENTIFIER("a")],
      Location(),
      nil,
      Location(),
      Location(),
      nil,
      Location()
    )

    assert_errors expected, "def foo(&, a)\nend", ["Unexpected parameter order"]
  end

  def test_method_parameters_after_arguments_forwarding
    expected = DefNode(
      IDENTIFIER("foo"),
      nil,
      ParametersNode(
        [],
        [],
        [RequiredParameterNode()],
        nil,
        [],
        ForwardingParameterNode(),
        nil
      ),
      nil,
      [UDOT_DOT_DOT("..."), IDENTIFIER("a")],
      Location(),
      nil,
      Location(),
      Location(),
      nil,
      Location()
    )
    assert_errors expected, "def foo(..., a)\nend", ["Unexpected parameter order"]
  end

  def test_keywords_parameters_before_required_parameters
    expected = DefNode(
      IDENTIFIER("foo"),
      nil,
      ParametersNode(
        [],
        [],
        [RequiredParameterNode()],
        nil,
        [KeywordParameterNode(LABEL("b:"), nil)],
        nil,
        nil
      ),
      nil,
      [LABEL("b"), IDENTIFIER("a")],
      Location(),
      nil,
      Location(),
      Location(),
      nil,
      Location()
    )
    assert_errors expected, "def foo(b:, a)\nend", ["Unexpected parameter order"]
  end

  def test_rest_keywords_parameters_before_required_parameters
    expected = DefNode(
      IDENTIFIER("foo"),
      nil,
      ParametersNode(
        [],
        [],
        [],
        nil,
        [KeywordParameterNode(LABEL("b:"), nil)],
        KeywordRestParameterNode(
          USTAR_STAR("**"),
          IDENTIFIER("rest")
        ),
        nil
      ),
      nil,
      [IDENTIFIER("rest"), LABEL("b")],
      Location(),
      nil,
      Location(),
      Location(),
      nil,
      Location()
    )
    assert_errors expected, "def foo(**rest, b:)\nend", ["Unexpected parameter order"]
  end

  def test_double_arguments_forwarding
    expected = DefNode(
      IDENTIFIER("foo"),
      nil,
      ParametersNode([], [], [], nil, [], ForwardingParameterNode(), nil),
      nil,
      [UDOT_DOT_DOT("...")],
      Location(),
      nil,
      Location(),
      Location(),
      nil,
      Location()
    )
    assert_errors expected, "def foo(..., ...)\nend", ["Unexpected parameter order"]
  end

  def test_multiple_error_in_parameters_order
    expected = DefNode(
      IDENTIFIER("foo"),
      nil,
      ParametersNode(
        [],
        [],
        [RequiredParameterNode()],
        nil,
        [KeywordParameterNode(LABEL("b:"), nil)],
        KeywordRestParameterNode(
          USTAR_STAR("**"),
          IDENTIFIER("args")
        ),
        nil
      ),
      nil,
      [IDENTIFIER("args"), IDENTIFIER("a"), LABEL("b")],
      Location(),
      nil,
      Location(),
      Location(),
      nil,
      Location()
    )
    assert_errors expected, "def foo(**args, a, b:)\nend", ["Unexpected parameter order", "Unexpected parameter order"]
  end

  def test_switching_to_optional_arguments_twice
    expected = DefNode(
      IDENTIFIER("foo"),
      nil,
      ParametersNode(
        [],
        [],
        [RequiredParameterNode()],
        nil,
        [KeywordParameterNode(LABEL("b:"), nil)],
        KeywordRestParameterNode(
          USTAR_STAR("**"),
          IDENTIFIER("args")
        ),
        nil
      ),
      nil,
      [IDENTIFIER("args"),
        IDENTIFIER("a"),
        LABEL("b")],
      Location(),
      nil,
      Location(),
      Location(),
      nil,
      Location(),
    )
    assert_errors expected, "def foo(**args, a, b:)\nend", ["Unexpected parameter order", "Unexpected parameter order"]
  end

  def test_switching_to_named_arguments_twice
    expected = DefNode(
      IDENTIFIER("foo"),
      nil,
      ParametersNode(
        [],
        [],
        [RequiredParameterNode()],
        nil,
        [KeywordParameterNode(LABEL("b:"), nil)],
        KeywordRestParameterNode(
          USTAR_STAR("**"),
          IDENTIFIER("args")
        ),
        nil
      ),
      nil,
      [IDENTIFIER("args"),
        IDENTIFIER("a"),
        LABEL("b")],
      Location(),
      nil,
      Location(),
      Location(),
      nil,
      Location(),
    )
    assert_errors expected, "def foo(**args, a, b:)\nend", ["Unexpected parameter order", "Unexpected parameter order"]
  end

  def test_returning_to_optional_parameters_multiple_times
    expected = DefNode(
      IDENTIFIER("foo"),
      nil,
      ParametersNode(
        [RequiredParameterNode()],
        [OptionalParameterNode(
           IDENTIFIER("b"),
           EQUAL("="),
           IntegerNode()
         ),
         OptionalParameterNode(
           IDENTIFIER("d"),
           EQUAL("="),
           IntegerNode()
         )],
        [RequiredParameterNode(),
         RequiredParameterNode()],
        nil,
        [],
        nil,
        nil
      ),
      nil,
      [IDENTIFIER("a"),
        IDENTIFIER("b"),
        IDENTIFIER("c"),
        IDENTIFIER("d"),
        IDENTIFIER("e")],
      Location(),
      nil,
      Location(),
      Location(),
      nil,
      Location(),
    )
    assert_errors expected, "def foo(a, b = 1, c, d = 2, e)\nend", ["Unexpected parameter order"]
  end

  def test_case_without_when_clauses_errors_on_else_clause
    expected = CaseNode(
      SymbolNode(SYMBOL_BEGIN(":"), IDENTIFIER("a"), nil, "a"),
      [],
      ElseNode(KEYWORD_ELSE("else"), nil, KEYWORD_END("end")),
      Location(),
      Location()
    )

    assert_errors expected, "case :a\nelse\nend", ["Unexpected else without no when clauses in case statement."]
  end

  def test_setter_method_cannot_be_defined_in_an_endless_method_definition
    expected = DefNode(
      IDENTIFIER("a="),
      nil,
      nil,
      StatementsNode([IntegerNode()]),
      [],
      Location(),
      nil,
      Location(),
      Location(),
      Location(),
      nil
    )

    assert_errors expected, "def a=() = 42", ["Setter method cannot be defined in an endless method definition"]
  end

  def test_do_not_allow_forward_arguments_in_lambda_literals
    expected = LambdaNode(
      [UDOT_DOT_DOT("...")],
      MINUS_GREATER("->"),
      BlockParametersNode(ParametersNode([], [], [], nil, [], ForwardingParameterNode(), nil), [], Location(), Location()),
      nil
    )

    assert_errors expected, "->(...) {}", ["Unexpected ..."]
  end

  def test_do_not_allow_forward_arguments_in_blocks
    expected = CallNode(
      nil,
      nil,
      IDENTIFIER("a"),
      nil,
      nil,
      nil,
      BlockNode(
        [UDOT_DOT_DOT("...")],
        BlockParametersNode(ParametersNode([], [], [], nil, [], ForwardingParameterNode(), nil), [], Location(), Location()),
        nil,
        Location(),
        Location()
      ),
      "a"
    )

    assert_errors expected, "a {|...|}", ["Unexpected ..."]
  end

  def test_dont_allow_return_inside_class_body
    expected = ClassNode(
      [],
      KEYWORD_CLASS("class"),
      ConstantReadNode(),
      nil,
      nil,
      StatementsNode([ReturnNode(KEYWORD_RETURN("return"), nil)]),
      KEYWORD_END("end")
    )

    assert_errors expected, "class A; return; end", ["Invalid return in class/module body"]
  end

  def test_dont_allow_return_inside_module_body
    expected = ModuleNode(
      [],
      KEYWORD_MODULE("module"),
      ConstantReadNode(),
      StatementsNode([ReturnNode(KEYWORD_RETURN("return"), nil)]),
      KEYWORD_END("end")
    )

    assert_errors expected, "module A; return; end", ["Invalid return in class/module body"]
  end

  def test_dont_allow_setting_to_back_and_nth_reference
    expected = BeginNode(
      KEYWORD_BEGIN("begin"),
      StatementsNode([GlobalVariableWriteNode(BACK_REFERENCE("$+"), EQUAL("="), NilNode()),
       GlobalVariableWriteNode(NTH_REFERENCE("$1466"), EQUAL("="), NilNode())]),
      nil,
      nil,
      nil,
      KEYWORD_END("end")
    )

    assert_errors expected, "begin\n$+ = nil\n$1466 = nil\nend", ["Can't set variable", "Can't set variable"]
  end

  def test_duplicated_parameter_names
    expected = DefNode(
      IDENTIFIER("foo"),
      nil,
      ParametersNode([RequiredParameterNode(), RequiredParameterNode(), RequiredParameterNode()], [], [], nil, [], nil, nil),
      nil,
      [IDENTIFIER("a"), IDENTIFIER("b")],
      Location(),
      nil,
      Location(),
      Location(),
      nil,
      Location()
    )
    assert_errors expected, "def foo(a,b,a);end", ["Duplicated argument name."]

    expected = DefNode(
      IDENTIFIER("foo"),
      nil,
      ParametersNode([RequiredParameterNode(), RequiredParameterNode()], [], [], RestParameterNode(USTAR("*"), IDENTIFIER("a")), [], nil, nil),
      nil,
      [IDENTIFIER("a"), IDENTIFIER("b")],
      Location(),
      nil,
      Location(),
      Location(),
      nil,
      Location()
    )
    assert_errors expected, "def foo(a,b,*a);end", ["Duplicated argument name."]

    expected = DefNode(
      IDENTIFIER("foo"),
      nil,
      ParametersNode([RequiredParameterNode(), RequiredParameterNode()], [], [], nil, [], KeywordRestParameterNode(USTAR_STAR("**"), IDENTIFIER("a")), nil),
      nil,
      [IDENTIFIER("a"), IDENTIFIER("b")],
      Location(),
      nil,
      Location(),
      Location(),
      nil,
      Location()
    )
    assert_errors expected, "def foo(a,b,**a);end", ["Duplicated argument name."]

    expected = DefNode(
      IDENTIFIER("foo"),
      nil,
      ParametersNode([RequiredParameterNode(), RequiredParameterNode()], [], [], nil, [], nil, BlockParameterNode(IDENTIFIER("a"), Location())),
      nil,
      [IDENTIFIER("a"), IDENTIFIER("b")],
      Location(),
      nil,
      Location(),
      Location(),
      nil,
      Location()
    )
    assert_errors expected, "def foo(a,b,&a);end", ["Duplicated argument name."]
  end

  private

  def assert_errors(expected, source, errors)
    assert_nil Ripper.sexp_raw(source)

    result = YARP.parse_dup(source)
    result => YARP::ParseResult[value: YARP::ProgramNode[statements: YARP::StatementsNode[body: [*, node]]]]

    assert_equal_nodes(expected, node, compare_location: false)
    assert_equal(errors, result.errors.map(&:message))
  end

  def assert_error_messages(source, errors)
    assert_nil Ripper.sexp_raw(source)
    result = YARP.parse_dup(source)
    assert_equal(errors, result.errors.map(&:message))
  end

  def expression(source)
    YARP.parse_dup(source) => YARP::ParseResult[value: YARP::ProgramNode[statements: YARP::StatementsNode[body: [*, node]]]]
    node
  end
end
