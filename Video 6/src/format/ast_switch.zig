

const std = @import("std");
const structs_script = @import("../core/structs.zig");
const enums_script = @import("../core/enums.zig");
const expressions_script = @import("../core/expression.zig");
const errors_script = @import("../core/errors.zig");
const ast_utils_script = @import("ast_utils.zig");
const ast_node_utils_script = @import("../core/ast_node_utils.zig");
const ast_functions_script = @import("ast_functions.zig");
const print = std.debug.print;
const ASTNode = structs_script.ASTNode;
const TokenType = enums_script.TokenType;
const ASTData = structs_script.ASTData;
const Token = structs_script.Token;
const ASTNodeType = enums_script.ASTNodeType;
const AstError = errors_script.AstError;
const Allocator = std.mem.Allocator;
const SwitchPhase = enums_script.SwitchPhase;
const ArrayList = std.ArrayList;

fn fillSwitchCondition(allocator:*Allocator, ast_data:*ASTData) AstError!*ASTNode {
    const condition_node:*ASTNode = try ast_node_utils_script.createDefaultAstNode(allocator);

    const token:Token = try ast_data.getToken();
    try ast_data.incrementIndex();

    if (token.Type != TokenType.Identifier) {
        ast_data.error_token = token;
        ast_data.error_detail = "Only identifier expected in switch ()";
        return AstError.Missing_Expected_Type;
    }

    condition_node.node_type = ASTNodeType.Identifier;
    condition_node.token = token;

    return condition_node;
}


fn fillCaseCondition(allocator:*Allocator, ast_data:*ASTData, switch_phase:*SwitchPhase) AstError!*ASTNode {

    //std.debug.print("-> fillCaseCondition\n", .{});
    //defer std.debug.print("<- fillCaseCondition\n", .{});
    //look for case
    var case_block:*ASTNode = try ast_node_utils_script.createDefaultAstNode(allocator);

    case_block.node_type = ASTNodeType.SwitchCondition;

    const condition_node:*ASTNode = try ast_utils_script.parseExpressionPartUntil(allocator, ast_data, TokenType.Colon);

    try ast_data.expectType(TokenType.Colon, "missing expected ':' in switch");

    case_block.left = condition_node;
    switch_phase.* = SwitchPhase.Body;
    return condition_node;
}

