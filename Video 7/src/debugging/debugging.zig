

const std = @import("std");
const structs_script = @import("../core/structs.zig");
const printing_script = @import("../core/printing.zig");
const print = std.debug.print;
const ArrayList = std.ArrayList;
const Token = structs_script.Token;
const ASTData = structs_script.ASTData;
const ASTNode = structs_script.ASTNode;
const Allocator = std.mem.Allocator;
const ConvertData = structs_script.ConvertData;
const AnalysisData = structs_script.AnalysisData;
const CompilerSettings = structs_script.CompilerSettings;
const SplitIterator = std.mem.SplitIterator;

const string = []const u8;

pub fn printTokens(token_list:ArrayList(Token), compiler_settings:*const CompilerSettings) void {

    if (compiler_settings.show_tokens == false) {
        return;
    }

    print("\nPrinting Tokens:\n", .{});

    const LENGTH:usize = token_list.items.len;
    if (LENGTH == 0) {
        print("\tzero length: {}\n", .{LENGTH});
        return;
    }
    for (0..LENGTH) |i| {
        
        const token:Token = token_list.items[i];
        std.debug.print("\t{s}Text:{s} {s}'{s}'{s}, {s}type:{s} {s}{}{s} {s}line:{s} {}, {s}char:{s} {}\n", .{
            printing_script.GREY,
            printing_script.RESET,

            printing_script.ORANGE,
            token.Text, 
            printing_script.RESET,

            printing_script.GREY,
            printing_script.RESET,

            printing_script.CREAM,
            token.Type,
            printing_script.RESET,

            printing_script.GREY,
            printing_script.RESET,
            token.LineNumber,

            printing_script.GREY,
            printing_script.RESET,
            token.CharNumber,
        });
    }
}

pub fn isInfiniteWhileLoop(count:*usize, cap:usize) bool {
    count.* += 1;
    if (count.* >= cap) {
        return true;
    }
    return false;
}

pub fn printASTNodes(allocator:*Allocator, ast_nodes:ArrayList(*ASTNode), compiler_settings:*const CompilerSettings) !void {

    if (compiler_settings.show_ast_nodes == false) {
        return;
    }

    std.debug.print("\n{s}Printing Ast Nodes:{s}\n", .{printing_script.GREY, printing_script.RESET});

    const node_count:usize = ast_nodes.items.len;

    if (node_count == 0) {
        std.debug.print("{s}\tNo nodes{s}\n", .{printing_script.RED, printing_script.RESET});
        return;
    }
    for (0..node_count) |i| {
        const node:?*ASTNode = ast_nodes.items[i];
        try printASTNode(allocator, node, 3, "base");
    }
}

pub fn printASTNode(allocator: *Allocator, node: ?*ASTNode, indent: usize, ast_type_text: []const u8) !void {
    
    if (node == null) {
        return;
    }
    
    // Create padding
    const padding:*ArrayList(u8) = try allocator.*.create(ArrayList(u8));
    padding.* = try ArrayList(u8).initCapacity(allocator.*, indent);
    
    for (0..indent) |i| {
        try addSpacing(allocator, indent, padding, i);
    }
    
    // Print node info
    if (padding.items.len > 0) {
        std.debug.print("{s}", .{padding.items});
    }
    
    std.debug.print("{s}{}{s} ", .{ printing_script.CREAM, node.?.node_type, printing_script.RESET});
    
    // Print token info
    if (node.?.token) |token| {
        std.debug.print("{s}'{s}'{s} - {s}\n", .{
            printing_script.CYAN,
            token.Text,
            printing_script.RESET,
            ast_type_text,
        });
    } else {
        std.debug.print("NA - {s}\n", .{ast_type_text});
    }
    
    // Recursively print children with increased indent
    if (node.?.left) |left| {
        try printASTNode(allocator, left, indent + 1, "left");
    }
    
    if (node.?.middle) |middle| {
        try printASTNode(allocator, middle, indent + 1, "middle");
    }
    
    if (node.?.right) |right| {
        try printASTNode(allocator, right, indent + 1, "right");
    }
    
    if (node.?.children) |children| {
        const children_count:usize = children.items.len;
        if (children_count > 10000) {
            print("WARNING: count: {}\n", .{children});
            return;
        }

        for (0..children_count) |i| {

            const child:*ASTNode = children.items[i];
            
            // Validate child pointer before using it
            const child_addr:usize = @intFromPtr(child);
            if (child_addr < 0x1000) {
                std.debug.print("{s}[INVALID CHILD POINTER at index {}] - child\n", .{ padding.items, i });
                continue;
            }
            
            try printASTNode(allocator, child, indent + 1, "child");
        }
    }
}

