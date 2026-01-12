
const std = @import("std");
const structs_script = @import("../core/structs.zig");
const enums_script = @import("../core/enums.zig");
const token_utils_script = @import("../core/token_utils.zig");
const expressions_script = @import("../core/expression.zig");
const errors_script = @import("../core/errors.zig");
const ast_node_utils_script = @import("../core/ast_node_utils.zig");
const ast_integers_script = @import("ast_integers.zig");
const ast_pointer_script = @import("ast_pointers.zig");
const ast_return_script = @import("ast_return.zig");
const ast_strings_script = @import("ast_strings.zig");
const ast_utils_script = @import("ast_utils.zig");
const ast_print_script = @import("ast_print.zig");
const ast_if_script = @import("ast_if.zig");
const ast_bool_script = @import("ast_bools.zig");
const ast_for_script = @import("ast_for.zig");
const ast_variable_script = @import("ast_variables.zig");
const ast_array_script = @import("ast_arrays.zig");
const ast_switch_script = @import("ast_switch.zig");
const ast_float_script = @import("ast_floats.zig");
const print = std.debug.print;
const ASTNode = structs_script.ASTNode;
const TokenType = enums_script.TokenType;
const ASTData = structs_script.ASTData;
const Token = structs_script.Token;
const ASTNodeType = enums_script.ASTNodeType;
const AstError = errors_script.AstError;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

pub fn processFunctionTokenAST(allocator:*Allocator, ast_data:*ASTData, first_token:Token, block_node:*ASTNode, is_const:bool) AstError!void {

    ast_data.error_function = "processFunctionTokenAST";

    switch (first_token.Type) {

        TokenType.Const => {

            ast_data.token_index += 1;
            const possibleNextToken:Token = try ast_data.getToken();
            try processFunctionTokenAST(allocator, ast_data, possibleNextToken, block_node, true);
        },
        TokenType.u32, TokenType.i16, TokenType.i8, TokenType.i64, TokenType.u64, TokenType.i32, TokenType.u8, TokenType.Usize => {

            const intDeclarationNode:*ASTNode = try ast_integers_script.processIntDeclaration(allocator, ast_data, first_token, is_const);
            block_node.children.?.append(allocator.*, intDeclarationNode) catch {
                return AstError.Out_Of_Memory;
            };
        },
        TokenType.f64, TokenType.f32 => {
            const float_declaration_node:*ASTNode = try ast_float_script.processFloatDeclaration(allocator, ast_data, first_token, is_const);
            block_node.children.?.append(allocator.*, float_declaration_node) catch return AstError.Out_Of_Memory;
        },
        TokenType.Return => {

            const returnNode = try ast_return_script.processReturn(allocator, ast_data);
            block_node.children.?.append(allocator.*, returnNode) catch return AstError.Out_Of_Memory;
        },
        TokenType.Bool => {

            const bool_declaration_node:*ASTNode = try ast_bool_script.processBoolDeclaration(allocator, ast_data, first_token, is_const);
            block_node.children.?.append(allocator.*, bool_declaration_node) catch return AstError.Out_Of_Memory;
        },
        TokenType.Print => {

            const printNode:*ASTNode = try ast_print_script.processPrint(allocator, ast_data, false);
            block_node.children.?.append(allocator.*, printNode) catch return AstError.Out_Of_Memory;
        },
        TokenType.Println => {

            const printNode:*ASTNode = try ast_print_script.processPrint(allocator, ast_data, true);
            block_node.children.?.append(allocator.*, printNode) catch return AstError.Out_Of_Memory;
        },
        TokenType.Printf => {

            const printNode:*ASTNode = try ast_print_script.processPrintF(allocator, ast_data, false);
            block_node.children.?.append(allocator.*, printNode) catch return AstError.Out_Of_Memory;
        },
        TokenType.If => {

            const if_node:*ASTNode = try ast_if_script.processIf(allocator, ast_data, true);
            block_node.children.?.append(allocator.*, if_node) catch return AstError.Out_Of_Memory;
        },
        TokenType.While => {

            const while_node:*ASTNode = try ast_if_script.processWhile(allocator, ast_data);
            block_node.children.?.append(allocator.*, while_node) catch return AstError.Out_Of_Memory;
        },
        TokenType.For => {

            const for_node:*ASTNode = try ast_for_script.processFor(allocator, ast_data);
            block_node.children.?.append(allocator.*, for_node) catch return AstError.Out_Of_Memory;
        },
        TokenType.Identifier => {

            const variable_node:*ASTNode = try ast_variable_script.processVariableName(allocator, ast_data, true);
            block_node.children.?.append(allocator.* , variable_node) catch return AstError.Out_Of_Memory;
        },
        TokenType.LeftSquareBracket => {

            const array_declaration_node:*ASTNode = try ast_array_script.processArrayDeclaration(allocator, ast_data, is_const);
            block_node.children.?.append(allocator.*, array_declaration_node) catch return AstError.Out_Of_Memory;
        },
        TokenType.String => {

            const string_declaration:*ASTNode = try ast_strings_script.processStringDeclarations(allocator, ast_data, first_token, is_const);
            block_node.children.?.append(allocator.*, string_declaration) catch return AstError.Out_Of_Memory;
        },
        TokenType.Char => {

            const char_declaration:*ASTNode = try ast_strings_script.processCharDeclaration(allocator, ast_data, first_token, is_const);
            block_node.children.?.append(allocator.*, char_declaration) catch return AstError.Out_Of_Memory;
        },
        TokenType.Comment => {

            //const commentNode:*ASTNode = try ast_utils_script.createDefaultAstNode(allocator);
            //const child_list = std.ArrayList(*ASTNode).initCapacity(allocator, 0);
            //commentNode.Token = firstToken;
            //commentNode.Children = &child_list;
            //commentNode.NodeType = ASTNodeType.Comment;

            //while (true) {

                //const token:Token = TokenUtils.GetNextToken(astData);
                //if (token == null) {
                    //break;
                //}
                //const commendPart:*ASTNode = try ast_utils_script.createDefaultAstNode(allocator);
                //commendPart.NodeType = ASTNodeType.StringLiteral;
                //commendPart.Token = Token;

                //commentNode.Children.append(allocator.*, commendPart) catch {
                    //return AstError.Out_Of_Memory;
                //};
                //if (token.Value.Type == TokenType.EndComment) {
                    //astData.TokenIndex += 1;
                    //break;
                //}
            //}

            //blockNode.Children.Add(commentNode);
            //break;
        },
        TokenType.Continue => {

            const continue_node:*ASTNode = try ast_node_utils_script.createDefaultAstNode(allocator);
            continue_node.token = first_token;
            continue_node.node_type = ASTNodeType.Continue;

            try ast_data.incrementIndex();
            try ast_data.expectType(TokenType.Semicolon, "missing expected ';' in continue");
            ast_data.token_index += 1;
            block_node.children.?.append(allocator.*, continue_node) catch return AstError.Out_Of_Memory;
        },
        TokenType.Break => {
            
            const break_node:*ASTNode = try ast_node_utils_script.createDefaultAstNode(allocator);
            break_node.token = first_token;
            break_node.node_type = ASTNodeType.Break;

            try ast_data.incrementIndex();
            try ast_data.expectType(TokenType.Semicolon, "missing expected ';' in break");
            ast_data.token_index += 1;
            block_node.children.?.append(allocator.*, break_node) catch return AstError.Out_Of_Memory;
        },
        TokenType.Switch => {
            const switch_node:*ASTNode = try ast_switch_script.processSwitch(allocator, ast_data, first_token);
            block_node.children.?.append(allocator.*, switch_node) catch return AstError.Out_Of_Memory;
        },
        //TokenType.Multiply => {

            //const pointerNode:*ASTNode = try ast_pointer_script.processPointerDeclaration(allocator, ast_data, first_token, is_global, is_const);
            //block_node.Children.?.append(allocator.*, pointerNode) catch return AstError.Out_Of_Memory;
        //},
        else => {            
            ast_data.error_detail = "unimplemented type in function";
            ast_data.error_token = first_token;
            return AstError.Unimplemented_Type;
        },
    }
}

