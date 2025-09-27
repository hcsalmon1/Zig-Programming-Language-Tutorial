
const std = @import("std");
const structs_script = @import("../core/structs.zig");
const enums_script = @import("../core/enums.zig");
const token_utils_script = @import("../core/token_utils.zig");
const expressions_script = @import("../core/expression.zig");
const errors_script = @import("../core/errors.zig");
const ast_utils_script = @import("../core/ast_utils.zig");
const ast_integers_script = @import("ast_integers.zig");
const ast_pointer_script = @import("ast_pointers.zig");
const ast_return_script = @import("ast_return.zig");
const print = std.debug.print;
const ASTNode = structs_script.ASTNode;
const TokenType = enums_script.TokenType;
const ASTData = structs_script.ASTData;
const Token = structs_script.Token;
const ASTNodeType = enums_script.ASTNodeType;
const AstError = errors_script.AstError;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

fn processFunctionTokenAST(allocator:*Allocator, ast_data:*ASTData, first_token:Token, block_node:*ASTNode, is_global:bool, is_const:bool) AstError!void {

    ast_data.error_function = "processFunctionTokenAST";

    switch (first_token.Type) {

        TokenType.Const => {

            ast_data.token_index += 1;
            const possibleNextToken:Token = try ast_data.getToken();
            try processFunctionTokenAST(allocator, ast_data, possibleNextToken, block_node, is_global, true);
        },
        TokenType.u32, TokenType.i16, TokenType.i8, TokenType.i64, TokenType.u64, TokenType.i32, TokenType.u8, TokenType.Usize => {

            const intDeclarationNode:*ASTNode = try ast_integers_script.processIntDeclaration(allocator, ast_data, first_token, is_global, is_const);
            block_node.children.?.append(allocator.*, intDeclarationNode) catch {
                return AstError.Out_Of_Memory;
            };
        },
        TokenType.f64, TokenType.f32 => {

            //const floatDeclarationNode:*ASTNode = AstFloats.ProcessFloatDeclaration(astData, firstToken, isGlobal, isConst);
            //blockNode.Children.append(allocator.*, floatDeclarationNode);
        },
        TokenType.Return => {

            const returnNode = try ast_return_script.processReturn(allocator, ast_data);
            block_node.children.?.append(allocator.*, returnNode) catch return AstError.Out_Of_Memory;
        },
        TokenType.Bool => {

            //const boolDeclarationNode:*ASTNode = AstBools.ProcessBoolDeclaration(astData, firstToken, isGlobal, isConst);
            //blockNode.Children.append(allocator.*, boolDeclarationNode);
        },
        TokenType.Print => {

            //const printNode:*ASTNode = AstPrint.ProcessPrint(astData, false);
            //blockNode.Children.Add(printNode);
        },
        TokenType.Println => {

            //const println_node:*ASTNode = AstPrint.ProcessPrint(astData, true);
            //blockNode.Children.Add(println_node);
        },
        TokenType.If => {

            //const ifNode:*ASTNode = AstIf.ProcessIf(astData, true);
            //blockNode.Children.Add(ifNode);
            //break;
        },
        TokenType.While => {

            //const whileNode:*ASTNode = AstWhile.ProcessWhile(astData);
            //blockNode.Children.Add(whileNode);
        },
        TokenType.For => {

            //const forNode:*ASTNode = AstFor.ProcessFor(astData);
            //blockNode.Children.Add(forNode);
        },
        TokenType.Identifier => {

            //const variableNode:*ASTNode = AstVariables.ProcessVariableName(astData, true);
            //blockNode.Children.Add(variableNode);
        },
        TokenType.LeftSquareBracket => {

            //const arrayDeclarationNode:*ASTNode = AstArrays.ProcessArrayDeclaration(astData, isGlobal, isConst);
            //blockNode.Children.Add(arrayDeclarationNode);
        },
        TokenType.String => {

            //const stringDeclaration:*ASTNode = AstStrings.ProcessStringDeclarations(astData, firstToken, isGlobal, isConst);
            //blockNode.Children.Add(stringDeclaration);
            //break;
        },
        TokenType.Char => {

            //const charDeclaration:*ASTNode = AstStrings.ProcessCharDeclaration(astData, firstToken, isGlobal, isConst);
            //blockNode.Children.Add(charDeclaration);
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

            //const continueNode:*ASTNode = try ast_utils_script.createDefaultAstNode(allocator);
            //continueNode.Token = firstToken;
            //continueNode.NodeType = ASTNodeType.Continue;

            //nextToken = TokenUtils.GetNextToken(astData);
            //if (nextToken.Value.Type != TokenType.Semicolon) {
                //AstValidation.MissingExpectedType(astData, "Missing ';' after continue", nextToken, thisFunctionName);
                //return;
            //}
            //astData.token_index += 1;
            //blockNode.Children.Add(continueNode);
        },
        TokenType.Break => {
            
            //const breakNode:*ASTNode = try ast_utils_script.createDefaultAstNode(allocator);
            //breakNode.Token = firstToken;
            //breakNode.NodeType = ASTNodeType.Break;

            //nextToken = TokenUtils.GetNextToken(astData);
            //if (nextToken.Value.Type != TokenType.Semicolon) {
                //AstValidation.MissingExpectedType(astData, "Missing ';' after continue", nextToken, thisFunctionName);
                //return;
            //}
            //astData.TokenIndex += 1;

            //blockNode.Children.Add(breakNode);
            //break;
        },
        TokenType.Multiply => {

            //const pointerNode:*ASTNode = try ast_pointer_script.processPointerDeclaration(allocator, ast_data, first_token, is_global, is_const);
            //block_node.Children.?.append(allocator.*, pointerNode) catch return AstError.Out_Of_Memory;
        },
        else => {            
            ast_data.error_detail = "unimplemented type in function";
            ast_data.error_token = first_token;
            return AstError.Unimplemented_Type;
        },
    }
}

