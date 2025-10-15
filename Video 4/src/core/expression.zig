const std = @import("std");
const structs_script = @import("../core/structs.zig");
const printing_script = @import("../core/printing.zig");
const enums_script = @import("../core/enums.zig");
const token_utils_script = @import("token_utils.zig");
const debugging_script = @import("../Debugging/debugging.zig");
const errors_script = @import("errors.zig");
const ast_utils_script = @import("../core/ast_utils.zig");
const print = std.debug.print;
const Token = structs_script.Token;
const ASTData = structs_script.ASTData;
const ASTNode = structs_script.ASTNode;
const TokenType = enums_script.TokenType;
const ASTNodeType = enums_script.ASTNodeType;
const AstError = errors_script.AstError;
const LoopResult = enums_script.LoopResult;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;





pub fn fillParameters(allocator:*std.mem.Allocator, ast_data:*ASTData) AstError!*ASTNode {

    ast_data.error_function = "fillParameters";

    const child_lists:*ArrayList(*ASTNode) = allocator.*.create(ArrayList(*ASTNode)) catch {
        return AstError.Out_Of_Memory;
    };
    child_lists.* = std.ArrayList(*ASTNode).initCapacity(allocator.*, 0) catch {
        return AstError.Out_Of_Memory;
    };

    const parameters_node:*ASTNode = try ast_utils_script.createDefaultAstNode(allocator);
    parameters_node.children = child_lists;
    parameters_node.node_type = ASTNodeType.Parameters;

    var while_count:usize = 0;
    const MAX:usize = 1000;

    const token_count:usize = ast_data.token_list.items.len;
    while (ast_data.token_index < token_count) {

        if (debugging_script.isInfiniteWhileLoop(&while_count, MAX) == true) {
            return AstError.Infinite_While_Loop;
        }

        const index_before:usize = ast_data.token_index;

        const token:Token = try ast_data.getToken();

        if (token.Type == TokenType.RightParenthesis) {
            break;
        }
        if (token.Type != TokenType.Comma) {

            //print("Add parameter\n", .{});
            const parameter_node:*ASTNode = try parseSingleParameterNew(allocator, ast_data);
            parameters_node.children.?.append(allocator.*, parameter_node) catch {
                return AstError.Out_Of_Memory;
            };
        }

        if (index_before == ast_data.token_index) {
            ast_data.token_index += 1;
        }
    }

    return parameters_node;
}      

fn parseSingleParameterNew(allocator:*Allocator, ast_data:*ASTData) AstError!*ASTNode {

    const current:?*ASTNode = try createComplexDeclarations(allocator, ast_data);

    // Now parse the parameter name
    const nameToken:Token = try ast_data.getToken();
    if (nameToken.Type != TokenType.Identifier) {
        ast_data.setErrorData( "Expected identifier for parameter name", nameToken);
        return AstError.Missing_Expected_Type;
    }
    ast_data.token_index += 1;

    const parameter_node:*ASTNode = try ast_utils_script.createDefaultAstNode(allocator);

    parameter_node.node_type = ASTNodeType.Parameter;
    parameter_node.token = nameToken;
    parameter_node.left = current;

    return parameter_node;
}

