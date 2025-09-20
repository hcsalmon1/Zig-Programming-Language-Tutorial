

const std = @import("std");
const structs_script = @import("../core/structs.zig");
const printing_script = @import("../core/printing.zig");
const print = std.debug.print;
const ArrayList = std.ArrayList;
const Token = structs_script.Token;
const ASTData = structs_script.ASTData;
const ASTNode = structs_script.ASTNode;
const Allocator = std.mem.Allocator;

pub fn printTokens(token_list:*ArrayList(Token)) void {
    print("\nPrinting Tokens:\n", .{});

    const LENGTH:usize = token_list.items.len;
    if (LENGTH == 0) {
        print("\tzero length: {}\n", .{LENGTH});
        return;
    }
    for (0..LENGTH) |i| {
        
        const token:Token = token_list.items[i];
        std.debug.print("\t{s}Text:{s} {s}'{s}'{s}, {s}type:{s} {}\n", .{
            printing_script.GREY,
            printing_script.RESET,

            printing_script.ORANGE,
            token.Text, 
            printing_script.RESET,

            printing_script.GREY,
            printing_script.RESET,
            token.Type
        });
    }
}