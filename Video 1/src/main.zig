const std = @import("std");
const code_sample_script = @import("core/code_samples.zig");
const parse_code_script = @import("parse/parse_code.zig");
const struct_script = @import("core/structs.zig");
const enum_script = @import("core/enums.zig");
const debugging_script = @import("debugging/debugging.zig");
const print = std.debug.print;
const ArenaAllocator = std.heap.ArenaAllocator;
const Allocator = std.mem.Allocator;
const Token = struct_script.Token;

fn convertCode(code:[]const u8) void {

    print("Code: \n{s}\n", .{code});

    const page_allocator = std.heap.page_allocator;
    var arena = ArenaAllocator.init(page_allocator);
    defer arena.deinit();

    var arena_allocator:Allocator = arena.allocator();

    //parse code
    const token_list:*std.ArrayList(Token) = parse_code_script.parseToTokens(&arena_allocator, code) catch |err| {
        print("Error {}\n", .{err});
        return;
    };
    debugging_script.printTokens(token_list);

}

pub fn main() void {
    convertCode(code_sample_script.RETURN_ZERO);
}

