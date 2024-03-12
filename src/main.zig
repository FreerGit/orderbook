const std = @import("std");
const Money = @import("money").Money;
const testing = std.testing;
const assert = std.debug.assert;

pub const Order_Book = struct {
    tick_size: f64,
    ba: Level,
    bb: Level,
    // TODO(perf) test SOA vs AOS
    price_levels: std.MultiArrayList(Level),
    start_price: Money,
    level_count: usize,
    allr: std.mem.Allocator,

    pub const Side = enum {
        Bid,
        Ask,
    };

    pub const Level = struct {
        price: Money,
        qty: Money,

        pub fn new(price: f64, qty: f64) Level {
            return .{ .price = Money.new(price), .qty = Money.new(qty) };
        }
    };

    pub fn init(tick_size: f64, level_count: usize, best_bid: Money, allr: std.mem.Allocator) !Order_Book {
        assert(level_count % 2 == 0); // divisible by 2, otherwise uneven sides.
        var price_levels = std.MultiArrayList(Level){};
        const side_count = Money.new(@round(tick_size * @as(f64, @floatFromInt(level_count))));
        const lowest_bid = best_bid.sub(side_count._div(2.0));
        var count: f64 = 0;
        const last = @as(f64, @floatFromInt(level_count));
        while (count < last) {
            const price = Money.new(count * tick_size).add(lowest_bid);
            const level = Level{
                .price = price,
                .qty = Money.new(0.0),
            };
            assert(level.price.val >= 0.0);
            try price_levels.append(allr, level);
            count += 1;
        }
        return Order_Book{ .tick_size = tick_size, .ba = undefined, .bb = undefined, .price_levels = price_levels, .start_price = price_levels.get(0).price, .level_count = level_count, .allr = allr };
    }

    pub fn deinit(self: *Order_Book) void {
        self.price_levels.deinit(self.allr);
    }

    pub fn snapshot(self: *Order_Book, bids: []const Level, asks: []const Level) void {
        self.bb = bids[0];
        self.ba = asks[0];
        for (bids) |lvl| {
            self.update(lvl, .Bid);
        }
        for (asks) |lvl| {
            self.update(lvl, .Ask);
        }
    }

    fn get_index(self: *Order_Book, price: Money) usize {
        var copy = price;
        copy = copy.sub(self.start_price)._div(self.tick_size);
        // TODO(feat) check if index is out of bounds and then realloc.
        assert(copy.to_f64() >= 0.0);
        return @as(usize, @intFromFloat(copy.to_f64()));
    }

    // fn realloc(self: *Order_Book) !void {
    //     // https://github.com/jeog/SimpleOrderbook/blob/master/src/orderbook/impl.tpp#L133
    //     // Not certain on what behaviour I actually want, but the following seems good for now:
    //     // Depending what side of the orderbook the price goes beyond, keep that half
    //     // and allocate the other half.
    // }

    pub fn update(self: *Order_Book, level: Level, side: Side) void {

        // TODO(feat) check if index is out of bounds and then realloc.
        const idx = self.get_index(level.price);
        std.debug.assert(idx <= self.price_levels.len);

        // A better bid/ask was submitted
        if (side == .Bid and level.price.val > self.bb.price.val) {
            self.bb = level;
        } else if (side == .Ask and level.price.val < self.bb.price.val) {
            self.ba = level;
        }

        // Current best bid/ask was removed
        if (level.qty.val == 0.0 and level.price.val == self.bb.price.val) {
            for (1..self.price_levels.len) |i| {
                const count = @as(f64, @floatFromInt(i));
                const next_level = self.get_level(level.price.sub(Money.new(self.tick_size * count)));
                if (next_level.qty.val != 0.0) {
                    self.bb = next_level;
                    break;
                }
            }
        } else if (level.qty.val == 0.0 and level.price.val == self.ba.price.val) {
            for (1..self.price_levels.len) |i| {
                const count = @as(f64, @floatFromInt(i));
                const next_level = self.get_level(level.price.add(Money.new(self.tick_size * count)));
                if (next_level.qty.val != 0.0) {
                    self.ba = next_level;
                    break;
                }
            }
        }

        self.price_levels.set(idx, level);
    }

    pub fn get_level(self: *Order_Book, price: Money) Level {
        return self.price_levels.get(self.get_index(price));
    }
};

test "assert length" {
    const start_price = Money.new(100.0);
    var ob = try Order_Book.init(0.05, 1000, start_price, std.testing.allocator);
    defer ob.deinit();
    try std.testing.expect(ob.price_levels.len == 1000);
}

