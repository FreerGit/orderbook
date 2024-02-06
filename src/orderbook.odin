package orderbook

import money "../money/src"
import "core:testing"

Side :: enum {
	Bid,
	Ask,
}

Level :: struct {
	price: money.Money,
	size:  money.Money,
}

Order_Book :: struct {
	tick_size:    f64,
	start_price:  money.Money,
	ba:           Level,
	bb:           Level,
	price_levels: #soa[]Level,
}

Error :: enum {
	Allocation_Error,
}

new_level :: proc(price: f64, qty: f64) -> Level {
	return Level{price = money.new(price), size = money.new(qty)}
}

new_orderbook :: proc(tick_size: f64, levels: uint, bb: money.Money) -> (Order_Book, Error) {
	assert(levels % 2 == 0) // handle as error case if needed in the future
	price_levels := make([]Level, levels)
	side_count: money.Money = money.new(tick_size * transmute(f64)levels)
	lowest_bid := bb - side_count / 2.0

	assert(bb == 5.0)
	return {}, nil

}


@(test, private)
new_level_test :: proc(t: ^testing.T) {
	lvl := new_level(42.42, 11.99)
	testing.expect(t, lvl.price == money.new(42.42))
	testing.expect(t, lvl.size == money.new(11.99))
}

@(test, private)
struct_sizes_test :: proc(t: ^testing.T) {
	testing.expect_value(t, size_of(Order_Book), 72)
	testing.expect_value(t, size_of(Level), 16)
}
