package money

import "core:fmt"
import "core:math/rand"
import "core:testing"
// A Money is stored as 10^-6 units instead of 1 unit. 
// For example: 1.05 dollars -> 1050000.0 Money
// Has 15 digits of guaranteed precision
Money :: distinct f64

new :: proc(v: f64) -> Money {
	assert(v >= 0.0)
	return Money(v) * 1_000_000.0
}

to_f64 :: proc(m: Money) -> f64 {
	return f64(m) / 1_000_000.0
}

@(test)
money_size :: proc(t: ^testing.T) {
	testing.expect(t, size_of(f64) == size_of(Money))
}

@(test)
conversion_f64 :: proc(t: ^testing.T) {
	my_rand: rand.Rand
	rand.init(&my_rand, 0)
	for i in 0 ..= 10_000 {
		some_random_number := f64(rand.int63_max(9_999_999, &my_rand))
		money := new(some_random_number)
		testing.expect(t, some_random_number == to_f64(money))
	}
}

@(test)
conversion_money :: proc(t: ^testing.T) {
	my_rand: rand.Rand
	rand.init(&my_rand, 0)
	for i in 0 ..= 10_000 {
		some_random_number := f64(rand.int63_max(9_999_999, &my_rand))
		money := new(some_random_number)
		testing.expect(t, to_f64(new(to_f64(money))) == some_random_number)
	}
}

@(test)
min_max :: proc(t: ^testing.T) {
	min := new(0.000001)
	max := new(9_999_999_999.999_999)
	testing.expect(t, to_f64(min) == 0.000001)
	testing.expect(t, to_f64(max) == 9_999_999_999.999_999)
}
