const std = @import("std");
const Money = @import("lib/money.zig").Money;
const debug = @import("lib/util.zig").debug;

const Order_Book = struct {
    tick_size: f64,
    price_levels: std.MultiArrayList(Level),

    pub fn init(tick_size: f16, allr: std.mem.Allocator) !Order_Book {
        var price_levels = std.MultiArrayList(Level){};
        for (0..10) |idx| {
            const level = Level{
                .price = Money.of_f64(@as(f64, @floatFromInt(idx)) * tick_size),
                .qty = Money.of_f64(0.0),
            };
            try price_levels.append(allr, level);
        }
        return Order_Book{
            .tick_size = tick_size,
            .price_levels = price_levels,
        };
    }
};

const Level = struct {
    price: Money,
    qty: Money,
};

pub fn main() !void {
    var buffer: [1024 * 1024]u8 = undefined;
    var x = std.heap.FixedBufferAllocator.init(&buffer);
    var arena = std.heap.ArenaAllocator.init(x.allocator());
    const ob = Order_Book.init(0.05, arena.allocator());
    debug("{any}", .{ob});
}
