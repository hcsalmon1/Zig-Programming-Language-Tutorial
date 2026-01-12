
pub const ParseError = error {
    Code_Length_Is_Zero,
    Unterminated_String,
    Unexpected_Value,
    Unterminated_Char,
};

pub const AstError = error {
    Infinite_While_Loop,
    Infinite_Recursion,
    Index_Out_Of_Range,
    Invalid_Declaration,
    Unexpected_Type,
    Unimplemented_Type,
    Missing_Expected_Type,
    Unexpected_End_Of_File,
    Null_Type,
    Children_ArrayList_Is_Null,
    Out_Of_Memory,
};

pub const ConvertError = error {
    Node_Is_Null,
    No_AST_Nodes,
    Out_Of_Memory,
    Unimplemented_Node_Type,
    Invalid_Return_Type,
    Invalid_Node_Type,
    Infinite_While_Loop,
    Internal_Error,
    Invalid_Var_Type,
};

pub const SemanticError = error {
    Function_Redefinition,
    Variable_Redefinition,
    Out_Of_Memory,
    Type_Id_Map_Is_Null,
    Type_ArrayList_Is_Null,
    Identifier_Has_No_Id,
    Invalid_Struct_Declaration,
    Internal_Error,
    Unknown_Type,
    Invalid_Type_Expression,
    Duplicate_Symbol,
    Invalid_Function,
    Invalid_Global_Declaration,
};