fn complexDeclarationInnerLoop(allocator:*Allocator, ast_data:*ASTData, final_node:*ASTNode, token:Token) !LoopResult {
    
    if (printing_script.twoSlicesAreTheSame(token.Text,"const") == true) {

        final_node.is_const = true;
        return LoopResult.Continue;
    }

    if (printing_script.twoSlicesAreTheSame(token.Text, "*") == true) {

        try token_utils_script.incrementIndex(ast_data);
    
        var pointer_node:*ASTNode = try ast_utils_script.createDefaultAstNode(allocator);

        pointer_node.node_type = ASTNodeType.Pointer;
        pointer_node.token = token;
        pointer_node.left = final_node;

        ast_utils_script.copyNodeValues(final_node,  pointer_node);
        return LoopResult.Continue;
    }

    if (printing_script.twoSlicesAreTheSame(token.Text, "[") == true) {

        try token_utils_script.incrementIndex(ast_data);
        // Expect closing bracket immediately (no sized arrays yet?)
        const next_token:Token = try token_utils_script.getToken(ast_data);
        var array_size:?usize = null;

        if (next_token.Type != TokenType.RightSquareBracket) {

            if (next_token.Type != TokenType.IntegerValue) {
                ast_data.error_detail = "Expected ']' or array size after '[' in array";
                ast_data.error_token = next_token;
                return AstError.Missing_Expected_Type;
            }

            const size = std.fmt.parseInt(usize, token.Text, 10) catch {
                return AstError.Missing_Expected_Type;
            };

            array_size = size;

            const close2:Token = try token_utils_script.getNextToken(ast_data);
            if (close2.Type != TokenType.RightSquareBracket) {
                ast_data.setErrorData("Expected ']' or after '[' in array", next_token);
                return AstError.Missing_Expected_Type;
            }
        }

        try token_utils_script.incrementIndex(ast_data);

        var array_node:*ASTNode = try ast_utils_script.createDefaultAstNode(allocator);

        array_node.node_type = ASTNodeType.Array;
        array_node.left = final_node;

        if (array_size != null) {
            array_node.size = array_size.?;
        }
        ast_utils_script.copyNodeValues(final_node,  array_node);
        return LoopResult.Continue;
    }
    return LoopResult.None;
}
pub fn createComplexDeclarations(allocator:*Allocator, ast_data:*ASTData) !?*ASTNode {

    const final_node:*ASTNode = try ast_utils_script.createDefaultAstNode(allocator);
    var while_count:usize = 0;
    const MAX:usize = 1000;

    while (true) {

        if (debugging_script.isInfiniteWhileLoop(&while_count, MAX) == true) {
            return AstError.Infinite_While_Loop;
        }

        const token:Token = try token_utils_script.getToken(ast_data);

        // Handle inner loop declarations like array size brackets
        const loop_result:LoopResult = try complexDeclarationInnerLoop(allocator, ast_data, final_node, token);
        if (loop_result == LoopResult.ReturnNull) {
            return null;
        }
        if (loop_result == LoopResult.Continue) {
            continue;
        }

        // If the token is a base type (e.g., "i32"), attach it at the innermost level
        if (token_utils_script.isTypeToken(token)) {

            try ast_data.incrementIndex();

            var type_node:*ASTNode = try ast_utils_script.createDefaultAstNode(allocator);

            type_node.node_type = ASTNodeType.VarType;
            type_node.token = token;

            if (final_node.node_type == ASTNodeType.Invalid) {
                ast_utils_script.copyNodeValues(final_node, type_node);
                break;
            }

            // Traverse to the deepest .Left node to attach the type
            var innermost:?*ASTNode = final_node;
            while (innermost.?.left != null) {
                innermost = innermost.?.left;
            }
            innermost.?.left = type_node;
            break;
        }

        // If not a known type or array token, break (e.g., variable name follows)
        break;
    }

    return final_node;
}

fn processFullStop(allocator:*Allocator, ast_data:*ASTData, node:*ASTNode, first_token:Token) AstError!void {

    const token:Token = try token_utils_script.getNextToken(ast_data);

    if (token.Type == TokenType.FullStop) {
        node.node_type = ASTNodeType.Identifier;
        node.token = first_token;
        ast_data.token_index -= 1;
        return;
    }
    if (token.Type == TokenType.Identifier) {

        node.node_type = ASTNodeType.StructVariable;
        node.token = first_token;

        const left:*ASTNode = ast_utils_script.createDefaultAstNode(allocator) catch {
            return AstError.Out_Of_Memory;
        };

        left.node_type = ASTNodeType.Identifier;
        left.token = token;

        node.left = left;
    }
    
}

fn processArrayAccess(allocator:*Allocator, ast_data:*ASTData, node:*ASTNode, first_token:Token) AstError!void {

    node.node_type = ASTNodeType.ArrayAccess;
    node.token = first_token;

    const fourthToken:Token = try token_utils_script.getNextToken(ast_data);
    const validArrayAccess: bool =
        fourthToken.Type == TokenType.IntegerValue or
        fourthToken.Type == TokenType.Identifier;

    if (validArrayAccess == false) {
        ast_data.setErrorData("Missing index in array access", fourthToken);
        return AstError.Missing_Expected_Type;
    }

    const indexNode:*ASTNode = try parseBinaryExprAny(allocator, ast_data, 0, ASTNodeType.Identifier);

    node.left = indexNode;

    const fifthToken:Token = try token_utils_script.getToken(ast_data);

    if (fifthToken.Type != TokenType.RightSquareBracket) {
        ast_data.setErrorData("Missing ']' in array access", fourthToken);
        return AstError.Missing_Expected_Type;
    }
}

fn processFunctionCall(allocator:*Allocator, ast_data:*ASTData, node:*ASTNode, first_token: Token) AstError!void {

    ast_data.token_index += 1; // Move past the identifier and the '('

    const children_list:*ArrayList(*ASTNode) = allocator.*.create(ArrayList(*ASTNode)) catch {
        return AstError.Out_Of_Memory;
    };

    children_list.* = std.ArrayList(*ASTNode).initCapacity(allocator.*, 0) catch {
        return AstError.Out_Of_Memory;
    };

    node.node_type = ASTNodeType.FunctionCall;
    node.token = first_token;
    node.children = children_list;

    var whileCount:usize = 0;
    const MAX:usize = 1000;

    while (true) {

        if (debugging_script.isInfiniteWhileLoop(&whileCount, MAX) == true) {
            return AstError.Infinite_While_Loop;
        }

        const indexBefore:usize = ast_data.token_index;

        if (ast_data.token_index >= ast_data.token_list.items.len) {
            return AstError.Unexpected_End_Of_File;
        }

        const nextToken:Token = ast_data.token_list.items[ast_data.token_index];

        if (nextToken.Type == TokenType.RightParenthesis) {
            ast_data.token_index += 1; // consume ')'
            break;
        }

        const parameterNode:*ASTNode = try parseBinaryExprAny(allocator, ast_data, 0, ASTNodeType.Parameter);

        node.children.?.append(allocator.*, parameterNode) catch {
            return AstError.Out_Of_Memory;
        };

        if (ast_data.token_index >= ast_data.token_list.items.len) {
            return AstError.Unexpected_End_Of_File;
        }

        const lastToken:Token = ast_data.token_list.items[ast_data.token_index];
        if (lastToken.Type == TokenType.Comma) {
            ast_data.token_index += 1; // consume ','
            continue;
        }
        if (lastToken.Type == TokenType.RightParenthesis) {
            break; // Will be handled by outer loop
        }
        if (lastToken.Type == TokenType.Semicolon) {
            ast_data.token_index -= 1;
            break;
        }
        if (indexBefore == ast_data.token_index) {
            ast_data.token_index += 1;
        }
    }
}