fn addSpacing(allocator:*Allocator, indent:usize, padding:*ArrayList(u8), i:usize) !void {

    if (i + 1 == indent) {
        try padding.append(allocator.*, '|');
        try padding.append(allocator.*, '-');
        return;
    }
    if (i == 2) {
        try padding.append(allocator.*, '|');
        try padding.append(allocator.*, ' ');
        return;
    }
    if (i == 3) {
        try padding.append(allocator.*, '|');
        try padding.append(allocator.*, ' ');
        return;
    }
    
    try padding.append(allocator.*, ' ');
    try padding.append(allocator.*, ' ');
    
}

pub fn printSemanticError(allocator:*Allocator, analysis_data:AnalysisData, code:string) !void {

    const error_token:?Token = analysis_data.error_token;

    const line_number:usize = getLineNumber(error_token);
    const char_number:usize = getCharNumber(error_token);
    const temp_error_detail:?string = analysis_data.error_detail;
    var error_detail:string = undefined;

    if (temp_error_detail == null) {
        error_detail = "NA";
    } else {
        error_detail = temp_error_detail.?;
    }

    const normalized_code:[]u8 = try std.mem.replaceOwned(u8, allocator.*, code, "\r\n", "\n");
    defer allocator.free(normalized_code);
    
    var line_iterator = std.mem.splitScalar(u8, normalized_code, '\n');
    var code_lines = try ArrayList([]const u8).initCapacity(allocator.*, 0);
    
    while (line_iterator.next()) |line| {
        try code_lines.append(allocator.*, line);
    }

    print("\t{s}Error on line {}, {}: {s}{s}\n", .{
        printing_script.CREAM, 
        line_number + 1, 
        char_number, 
        error_detail, 
        printing_script.RESET
    });

    printCodeLines(line_number, char_number, &code_lines);

    printErrorToken(error_token);

    if (analysis_data.error_function) |error_function_name| {
        std.debug.print("\tFunction: {s}{s}{s}\n", .{
            printing_script.CREAM, 
            error_function_name, 
            printing_script.RESET
        });
    }
}

pub fn printAstError(allocator:*Allocator, ast_data:ASTData, code:string) !void {

    const error_token:?Token = ast_data.error_token;

    const line_number:usize = getLineNumber(error_token);
    const char_number:usize = getCharNumber(error_token);
    const temp_error_detail:?string = ast_data.error_detail;
    var error_detail:string = undefined;

    if (temp_error_detail == null) {
        error_detail = "NA";
    } else {
        error_detail = temp_error_detail.?;
    }

    const normalized_code:[]u8 = try std.mem.replaceOwned(u8, allocator.*, code, "\r\n", "\n");
    defer allocator.free(normalized_code);
    
    var line_iterator = std.mem.splitScalar(u8, normalized_code, '\n');
    var code_lines = try ArrayList([]const u8).initCapacity(allocator.*, 0);
    
    while (line_iterator.next()) |line| {
        try code_lines.append(allocator.*, line);
    }

    print("\t{s}Error on line {}, {}: {s}{s}\n", .{
        printing_script.CREAM, 
        line_number + 1, 
        char_number, 
        error_detail, 
        printing_script.RESET
    });

    printCodeLines(line_number, char_number, &code_lines);

    printErrorToken(error_token);

    if (ast_data.error_function) |error_function_name| {
        std.debug.print("\tFunction: {s}{s}{s}\n", .{
            printing_script.CREAM, 
            error_function_name, 
            printing_script.RESET
        });
    }
}

