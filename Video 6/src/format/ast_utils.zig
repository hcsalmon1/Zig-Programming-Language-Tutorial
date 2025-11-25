
const std = @import("std");
const structs_script = @import("../core/structs.zig");
const enums_script = @import("../core/enums.zig");
const expressions_script = @import("../core/expression.zig");
const errors_script = @import("../core/errors.zig");
const ast_node_utils_script = @import("../core/ast_node_utils.zig");
const ASTNode = structs_script.ASTNode;
const TokenType = enums_script.TokenType;
const ASTData = structs_script.ASTData;
const Token = structs_script.Token;
const ASTNodeType = enums_script.ASTNodeType;
const AstError = errors_script.AstError;
const Allocator = std.mem.Allocator;

// For print and function calls
pub fn fillNodeInBrackets(allocator:*Allocator, ast_data:*ASTData, output_node:*ASTNode, nodeType:ASTNodeType) !void {

    ast_data.error_function = "fillNodeInBrackets";
    var count:usize = 0;

    while (true) {

        count += 1;

        if (count > 500) {
            return AstError.Infinite_While_Loop;
        }

        const token:Token = try ast_data.getToken();

        if (token.Type == TokenType.RightParenthesis) {
            break;
        }

        if (token.Type == TokenType.Comma) {
            ast_data.token_index += 1;
            continue;
        }
        
        const value_node:*ASTNode = try expressions_script.parseBinaryExprAny(allocator, ast_data, 0, nodeType);

        if (output_node.children == null) {
            ast_data.error_detail = "output node children is null in fillNodeInBrackets";
            ast_data.error_token = token;
            return AstError.Null_Type;
        }
        output_node.children.?.append(allocator.*, value_node) catch return AstError.Out_Of_Memory;
    }
}

pub fn createBoolLiteralNode(allocator:*Allocator, token_text:[]const u8) AstError!*ASTNode {
    const literal_node:*ASTNode = try ast_node_utils_script.createDefaultAstNode(allocator);
    literal_node.node_type = ASTNodeType.BoolLiteral;
    const token_size:usize = token_text.len;
    var temp_text:[]u8 = allocator.alloc(u8, token_size) catch return AstError.Out_Of_Memory;
    for (0..token_size) |i| {
        temp_text[i] = token_text[i];
    }
    const token:Token = .{
        .Text = temp_text,
        .Type = TokenType.StringValue,
        .LineNumber = 0,
        .CharNumber = 0,
    };
    literal_node.token = token;
    return literal_node;
}

fn parseIdentifierExpressionUntil(allocator:*Allocator, ast_data:*ASTData, end_type:TokenType, first_token:Token) AstError!*ASTNode {
    
    //std.debug.print("-> parseIdentifierExpressionUntil", .{});
    //defer std.debug.print("<- parseIdentifierExpressionUntil", .{});
    ast_data.error_function = "parseIdentifierExpressionUntil";
    // Start with the first token (identifier etc)
    var current_node: *ASTNode = try ast_node_utils_script.createDefaultAstNode(allocator);
    current_node.token = first_token;
    current_node.node_type = ASTNodeType.Identifier;

    try ast_data.incrementIndex();
    var loop_count: usize = 0;
    
    while (ast_data.tokenIndexInBounds()) {
        try ast_data.isInfiniteLoop(loop_count, 1000);
        loop_count += 1;
        
        const token: Token = try ast_data.getToken();
        //std.debug.print("token: {s}\n", .{token.Text});

        if (token.Type == end_type) {
            break;
        }
        
        switch (token.Type) {
            
            .Identifier => {
                try ast_data.incrementIndex();
                const next_token = try ast_data.getToken();
                
                var dot_node = try ast_node_utils_script.createDefaultAstNode(allocator);
                dot_node.node_type = ASTNodeType.Identifier;
                dot_node.token = next_token;
                dot_node.left = current_node;  // Previous expression on left
                
                current_node = dot_node;  // This becomes the new "current"
                try ast_data.incrementIndex();
            },
            .FullStop => {
                // struct.value case
                try ast_data.incrementIndex();
                const next_token = try ast_data.getToken();
                
                var dot_node = try ast_node_utils_script.createDefaultAstNode(allocator);
                dot_node.node_type = ASTNodeType.FullStop;
                dot_node.token = next_token;
                dot_node.left = current_node;  // Previous expression on left
                
                current_node = dot_node;  // This becomes the new "current"
                try ast_data.incrementIndex();
            },
            
            //.LeftBracket => {
                // array[0] case - similar pattern
                // Parse the index expression, create node, set left to current_node
            //},
            
            //.Asterisk => {
                // ptr* case
                //var deref_node = try createNode(allocator, .Pointer, token);
                //deref_node.left = current_node;
                //current_node = deref_node;
                //try ast_data.incrementIndex();
            //},
            
            else => {
                return AstError.Unexpected_Type;
            }
        }
    }
    
    return current_node;
}
fn parseStringValueExpression(allocator:*Allocator, ast_data:*ASTData, first_token:Token) AstError!*ASTNode {
    var string_literal_block:*ASTNode = try ast_node_utils_script.createDefaultAstNode(allocator);
    try ast_data.incrementIndex();

    string_literal_block.node_type = ASTNodeType.StringLiteral;
    string_literal_block.token = first_token;
    return string_literal_block;
}

fn parseIntegerValueExpression(allocator:*Allocator, ast_data:*ASTData, first_token:Token) AstError!*ASTNode {

    //std.debug.print("-> parseIntegerValueExpression\n", .{});
    //defer std.debug.print("<- parseIntegerValueExpression\n", .{});
    var integer_literal_block:*ASTNode = try ast_node_utils_script.createDefaultAstNode(allocator);
    try ast_data.incrementIndex();

    integer_literal_block.node_type = ASTNodeType.IntegerLiteral;
    integer_literal_block.token = first_token;
    return integer_literal_block;
}

pub fn parseExpressionPartUntil(allocator:*Allocator, ast_data:*ASTData, end_type:TokenType) AstError!*ASTNode {

    //std.debug.print("-> parseExpressionPartUntil\n", .{});
    //defer std.debug.print("<- parseExpressionPartUntil\n", .{});
    ast_data.error_function = "parseExpressionPartUntil";
    const first_token:Token = try ast_data.getToken();
    //std.debug.print("\ttoken: '{s}'\n", .{first_token.Text});

    switch (first_token.Type) {
        .Identifier => return try parseIdentifierExpressionUntil(allocator, ast_data, end_type, first_token),
        .StringValue => return try parseStringValueExpression(allocator, ast_data, first_token),
        .IntegerValue => return try parseIntegerValueExpression(allocator, ast_data, first_token),
        else => {
            ast_data.error_token = first_token;
            ast_data.error_detail = "Unexpected type in switch case";
            return AstError.Unexpected_Type;
        },
    }
}


