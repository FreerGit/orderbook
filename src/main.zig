const std = @import("std");
const Money = @import("lib/money.zig").Money;
const debug = @import("lib/util.zig").debug;

const Order_Book = struct {
    tick_size: f64,
    ba: Level,
    bb: Level,
    price_levels: std.MultiArrayList(Level),

    pub fn init(tick_size: f64, allr: std.mem.Allocator) !Order_Book {
        var price_levels = std.MultiArrayList(Level){};
        for (500_000..1_000_000) |idx| {
            var price = Money.of_f64(@as(f64, @floatFromInt(idx)));
            price.mul(0.05);
            const level = Level{
                .price = price,
                .qty = Money.of_f64(0.0),
            };
            try price_levels.append(allr, level);
        }
        return Order_Book{
            .tick_size = tick_size,
            .price_levels = price_levels,
        };
    }

    pub fn snapshot(self: *Order_Book, []Level) !void {}

    pub fn update(self: *Order_Book, level: Level) !void {
        _ = self; // autofix
        _ = level; // autofix

        // self.price_levels.get(self.bb.price)
    }

    pub fn delete(price: Money, price: Money) !void {
        _ = price; // autofix
    }
};

const Level = struct {
    price: Money,
    qty: Money,
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.c_allocator);
    const ob = try Order_Book.init(0.05, arena.allocator());
    defer arena.deinit();

    debug("{any}", .{ob.price_levels.slice().items(.price)});
}