pub fn printConvertError(allocator:*Allocator, convert_data:ConvertData, code:[]const u8) !void {

    const error_token:?Token = convert_data.error_token;

    const line_number:usize = getLineNumber(error_token);
    const char_number:usize = getCharNumber(error_token);
    const temp_error_detail:?[]const u8 = convert_data.error_detail;
    var error_detail:[]const u8 = undefined;

    if (temp_error_detail == null) {
        error_detail = "NA";
    } else {
        error_detail = temp_error_detail.?;
    }

    const normalized_code:[]u8 = try std.mem.replaceOwned(u8, allocator.*, code, "\r\n", "\n");
    defer allocator.free(normalized_code);
    
    var line_iterator = std.mem.splitScalar(u8, normalized_code, '\n');
    var code_lines = try std.ArrayList([]const u8).initCapacity(allocator.*, 0);
    
    while (line_iterator.next()) |line| {
        try code_lines.append(allocator.*, line);
    }

    std.debug.print("\t{s}Error on line {}, {}: {s}{s}\n", .{
        printing_script.CREAM, 
        line_number, 
        char_number, 
        error_detail, 
        printing_script.RESET
    });

    printCodeLines(line_number, char_number, &code_lines);

    printErrorToken(error_token);

    if (convert_data.error_function) |error_function| {
        std.debug.print("\tFunction: {s}{s}{s}\n", .{printing_script.CREAM, error_function, printing_script.RESET});
    }
}

fn getLineNumber(error_token:?Token) usize {
    if (error_token == null) {
        return 0;
    }
    return error_token.?.LineNumber;
}

fn getCharNumber(error_token:?Token) usize {
    if (error_token == null) {
        return 0;
    }
    return error_token.?.CharNumber;
}

fn printCodeLines(line_number:usize, char_number:usize, code_lines:*ArrayList([]const u8)) void {

    var previous_line:[]const u8 = "...";

    var previous_index_in_range:bool = false;

    if (line_number > 0) {
        previous_index_in_range =
            line_number - 1 >= 0 and 
            line_number - 1 < code_lines.items.len;
    }

    if (previous_index_in_range) {
        previous_line = code_lines.items[line_number - 1];
    }

    var code_line:[]const u8 = "...";

    const index_in_range:bool = 
        line_number >= 0 and 
        line_number < code_lines.items.len;

    if (index_in_range) {
        code_line = code_lines.items[line_number];
    }

    std.debug.print("\tline {}: {s}\n\tline {}: {s}\n\t\t{s}", .{
        line_number, 
        previous_line, 
        line_number + 1, 
        code_line,
        printing_script.GREEN
    });
    var i: usize = 0;
    while (i < char_number) : (i += 1) {
        std.debug.print("~", .{});
    }
    print("^{s}\n\n", .{printing_script.RESET});
}

fn printErrorToken(error_token:?Token) void {
    std.debug.print("\tToken: ", .{});
    if (error_token != null) {
        std.debug.print("{s}'{s}'{s}\n", .{printing_script.GREEN, error_token.?.Text, printing_script.RESET});
    } else {
        std.debug.print("Error token not set\n", .{});
    }
}

fn printTypeNodeRecursive(type_node:*const ASTNode) void {
    if (type_node.*.token == null) {
        return;
    }
    print("{s} ", .{type_node.*.token.?.Text});
    if (type_node.left != null) {
        printTypeNodeRecursive(type_node.*.left.?);
    }
}

fn printParameters(parameters:?ArrayList(*ASTNode)) void {

    if (parameters == null) {
        return;
    }
    const parameter_count:usize = parameters.?.items.len;
    if (parameter_count == 0) {
        return;
    }
    for (0..parameter_count) |i| {
        if (i != 0) {
            print(", ", .{});
        }
        const parameter:*ASTNode = parameters.?.items[i];
        print("{s}", .{printing_script.CYAN});
        printTypeNodeRecursive(parameter.*.left.?);
        print("{s}{s}", .{printing_script.RESET, parameter.*.token.?.Text});
    }
}

