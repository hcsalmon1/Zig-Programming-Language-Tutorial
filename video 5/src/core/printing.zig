

const std = @import("std");
//const print = std.debug.print;


pub const RED = "\x1b[31m";
pub const RESET = "\x1b[0m";
pub const GREEN = "\x1b[32m";
pub const YELLOW = "\x1b[33m";
pub const MAGENTA = "\x1b[35m";
pub const CYAN = "\x1b[36m";
pub const BLUE = "\x1b[34m";
pub const ORANGE = "\x1b[38;2;206;145;120m";
pub const GREY = "\x1b[38;2;156;156;156m";
pub const CREAM = "\x1b[38;2;220;220;145m";
pub const LIGHT_GREEN = "\x1b[38;2;181;206;143m";
pub const LIGHT_BLUE = "\x1b[38;2;5;169;173m";
pub const PEACH = "\x1b[38;2;255;231;190m";

pub fn printNumberSlice(comptime T:type, input:[]const T) void {
	std.debug.print("{any}",.{input});
}
pub fn printlnNumberSlice(comptime T:type, input:[]const T) void {
	std.debug.print("{any}\n",.{input});
}

pub fn printlnQuotes(input:[]const u8) void {
	std.debug.print("'{s}'\n",.{input});
}

pub fn printlnMessage(message:[]const u8, input:[]const u8) void {
	std.debug.print("{s} {s}\n",.{message, input});
}

pub fn printMessage(message:[]const u8, input:[]const u8) void {
	std.debug.print("{s} {s}",.{message, input});
}

pub fn println(input:[]const u8) void {
	std.debug.print("{s}\n",.{input});
}

pub fn print(input:[]const u8) void {
	std.debug.print("{s}",.{input});
}

pub fn printVar(input:anytype) void {
	std.debug.print("{}", .{input});
}

pub fn printlnVar(input:anytype) void {
	std.debug.print("{}\n", .{input});
}

pub fn nl() void {
	std.debug.print("\n",.{});
}

pub fn printMessageVariable(message:[]const u8, input:anytype) void {
	std.debug.print("{s} {}", .{message, input});
}

pub fn printMessageVariableln(message:[]const u8, input:anytype) void {
	std.debug.print("{s} {}\n", .{message, input});
}

pub fn printTypeOfVariable(input:anytype) void {
	std.debug.print("Type: {}\n", .{@TypeOf(input)});
}

pub fn printFloat(input:anytype, decimal_point_count:u4) void {
	switch (decimal_point_count) 
	{
		0 => std.debug.print("float: {d:.0}", .{input}),
		1 => std.debug.print("float: {d:.1}", .{input}),
		2 => std.debug.print("float: {d:.2}", .{input}),
		3 => std.debug.print("float: {d:.3}", .{input}),
		4 => std.debug.print("float: {d:.4}", .{input}),
		5 => std.debug.print("float: {d:.5}", .{input}),
		6 => std.debug.print("float: {d:.6}", .{input}),
		7 => std.debug.print("float: {d:.7}", .{input}),
		8 => std.debug.print("float: {d:.8}", .{input}),
		9 => std.debug.print("float: {d:.9}", .{input}),
		10 => std.debug.print("float: {d:.10}", .{input}),
		11 => std.debug.print("float: {d:.11}", .{input}),		
		12 => std.debug.print("float: {d:.12}", .{input}),		
		13 => std.debug.print("float: {d:.13}", .{input}),		
		14 => std.debug.print("float: {d:.14}", .{input}),		
		15 => std.debug.print("float: {d:.15}", .{input}),		
		else => std.debug.print("float: {}", .{input}),
	}

}

pub fn printFloatln(input:anytype, decimal_point_count:u4) void {
	switch (decimal_point_count) 
	{
		0 => std.debug.print("float: {d:.0}", .{input}),
		1 => std.debug.print("float: {d:.1}", .{input}),
		2 => std.debug.print("float: {d:.2}", .{input}),
		3 => std.debug.print("float: {d:.3}", .{input}),
		4 => std.debug.print("float: {d:.4}", .{input}),
		5 => std.debug.print("float: {d:.5}", .{input}),
		6 => std.debug.print("float: {d:.6}", .{input}),
		7 => std.debug.print("float: {d:.7}", .{input}),
		8 => std.debug.print("float: {d:.8}", .{input}),
		9 => std.debug.print("float: {d:.9}", .{input}),
		10 => std.debug.print("float: {d:.10}", .{input}),
		11 => std.debug.print("float: {d:.11}", .{input}),		
		12 => std.debug.print("float: {d:.12}", .{input}),		
		13 => std.debug.print("float: {d:.13}", .{input}),		
		14 => std.debug.print("float: {d:.14}", .{input}),		
		15 => std.debug.print("float: {d:.15}", .{input}),
		else => std.debug.print("float: {}", .{input}),
	}
	std.debug.print("\n", .{});
}

pub fn printBitsU8(input:u8) void {
	var output:[8]u8 = [8]u8 {'0', '0', '0', '0', '0', '0', '0', '0'};
	var temp:u8 = 128;

	for (0..8) |i| {
		const AND_RESULT:u8 = temp & input;
		if (AND_RESULT != 0) {
			output[i] = '1';
		}
		temp /= 2;
	}
	std.debug.print("{s} ", .{output[0..]});
}

pub fn isIndexInRange(max:usize, index:usize) bool {
	if (index >= max) {
		return false;
	}
	return true;
}

const UsizeConversionError = error {
	OutOfRange,
};

pub fn convertIndexToUsize(input:anytype) !usize {
	if (input < 0) {
		return UsizeConversionError.OutOfRange;
	}
	return @intCast(input);
}

pub fn twoSlicesAreTheSame(first_slice:[]const u8, second_slice:[]const u8) bool {
	const FIRST_SLICE_LENGTH:usize = first_slice.len;

	if (FIRST_SLICE_LENGTH != second_slice.len) {
		return false;
	}
	for (0..FIRST_SLICE_LENGTH) |index| {
		if (first_slice[index] != second_slice[index]) {
			return false;
		}
	}
	return true;
}

pub fn contains(slice:[]const u8, char:u8) bool {
	const LENGTH:usize = slice.len;

	if (LENGTH == 0) {
		return false;
	}
	for (0..LENGTH) |index| {
		if (slice[index] == char) {
			return true;
		}
	}
	return false;
}