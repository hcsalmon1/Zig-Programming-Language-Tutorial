
pub const ParseError = error {
    Code_Length_Is_Zero,
    Unterminated_String,
    Unexpected_Value,
    Unterminated_Char,
};

pub const AstError = error {
    Infinite_While_Loop,
    Index_Out_Of_Range,
    Invalid_Declaration,
    Unexpected_Type,
    Unimplemented_Type,
    Missing_Expected_Type,
    Unexpected_End_Of_File,
    Null_Type,
    Out_Of_Memory,
};

