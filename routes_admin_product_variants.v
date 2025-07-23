module peony

import arrays
import net.http
import veb
import json

// lists product variants
@['/admin/variants'; get]
fn (mut app App) admin_variants_get(mut ctx Context) veb.Result {
	p := extract_retrieve_variant_params(ctx.query)
	variants := app.retrieve_product_variants(p) or {
		ctx.res.set_status(http.Status.internal_server_error)
		return ctx.json(new_peony_error('Could not retrieve variants ', err.msg()))
	}

	return ctx.json(variants)
}

// gets a product variant
@['/admin/variants/:id'; get]
fn (mut app App) admin_variants_id_get(mut ctx Context, id string) veb.Result {
	variant := app.retrieve_product_variant_by_id(id) or {
		ctx.res.set_status(http.Status.internal_server_error)
		return ctx.json(new_peony_error('Could not retrieve variant ', err.msg()))
	}
	return ctx.json(variant)
}

// updates a product variant
@['/admin/variants/:id'; post]
fn (mut app App) admin_variants_id_post(mut ctx Context, id string) veb.Result {
	variant_id_bin := id_string_to_bin(id) or {
		return handle_error(mut ctx, http.Status.bad_request, error_invalid_id, err.msg())
	}

	p := json.decode(ProductVariantRequest, ctx.req.data) or {
		ctx.res.set_status(http.Status.bad_request)
		return ctx.json(new_peony_error('Could not decode VariantRequest', err.msg()))
	}

	// TODO validate all ids in ProductVariantRequest

	mut mahs := []MoneyAmountRequestHygienised{}
	if money_amounts := p.money_amounts {
		for i := 0; i < money_amounts.len; i++ {
			if money_amounts[i].currency_code == none && money_amounts[i].region_id == none {
				return handle_error(mut ctx, http.Status.bad_request, 'invalid moneyAmount',
					'currencyCode or regionId is required')
			}

			mut money_amount_id_bin := []u8{}
			if money_amount_id := money_amounts[i].id {
				money_amount_id_bin = id_string_to_bin(money_amount_id) or {
					return handle_error(mut ctx, http.Status.bad_request, 'Invalid id',
						err.msg())
				}
			}

			mut region_id_bin := []u8{}
			if region_id := money_amounts[i].region_id {
				region_id_bin = id_string_to_bin(region_id) or {
					return handle_error(mut ctx, http.Status.bad_request, 'Invalid regionId',
						err.msg())
				}
			}

			mah := MoneyAmountRequestHygienised{
				amount:        money_amounts[i].amount
				currency_code: money_amounts[i].currency_code
				id:            money_amounts[i].id
				id_bin:        money_amount_id_bin
				max_quantity:  money_amounts[i].max_quantity
				min_quantity:  money_amounts[i].min_quantity
				region_id:     money_amounts[i].region_id
				region_id_bin: region_id_bin
			}
			mahs = arrays.concat(mahs, mah)
		}
	}

	return conduit_product_variant_update(mut app, mut ctx, variant_id_bin, p, mahs)
}

// gets the available inventory of the product variant
@['/admin/variants/:id/inventory'; get]
fn (mut app App) admin_variants_inventory_get(mut ctx Context, id string) veb.Result {
	return ctx.text('TODO')
}