fn fillCaseBody(allocator:*Allocator, ast_data:*ASTData, switch_phase:*SwitchPhase) AstError!*ASTNode {

    //std.debug.print("-> fillCaseBody\n", .{});
    //defer std.debug.print("<- fillCaseBody\n", .{});
    ast_data.error_function = "fillCaseBody";

    const token_count:usize = ast_data.token_list.items.len;

    const block_node:*ASTNode = ast_node_utils_script.createDefaultAstNode(allocator) catch return AstError.Out_Of_Memory;

    const child_list = ArrayList(*ASTNode).initCapacity(allocator.*, 0) catch {
        return AstError.Out_Of_Memory;
    };
    block_node.children = child_list;
    block_node.node_type = ASTNodeType.SwitchBody;

    while (ast_data.token_index < token_count) {

        const index_before:usize = ast_data.token_index;

        const token:Token = try ast_data.getToken();
        //std.debug.print("\ttoken: '{s}'\n", .{token.Text});

        const is_end_character:bool = 
            token.Type == TokenType.RightBrace or
            token.Type == TokenType.Case or
            token.Type == TokenType.Default;

        if (is_end_character == true) {
            //print("\tend token, break\n", .{});
            break;
        }
        try ast_functions_script.processFunctionTokenAST(
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

    switch_phase.* = SwitchPhase.Case;
    return block_node;
}

fn fillCaseBlock(allocator:*Allocator, ast_data:*ASTData) AstError!*ASTNode {
    
    //std.debug.print("-> fillCaseBlock\n", .{});
    //defer std.debug.print("<- fillCaseBlock\n", .{});
    var case_block:*ASTNode = try ast_node_utils_script.createDefaultAstNode(allocator);

    var switch_phrase = SwitchPhase.Case;

    while (ast_data.tokenIndexInBounds() == true) {

        const token:Token = try ast_data.getToken();
        //std.debug.print("\ttoken: '{s}'\n", .{token.Text});

        const end_token:bool =
            token.Type == TokenType.RightBrace or
            token.Type == TokenType.Default;

        if (end_token == true) {
            break;
        }
        try ast_data.incrementIndex();

        switch (switch_phrase) {
            SwitchPhase.Case => case_block.left = try fillCaseCondition(allocator, ast_data, &switch_phrase),
            SwitchPhase.Body => {
                case_block.right = try fillCaseBody(allocator, ast_data, &switch_phrase);
                break;
            },
        }
    }
    case_block.node_type = ASTNodeType.SwitchCase;
    return case_block;
}

fn fillDefaultBlock(allocator:*Allocator, ast_data:*ASTData) AstError!*ASTNode {

    //std.debug.print("-> fillDefaultBlock\n", .{});
    //defer std.debug.print("<- fillDefaultBlock\n", .{});
    var case_block:*ASTNode = try ast_node_utils_script.createDefaultAstNode(allocator);
    try ast_data.expectType(TokenType.Default, "missing expected 'default' in switch");
    try ast_data.incrementIndex();
    try ast_data.expectType(TokenType.Colon, "missing expected ':' in switch");
    try ast_data.incrementIndex();

    var switch_phrase = SwitchPhase.Case;
    case_block.node_type = ASTNodeType.SwitchDefault;
    case_block.right = try fillCaseBody(allocator, ast_data, &switch_phrase);
    return case_block;
}

fn fillSwitchBody(allocator:*Allocator, ast_data:*ASTData) AstError!*ASTNode {

    //print("-> fillDefaultBlock\n", .{});
    //defer print("<- fillDefaultBlock\n", .{});
    const body_node:*ASTNode = try ast_node_utils_script.createDefaultAstNode(allocator);
    body_node.node_type = ASTNodeType.SwitchBody;

    const child_list = ArrayList(*ASTNode).initCapacity(allocator.*, 0) catch {
        return AstError.Out_Of_Memory;
    };

    body_node.children = child_list;

    while (ast_data.tokenIndexInBounds() == true) {
        const token:Token = try ast_data.getToken();

        //print("\ttoken: '{s}'\n", .{token.Text});

        switch (token.Type) {
            TokenType.Case => {
                const case_block:*ASTNode = try fillCaseBlock(allocator, ast_data);
                body_node.children.?.append(allocator.*, case_block) catch return AstError.Out_Of_Memory;
            },
            TokenType.RightBrace => {
                break;
            },
            TokenType.Default => {
                //print("___DEFAULT___\n", .{});
                const default_block:*ASTNode = try fillDefaultBlock(allocator, ast_data);
                try body_node.appendChild(allocator, default_block);
            },
            else => {
                ast_data.error_token = token;
                return AstError.Unexpected_Type;
            },
        }
    }
    return body_node;
}

pub fn processSwitch(allocator:*Allocator, ast_data:*ASTData, first_token:Token) AstError!*ASTNode {
    const switch_node:*ASTNode = try ast_node_utils_script.createDefaultAstNode(allocator);
    switch_node.node_type = ASTNodeType.SwitchStatement;

    switch_node.token = first_token;
    try ast_data.incrementIndex();

    try ast_data.expectType(TokenType.LeftParenthesis, "missing expected '(' in switch");
    try ast_data.incrementIndex();
    const condition_node:*ASTNode = try fillSwitchCondition(allocator, ast_data);
    try ast_data.expectType(TokenType.RightParenthesis, "missing expected ')' in switch");
    try ast_data.incrementIndex();
    try ast_data.expectType(TokenType.LeftBrace, "missing expected '{' in switch");
    try ast_data.incrementIndex();

    const body_node:*ASTNode = try fillSwitchBody(allocator, ast_data);
    try ast_data.expectType(TokenType.RightBrace, "missing expected '}' in switch");
    try ast_data.incrementIndex();

    switch_node.left = condition_node;
    switch_node.right = body_node;

    return switch_node;
}