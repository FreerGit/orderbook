const std = @import("std");
const testing = std.testing;
const RndGen = std.rand.DefaultPrng;

// A Money is stored as 10^-6 units instead of 1 unit. For example:
//      1.05 dollars -> 1050000.0 Money
// Has 15 digits of guaranteed precision
pub const Money = struct {
    val: f64,

    pub fn of_f64(v: f64) Money {
        return Money{ .val = v * 1_000_000.0 };
    }

    pub fn to_f64(m: Money) f64 {
        return m.val / 1_000_000.0;
    }

    pub fn mul(m: *Money, v: Money) void {
        m.val = m.val * v.val;
    }

    pub fn div(m: *Money, v: Money) void {
        m.val = m.val / v.val;
    }

    pub fn add(m: *Money, v: Money) void {
        m.val = m.val + v.val;
    }

    pub fn format(
        money: Money,
        comptime _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = try writer.print("Money {d}", .{money.to_f64()});
    }
};

test "Struct should inline the f64, same size" {
    try testing.expect(@sizeOf(f64) == @sizeOf(Money));
}

test "f64 -> Money -> f64 should not change f64" {
    var rnd = RndGen.init(0);
    for (0..10_000) |_| {
        const some_random_number = rnd.random().intRangeAtMost(i64, 1, 9_999_999);
        const money = Money.of_f64(@as(f64, @floatFromInt(some_random_number)));
        try testing.expect(@as(f64, @floatFromInt(some_random_number)) == money.to_f64());
    }
}

test "Money -> f64 -> Money should not change the val" {
    var rnd = RndGen.init(0);
    for (0..10_000) |_| {
        const some_random_number = rnd.random().intRangeAtMost(i64, 1, 9_999_999);
        const money = Money.of_f64(@as(f64, @floatFromInt(some_random_number)));
        try testing.expect(Money.of_f64(money.to_f64()).to_f64() == @as(f64, @floatFromInt(some_random_number)));
    }
}

test "Min and max" {
    const max = Money.of_f64(0.000001);
    const min = Money.of_f64(9_999_999_999.999_999);

    try testing.expect(max.to_f64() == 0.000001);
    try testing.expect(min.to_f64() == 9_999_999_999.999_999);
}