test "Simple order book update" {
    const start_price = Money.new(100.0);

    var ob = try Order_Book.init(0.05, 1000, start_price, std.testing.allocator);
    defer ob.deinit();
    const lvl = .{ .price = Money.new(75.0), .qty = Money.new(5.55) };
    const lvl_2 = .{ .price = Money.new(75.05), .qty = Money.new(1.0002) };
    const lvl_3 = .{ .price = Money.new(76), .qty = Money.new(1.22) };
    const lvl_4 = .{ .price = Money.new(85), .qty = Money.new(1.33) };
    const last = .{ .price = Money.new(124.95), .qty = Money.new(42.0) };
    ob.update(lvl, .Bid);
    try testing.expect(ob.price_levels.get(0).qty.to_f64() == 5.55);
    ob.update(lvl_2, .Bid);
    try testing.expect(ob.price_levels.get(1).qty.to_f64() == 1.0002);
    ob.update(lvl_3, .Bid);
    try testing.expect(ob.price_levels.get(20).qty.to_f64() == 1.22);
    ob.update(lvl_4, .Bid);
    try testing.expect(ob.price_levels.get(200).qty.to_f64() == 1.33);
    ob.update(last, .Ask);
    try testing.expect(ob.price_levels.get(999).qty.to_f64() == 42.0);
}

test "Get the correct level based on price" {
    const start_price = Money.new(10_000.0);
    var ob = try Order_Book.init(0.05, 100, start_price, std.testing.allocator);
    defer ob.deinit();

    ob.update(Order_Book.Level.new(10_000.0, 42.0), .Bid);
    try testing.expect(std.meta.eql(ob.get_level(Money.new(10_000.0)), ob.price_levels.get(50)));
    try testing.expect(std.meta.eql(ob.get_level(Money.new(9997.5)), ob.price_levels.get(0)));
    try testing.expect(std.meta.eql(ob.get_level(Money.new(10_002.45)), ob.price_levels.get(99)));
    try testing.expect(std.meta.eql(ob.get_level(Money.new(10_000.05)), ob.price_levels.get(51)));
    try testing.expect(std.meta.eql(ob.get_level(Money.new(9999.95)), ob.price_levels.get(49)));
    try testing.expect(std.meta.eql(ob.get_level(Money.new(9997.55)), ob.price_levels.get(1)));
}

test "Snapshot" {
    const start_price = Money.new(2500.0);
    var ob = try Order_Book.init(0.05, 1000, start_price, std.testing.allocator);
    defer ob.deinit();
    const bids = [_]Order_Book.Level{
        Order_Book.Level.new(2500.0, 1.0),
        Order_Book.Level.new(2499.95, 1.5),
        Order_Book.Level.new(2499.9, 2.1),
    };
    const asks = [_]Order_Book.Level{
        Order_Book.Level.new(2500.05, 1.0),
        Order_Book.Level.new(2500.1, 1.5),
        Order_Book.Level.new(2500.15, 2.1),
    };
    ob.snapshot(bids[0..], asks[0..]);

    try testing.expect(std.meta.eql(ob.get_level(Money.new(2500.0)), ob.bb));
    try testing.expect(std.meta.eql(ob.get_level(Money.new(2500.05)), ob.ba));
}

test "Changing BB/BA on updates" {
    const start_price = Money.new(1000.0);
    var ob = try Order_Book.init(0.05, 1000, start_price, std.testing.allocator);
    defer ob.deinit();
    const bids = [_]Order_Book.Level{
        Order_Book.Level.new(1000.0, 1.0),
        Order_Book.Level.new(999.95, 1.5),
        Order_Book.Level.new(999.9, 2.1),
    };
    const asks = [_]Order_Book.Level{
        Order_Book.Level.new(1000.05, 1.0),
        Order_Book.Level.new(1000.1, 1.5),
        Order_Book.Level.new(1000.15, 2.1),
    };
    ob.snapshot(bids[0..], asks[0..]);

    try testing.expect(std.meta.eql(ob.get_level(Money.new(1000.0)), ob.bb));
    try testing.expect(std.meta.eql(ob.get_level(Money.new(1000.05)), ob.ba));

    ob.update(Order_Book.Level.new(1000.0, 0.0), .Bid);
    const new_best_bid = Order_Book.Level.new(1001.0, 5.0);
    ob.update(new_best_bid, .Bid);

    try testing.expect(std.meta.eql(new_best_bid, ob.bb));
    try testing.expect(std.meta.eql(ob.get_level(Money.new(1000.05)), ob.ba));

    ob.update(Order_Book.Level.new(1000.05, 0.0), .Ask);
    try testing.expect(std.meta.eql(new_best_bid, ob.bb));
    try testing.expect(std.meta.eql(Order_Book.Level.new(1000.1, 1.5), ob.ba));

    const new_best_ask = Order_Book.Level.new(1000.05, 5.55);
    ob.update(new_best_ask, .Ask);
    try testing.expect(std.meta.eql(Order_Book.Level.new(1000.05, 5.55), ob.ba));
}

fn debug(comptime fmt: []const u8, args: anytype) void {
    std.debug.print(fmt ++ "\n", args);
}
