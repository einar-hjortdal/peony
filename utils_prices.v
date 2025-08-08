module peony

import arrays

struct PriceContext {
	cart_id_bin             []u8
	customer_id_bin         []u8
	region_id_bin           []u8
	currency_code           string
	include_discount_prices bool
}

struct Prices {
	currency_code                     string
	original_price                    i32
	original_price_does_include_tax   bool
	original_price_excluding_tax      i32
	original_price_including_tax      i32
	calculated_price                  i32
	calculated_price_does_include_tax bool
	calculated_price_excluding_tax    i32
	calculated_price_including_tax    i32
	tax_rates                         []TaxRate
}

// use app.tax_provider when necessary
fn calculate_taxes() {
}

fn is_original_price(ma MoneyAmount, currency_code string, region_id_bin []u8) bool {
	return ma.min_quantity.is_null && ma.max_quantity.is_null
		&& (region_id_bin.len == 0 || ma.region_id_bin.value == region_id_bin)
}

fn select_original_price(original_prices []MoneyAmount) MoneyAmount {
	mut with_region := false
	for i := 0; i < original_prices.len; i++ {
		if !original_prices[i].region_id_bin.is_null {
			with_region = true
			break
		}
	}

	mut lowest := original_prices[0]
	if with_region {
		for i := 0; i < original_prices.len; i++ {
			if !original_prices[i].region_id_bin.is_null
				&& original_prices[i].amount < lowest.amount {
				lowest = original_prices[i]
			}
		}
		return lowest
	}

	for i := 0; i < original_prices.len; i++ {
		if original_prices[i].amount < lowest.amount {
			lowest = original_prices[i]
		}
	}
	return lowest
}

fn is_valid_price(ma MoneyAmount, quantity i32, currency_code string, region_id_bin []u8) bool {
	return (ma.min_quantity.is_null || ma.max_quantity.value < quantity)
		&& (ma.max_quantity.is_null || ma.max_quantity.value > quantity)
		&& (currency_code == '' || ma.currency_code == currency_code)
		&& (region_id_bin.len == 0 || ma.region_id_bin.value == region_id_bin)
}

// this function should find the lowest possible price that fits all the criteria.
// it considers: quantity, currency, region, discount, rules, lists.
// this function also finds and applies taxes.
// a tax of type override will override all taxes of lower hierarchy.
// the tax hierarchy, from most important to least important, is as follows:
// product -> product type -> region (TODO verify)
fn calculate_price(variant Variant, quantity i32, pctx PriceContext) Prices {
	// for now just consider variant.money_amounts and pctx.region
	mut original_prices := []MoneyAmount{}
	mut valid_money_amounts := []MoneyAmount{}
	for i := 0; i < variant.money_amounts.len; i++ {
		if is_original_price(variant.money_amounts[i], pctx.currency_code, pctx.region_id_bin) {
			original_prices = arrays.concat(original_prices, variant.money_amounts[i])
		}

		if is_valid_price(variant.money_amounts[i], quantity, pctx.currency_code, pctx.region_id_bin) {
			valid_money_amounts = arrays.concat(valid_money_amounts, variant.money_amounts[i])
		}
	}

	if original_prices.len == 0 {
		return Prices{
			currency_code: pctx.currency_code
		}
	}

	original_price := select_original_price(original_prices)

	return Prices{
		currency_code:  pctx.currency_code
		original_price: original_price.amount
		// original_price_does_include_tax:
		// original_price_excluding_tax:
		// original_price_including_tax:
		// calculated_price:
		// calculated_price_does_include_tax:
		// calculated_price_excluding_tax:
		// calculated_price_including_tax:
	}
}
