

const std = @import("std");
const structs_script = @import("../core/structs.zig");
const enums_script = @import("../core/enums.zig");
const expressions_script = @import("../core/expression.zig");
const errors_script = @import("../core/errors.zig");
const ast_node_utils_script = @import("../core/ast_node_utils.zig");
const ast_integers_script = @import("ast_integers.zig");
const ast_bool_script = @import("ast_bools.zig");
const ast_utils_script = @import("ast_utils.zig");
const token_utils_script = @import("../core/token_utils.zig");
const print = std.debug.print;
const ASTNode = structs_script.ASTNode;
const TokenType = enums_script.TokenType;
const ASTData = structs_script.ASTData;
const Token = structs_script.Token;
const ASTNodeType = enums_script.ASTNodeType;
const AstError = errors_script.AstError;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

fn processStructMemberAccess(allocator:*Allocator, ast_data:*ASTData, first_token:Token) AstError!*ASTNode {
    const member_access_node:*ASTNode = try ast_node_utils_script.createDefaultAstNode(allocator);
    member_access_node.node_type = ASTNodeType.StructMemberAccess;
    member_access_node.token = first_token;
    member_access_node.left = try processVariableName(allocator, ast_data, true);
    return member_access_node;
}

fn processCustomDeclaration(allocator:*Allocator, ast_data:*ASTData, first_token:Token, second_token:Token) AstError!*ASTNode {

    const declaration_node:*ASTNode = try ast_node_utils_script.createDefaultAstNode(allocator);

    declaration_node.node_type = ASTNodeType.Declaration;
    declaration_node.token = second_token;
    declaration_node.left = try ast_node_utils_script.createTypeNode(allocator, first_token);

    try ast_data.expectType(TokenType.Semicolon, "missing expected ';' in declaration");
    try ast_data.incrementIndex();
    return declaration_node;
}

fn processPotentialFunctionCall(allocator:*Allocator, ast_data:*ASTData, first_token:Token) AstError!*ASTNode {

    const function_call_node:*ASTNode = try ast_node_utils_script.createDefaultAstNode(allocator);

    const child_list = ArrayList(*ASTNode).initCapacity(allocator.*, 0) catch {
        return AstError.Out_Of_Memory;
    };

    function_call_node.children = child_list;
    function_call_node.node_type = ASTNodeType.FunctionCall;
    function_call_node.token = first_token;

    try ast_utils_script.fillNodeInBrackets(allocator, ast_data, function_call_node, ASTNodeType.Parameter);

    try ast_data.expectType(TokenType.RightParenthesis, "missing expected ')' in function call");
    try ast_data.incrementIndex();
    try ast_data.expectType(TokenType.Semicolon, "missing expected ';' in function call");
    try ast_data.incrementIndex();
    return function_call_node;
}

fn processArrayAccess(allocator:*Allocator, ast_data:*ASTData, first_token:Token) AstError!*ASTNode {
    
    ast_data.error_function = "processArrayAccess";

    const assignment_node:*ASTNode = try ast_node_utils_script.createDefaultAstNode(allocator);
    assignment_node.node_type = ASTNodeType.Assignment;
    
    const array_access_node:*ASTNode = try ast_node_utils_script.createDefaultAstNode(allocator);
    array_access_node.token = first_token;

    //try ast_data.incrementIndex();

    const index_token:Token = try ast_data.getToken();

    const is_valid_token:bool = 
            index_token.Type == TokenType.Identifier or
            index_token.Type == TokenType.IntegerValue;

    if (is_valid_token == false) {
        ast_data.error_detail = "only identifier and int value implemented in array access";
        ast_data.error_token = index_token;
        return AstError.Unexpected_Type;
    }

    const index_node:*ASTNode = try ast_node_utils_script.createDefaultAstNode(allocator);
    index_node.node_type = ASTNodeType.IntegerLiteral;
    index_node.token = index_token;

    try ast_data.incrementIndex();
    try ast_data.expectType(TokenType.RightSquareBracket, "missing expected ']' in array access");
    try ast_data.incrementIndex();

    const operator_token:Token = try ast_data.getToken();
    if (token_utils_script.isAssignmentToken(operator_token.Type) == false) {
        ast_data.error_token = operator_token;
        ast_data.error_detail = "missing expected '=' in string declaration";
        return AstError.Missing_Expected_Type;
    }
    try ast_data.incrementIndex();

    const value_node = try ast_integers_script.getValueNodeI32(allocator, ast_data);

    try ast_data.expectType(TokenType.Semicolon, "missing expected ';' in array access");
    ast_data.token_index += 1;

    array_access_node.node_type = ASTNodeType.ArrayAccess;
    array_access_node.left = index_node;
    
    assignment_node.token = operator_token;
    assignment_node.left = array_access_node;
    assignment_node.right = value_node;

    return assignment_node;
}

