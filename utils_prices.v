module peony

import arrays

// `original_price` is the price of the item before an adjustment or a sale.
// `base_price` is the price of the item.
//
// The original_price is the money_amount amount for the given region that is marked with is_original.
// If the customer has a price_list, the base_price is the price from its price_list, if it exists.
// Otherwise is is the money_amount amount for the given region that is not marked with is_original.
// It is called base_price because discounts may apply to these prices in the cart.
struct ProductVariantPrice {
	currency_code  string
	includes_tax   bool
	original_price i32
	base_price     i32
}

// TODO build PriceContext in route (verify ids are valid and exist in db, get default region_id if needed)
// customer_id is used for price_list prices, it is obtained from customer session.
// cart_id is obtained from url parameters.
// region_id is obtained from url paramters, or from the database if none is provided by the request.
// Change context to contain the Cart, Customer and Region structs instead of their id alone
struct PriceContext {
	cart_id_bin     []u8
	customer_id_bin []u8
	region_id_bin   []u8
}

// use app.tax_provider when necessary
fn calculate_taxes() {}

fn is_fitting_price(ma MoneyAmount, region_id_bin []u8, quantity i32) bool {
	return !ma.is_original && ma.region_id_bin == region_id_bin
		&& (ma.min_quantity.is_null || ma.max_quantity.value < quantity)
		&& (ma.max_quantity.is_null || ma.max_quantity.value > quantity)
}

fn get_original_price(mas []MoneyAmount, region_id_bin []u8) MoneyAmount {
	for i := 0; i < mas.len; i++ {
		ma := mas[i]
		if ma.is_original && ma.region_id_bin == region_id_bin {
			return ma
		}
	}
	return MoneyAmount{}
}

fn get_fitting_prices(mas []MoneyAmount, region_id_bin []u8, quantity i32) []MoneyAmount {
	mut fitting_prices := []MoneyAmount{}
	for i := 0; i < mas.len; i++ {
		ma := mas[i]
		if is_fitting_price(ma, region_id_bin, quantity) {
			arrays.concat(fitting_prices, ma)
		}
	}
	return fitting_prices
}

fn get_lowest_price(mas []MoneyAmount) MoneyAmount {
	mut lowest := MoneyAmount{}
	for i := 0; i < mas.len; i++ {
		ma := mas[i]
		if lowest.id_bin.len == 0 {
			lowest = ma
			continue
		}

		if ma.amount < lowest.amount {
			lowest = ma
		}
	}
	return lowest
}

// this function should find the lowest possible price that fits all the criteria.
// it considers: quantity, region.
// TODO consider price_list.
fn calculate_price(variant ProductVariant, quantity i32, pctx PriceContext) ProductVariantPrice {
	// for now just consider variant.money_amounts and pctx.region
	original_price := get_original_price(variant.money_amounts, pctx.region_id_bin)
	fitting_prices := get_fitting_prices(variant.money_amounts, pctx.region_id_bin, quantity)
	base_price := get_lowest_price(fitting_prices)

	// all prices match the given region, therefore they have the same currency_code and includes_tax
	return ProductVariantPrice{
		currency_code:  original_price.currency_code
		includes_tax:   original_price.includes_tax
		original_price: original_price.amount
		base_price:     base_price.amount
	}
}

// TODO taxes and discounts for cart
// a tax of type override will override all taxes of lower hierarchy.
// the tax hierarchy, from most important to least important, is as follows:
// product -> product type -> region (TODO verify)