fn parseProcessIdentifier(allocator:*Allocator, ast_data:*ASTData, node:*ASTNode, first_token:Token) AstError!void {

    const secondToken:Token = try token_utils_script.getNextToken(ast_data);

    switch (secondToken.Type) {
        //function
        TokenType.LeftParenthesis => try processFunctionCall(allocator, ast_data, node, first_token),
        //array
        TokenType.LeftSquareBracket => try processArrayAccess(allocator, ast_data, node, first_token),
        //class
        TokenType.FullStop => try processFullStop(allocator, ast_data, node, first_token),
        else => {
            node.node_type = ASTNodeType.Identifier;
            node.token = first_token;
            ast_data.token_index -= 1;
        },
    }
}

pub fn parsePrimaryAny(allocator:*Allocator, ast_data:*ASTData, node_type: ASTNodeType) AstError!?*ASTNode {

    _ = node_type;
    if (ast_data.token_index >= ast_data.token_list.items.len) { 
        return AstError.Unexpected_End_Of_File;
    }

    const token:Token = ast_data.token_list.items[ast_data.token_index];
    var node:*ASTNode = ast_utils_script.createDefaultAstNode(allocator) catch {
        return AstError.Out_Of_Memory;
    };

    switch (token.Type) {

        //TokenType.False, TokenType.True => {
            //node.node_type = ASTNodeType.BoolLiteral;
            //node.token = token;
        //},
        TokenType.IntegerValue => {
            node.node_type = ASTNodeType.IntegerLiteral;
            node.token = token;
        },
        TokenType.Identifier => try parseProcessIdentifier(allocator, ast_data, node, token),
        //TokenType.StringValue => {
            //node.node_type = ASTNodeType.StringLiteral;
            //node.token = token;
        //},
        //TokenType.CharValue => {
            //node.node_type = ASTNodeType.CharLiteral;
            //node.token = token;
        //},
        //TokenType.LeftParenthesis => return ProcessParsePrimaryLeftParenthesis(ast_data, node_type, allocator),
        //TokenType.RightParenthesis => return null,
        //TokenType.And => return ProcessReference(ast_data, token, allocator),
        //TokenType.Minus => return ProcessMinus(ast_data, token, allocator),
        else => { 
            ast_data.error_detail = "Unexpected type in expression, {token.Type}";
            ast_data.error_token = token;
            return AstError.Unexpected_Type;
        }
    }

    ast_data.token_index += 1;
    return node;
}

pub fn parseBinaryExprAny(allocator:*Allocator, ast_data:*ASTData, minPrec:usize, nodeType:ASTNodeType) AstError!*ASTNode {

    var left:?*ASTNode = try parsePrimaryAny(allocator, ast_data, nodeType);

    var whileCount:usize = 0;
    const MAX:usize = 1000;

    while (ast_data.token_index < ast_data.token_list.items.len) {

        if (debugging_script.isInfiniteWhileLoop(&whileCount, MAX) == true) {
            return AstError.Infinite_While_Loop;
        }

        const operator_token:Token = ast_data.token_list.items[ast_data.token_index];

        if (token_utils_script.isBinaryOperatorBool(operator_token.Type) == false) {
            break;
        }

        const precedence:usize = token_utils_script.getPrecedenceBool(operator_token.Type);

        if (precedence < minPrec) {
            break;
        }

        ast_data.token_index += 1; // move past operator
        const right:?*ASTNode = try parseBinaryExprAny(allocator, ast_data, precedence + 1, nodeType);

        if (right == null) {
            ast_data.error_detail = "Missing value after equation symbol";
            ast_data.error_token = operator_token;
            return AstError.Unexpected_Type;
        }

        var new_node:*ASTNode = try ast_utils_script.createDefaultAstNode(allocator);

        new_node.node_type = nodeType;
        new_node.token = operator_token;
        new_node.left = left;
        new_node.right = right;

        left = new_node;
    }
    return left.?;
}