module main

fn is_empty(v []u8) bool {
	return v.len == 0
}

// hierarchy:
// price-list
// region
// money_amount with set min_quantity/max_quantity
// money_amount without set min_quantity/max_quantity
// discount prices if include_discount_prices

struct PriceContext {
	cart_id_bin             []u8
	customer_id_bin         []u8
	region_id_bin           []u8
	currency_code           string
	include_discount_prices bool
	ignore_cache            bool
}

struct Price {
	currency_code                     string
	original_price                    i32
	original_price_does_include_tax   bool
	original_price_excluding_tax      i32
	original_price_including_tax      i32
	calculated_price                  i32
	calculated_price_does_include_tax bool
	calculated_price_excluding_tax    i32
	calculated_price_including_tax    i32
}

fn calculate_taxes() {
}

fn is_valid_price() bool {
	return true
}

fn calculate_price(variant_ids_bin [][]u8, quantity i32, pctx PriceContext) Price {
	// if cart_id_bin is provided: verify cart.shipping_address_id cart.region_id cart.customer_id cart_discounts
	// if customer_id_bin is provided: verify price_list_customer_groups, discount_condition_customer_group
	// if region_id_bin is provided: verify region.includes_tax, region_tax_rate
	// verify currency.includes_tax

	// original price:
	// region_id matches
	// price_list_id == null
	// no min_quantity or max_quantity ⇒ set originalPrice.
	// If none found, fall back to a currency-specific base price with the same null checks.

	mut currency_code := pctx.currency_code
	mut tax_rate := f32(0)
	mut automatic_taxes := false
	if is_empty(pctx.region_id_bin) {
		// get region
		// currency_code = region.currency_code
		// tax_rate = ...
		// automatic_taxes = region.automatic_taxes
	}

	return Price{
		currency_code: currency_code
	}
}
