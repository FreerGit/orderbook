const std = @import("std");
const print = std.debug.print;

const Order_Book = struct {
    tick_size: f16,
    price_levels: std.MultiArrayList(Level),
    pub fn init(tick_size: f16, allr: std.mem.Allocator) Order_Book {
        var price_levels: std.MultiArrayList(Level) = undefined;
        for (0..10_000) |idx| {
            const level = Level{
                .price = @as(f16, idx) * tick_size,
                .qty = 0,
            };
            price_levels.insert(allr, idx, level);
        }
        return Order_Book{
            .tick_size = tick_size,
            .price_levels = price_levels,
        };
    }
};

const Level = struct {
    price: i32,
    qty: u32,
};

fn debug(comptime fmt: []const u8, args: anytype) void {
    print(fmt ++ "\n", args);
}

pub fn main() !void {
    var buffer: [1024 * 1024 * 16]u8 = undefined;
    var x = std.heap.FixedBufferAllocator.init(&buffer);
    const ob = Order_Book.init(0.05, x.allocator());
    debug("{any}", .{ob});
}
