module peony

import net.http
import json
import veb

// lists products
@['/admin/products'; get]
pub fn (mut app App) admin_products_get(mut ctx Context) veb.Result {
	p := extract_retrieve_admin_products_params(ctx.query)

	ids_bin := zero_array_id_string_to_array_id_bin(p.ids) or {
		return handle_error(mut ctx, http.Status.bad_request, error_id_invalid, err.msg())
	}

	region_id_bin := zero_id_string_to_id_bin(p.region_id) or {
		return handle_error(mut ctx, http.Status.bad_request, 'Invalid region_id', err.msg())
	}

	ph := RetrieveProductParamsHygienised{
		ids:            p.ids
		ids_bin:        ids_bin
		handle:         p.handle
		is_giftcard:    p.is_giftcard
		status:         p.status
		collection_ids: p.collection_ids
		// collection_ids_bin:    p.collection_id_bin
		type_ids: p.type_ids
		// type_ids_bin:          p.type_id_bin
		tag_ids: p.tag_ids
		// tag_ids_bin:           p.tag_id_bin
		title:        p.title
		description:  p.description
		category_ids: p.category_ids
		// category_ids_bin:      p.category_id_bin
		price_list_ids: p.price_list_ids
		// price_list_ids_bin:    p.price_list_id_bin
		sales_channel_ids: p.sales_channel_ids
		// sales_channel_ids_bin: p.sales_channel_id_bin
		region_id:     p.region_id
		region_id_bin: region_id_bin
		currency_code: p.currency_code
		with_deleted:  p.with_deleted
		offset:        p.offset
		fetch:         p.fetch
		order:         p.order
		cart_id:       p.cart_id
		// cart_id_bin:           p.cart_id_bin
	}

	return conduit_products_get(mut app, mut ctx, ph)
}

// create a product
@['/admin/products'; post]
pub fn (mut app App) admin_products_post(mut ctx Context) veb.Result {
	body := json.decode(ProductData, ctx.req.data) or {
		ctx.res.set_status(http.Status.bad_request)
		return ctx.json(new_peony_error('Could not decode ProductData', err.msg()))
	}

	id := app.create_product(body) or {
		ctx.res.set_status(http.Status.internal_server_error)
		return ctx.json(new_peony_error('Failed to create product', err.msg()))
	}

	return app.admin_products_id_get(mut ctx, id)
}

// retrieves a list of tags and the amount of times each tag is being used by products
@['/admin/products/tag-usage'; get]
pub fn (app &App) admin_products_tag_usage_get(mut ctx Context) veb.Result {
	return ctx.text('TODO')
}

// get a product
@['/admin/products/:id'; get]
pub fn (mut app App) admin_products_id_get(mut ctx Context, id string) veb.Result {
	id_bin := id_string_to_bin(id) or {
		return handle_error(mut ctx, http.Status.bad_request, error_id_invalid, err.msg())
	}

	id_zas := ZeroArrayString{
		v:      [id]
		is_set: true
	}

	ph := RetrieveProductParamsHygienised{
		ids:     id_zas
		ids_bin: [id_bin]
	}

	return conduit_products_get_by_id(mut app, mut ctx, ph)
}

@['/admin/products/:id'; post]
pub fn (mut app App) admin_products_id_post(mut ctx Context, id string) veb.Result {
	id_bin := id_string_to_bin(id) or {
		return handle_error(mut ctx, http.Status.bad_request, error_id_invalid, err.msg())
	}

	p := json.decode(ProductData, ctx.req.data) or {
		ctx.res.set_status(http.Status.bad_request)
		return ctx.json(new_peony_error('Could not decode ProductData', err.msg()))
	}

	// TODO validate ProductData ids if any
	return conduit_products_update(mut app, mut ctx, id_bin, p)
}

// deletes a product
@['/admin/products/:id'; delete]
pub fn (mut app App) admin_products_id_delete(mut ctx Context, id string) veb.Result {
	app.delete_product(id) or {
		ctx.res.set_status(http.Status.internal_server_error)
		return ctx.json(new_peony_error('Failed to delete product', err.msg()))
	}
	return ctx.json(new_peony_success())
}

// creates a product variant
@['/admin/products/:id/variants'; post]
pub fn (mut app App) admin_products_id_variants_post(mut ctx Context, id string) veb.Result {
	data := json.decode(ProductVariantRequest, ctx.req.data) or {
		ctx.res.set_status(http.Status.bad_request)
		return ctx.json(new_peony_error('Could not decode VariantRequest ', err.msg()))
	}

	// TODO require p.options if options exist for this product
	id_bin := id_string_to_bin(id) or {
		return handle_error(mut ctx, http.Status.bad_request, error_id_invalid, err.msg())
	}

	app.create_product_variant(id_bin, data) or {
		return handle_error(mut ctx, http.Status.bad_request, 'Could not create product_variant',
			err.msg())
	}

	return ctx.json(new_peony_success())
}

