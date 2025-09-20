

const std = @import("std");
const struct_script = @import("../core/structs.zig");
const enum_script = @import("../core/enums.zig");
const error_script = @import("../core/errors.zig");
const printing_script = @import("../core/printing.zig");
const parse_utils_script = @import("parse_utils.zig");
const Allocator = std.mem.Allocator;
const Token = struct_script.Token;
const ArrayList = std.ArrayList;
const ParseData = struct_script.ParseData;
const ParseError = error_script.ParseError;
const TokenType = enum_script.TokenType;
const print = std.debug.print;


pub fn parseToTokens(allocator:*Allocator, code:[]const u8) !*std.ArrayList(Token) {
    std.debug.print("\t{s}Parsing{s}\t\t\t\t", .{printing_script.GREY, printing_script.RESET});

    const token_list = try allocator.*.create(ArrayList(Token));
    token_list.* = try std.ArrayList(Token).initCapacity(allocator.*, 0);

    var parse_data = ParseData {
        .token_list = token_list,
        .code = code,
    };

    if (parse_data.code.len == 0) {
        return ParseError.Code_Length_Is_Zero;
    }

    const STRING_LENGTH:usize = code.len;
    while (parse_data.character_index < STRING_LENGTH) {

        try processCharacter(allocator, &parse_data);
        //break;
    }
    std.debug.print("{s}Done{s}\n", .{printing_script.CYAN, printing_script.RESET});
    return token_list;
}

fn shouldSkip(allocator:*std.mem.Allocator, parse_data:*ParseData) !bool {

    parse_data.char_count += 1;
    if (parse_data.last_token != null) {

        if (parse_data.last_token.?.Type == TokenType.Comment) {
            parse_data.was_comment = true;
        }
    }

    const currentChar:u8 = parse_data.code[parse_data.character_index];

    if (currentChar == '\n') {

        if (parse_data.was_comment == true) {

            try parse_data.token_list.append(
                allocator.*,
                Token{
                    .Text = "", 
                    .Type = TokenType.EndComment, 
                    .LineNumber = parse_data.line_count, 
                    .CharNumber = parse_data.char_count
                },
            );
            parse_data.was_comment = false;
        }
        parse_data.line_count += 1;
        parse_data.char_count = 0;
        parse_data.character_index += 1;
        return true;
    }
    const is_special_char:bool =
        currentChar == '\r' or
        currentChar == '\t' or
        currentChar == ' ' or
        currentChar == '\\';

    if (is_special_char == true) {
        parse_data.character_index += 1;
        return true;
    }
    return false;
}

fn processCharacter(allocator:*std.mem.Allocator, parse_data:*ParseData) !void {

    if (try shouldSkip(allocator, parse_data) == true) {
        return;
    }

    const previous_character_index:usize = parse_data.character_index;
    const token:Token = try getToken(allocator, parse_data);

    if (previous_character_index == parse_data.character_index) {
        parse_data.character_index += 1;
    }

    try parse_data.token_list.append(allocator.*, token);
    parse_data.last_token = token;
}

fn getToken(allocator:*Allocator, parse_data:*ParseData) !Token {

    const current_char:u8 = parse_data.code[parse_data.character_index];

    if (current_char == '"') {
        return readString(allocator, parse_data);
    }
    if (current_char == '\'') {
        return readChar(allocator, parse_data);
    }
    if (parse_utils_script.isOperator(current_char)) {
        return readOperator(allocator, parse_data);
    }
    if (parse_utils_script.isSeparator(current_char)) {
        return readSeparator(allocator, parse_data);
    }

    return ReadWord(allocator, parse_data);
}

fn readString(allocator:*Allocator, parse_data:*ParseData) !Token {

    var text_builder:std.ArrayList(u8) = try std.ArrayList(u8).initCapacity(allocator.*, 0);

    //go past the '"'
    parse_data.*.character_index += 1;

    while (parse_data.character_index < parse_data.code.len) {

        const char:u8 = parse_data.code[parse_data.character_index];
        if (char == '"') {

            parse_data.character_index += 1;
            const text:[]u8 = try text_builder.toOwnedSlice(allocator.*);
            
            return Token{
                .Text = text,
                .Type = TokenType.StringValue,
                .LineNumber = parse_data.line_count,
                .CharNumber = parse_data.char_count,
            };
        }
        try text_builder.append(allocator.*, char);
        parse_data.character_index += 1;
    }

    return ParseError.Unterminated_String;
}

fn readSeparator(allocator:*Allocator, parse_data: *ParseData) !Token {
    
    const char:[]u8 = try allocator.alloc(u8, 1);
    char[0] = parse_data.code[parse_data.character_index];

    parse_data.character_index += 1;
    const tokenText:[]const u8 = char[0..];
    return Token{
        .Text = tokenText, 
        .Type = parse_utils_script.getTokenType(tokenText), 
        .LineNumber = parse_data.line_count, 
        .CharNumber = parse_data.char_count
    };
}

fn readChar(allocator:*std.mem.Allocator, parse_data:*ParseData) !Token {

    parse_data.character_index += 1;
    if (parse_data.character_index >= parse_data.code.len) {
        return ParseError.Unexpected_Value;
    }

    const char_value:[]u8 = try allocator.alloc(u8, 1);
    char_value[0] = parse_data.code[parse_data.character_index];
    parse_data.character_index += 1;

    if (parse_data.character_index >= parse_data.code.len) {
        return ParseError.Unexpected_Value;
    }

    if (parse_data.code[parse_data.character_index] != '\'') {
        return ParseError.Unterminated_Char;
    }
    parse_data.character_index += 1;

    return Token{
        .Text = char_value, 
        .Type = TokenType.CharValue, 
        .LineNumber = parse_data.line_count, 
        .CharNumber = parse_data.char_count
    };
}

fn readOperator(allocator:*Allocator, parse_data:*ParseData) !Token {

    var text_builder:std.ArrayList(u8) = try std.ArrayList(u8).initCapacity(allocator.*, 0);

    const char:u8 = parse_data.code[parse_data.character_index];
    try text_builder.append(allocator.*, char);

    parse_data.character_index += 1;

    // Lookahead for compound operators like "==", "!="
    if (parse_data.character_index < parse_data.code.len) {

        const next:u8 = parse_data.code[parse_data.character_index];
        if (parse_utils_script.isOperator(next)) {
            try text_builder.append(allocator.*, next);
            parse_data.character_index += 1;
        }
    }

    const text:[]u8 = try text_builder.toOwnedSlice(allocator.*);
    return Token{
        .Text = text, 
        .Type = parse_utils_script.getTokenType(text), 
        .LineNumber = parse_data.line_count, 
        .CharNumber = parse_data.char_count
    };
}

fn ReadWord(allocator:*std.mem.Allocator, parse_data:*ParseData) !Token {

    var text_builder:std.ArrayList(u8) = try std.ArrayList(u8).initCapacity(allocator.*, 0);

    while (parse_data.character_index < parse_data.code.len) {

        const c:u8 = parse_data.code[parse_data.character_index];

        if (parse_utils_script.isLetterOrDigit(c) or c == '_') {
            try text_builder.append(allocator.*, c);
            parse_data.character_index += 1;
        } else {
            break;
        }
    }

    const text:[]u8 = try text_builder.toOwnedSlice(allocator.*);
    return Token{
        .Text = text,
        .Type = parse_utils_script.getTokenType(text),
        .LineNumber = parse_data.line_count, 
        .CharNumber = parse_data.char_count
    };
}