fn processAssignment(allocator:*Allocator, ast_data:*ASTData, first_token:Token, second_token:Token, check_semicolon:bool) AstError!*ASTNode {
    
    ast_data.error_function = "processAssignment";

    const assignment_node:*ASTNode = try ast_node_utils_script.createDefaultAstNode(allocator);
    assignment_node.node_type = ASTNodeType.Assignment;
    
    const value_node = try ast_integers_script.getValueNodeI32(allocator, ast_data);

    if (check_semicolon) {
        try ast_data.expectType(TokenType.Semicolon, "missing expected ';' in assignment");
        try ast_data.incrementIndex();
    }
    const name_node:*ASTNode = try ast_node_utils_script.createIdentifierNode(allocator, first_token);
    assignment_node.token = second_token;
    assignment_node.left = name_node;
    assignment_node.right = value_node;
    return assignment_node;
}

fn processDereference(allocator:*Allocator, ast_data:*ASTData, first_token:Token, check_semicolon:bool) AstError!*ASTNode {
    
    ast_data.error_function = "processDereference";

    const third_token:Token = try ast_data.getToken();

    if (token_utils_script.isAssignmentToken(third_token.Type) == false) {
        ast_data.error_detail = "missing assignment operator in dereference";
        ast_data.error_token = third_token;
        return AstError.Missing_Expected_Type;
    }
    try ast_data.incrementIndex();

    const assignment_node:*ASTNode = try ast_node_utils_script.createDefaultAstNode(allocator);
    assignment_node.node_type = ASTNodeType.DereferenceAssignment;

    const value_node:*ASTNode = try ast_integers_script.getValueNodeI32(allocator, ast_data);
    if (check_semicolon) {
        try ast_data.expectType(TokenType.Semicolon, "missing expected ';' in dereference");
    }
    const name_node:*ASTNode = try ast_node_utils_script.createIdentifierNode(allocator, first_token);
    assignment_node.token = third_token;
    assignment_node.left = name_node;
    assignment_node.right = value_node;
    return assignment_node;
}

pub fn processVariableName(allocator:*Allocator, ast_data:*ASTData, check_semicolon:bool) AstError!*ASTNode { //expectedSemicolon is for loop ends, no semicolon needed

    ast_data.error_function = "processVariableName";

    //either a function or var name
    const first_token:Token = try ast_data.getToken();
    try ast_data.incrementIndex();
    const second_token:Token = try ast_data.getToken();
    try ast_data.incrementIndex();

    if (token_utils_script.isAssignmentToken(second_token.Type) == true) {
        return try processAssignment(allocator, ast_data, first_token, second_token, check_semicolon);
    }

    switch (second_token.Type) {

        TokenType.FullStop => return try processStructMemberAccess(allocator, ast_data, first_token),
        TokenType.Identifier => return try processCustomDeclaration(allocator, ast_data, first_token, second_token),
        TokenType.LeftParenthesis => return try processPotentialFunctionCall(allocator, ast_data, first_token),
        TokenType.LeftSquareBracket => return try processArrayAccess(allocator, ast_data, first_token),
        TokenType.Multiply => return try processDereference(allocator, ast_data, first_token, check_semicolon),
        TokenType.Plus, TokenType.PlusPlus => {
            ast_data.error_detail = "Expecting a reassignment, '+' or '++', not valid. Use '+='";
            ast_data.error_token = second_token;
            return AstError.Unexpected_Type;
        },
        else => {
            ast_data.error_token = second_token;
            ast_data.error_detail = "Unexpected type found after identifier";
            return AstError.Unexpected_Type;
        },
    }
}