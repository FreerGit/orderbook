const std = @import("std");
const print = std.debug.print;

const level = struct {
    price: i32,
    qty: u32,
};

fn debug(comptime fmt: []const u8, args: anytype) void {
    print(fmt ++ "\n", args);
}

pub fn main() !void {
    debug("hello world", .{});
}
