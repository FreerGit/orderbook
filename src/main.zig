const std = @import("std");
const Money = @import("lib/money.zig").Money;
const debug = @import("lib/util.zig").debug;
const testing = std.testing;

const Order_Book = struct {
    tick_size: f64,
    // ba: Level,
    // bb: Level,
    price_levels: std.MultiArrayList(Level),
    start_price: Money,

    pub fn init(tick_size: f64, start_price: Money, allr: std.mem.Allocator) !Order_Book {
        var price_levels = std.MultiArrayList(Level){};
        // TODO(robustness) count should be passed and not hardcored.
        var count: f64 = 0;
        while (count <= 200) {
            var price = Money.of_f64(count * tick_size);
            price.add(start_price);
            const level = Level{
                .price = price,
                .qty = Money.of_f64(0.0),
            };
            try price_levels.append(allr, level);
            count += 1;
        }
        return Order_Book{
            .tick_size = tick_size,
            .price_levels = price_levels,
            .start_price = start_price,
        };
    }

    pub fn snapshot(self: *Order_Book, levels: []Level) !void {
        for (levels) |lvl| {
            self.update(lvl);
        }
    }

    fn get_index(self: *Order_Book, price: Money) usize {
        var copy = price;
        copy.sub(self.start_price);
        copy.div(Money.of_f64(self.tick_size));
        return @as(usize, @intFromFloat(copy.val));
    }

    pub fn update(self: *Order_Book, level: Level) !void {
        const idx = self.get_index(level.price);
        self.price_levels.set(idx, level);
    }

    pub fn get_level(self: *Order_Book, price: Money) !Level {
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
    const ob = try Order_Book.init(0.05, start_price, arena.allocator());
    defer arena.deinit();
    for (ob.price_levels.items(.price), ob.price_levels.items(.qty)) |p, q| {
        debug("{d}, {d}", .{ p, q });
    }
}

test "Simple order book update" {
    const start_price = Money.of_f64(100.0);
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    var ob = try Order_Book.init(0.05, start_price, allocator);
    const lvl = .{ .price = Money.of_f64(101.0), .qty = Money.of_f64(5.55) };
    try ob.update(lvl);
    for (ob.price_levels.items(.price), ob.price_levels.items(.qty)) |p, q| {
        if (p.to_f64() != 101.0) {
            try testing.expect(q.to_f64() == 0.0);
        } else {
            try testing.expect(q.to_f64() == 5.55);
        }
    }
}
