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

snapshot :: proc(ob: ^Order_Book, bids: []Level, asks: []Level) {
	ob.bb = bids[0]
	ob.ba = asks[0]
	for lvl in bids {
		update(ob, lvl, Side.Bid)
	}
	for lvl in asks {
		update(ob, lvl, Side.Ask)
	}
}

update :: proc(ob: ^Order_Book, level: Level, side: Side) {
	// TODO(feat) check if index is out of bounds and then realloc.
	idx := get_index(ob, level.price)
	assert(idx <= len(ob.price_levels))

	// A better bid/ask was submitted
	if (side == .Bid && level.price.v > ob.bb.price.v) {
		ob.bb = level
	} else if (side == .Ask && level.price.v < ob.bb.price.v) {
		ob.ba = level
	}

	// Current best bid/ask was removed
	if (level.size.v == 0.0 && level.price.v == ob.bb.price.v) {
		for i in 1 ..= len(ob.price_levels) {
			count := cast(f64)i
			next_level := get_level(ob, money.sub(level.price, money.new(ob.tick_size * count)))
			if next_level.size.v != 0. {
				ob.bb = next_level
				break
			}
		}
	} else if (level.size.v == 0.0 && level.price.v == ob.ba.price.v) {
		for i in 1 ..= len(ob.price_levels) {
			count := cast(f64)i
			next_level := get_level(ob, money.sub(level.price, money.new(ob.tick_size * count)))
			if next_level.size.v != 0. {
				ob.ba = next_level
				break
			}
		}
	}

	ob.price_levels[idx] = level
}

@(private)
get_index :: proc(ob: ^Order_Book, price: money.Money) -> int {
	copy := price
	copy = money._div(money.sub(copy, ob.start_price), ob.tick_size)
	index := cast(int)money.to_f64(copy)
	// TODO(feat) check if index is out of bounds and then realloc.
	assert(index >= 0)
	return index
}

get_level :: proc(ob: ^Order_Book, price: money.Money) -> Level {
	return ob.price_levels[get_index(ob, price)]
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

@(test, private)
assert_length_test :: proc(t: ^testing.T) {
	start_price := money.new(100.)
	ob, err := new_orderbook(0.05, 1000, start_price)
	testing.expect_value(t, err, nil)
	testing.expect(t, len(ob.price_levels) == 1000)

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
get_level_based_on_price_test :: proc(t: ^testing.T) {
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

@(test, private)
simple_ob_update_test :: proc(t: ^testing.T) {
	start_price := money.new(100.0)

	ob, err := new_orderbook(0.05, 1000, start_price)
	testing.expect_value(t, err, nil)

	lvl := Level {
		price = money.new(75.),
		size  = money.new(5.55),
	}
	lvl_2 := Level {
		price = money.new(75.05),
		size  = money.new(1.0002),
	}
	lvl_3 := Level {
		price = money.new(76.),
		size  = money.new(1.22),
	}
	lvl_4 := Level {
		price = money.new(85.),
		size  = money.new(1.33),
	}
	lvl_5 := Level {
		price = money.new(124.95),
		size  = money.new(42.0),
	}
	update(&ob, lvl, .Bid)
	testing.expect_value(t, money.to_f64(ob.price_levels[0].size), 5.55)
	update(&ob, lvl_2, .Bid)
	testing.expect_value(t, money.to_f64(ob.price_levels[1].size), 1.0002)
	update(&ob, lvl_3, .Bid)
	testing.expect_value(t, money.to_f64(ob.price_levels[20].size), 1.22)
	update(&ob, lvl_4, .Bid)
	testing.expect_value(t, money.to_f64(ob.price_levels[200].size), 1.33)
	update(&ob, lvl_5, .Ask)
	testing.expect_value(t, money.to_f64(ob.price_levels[999].size), 42.0)
}


@(test, private)
snapshot_test :: proc(t: ^testing.T) {
	start_price := money.new(2500.)
	ob, err := new_orderbook(0.05, 1000, start_price)
	testing.expect_value(t, err, nil)

	bids := [3]Level{new_level(2500., 1.), new_level(2499.95, 1.5), new_level(2499.9, 2.1)}
	asks := [3]Level{new_level(2500.05, 1.), new_level(2500.1, 1.5), new_level(2500.15, 2.1)}
	snapshot(&ob, bids[:], asks[:])

	testing.expect_value(t, get_level(&ob, money.new(2500.)), ob.bb)
	testing.expect_value(t, get_level(&ob, money.new(2500.05)), ob.ba)
}

bb_ba_updates_test :: proc(t: ^testing.T) {
	start_price := money.new(2500.)
	ob, err := new_orderbook(0.05, 1000, start_price)
	testing.expect_value(t, err, nil)

	bids := [3]Level{new_level(1000., 1.), new_level(999.95, 1.5), new_level(999.9, 2.1)}
	asks := [3]Level{new_level(1000.05, 1.), new_level(1000.1, 1.5), new_level(1000.15, 2.1)}

	snapshot(&ob, bids[:], asks[:])

	testing.expect_value(t, get_level(&ob, money.new(1000.)), ob.bb)
	testing.expect_value(t, get_level(&ob, money.new(1000.05)), ob.ba)

	update(&ob, new_level(1000., 0.), .Bid)
	new_best_bid := new_level(1001., 5.)
	update(&ob, new_best_bid, .Bid)

	testing.expect_value(t, new_best_bid, ob.bb)
	testing.expect_value(t, get_level(&ob, money.new(1000.05)), ob.ba)

	update(&ob, new_level(1000.05, 0.), .Ask)
	testing.expect_value(t, new_best_bid, ob.bb)
	testing.expect_value(t, new_level(1000.1, 1.5), ob.ba)

	new_best_ask := new_level(1000.05, 5.55)
	update(&ob, new_best_ask, .Ask)
	testing.expect_value(t, new_level(1000.05, 5.55), ob.ba)
}
