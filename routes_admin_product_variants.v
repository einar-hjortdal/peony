module peony

import arrays
import net.http
import veb
import json

// lists product variants
@['/admin/variants'; get]
pub fn (mut app App) admin_variants_get(mut ctx Context) veb.Result {
	p := extract_retrieve_variant_params(ctx.query)

	ids_bin := zero_array_id_string_to_array_id_bin(p.ids) or {
		return handle_error(mut ctx, http.Status.bad_request, error_id_invalid, err.msg())
	}

	region_id_bin := zero_id_string_to_id_bin(p.region_id) or {
		return handle_error(mut ctx, http.Status.bad_request, error_id_invalid, err.msg())
	}

	ph := RetrieveProductVariantParamsHygienised{
		ids:                p.ids
		ids_bin:            ids_bin
		allow_backorder:    p.allow_backorder
		manage_inventory:   p.manage_inventory
		region_id:          p.region_id
		region_id_bin:      region_id_bin
		currency_code:      p.currency_code
		title:              p.title
		inventory_quantity: p.inventory_quantity
		with_deleted:       p.with_deleted
		offset:             p.offset
		fetch:              p.fetch
		order:              p.order
	}

	return conduit_product_variants_get(mut app, mut ctx, ph)
}

// gets a product variant
@['/admin/variants/:id'; get]
pub fn (mut app App) admin_variants_id_get(mut ctx Context, id string) veb.Result {
	id_bin := id_string_to_bin(id) or {
		return handle_error(mut ctx, http.Status.bad_request, error_id_invalid, err.msg())
	}

	m := {
		'ids': id
	}
	p := extract_retrieve_variant_params(m)
	ph := RetrieveProductVariantParamsHygienised{
		ids:     p.ids
		ids_bin: [id_bin]
	}

	return conduit_product_variant_get(mut app, mut ctx, ph)
}

// updates a product variant
@['/admin/variants/:id'; post]
pub fn (mut app App) admin_variants_id_post(mut ctx Context, id string) veb.Result {
	variant_id_bin := id_string_to_bin(id) or {
		return handle_error(mut ctx, http.Status.bad_request, error_id_invalid, err.msg())
	}

	p := json.decode(ProductVariantRequest, ctx.req.data) or {
		return handle_error(mut ctx, http.Status.bad_request, 'Could not decode VariantRequest',
			err.msg())
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

// deletes a product variant
@['/admin/variants/:id'; delete]
pub fn (mut app App) admin_variants_id_delete(mut ctx Context, id string) veb.Result {
	variant_id_bin := id_string_to_bin(id) or {
		return handle_error(mut ctx, http.Status.bad_request, error_id_invalid, err.msg())
	}
	return conduit_product_variant_delete(mut app, mut ctx, variant_id_bin)
}
