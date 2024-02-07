package money

import "core:fmt"
import "core:math/rand"
import "core:testing"
// A Money is stored as 10^-6 units instead of 1 unit. 
// For example: 1.05 dollars -> 1050000.0 Money
// Has 15 digits of guaranteed precision
// -- DO NOT ACCESS FIELDS IN MONEY DIRECTLY -- 
Money :: struct {
	v: f64,
}

new :: proc(v: f64) -> Money {
	assert(v >= 0.0)
	return Money{v * 1_000_000.0}
}

to_f64 :: proc(m: Money) -> f64 {
	return m.v / 1_000_000.0
}

_sub :: proc(l: Money, r: f64) -> Money {
	return Money{l.v - new(r).v}
}

sub :: proc(l: Money, r: Money) -> Money {
	return Money{l.v - r.v}
}

_add :: proc(l: Money, r: f64) -> Money {
	return Money{l.v + new(r).v}
}

add :: proc(l: Money, r: Money) -> Money {
	return Money{l.v + r.v}
}

_mul :: proc(l: Money, r: f64) -> Money {
	return Money{l.v * r}
}

mul :: proc(l: Money, r: Money) -> Money {
	return Money{to_f64(Money{l.v * r.v})} // bring one of the scalers down.
}

_div :: proc(l: Money, r: f64) -> Money {
	return Money{l.v / r}
}

div :: proc(l: Money, r: Money) -> Money {
	return new(l.v / r.v) // bring one of the scalers up.
}

@(test, private)
sub_test :: proc(t: ^testing.T) {
	m1 := new(51.25)
	m2 := new(1.25)
	testing.expect(t, sub(m1, m2) == new(50.0))
	testing.expect(t, sub(m1, m2) == sub(m1, m2))
	testing.expect(t, sub(m2, m1) == sub(m2, m1))

	testing.expect(t, _sub(m1, 1.25) == new(50.0))
	testing.expect(t, _sub(m1, 42.) == _sub(m1, 42.0))
	testing.expect(t, _sub(m2, 99.9) == _sub(m2, 99.9))

	testing.expect(t, sub(m1, m2) == _sub(m1, 1.25))
}

@(test, private)
add_test :: proc(t: ^testing.T) {
	m1 := new(51.25)
	m2 := new(1.25)
	testing.expect(t, add(m1, m2) == new(52.5))
	testing.expect(t, add(m1, m2) == add(m1, m2))
	testing.expect(t, add(m2, m1) == add(m2, m1))

	testing.expect(t, _add(m1, 1.25) == new(52.5))
	testing.expect(t, _add(m1, 42.) == _add(m1, 42.0))
	testing.expect(t, _add(m2, 99.9) == _add(m2, 99.9))

	testing.expect(t, add(m1, m2) == _add(m1, 1.25))
}

@(test, private)
mul_test :: proc(t: ^testing.T) {
	m1 := new(7.77)
	m2 := new(10.21)
	testing.expect(t, mul(m1, m2) == new(79.3317))
	testing.expect(t, mul(new(0.0001), new(9999.9999)) == new(0.99999999))
	testing.expect(t, mul(m1, m2) == mul(m1, m2))
	testing.expect(t, mul(m2, m1) == mul(m2, m1))


	testing.expect(t, _mul(m1, 10.0) == new(77.7))
	testing.expect(t, _mul(m1, 42.) == _mul(m1, 42.0))
	testing.expect(t, _mul(m2, 99.9) == _mul(m2, 99.9))

	testing.expect(t, mul(m1, m2) == _mul(m1, 10.21))
}

@(test, private)
div_test :: proc(t: ^testing.T) {
	m1 := new(41091.21)
	m2 := new(2.0)
	testing.logf(t, "%.40", div(m1, m2))
	testing.expect(t, div(m1, m2) == new(20545.605))
	testing.expect(t, div(m1, m2) == div(m1, m2))
	testing.expect(t, div(m2, m1) == div(m2, m1))


	testing.expect(t, _div(m1, 10.0) == new(4109.121))
	testing.expect(t, _div(m1, 42.) == _div(m1, 42.))
	testing.expect(t, _div(m2, 99.9) == _div(m2, 99.9))

	testing.expect(t, div(m1, m2) == _div(m1, 2.0))
}


@(test, private)
money_size :: proc(t: ^testing.T) {
	testing.expect(t, size_of(f64) == size_of(Money))
}

@(test, private)
conversion_f64 :: proc(t: ^testing.T) {
	my_rand: rand.Rand
	rand.init(&my_rand, 0)
	for i in 0 ..= 10_000 {
		some_random_number := f64(rand.int63_max(9_999_999, &my_rand))
		money := new(some_random_number)
		testing.expect(t, some_random_number == to_f64(money))
	}
}

@(test, private)
conversion_money :: proc(t: ^testing.T) {
	my_rand: rand.Rand
	rand.init(&my_rand, 0)
	for i in 0 ..= 10_000 {
		some_random_number := f64(rand.int63_max(9_999_999, &my_rand))
		money := new(some_random_number)
		testing.expect(t, to_f64(new(to_f64(money))) == some_random_number)
	}
}

@(test, private)
min_max :: proc(t: ^testing.T) {
	min := new(0.000001)
	max := new(9_999_999_999.999_999)
	testing.expect(t, to_f64(min) == 0.000001)
	testing.expect(t, to_f64(max) == 9_999_999_999.999_999)
}