// updates a product variant
@['/admin/products/:product_id/variants/:variant_id'; post]
pub fn (mut app App) admin_variants_id_post(mut ctx Context, product_id string, variant_id string) veb.Result {
	product_id_bin := id_string_to_bin(product_id) or {
		return handle_error(mut ctx, http.Status.bad_request, error_id_invalid, 'product_id')
	}

	variant_id_bin := id_string_to_bin(variant_id) or {
		return handle_error(mut ctx, http.Status.bad_request, error_id_invalid, 'variant_id')
	}

	p := json.decode(ProductVariantRequest, ctx.req.data) or {
		return handle_error(mut ctx, http.Status.bad_request, 'Could not decode VariantRequest',
			err.msg())
	}

	mut poh := []ProductOptionValueRequestHygienised{}
	if options := p.options {
		poh = []ProductOptionValueRequestHygienised{len: options.len}
		for i := 0; i < options.len; i++ {
			option_id_bin := id_string_to_bin(options[i].option_id) or {
				return handle_error(mut ctx, http.Status.bad_request, error_id_invalid,
					'option_id')
			}

			mut translations := []ProductOptionValueTranslationRequestHygienised{len: options[i].translations.len}
			for j := 0; j < options[i].translations.len; j++ {
				locale_id_bin := id_string_to_bin(options[i].translations[j].locale_id) or {
					return handle_error(mut ctx, http.Status.bad_request, error_id_invalid,
						'locale_id')
				}
				translations[j] = ProductOptionValueTranslationRequestHygienised{
					locale_id:     options[i].translations[j].locale_id
					locale_id_bin: locale_id_bin
					name:          options[i].translations[j].name
				}
			}

			poh[i] = ProductOptionValueRequestHygienised{
				option_id:     options[i].option_id
				option_id_bin: option_id_bin
				translations:  translations
			}
		}
	}

	// TODO validate all ids in ProductVariantRequest
	mut mah := []MoneyAmountRequestHygienised{}
	if money_amounts := p.money_amounts {
		mah = []MoneyAmountRequestHygienised{len: money_amounts.len}
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

			mah[i] = MoneyAmountRequestHygienised{
				amount:        money_amounts[i].amount
				currency_code: money_amounts[i].currency_code
				id:            money_amounts[i].id
				id_bin:        money_amount_id_bin
				max_quantity:  money_amounts[i].max_quantity
				min_quantity:  money_amounts[i].min_quantity
				region_id:     money_amounts[i].region_id
				region_id_bin: region_id_bin
			}
		}
	}

	return conduit_product_variant_update(mut app, mut ctx, product_id_bin, variant_id_bin,
		p, poh, mah)
}

// creates a product option
@['/admin/products/:id/options'; post]
pub fn (mut app App) admin_products_id_options_post(mut ctx Context, id string) veb.Result {
	id_bin := id_string_to_bin(id) or {
		return handle_error(mut ctx, http.Status.bad_request, error_id_invalid, err.msg())
	}

	p := json.decode(ProductOptionRequest, ctx.req.data) or {
		ctx.res.set_status(http.Status.bad_request)
		return ctx.json(new_peony_error('Could not decode ProductOptionRequest', err.msg()))
	}

	return conduit_product_option_create(mut app, mut ctx, id, id_bin, p)
}

// updates a product option
@['/admin/products/:product_id/options/:option_id'; post]
pub fn (mut app App) admin_update_product_option(mut ctx Context, product_id string, product_option_id string) veb.Result {
	product_id_bin := id_string_to_bin(product_id) or {
		return handle_error(mut ctx, http.Status.bad_request, error_id_invalid, err.msg())
	}

	product_option_id_bin := id_string_to_bin(product_option_id) or {
		return handle_error(mut ctx, http.Status.bad_request, error_id_invalid, err.msg())
	}

	p := json.decode(ProductOptionRequest, ctx.req.data) or {
		ctx.res.set_status(http.Status.bad_request)
		return ctx.json(new_peony_error('Could not decode ProductOptionRequest', err.msg()))
	}

	return conduit_product_option_update(mut app, mut ctx, product_id, product_id_bin,
		product_option_id, product_option_id_bin, p)
}

// deletes a product option
@['/admin/products/:product_id/options/:option_id'; delete]
pub fn (mut app App) admin_product_option_delete(mut ctx Context, product_id string, product_option_id string) veb.Result {
	product_id_bin := id_string_to_bin(product_id) or {
		return handle_error(mut ctx, http.Status.bad_request, error_id_invalid, err.msg())
	}

	product_option_id_bin := id_string_to_bin(product_option_id) or {
		return handle_error(mut ctx, http.Status.bad_request, error_id_invalid, err.msg())
	}

	return conduit_product_option_delete(mut app, mut ctx, product_id, product_id_bin,
		product_option_id, product_option_id_bin)
}
