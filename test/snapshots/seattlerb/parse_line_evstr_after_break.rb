ProgramNode(0...11)(
  ScopeNode(0...0)([]),
  StatementsNode(0...11)(
    [StringConcatNode(0...11)(
       StringNode(0...3)(
         STRING_BEGIN(0...1)("\""),
         STRING_CONTENT(1...2)("a"),
         STRING_END(2...3)("\""),
         "a"
       ),
       InterpolatedStringNode(5...11)(
         STRING_BEGIN(5...6)("\""),
         [StringInterpolatedNode(6...10)(
            EMBEXPR_BEGIN(6...8)("\#{"),
            StatementsNode(8...9)(
              [CallNode(8...9)(
                 nil,
                 nil,
                 IDENTIFIER(8...9)("b"),
                 nil,
                 nil,
                 nil,
                 nil,
                 "b"
               )]
            ),
            EMBEXPR_END(9...10)("}")
          )],
         STRING_END(10...11)("\"")
       )
     )]
  )
)