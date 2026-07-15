module peony

import arrays
import einar_hjortdal.firebird
import internal.cache
import internal.common
import internal.conduit
import internal.errors
import log

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
	region_id   common.ID
	cart_id     ?common.ID
	customer_id ?common.ID
}

fn (mut app App) get_price_context_region(id ?common.ID) !common.ID {
	region_id := id or {
		log.debug('region_id not provided, using default')
		return app.get_default_region_id()!
	}

	if _ := cache.region_get(mut app.redict, region_id) {
		log.debug('region_id is valid, region loaded from cache')
		return region_id
	}

	log.debug('region not in cache, getting it from db')
	region := app.with_rollback(fn [region_id] (mut tx firebird.ClientTransaction) !conduit.Region {
		return conduit.region_get(mut tx, region_id)
	}) or { return errors.unprocessable_entity(errors.id_invalid, 'region_id does not exist') }

	log.debug('region_id is valid, region loaded from db')
	cache.region_set(mut app.redict, region, app.config.cache_duration) or {
		log.error('could not cache region_id with error: ${err.msg()}')
	}
	return region_id
}

fn (mut app App) get_price_context(m map[string]string) !PriceContext {
	p := hygienise_price_context_query_params(m)!

	region_id := app.get_price_context_region(p.region_id)!

	return PriceContext{
		region_id: region_id
		cart_id:   p.cart_id
	}
}

// TODO use app.tax_provider
fn calculate_taxes() {}

// TODO should also consider money_amount related to price-list.
fn is_fitting_price(ma conduit.VariantMoneyAmount, region_id common.ID, _ i32) bool {
	return !ma.is_original && ma.region_id.string() == region_id.string()
	// && (ma.min_quantity.is_null || ma.max_quantity.value < quantity)
	// && (ma.max_quantity.is_null || ma.max_quantity.value > quantity)
}

// returns empty MoneyAmount if no original_price exists
fn get_original_price(mas []conduit.VariantMoneyAmount, region_id common.ID) conduit.VariantMoneyAmount {
	for i := 0; i < mas.len; i++ {
		ma := mas[i]
		if ma.is_original && ma.region_id.string() == region_id.string() {
			return ma
		}
	}
	return conduit.VariantMoneyAmount{}
}

// returns empty MoneyAmount if no price exists for the region
// TODO It cannot return empty though, peony must guarantee prices exist for each region
fn get_regional_prices(mas []conduit.VariantMoneyAmount, region_id common.ID, quantity i32) []conduit.VariantMoneyAmount {
	mut fitting_prices := []conduit.VariantMoneyAmount{}
	for i := 0; i < mas.len; i++ {
		ma := mas[i]
		if is_fitting_price(ma, region_id, quantity) {
			arrays.concat(fitting_prices, ma)
		}
	}
	return fitting_prices
}

fn get_lowest_price(mas []conduit.VariantMoneyAmount) conduit.VariantMoneyAmount {
	mut lowest := conduit.VariantMoneyAmount{}
	for _, ma in mas {
		if lowest.id.is_zero() {
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
// for now just consider variant.money_amounts and pctx.region
fn calculate_price(variant conduit.Variant, pctx PriceContext, quantity i32) VariantPrice {
	original_price := get_original_price(variant.money_amounts, pctx.region_id)
	regional_prices := get_regional_prices(variant.money_amounts, pctx.region_id, quantity)
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
