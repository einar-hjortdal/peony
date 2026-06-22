module peony

import arrays
import internal.conduit

// VariantPrice is for the store frontend
// `original_price` is the price of the item before an adjustment or a sale.
// `base_price` is the price of the item.
//
// The original_price is the money_amount amount for the given region that is marked with is_original.
// If the customer has a price_list, the base_price is the price from its price_list, if it exists.
// Otherwise is is the money_amount amount for the given region that is not marked with is_original.
// It is called base_price because discounts may apply in the cart.
struct VariantPrice {
	currency_code  string
	includes_tax   bool
	original_price i32
	base_price     i32
}

// customer_id is used for price_list prices, it is obtained from customer session.
// cart_id and region_id are obtained from url parameters.
struct PriceContext {
	cart_id     ?ID
	region_id   ?ID
	customer_id ?ID
}

// TODO verify cart_id exists in db
// TODO verify region_id exists in cache, or db if not cached
fn (ctx Context) get_price_context() !PriceContext {
	q := hygienise_price_context_query_params(ctx.query) or {
		return new_error_unprocessable_entity(error_id_invalid, err.msg())
	}

	return PriceContext{
		cart_id:   q.cart_id
		region_id: q.region_id
		// customer_id: ctx.customer_session_values.id
	}
}

// use app.tax_provider
fn calculate_taxes() {}

// TODO should also consider money_amount related to price-list.
fn is_fitting_price(ma VariantMoneyAmount, region_id ID, quantity i32) bool {
	return !ma.is_original && ma.region_id_bin == region_id.bytes()
	// && (ma.min_quantity.is_null || ma.max_quantity.value < quantity)
	// && (ma.max_quantity.is_null || ma.max_quantity.value > quantity)
}

// returns empty MoneyAmount if no original_price exists
fn get_original_price(mas []VariantMoneyAmount, region_id ID) VariantMoneyAmount {
	for i := 0; i < mas.len; i++ {
		ma := mas[i]
		if ma.is_original && ma.region_id_bin == region_id.bytes() {
			return ma
		}
	}
	return VariantMoneyAmount{}
}

// returns empty MoneyAmount if no price exists for the region
// TODO It cannot return empty though, peony must guarantee prices exist for each region
fn get_regional_prices(mas []VariantMoneyAmount, region_id ID, quantity i32) []VariantMoneyAmount {
	mut fitting_prices := []VariantMoneyAmount{}
	for i := 0; i < mas.len; i++ {
		ma := mas[i]
		if is_fitting_price(ma, region_id, quantity) {
			arrays.concat(fitting_prices, ma)
		}
	}
	return fitting_prices
}

fn get_lowest_price(mas []VariantMoneyAmount) VariantMoneyAmount {
	mut lowest := VariantMoneyAmount{}
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
// TODO Consider price_list when in context.
fn calculate_price(variant conduit.Variant, default_region_id ID, price_context PriceContext, quantity i32) VariantPrice {
	// for now just consider variant.money_amounts and pctx.region
	region_id := price_context.region_id or { default_region_id }
	original_price := get_original_price(variant.money_amounts, region_id)
	regional_prices := get_regional_prices(variant.money_amounts, region_id, quantity)
	base_price := get_lowest_price(regional_prices)

	return VariantPrice{
		currency_code:  base_price.currency_code
		includes_tax:   base_price.includes_tax
		original_price: original_price.amount
		base_price:     base_price.amount
	}
}

// TODO taxes and discounts for cart
// a tax of type override will override all taxes of lower hierarchy.
// the tax hierarchy, from most important to least important, is as follows:
// product -> product type -> region (TODO verify)
