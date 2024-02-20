package orderbook

import money "../money/src"
import "core:fmt"
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

new_orderbook :: proc(tick_size: f64, levels: int, bb: money.Money) -> (Order_Book, Error) {
	assert(levels % 2 == 0) // handle as error case if needed in the future
	price_levels := make_soa_slice(#soa[]Level, levels)
	last := levels
	side_count: money.Money = money.new(tick_size * cast(f64)last)
	lowest_bid := money.sub(bb, money._div(side_count, 2.0))
	count := 0
	for count < last {
		price := money.add(money.new(cast(f64)count * tick_size), lowest_bid)
		level := Level {
			price = price,
			size  = money.new(0),
		}
		assert(level.price.v >= 0.0)
		price_levels[count] = level
		count = count + 1
	}
	return (Order_Book {
				tick_size = tick_size,
				ba = {},
				bb = {},
				price_levels = price_levels,
				start_price = price_levels[0].price,
			}),
		nil

}

get_index :: proc(ob: ^Order_Book, price: money.Money) -> u64 {
	copy := price
	copy = money._div(money.sub(copy, ob.start_price), ob.tick_size)
	index := cast(u64)money.to_f64(copy)
	// TODO(feat) check if index is out of bounds and then realloc.
	assert(index >= 0)
	return index
}

get_level :: proc(ob: ^Order_Book, price: money.Money) -> Level {
	return ob.price_levels[get_index(ob, price)]
}

main :: proc() {}


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

@(test, private)
assert_length_test :: proc(t: ^testing.T) {
	start_price := money.new(100.)
	ob, err := new_orderbook(0.05, 1000, start_price)
	testing.expect_value(t, err, nil)
	testing.expect(t, len(ob.price_levels) == 1000)
	for level in ob.price_levels {
		fmt.println(money.to_f64(level.price))
	}
}

@(test, private)
lower_and_upper_init_test :: proc(t: ^testing.T) {
	start_price := money.new(100.)
	ob, err := new_orderbook(0.05, 1000, start_price)
	testing.expect_value(t, err, nil)
	lower := money.new(75.)
	upper := money.new(124.95)

	testing.expect_value(t, ob.price_levels[0].price, lower)
	testing.expect_value(t, ob.price_levels[len(ob.price_levels) - 1].price, upper)
}

@(test, private)
get_level_based_on_price :: proc(t: ^testing.T) {
	start_price := money.new(10_000.0)
	ob, err := new_orderbook(0.05, 100, start_price)
	testing.expect_value(t, err, nil)

	testing.expect_value(t, get_level(&ob, money.new(10_000.)), ob.price_levels[50])
	testing.expect_value(t, get_level(&ob, money.new(9997.5)), ob.price_levels[0])
	testing.expect_value(t, get_level(&ob, money.new(10_002.45)), ob.price_levels[99])
	testing.expect_value(t, get_level(&ob, money.new(10_000.05)), ob.price_levels[51])
	testing.expect_value(t, get_level(&ob, money.new(9999.95)), ob.price_levels[49])
	testing.expect_value(t, get_level(&ob, money.new(9997.55)), ob.price_levels[1])
}
