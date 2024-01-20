const std = @import("std");
const Money = @import("lib/money.zig").Money;
const debug = @import("lib/util.zig").debug;
const testing = std.testing;
const assert = std.debug.assert;

const Order_Book = struct {
    tick_size: f64,
    // ba: Level,
    // bb: Level,
    // TODO(perf) test SOA vs AOS
    price_levels: std.MultiArrayList(Level),
    start_price: Money,

    pub fn init(tick_size: f64, level_count: usize, best_bid: Money, allr: std.mem.Allocator) !Order_Book {
        assert(level_count % 2 == 0); // divisible by 2, otherwise uneven sides.
        var price_levels = std.MultiArrayList(Level){};
        const side_count = Money.of_f64(@round(tick_size * @as(f64, @floatFromInt(level_count))));
        debug("{d}", .{side_count.to_f64()});
        const lowest_bid = best_bid.sub(side_count._div(2.0));
        var count: f64 = 0;
        const last = @as(f64, @floatFromInt(level_count));
        while (count < last) {
            const price = Money.of_f64(count * tick_size).add(lowest_bid);
            const level = Level{
                .price = price,
                .qty = Money.of_f64(0.0),
            };
            assert(level.price.val >= 0.0);
            try price_levels.append(allr, level);
            count += 1;
        }
        return Order_Book{
            .tick_size = tick_size,
            .price_levels = price_levels,
            .start_price = price_levels.get(0).price,
        };
    }

    pub fn deinit(self: *Order_Book, allr: std.mem.Allocator) void {
        self.price_levels.deinit(allr);
    }

    pub fn snapshot(self: *Order_Book, levels: []Level) void {
        for (levels) |lvl| {
            self.update(lvl);
        }
    }

    fn get_index(self: *Order_Book, price: Money) usize {
        var copy = price;
        copy = copy.sub(self.start_price)._div(self.tick_size);
        return @as(usize, @intFromFloat(copy.to_f64()));
    }

    pub fn update(self: *Order_Book, level: Level) void {
        // TODO(feat) check if index is out of bounds and then realloc.
        const idx = self.get_index(level.price);
        std.debug.assert(idx <= self.price_levels.len);
        self.price_levels.set(idx, level);
    }

    pub fn get_level(self: *Order_Book, price: Money) Level {
        return self.price_levels.get(self.get_index(price));
    }
};

const Level = struct {
    price: Money,
    qty: Money,
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.c_allocator);
    const start_price = Money.of_f64(100.0);
    const ob = try Order_Book.init(0.05, 1000, start_price, arena.allocator());
    defer arena.deinit();
    for (ob.price_levels.items(.price), ob.price_levels.items(.qty)) |p, q| {
        debug("{d}, {d}", .{ p, q });
    }
}

test "assert length" {
    const start_price = Money.of_f64(100.0);
    var ob = try Order_Book.init(0.05, 1000, start_price, std.testing.allocator);
    defer ob.deinit(std.testing.allocator);
    try std.testing.expect(ob.price_levels.len == 1000);
}

test "Simple order book update" {
    const start_price = Money.of_f64(100.0);

    var ob = try Order_Book.init(0.05, 1000, start_price, std.testing.allocator);
    defer ob.deinit(std.testing.allocator);
    const lvl = .{ .price = Money.of_f64(75.0), .qty = Money.of_f64(5.55) };
    const lvl_2 = .{ .price = Money.of_f64(75.05), .qty = Money.of_f64(1.0002) };
    const lvl_3 = .{ .price = Money.of_f64(76), .qty = Money.of_f64(1.22) };
    const lvl_4 = .{ .price = Money.of_f64(85), .qty = Money.of_f64(1.33) };
    const last = .{ .price = Money.of_f64(124.95), .qty = Money.of_f64(42.0) };
    ob.update(lvl);
    try testing.expect(ob.price_levels.get(0).qty.to_f64() == 5.55);
    ob.update(lvl_2);
    try testing.expect(ob.price_levels.get(1).qty.to_f64() == 1.0002);
    ob.update(lvl_3);
    try testing.expect(ob.price_levels.get(20).qty.to_f64() == 1.22);
    ob.update(lvl_4);
    try testing.expect(ob.price_levels.get(200).qty.to_f64() == 1.33);
    ob.update(last);
    try testing.expect(ob.price_levels.get(999).qty.to_f64() == 42.0);
}