pub fn processFunctionDeclaration(allocator:*Allocator, ast_data:*ASTData) AstError!void {

    ast_data.error_function = "processFunctionDeclaration";

    //var type expected
    const var_type_token:Token = try ast_data.getNextToken();

    if (token_utils_script.isVarType(var_type_token.Type) == false) {
        ast_data.error_detail = "Missing expected function type";
        return AstError.Missing_Expected_Type;
    }

    const type_node:*ASTNode = try ast_utils_script.createDefaultAstNode(allocator);
    type_node.node_type = ASTNodeType.ReturnType;
    type_node.token = var_type_token;

    //var name expected

    const var_name_token:Token = try ast_data.getNextToken();
    if (var_name_token.Type != TokenType.Identifier) {
        ast_data.error_detail = "Missing expected function name";
        return AstError.Missing_Expected_Type;
    }

    const left_parenthesis_token:Token = try ast_data.getNextToken();
    if (left_parenthesis_token.Type != TokenType.LeftParenthesis) {
        ast_data.error_detail = "Missing expected '('";
        return AstError.Missing_Expected_Type;
    }
    ast_data.token_index += 1;

    //get parameters
    const parameters_node:?*ASTNode = null;// try expressions_script.fillParameters(allocator, ast_data);

    //expect ')'
    const right_parenthesis_token:Token = try ast_data.getToken();
    if (right_parenthesis_token.Type != TokenType.RightParenthesis) {
        ast_data.error_detail = "Missing expected ')'";
        return AstError.Missing_Expected_Type;
    }

    const left_brace_token:Token = try ast_data.getNextToken();
    if (left_brace_token.Type != TokenType.LeftBrace) {
        ast_data.error_detail = "Missing expected '{'";
        return AstError.Missing_Expected_Type;
    }
    ast_data.token_index += 1;

    const function_body_node:*ASTNode = try buildBodyBlock(allocator, ast_data, ASTNodeType.FunctionBody);

    const right_brace_token:Token = try ast_data.getToken();
    if (right_brace_token.Type != TokenType.RightBrace) {
        ast_data.error_detail = "Missing expected '}'";
        return AstError.Missing_Expected_Type;
    }
    ast_data.token_index += 1;

    const function_node:*ASTNode = try ast_utils_script.createDefaultAstNode(allocator);
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

    const block_node:*ASTNode = ast_utils_script.createDefaultAstNode(allocator) catch return AstError.Out_Of_Memory;

    const child_list:*ArrayList(*ASTNode) = allocator.*.create(ArrayList(*ASTNode)) catch {
        return AstError.Out_Of_Memory;
    };
    child_list.* = ArrayList(*ASTNode).initCapacity(allocator.*, 0) catch {
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
            false, //is global
            false, //is const
        );

        if (index_before == ast_data.token_index) {
            ast_data.token_index += 1;
        }
    }

    return block_node;
}