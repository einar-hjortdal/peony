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
@['/admin/products/:product_id/variants/'; post]
pub fn (mut app App) admin_products_id_variants_post(mut ctx Context, product_id string) veb.Result {
	p := json.decode(ProductVariantRequest, ctx.req.data) or {
		return handle_error(mut ctx, http.Status.bad_request, 'Could not decode VariantRequest ',
			err.msg())
	}

	product_id_bin := id_string_to_bin(product_id) or {
		return handle_error(mut ctx, http.Status.bad_request, error_id_invalid, err.msg())
	}

	// Must perform a database operation to verify if all options have been provided with a value
	mut tx := app.start_transaction() or {
		return handle_error(mut ctx, http.Status.internal_server_error, error_transaction_start,
			err.msg())
	}

	existing_options := model_product_options_retrieve_by_product_ids(mut tx, [
		product_id_bin,
	]) or {
		tx.rollback() or {}
		return handle_error(mut ctx, http.Status.internal_server_error, 'Could not retrieve product options',
			err.msg())
	}

	store := do_retrieve_store(mut tx) or {
		tx.rollback() or {}
		return handle_error(mut ctx, http.Status.internal_server_error, 'Could not retrieve product options',
			err.msg())
	}

	tx.rollback() or {
		return handle_error(mut ctx, http.Status.internal_server_error, error_transaction_rollback,
			err.msg())
	}

	if option_values := p.option_values {
		if option_values.len != existing_options.len {
			return handle_error(mut ctx, http.Status.unprocessable_entity, 'Missing product_option_value',
				'All existing product_option must be given a value')
		}

		// verify that each option.id exists in existing_options[i].id
		for i := 0; i < option_values.len; i++ {
			mut found := false
			for j := 0; j < existing_options.len; j++ {
				if option_values[i].option_id == existing_options[j].id {
					found = true
					break
				}
			}
			if !found {
				return handle_error(mut ctx, http.Status.unprocessable_entity, error_id_invalid,
					'option_id does not exist')
			}
		}

		// verify that each option.translation[index].locale_id exists in store.locales
		for i := 0; i < option_values.len; i++ {
			translations := option_values[i].translations
			for k := 0; k < translations.len; k++ {
				locale_id := translations[k].locale_id
				mut found := false
				for j := 0; j < store.locales.len; j++ {
					if locale_id == store.locales[j].id {
						found = true
						break
					}
				}
				if !found {
					return handle_error(mut ctx, http.Status.unprocessable_entity, error_id_invalid,
						'locale_id does not exist')
				}
			}
		}

		mut povh := []ProductOptionValueRequestHygienised{len: option_values.len}
		for i := 0; i < option_values.len; i++ {
			povh[i] = hygienise_product_option_value_request(option_values[i]) or {
				return handle_error(mut ctx, http.Status.bad_request, error_id_invalid,
					'While hygienising options')
			}
		}

		return conduit_product_variant_create(mut app, mut ctx, product_id_bin, p, povh)
	}

	if existing_options.len != 0 {
		return handle_error(mut ctx, http.Status.unprocessable_entity, 'No product_option_value provided',
			'All existing product_option must be given a value')
	}

	povh := []ProductOptionValueRequestHygienised{}
	return conduit_product_variant_create(mut app, mut ctx, product_id_bin, p, povh)
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
	if option_values := p.option_values {
		poh = []ProductOptionValueRequestHygienised{len: option_values.len}
		for i := 0; i < option_values.len; i++ {
			poh[i] = hygienise_product_option_value_request(option_values[i]) or {
				return handle_error(mut ctx, http.Status.bad_request, error_id_invalid,
					'at hygienise_product_option_value_request')
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
		return handle_error(mut ctx, http.Status.bad_request, 'Could not decode ProductOptionRequest',
			err.msg())
	}

	if p.translations.len == 0 {
		return handle_error(mut ctx, http.Status.bad_request, 'product_option must have a title',
			'No translations provided')
	}

	mut ph := []ProductOptionTranslationDataHygienised{len: p.translations.len}
	for i := 0; i < p.translations.len; i++ {
		translation := p.translations[i]
		if translation.title == '' {
			return handle_error(mut ctx, http.Status.bad_request, 'Invalid title', 'empty strings are not valid product_option titles')
		}

		locale_id_bin := id_string_to_bin(translation.locale_id) or {
			return handle_error(mut ctx, http.Status.bad_request, error_id_invalid, 'locale_id')
		}

		ph[i] = ProductOptionTranslationDataHygienised{
			title:         translation.title
			locale_id:     translation.locale_id
			locale_id_bin: locale_id_bin
		}
	}

	return conduit_product_option_create(mut app, mut ctx, id, id_bin, ph)
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

	if p.translations.len == 0 {
		return handle_error(mut ctx, http.Status.bad_request, 'product_option must have a title',
			'No translations provided')
	}

	mut ph := []ProductOptionTranslationDataHygienised{len: p.translations.len}
	for i := 0; i < p.translations.len; i++ {
		translation := p.translations[i]
		if translation.title == '' {
			return handle_error(mut ctx, http.Status.bad_request, 'Invalid title', 'empty strings are not valid product_option titles')
		}

		locale_id_bin := id_string_to_bin(translation.locale_id) or {
			return handle_error(mut ctx, http.Status.bad_request, error_id_invalid, 'locale_id')
		}

		ph[i] = ProductOptionTranslationDataHygienised{
			title:         translation.title
			locale_id:     translation.locale_id
			locale_id_bin: locale_id_bin
		}
	}

	return conduit_product_option_update(mut app, mut ctx, product_id, product_id_bin,
		product_option_id, product_option_id_bin, ph)
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
