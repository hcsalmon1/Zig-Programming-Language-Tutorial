
pub const TokenType = enum {
    Fn,
    IntegerValue, 
    DecimalValue, 
    CharValue, 
    StringValue,  
    i8,
    u8,
    i16,
    u16,
    Int,
    i32,
    u32,
    i64,
    u64,
    f32,
    f64,
    Usize,
    String,
    Bool,
    Char,
    Void,
    If,
    Else,
    For,
    While,
    Minus,
    Plus,
    PlusPlus,
    Divide,
    Multiply,
    Equals,
    Identifier,
    Return,
    Break,
    Continue,
    Print,
    Println,
    LeftParenthesis,
    RightParenthesis,
    LeftBrace,
    RightBrace,
    LeftSquareBracket,
    RightSquareBracket,
    Semicolon,
    True,
    False,
    Comment,
    EndComment,
    Comma,
    FullStop,
    PlusEquals,
    MinusEquals,
    MultiplyEquals,
    DivideEquals,
    GreaterThan,
    LessThan,
    EqualsEquals,
    GreaterThanEquals,
    LessThanEquals,
    VariableInSimpleForLoop,
    Defer,
    New,
    Delete,
    In,
    Const,
    Modulus,
    ModulusEquals,
    NotEquals,
    And,
    AndAnd,
    Or,
    OrOr,
    IntegerVarType,
    NA, //invalid type
};

pub const ASTNodeType = enum {
    Invalid,
    Comment,

    //Keywords
    Return,
    Break,
    Continue,
    Print,
    Println,

    //Literals
    IntegerLiteral,
    FloatLiteral,
    StringLiteral,
    CharLiteral,
    BoolLiteral,

    //__Operators__
    Minus,
    Reference,
    DereferenceAssignment,

    //__Bodies__
    FunctionBody,
    ForBody,
    ElseBody,
    IfBody,
    WhileBody,

    //__declarations__
    ArrayDeclaration,
    PointerDeclaration,
    FunctionDeclaration,
    Declaration,

    //__Functions__
    FunctionCall,

    //arrays
    ArrayGroup, //for multidimensional arrays
    ArrayElement,
    ArrayAccess,
    Array,

    //__Expressions__
    PrintExpression,
    BinaryExpression,
    ReturnExpression,
    BoolExpression,
    BoolComparison,

    //__Vartypes__
    VarType,
    Pointer,
    ReturnType,
    Const,
    Parameter,
    Parameters,

    //__Struct__
    StructVariable,

    //__Block things__
    IfStatement,
    WhileLoop,
    ForLoop,
    Else,

    //__General__
    Identifier,
    Assignment,
};

pub const LoopResult = enum {
    None,
    Continue,
    ReturnNull,
};

//struct ReturnAST
//
//ValueNode value

//struct DeclarationAST
//
//VarType type
//