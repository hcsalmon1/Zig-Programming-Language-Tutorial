



pub const OPERATORS = [_]u8 {'+','-','/','*', '|', '&', '%', '>', '<', '=' };
pub const SEPERATORS = [_]u8 {';','(',')','{','}','[',']',',','.','\n','\r','\t','\\',':'};

// Keywords
pub const FN = "fn";
pub const IF = "if";
pub const ELSE = "else";
pub const FOR = "for";
pub const WHILE = "while";
pub const RETURN = "return";
pub const BREAK = "break";
pub const CONTINUE = "continue";
pub const PRINT = "print";
pub const PRINTLN = "println";
pub const TRUE = "true";
pub const FALSE = "false";
pub const IN = "in";
pub const NEW = "new";
pub const DEFER = "defer";
pub const DELETE = "delete";

// Types
pub const I8 = "i8";
pub const U8 = "u8";
pub const I32 = "i32";
pub const U32 = "u32";
pub const I64 = "i64";
pub const U64 = "u64";
pub const F32 = "f32";
pub const F64 = "f64";
pub const STRING = "string";
pub const BOOL = "bool";
pub const CHAR = "char";
pub const VOID = "void";
pub const CONST = "const";
pub const INT = "int";
pub const USIZE = "usize";

// Operators
pub const PLUS = "+";
pub const PLUS_PLUS = "++";
pub const MINUS = "-";
pub const MULTIPLY = "*";
pub const DIVIDE = "/";
pub const EQUALS = "=";
pub const PLUS_EQUALS = "+=";
pub const MINUS_EQUALS = "-=";
pub const MULTIPLY_EQUALS = "*=";
pub const DIVIDE_EQUALS = "/=";
pub const GREATER_THAN = ">";
pub const LESS_THAN = "<";
pub const EQUALS_EQUALS = "==";
pub const GREATER_THAN_EQUALS = ">=";
pub const LESS_THAN_EQUALS = "<=";
pub const MODULUS = "%";
pub const COMMENT = "//";
pub const NOT_EQUALS = "!=";
pub const AND = "&";
pub const AND_AND = "&&";
pub const OR = "|";
pub const OR_OR = "||";
pub const MODULUS_EQUALS = "%=";
pub const THREE_SPACES = "   ";

// Parentheses and Brackets
pub const LEFT_PARENTHESIS = "(";
pub const RIGHT_PARENTHESIS = ")";
pub const LEFT_BRACE = "{";
pub const RIGHT_BRACE = "}";
pub const LEFT_SQUARE_BRACKET = "[";
pub const RIGHT_SQUARE_BRACKET = "]";

pub const SEMICOLON = ";";
pub const COMMA = ",";
pub const FULL_STOP = ".";
pub const COLON = ":";
pub const CASE = "case";
pub const DEFAULT = "default";
pub const SWITCH = "switch";

pub const STRUCT = "struct";
pub const ENUM = "enum";