pub fn processFunctionDeclaration(allocator:*Allocator, ast_data:*ASTData) AstError!void {

    ast_data.error_function = "processFunctionDeclaration";

    try ast_data.incrementIndex();

    const type_node:*ASTNode = try expressions_script.createComplexDeclarations(allocator, ast_data);

    //var name expected

    const var_name_token:Token = try ast_data.getToken();
    if (var_name_token.Type != TokenType.Identifier) {
        ast_data.error_detail = "Missing expected function name";
        return AstError.Missing_Expected_Type;
    }
    try ast_data.incrementIndex();
    try ast_data.expectType(TokenType.LeftParenthesis, "Missing expected '('");
    try ast_data.incrementIndex();

    //get parameters
    const parameters_node:?*ASTNode = try expressions_script.fillParameters(allocator, ast_data);

    //expect ')'
    try ast_data.expectType(TokenType.RightParenthesis, "Missing expected ')'");
    try ast_data.incrementIndex();
    try ast_data.expectType(TokenType.LeftBrace, "Missing expected '{'");
    ast_data.token_index += 1;

    const function_body_node:*ASTNode = try buildBodyBlock(allocator, ast_data, ASTNodeType.FunctionBody);

    try ast_data.expectType(TokenType.RightBrace, "Missing expected '}'");
    ast_data.token_index += 1;

    const function_node:*ASTNode = try ast_node_utils_script.createDefaultAstNode(allocator);
    function_node.node_type = ASTNodeType.FunctionDeclaration;
    function_node.token = var_name_token;
    function_node.left = type_node;
    function_node.middle = parameters_node;
    function_node.right = function_body_node;

    ast_data.ast_nodes.append(allocator.*, function_node) catch { 
        return AstError.Out_Of_Memory;
    };
}

pub fn buildBodyBlock(allocator:*Allocator, ast_data:*ASTData, node_type:ASTNodeType) AstError!*ASTNode {

    ast_data.error_function = "buildBodyBlock";

    const token_count:usize = ast_data.token_list.items.len;

    const block_node:*ASTNode = ast_node_utils_script.createDefaultAstNode(allocator) catch return AstError.Out_Of_Memory;

    const child_list = ArrayList(*ASTNode).initCapacity(allocator.*, 0) catch {
        return AstError.Out_Of_Memory;
    };
    block_node.children = child_list;
    block_node.node_type = node_type;

    while (ast_data.token_index < token_count) {

        const index_before:usize = ast_data.token_index;

        const token:Token = ast_data.token_list.items[ast_data.token_index];
        if (token.Type == TokenType.RightBrace) {
            break;
        }
        try processFunctionTokenAST(
            allocator,
            ast_data, 
            token, 
            block_node, 
            false, //is const
        );

        if (index_before == ast_data.token_index) {
            ast_data.token_index += 1;
        }
    }

    return block_node;
}