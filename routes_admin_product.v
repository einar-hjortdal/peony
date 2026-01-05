module peony

import json
import veb

// lists products
@['/admin/products'; get]
pub fn (mut app App) admin_products_get(mut ctx Context) veb.Result {
	ph := hygienise_retrieve_product_params(ctx.query) or {
		if err is InternalError {
			return handle_error_400(mut ctx, err.message, err.details)
		}
		return handle_error_500(mut ctx, 'Unhandled error at hygienise_product_request',
			err.msg())
	}

	if ph.fetch.is_set && ph.fetch.v == 0 {
		return handle_fetch_zero(mut ctx)
	}

	return conduit_products_get(mut app, mut ctx, ph)
}

// create a product
// TODO create variants, inventory_items and inventory_levels
@['/admin/products'; post]
pub fn (mut app App) admin_products_post(mut ctx Context) veb.Result {
	p := json.decode(ProductCreateRequest, ctx.req.data) or {
		return handle_error_400(mut ctx, 'Could not decode ProductRequest', err.msg())
	}

	ph := p.hygienise() or {
		if err is InternalError {
			return handle_error_400(mut ctx, err.message, err.details)
		}
		return handle_error_unhandled(mut ctx, err.msg(), 'ProductCreateRequest.hygienise')
	}

	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	store := model_store_retrieve(mut tx) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Failed to retrieve store', err.msg())
	}

	tx.rollback() or { return handle_error_500(mut ctx, error_transaction_rollback, err.msg()) }

	if translations := ph.translations {
		if translations.len == 0 {
			return handle_error_400(mut ctx, error_missing_default_translation, 'translations array is empty')
		}

		// TODO verify provided locale_id exist in database

		mut found := false
		for i := 0; i < translations.len; i++ {
			translation := translations[i]
			if translation.locale_id_bin == store.default_locale_id_bin {
				found = true
			}
		}
		if found == false {
			return handle_error_400(mut ctx, error_missing_default_translation, 'translations array does not contain default_locale_id translation')
		}
	} else {
		return handle_error_400(mut ctx, error_missing_default_translation, 'translations array is not set')
	}

	// if seo_translations := ph.seo_translations {
	// 	// TODO verify provided locale_id exist in database
	// }

	if options := ph.options {
		for i := 0; i < options.len; i++ {
			option := options[i]
			option.verify(store.default_locale_id_bin) or {
				if err is InternalError {
					return handle_error_400(mut ctx, err.message, err.details)
				}
				return handle_error_unhandled(mut ctx, err.msg(), 'ProductOptionCreateRequestHygienised.verify')
			}
		}
	}

	if thumbnail := ph.thumbnail {
		if thumbnail < 0 {
			return handle_error_400(mut ctx, 'thumbnail invalid', 'negative value')
		}

		if images := ph.images {
			if !(thumbnail < images.len) {
				return handle_error_400(mut ctx, 'thumbnail invalid', 'index out of range')
			}
		} else {
			return handle_error_400(mut ctx, 'thumbnail invalid', 'images array not provided')
		}
	}

	return conduit_product_create(mut app, mut ctx, ph)
}

// retrieves a list of tags and the amount of times each tag is being used by products
@['/admin/products/tag-usage'; get]
pub fn (app &App) admin_products_tag_usage_get(mut ctx Context) veb.Result {
	return ctx.json('TODO')
}

// get a product by id
@['/admin/products/:id'; get]
pub fn (mut app App) admin_products_id_get(mut ctx Context, id string) veb.Result {
	id_bin := id_string_to_bin(id) or {
		return handle_error_400(mut ctx, error_id_invalid, err.msg())
	}

	ph := RetrieveProductParamsHygienised{
		ids:     ZeroArrayString{
			is_set: true
		}
		ids_bin: [id_bin]
	}

	return conduit_products_get_by_id(mut app, mut ctx, ph)
}

// updates a product
@['/admin/products/:product_id'; post]
pub fn (mut app App) admin_products_id_post(mut ctx Context, product_id string) veb.Result {
	product_id_bin := id_string_to_bin(product_id) or {
		return handle_error_400(mut ctx, error_id_invalid, 'product_id')
	}

	p := json.decode(ProductUpdateRequest, ctx.req.data) or {
		return handle_error_400(mut ctx, 'Could not decode ProductUpdateRequest', err.msg())
	}

	ph := p.hygienise() or {
		if err is InternalError {
			return handle_error_400(mut ctx, err.message, err.details)
		}
		return handle_error_400(mut ctx, 'Unhandled error at hygienise_product_request',
			err.msg())
	}

	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	// store := model_store_retrieve(mut tx) or {
	// 	tx.rollback() or {}
	// 	return handle_error_500(mut ctx, 'Failed to retrieve store', err.msg())
	// }

	if translations := ph.translations {
		if translations.len == 0 {
			tx.rollback() or {}
			return handle_error_400(mut ctx, 'A product name is required', 'translations')
		}
		// TODO verify provided locale_id exist in database
	}

	if thumbnail := ph.thumbnail {
		if thumbnail < 0 {
			tx.rollback() or {}
			return handle_error_400(mut ctx, 'thumbnail invalid', 'negative value')
		}

		if images := ph.images {
			if !(thumbnail < images.len) {
				tx.rollback() or {}
				return handle_error_400(mut ctx, 'thumbnail invalid', 'index out of range')
			}
		} else {
			product_images := model_product_image_retrieve(mut tx, [
				product_id_bin,
			]) or {
				tx.rollback() or {}
				return handle_error_500(mut ctx, 'Failed to retrieve product_images',
					err.msg())
			}

			if !(thumbnail < product_images.len) {
				return handle_error_400(mut ctx, 'thumbnail invalid', 'index out of image_rank range')
			}
		}
	}

	tx.rollback() or { return handle_error_500(mut ctx, error_transaction_rollback, err.msg()) }

	// if seo_translations := ph.seo_translations {
	// 	// TODO verify provided locale_id exist in database
	// }

	return conduit_products_update(mut app, mut ctx, product_id_bin, ph)
}

// deletes a product
@['/admin/products/:product_id'; delete]
pub fn (mut app App) admin_products_id_delete(mut ctx Context, product_id string) veb.Result {
	product_id_bin := id_string_to_bin(product_id) or {
		return handle_error_400(mut ctx, error_id_invalid, 'product_id')
	}
	return conduit_product_delete(mut app, mut ctx, product_id_bin)
}

// creates a product variant
@['/admin/products/:product_id/variants/'; post]
pub fn (mut app App) admin_products_id_variants_post(mut ctx Context, product_id string) veb.Result {
	product_id_bin := id_string_to_bin(product_id) or {
		return handle_error_400(mut ctx, error_id_invalid, err.msg())
	}

	p := json.decode(VariantCreateRequest, ctx.req.data) or {
		return handle_error_400(mut ctx, 'Could not decode VariantRequest ', err.msg())
	}

	ph := p.hygienise() or {
		if err is InternalError {
			return handle_error_400(mut ctx, err.message, err.details)
		}
		return handle_error_unhandled(mut ctx, err.msg(), 'hygienise_product_variant_request')
	}

	if ph.money_amounts.len == 0 {
		return handle_error_400(mut ctx, 'money_amount required', 'A product_variant must have at least one price per region')
	}

	if title := ph.title {
		if title == '' {
			return handle_error_400(mut ctx, 'title is required', 'title not provided')
		}
	} else {
		return handle_error_400(mut ctx, 'title is required', 'title not provided')
	}

	if inventory_item := ph.inventory_item {
		if inventory_item.sku == none && inventory_item.origin_country == none
			&& inventory_item.hs_code == none && inventory_item.mid_code == none
			&& inventory_item.material == none && inventory_item.weight == none
			&& inventory_item.length == none && inventory_item.height == none
			&& inventory_item.width == none && inventory_item.manage_inventory == none
			&& inventory_item.requires_shipping == none {
			return handle_error_400(mut ctx, error_empty_object, 'InventoryItemCreateRequest')
		}
	}

	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	regions := model_region_retrieve(mut tx, RegionRetriveParams{}) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Failed to retrieve region', err.msg())
	}

	verify_money_amounts(ph.money_amounts, regions) or {
		tx.rollback() or {}
		if err is InternalError {
			return handle_suite_error(mut ctx, err)
		}
		return handle_error_unhandled(mut ctx, err.msg(), 'ProductVariantCreateRequestHygienised.verify_money_amounts')
	}

	if option_value_ids := ph.option_value_ids {
		mut product_option_data := suite_product_option_data_get(mut tx, [
			product_id_bin,
		]) or {
			tx.rollback() or {}
			if err is InternalError {
				return handle_suite_error(mut ctx, err)
			}
			return handle_error_unhandled(mut ctx, err.msg(), 'suite_product_option_data_get')
		}

		product_option_data.verify_product_option_value_ids(option_value_ids, ph.option_value_ids_bin) or {
			tx.rollback() or {}
			if err is InternalError {
				return handle_error_400(mut ctx, err.message, err.details)
			}
			return handle_error_unhandled(mut ctx, err.msg(), 'verify_product_option_value_ids')
		}
	} else {
		// peony automatically creates the first variant with no options.
		// There should not exist the chance to create a second variant with no options.
		tx.rollback() or {}
		return handle_error_400(mut ctx, 'Values for each existing product_option must be provided',
			'No product_option_value provided')
	}

	tx.rollback() or { return handle_error_500(mut ctx, error_transaction_rollback, err.msg()) }

	return conduit_product_variant_create(mut app, mut ctx, product_id_bin, ph)
}

// retrieves a product_variant by its id
@['/admin/products/:product_id/variants/:variant_id'; get]
pub fn (mut app App) admin_variants_id_get(mut ctx Context, product_id string, variant_id string) veb.Result {
	_ := id_string_to_bin(product_id) or {
		return handle_error_400(mut ctx, error_id_invalid, 'product_id')
	}

	variant_id_bin := id_string_to_bin(variant_id) or {
		return handle_error_400(mut ctx, error_id_invalid, 'variant_id')
	}

	// TODO is variant of product?

	ph := RetrieveProductVariantParamsHygienised{
		ids:     ZeroArrayString{
			is_set: true
		}
		ids_bin: [variant_id_bin]
	}

	return conduit_product_variant_get(mut app, mut ctx, ph)
}

// updates a product variant
@['/admin/products/:product_id/variants/:variant_id'; post]
pub fn (mut app App) admin_variants_id_post(mut ctx Context, product_id string, variant_id string) veb.Result {
	product_id_bin := id_string_to_bin(product_id) or {
		return handle_error_400(mut ctx, error_id_invalid, 'product_id')
	}

	variant_id_bin := id_string_to_bin(variant_id) or {
		return handle_error_400(mut ctx, error_id_invalid, 'variant_id')
	}

	p := json.decode(VariantUpdateRequest, ctx.req.data) or {
		return handle_error_400(mut ctx, 'Could not decode VariantRequest', err.msg())
	}

	ph := p.hygienise() or {
		if err is InternalError {
			return handle_error_400(mut ctx, err.message, err.details)
		}
		return handle_error_unhandled(mut ctx, err.msg(), 'hygienise_product_variant_request')
	}

	if inventory_item := ph.inventory_item {
		if inventory_item.sku == none && inventory_item.origin_country == none
			&& inventory_item.hs_code == none && inventory_item.mid_code == none
			&& inventory_item.material == none && inventory_item.weight == none
			&& inventory_item.length == none && inventory_item.height == none
			&& inventory_item.width == none && inventory_item.manage_inventory == none
			&& inventory_item.requires_shipping == none {
			return handle_error_400(mut ctx, error_empty_object, 'InventoryItemUpdateRequest')
		}
	}

	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	if money_amounts := ph.money_amounts {
		regions := model_region_retrieve(mut tx, RegionRetriveParams{}) or {
			tx.rollback() or {}
			return handle_error_500(mut ctx, 'Failed to retrieve region', err.msg())
		}

		verify_money_amounts(money_amounts, regions) or {
			tx.rollback() or {}
			if err is InternalError {
				return handle_suite_error(mut ctx, err)
			}
			return handle_error_unhandled(mut ctx, err.msg(), 'ProductVariantCreateRequestHygienised.verify_money_amounts')
		}
	}

	if option_value_ids := ph.option_value_ids {
		mut product_option_data := suite_product_option_data_get(mut tx, [
			product_id_bin,
		]) or {
			tx.rollback() or {}
			if err is InternalError {
				return handle_suite_error(mut ctx, err)
			}
			return handle_error_unhandled(mut ctx, err.msg(), 'suite_product_option_data_get')
		}

		product_option_data.verify_product_option_value_ids(option_value_ids, ph.option_value_ids_bin) or {
			if err is InternalError {
				return handle_error_400(mut ctx, err.message, err.details)
			}
			return handle_error_unhandled(mut ctx, err.msg(), 'verify_product_option_value_ids')
		}
	}

	tx.rollback() or { return handle_error_500(mut ctx, error_transaction_rollback, err.msg()) }

	return conduit_product_variant_update(mut app, mut ctx, product_id_bin, variant_id_bin,
		ph)
}

// deletes a product variant
@['/admin/products/:product_id/variants/:variant_id'; delete]
pub fn (mut app App) admin_variants_id_delete(mut ctx Context, product_id string, variant_id string) veb.Result {
	product_id_bin := id_string_to_bin(product_id) or {
		return handle_error_400(mut ctx, error_id_invalid, 'product_id')
	}

	variant_id_bin := id_string_to_bin(variant_id) or {
		return handle_error_400(mut ctx, error_id_invalid, 'variant_id')
	}

	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	ph := RetrieveProductVariantParamsHygienised{
		product_ids:     ZeroArrayString{
			is_set: true
		}
		product_ids_bin: [product_id_bin]
	}

	count := model_product_variants_retrieve_count(mut tx, ph) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not retrieve variants', err.msg())
	}

	if count == 0 {
		tx.rollback() or { return handle_error_500(mut ctx, error_transaction_rollback, err.msg()) }
		return handle_error_500(mut ctx, 'product_variant does not exist', 'count == 0')
	}

	product_variants := model_product_variants_retrieve(mut tx, ph) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not retrieve product_variant', err.msg())
	}

	tx.rollback() or { return handle_error_500(mut ctx, error_transaction_rollback, err.msg()) }

	for i := 0; i < product_variants.len; i++ {
		if product_variants[i].id_bin != variant_id_bin {
			continue
		}

		if product_variants.len == 1 {
			return handle_error_400(mut ctx, 'Cannot delete product_variant', 'A product must have at least 1 variant')
		}

		inventory_item_id_bin := product_variants[i].inventory_item.id_bin
		return conduit_product_variant_delete(mut app, mut ctx, variant_id_bin, inventory_item_id_bin)
	}

	return handle_error_404(mut ctx, 'product_variant does not exist', 'no product_variant with provided id')
}

// lists a product's options and their values
@['/admin/products/:product_id/options'; get]
pub fn (mut app App) admin_products_id_options_get(mut ctx Context, product_id string) veb.Result {
	product_id_bin := id_string_to_bin(product_id) or {
		return handle_error_400(mut ctx, error_id_invalid, err.msg())
	}

	return conduit_product_option_list(mut app, mut ctx, product_id_bin)
}

// creates a product option
@['/admin/products/:product_id/options'; post]
pub fn (mut app App) admin_products_id_options_post(mut ctx Context, product_id string) veb.Result {
	product_id_bin := id_string_to_bin(product_id) or {
		return handle_error_400(mut ctx, error_id_invalid, err.msg())
	}

	p := json.decode(ProductOptionCreateRequest, ctx.req.data) or {
		return handle_error_400(mut ctx, 'Could not decode ProductOptionCreateRequest',
			err.msg())
	}

	ph := p.hygienise() or {
		if err is InternalError {
			return handle_error_400(mut ctx, err.message, err.details)
		}
		return handle_error_500(mut ctx, 'Unhandled error at hygienise_product_option_request',
			err.msg())
	}

	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	store := model_store_retrieve(mut tx) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Failed to retrieve store', err.msg())
	}

	tx.rollback() or { return handle_error_500(mut ctx, error_transaction_rollback, err.msg()) }

	ph.verify(store.default_locale_id_bin) or {
		if err is InternalError {
			return handle_error_400(mut ctx, err.message, err.details)
		}
		return handle_error_500(mut ctx, 'Unhandled error at ProductOptionUpdateRequestHygienised.verify',
			err.msg())
	}

	return conduit_product_option_create(mut app, mut ctx, product_id, product_id_bin,
		ph)
}

// updates a product option
@['/admin/products/:product_id/options/:product_option_id'; post]
pub fn (mut app App) admin_update_product_option(mut ctx Context, product_id string, product_option_id string) veb.Result {
	product_id_bin := id_string_to_bin(product_id) or {
		return handle_error_400(mut ctx, error_id_invalid, err.msg())
	}

	product_option_id_bin := id_string_to_bin(product_option_id) or {
		return handle_error_400(mut ctx, error_id_invalid, err.msg())
	}

	p := json.decode(ProductOptionUpdateRequest, ctx.req.data) or {
		return handle_error_400(mut ctx, 'Could not decode ProductOptionUpdateRequest',
			err.msg())
	}

	ph := p.hygienise() or {
		if err is InternalError {
			return handle_error_400(mut ctx, err.message, err.details)
		}
		return handle_error_500(mut ctx, 'Unhandled error at hygienise_product_option_update_request',
			err.msg())
	}

	ph.verify() or {
		if err is InternalError {
			return handle_error_400(mut ctx, err.message, err.details)
		}
		return handle_error_500(mut ctx, 'Unhandled error at ProductOptionUpdateRequestHygienised.verify',
			err.msg())
	}

	return conduit_product_option_update(mut app, mut ctx, product_id, product_id_bin,
		product_option_id, product_option_id_bin, ph)
}

// deletes a product option
@['/admin/products/:product_id/options/:product_option_id'; delete]
pub fn (mut app App) admin_product_option_delete(mut ctx Context, product_id string, product_option_id string) veb.Result {
	product_id_bin := id_string_to_bin(product_id) or {
		return handle_error_400(mut ctx, error_id_invalid, err.msg())
	}

	product_option_id_bin := id_string_to_bin(product_option_id) or {
		return handle_error_400(mut ctx, error_id_invalid, err.msg())
	}

	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	product_options := model_product_options_retrieve_by_product_ids(mut tx, [
		product_id_bin,
	]) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not retrieve product_option', err.msg())
	}

	product_option_values := model_product_option_values_retrieve(mut tx, [
		product_option_id_bin,
	]) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not retrieve product_option_value', err.msg())
	}

	tx.rollback() or { return handle_error_500(mut ctx, error_transaction_rollback, err.msg()) }

	// TODO option is not related to this product

	if product_options.len == 0 {
		return handle_error_400(mut ctx, 'product does not exist', 'No product_option exist for the given product id')
	}

	if product_options.len == 1 {
		return handle_error_400(mut ctx, "Can't delete last option", 'A product must have at least one option')
	}

	mut found := false
	for i := 0; i < product_options.len; i++ {
		product_option := product_options[i]
		if product_option.product_id_bin == product_id_bin {
			found = true
		}
	}
	if found == false {
		return handle_error_400(mut ctx, 'product_option not found for this product',
			'The specified product_option does not belong to the given product')
	}

	if product_option_values.len == 0 {
		return handle_error_400(mut ctx, 'product_option does not exist', 'No product_option_value exist for the given product_option id')
	}

	if product_option_values.len > 1 {
		return handle_error_400(mut ctx, "Can't delete option with multiple values", 'Delete all other product_option_value first')
	}

	return conduit_product_option_delete(mut app, mut ctx, product_id, product_id_bin,
		product_option_id, product_option_id_bin)
}

// creates a product_option_value
@['/admin/products/:product_id/options/:product_option_id/values'; post]
pub fn (mut app App) admin_product_option_value_create(mut ctx Context, product_id string, product_option_id string) veb.Result {
	product_id_bin := id_string_to_bin(product_id) or {
		return handle_error_400(mut ctx, error_id_invalid, err.msg())
	}

	product_option_id_bin := id_string_to_bin(product_option_id) or {
		return handle_error_400(mut ctx, error_id_invalid, err.msg())
	}

	p := json.decode(ProductOptionValueRequest, ctx.req.data) or {
		return handle_error_400(mut ctx, 'Could not decode ProductOptionValueRequest',
			err.msg())
	}

	ph := p.hygienise() or {
		if err is InternalError {
			return handle_error_400(mut ctx, err.message, err.details)
		}
		return handle_error_500(mut ctx, 'Unhandled error at ProductOptionValueRequest.hygienise',
			err.msg())
	}

	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	store := model_store_retrieve(mut tx) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Failed to retrieve store', err.msg())
	}

	product_options := model_product_options_retrieve_by_product_ids(mut tx, [
		product_id_bin,
	]) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not retrieve product_option', err.msg())
	}

	product_option_values := model_product_option_values_retrieve(mut tx, [
		product_option_id_bin,
	]) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not retrieve product_option_value', err.msg())
	}

	tx.rollback() or { return handle_error_500(mut ctx, error_transaction_rollback, err.msg()) }

	ph.verify(store.default_locale_id_bin) or {
		if err is InternalError {
			return handle_error_400(mut ctx, err.message, err.details)
		}
		return handle_error_500(mut ctx, 'Unhandled error at ProductOptionValueRequestHygienised.verify',
			err.msg())
	}

	if product_options.len == 0 {
		return handle_error_400(mut ctx, 'product does not exist', 'No product_option exist for the given product id')
	}

	mut found := false
	for i := 0; i < product_options.len; i++ {
		product_option := product_options[i]
		if product_option.product_id_bin == product_id_bin {
			found = true
		}
	}
	if found == false {
		return handle_error_400(mut ctx, 'product_option not found for this product',
			'The specified product_option does not belong to the given product')
	}

	if product_option_values.len == 0 {
		return handle_error_400(mut ctx, 'product_option does not exist', 'No product_option_value exist for the given product_option id')
	}

	return conduit_product_option_value_create(mut app, mut ctx, product_option_id_bin,
		ph)
}

// updates a product_option_value
@['/admin/products/:product_id/options/:product_option_id/values/:product_option_value_id'; post]
pub fn (mut app App) admin_product_option_value_update(mut ctx Context, product_id string, product_option_id string, product_option_value_id string) veb.Result {
	product_id_bin := id_string_to_bin(product_id) or {
		return handle_error_400(mut ctx, error_id_invalid, 'product_id')
	}

	product_option_id_bin := id_string_to_bin(product_option_id) or {
		return handle_error_400(mut ctx, error_id_invalid, 'product_option_id')
	}

	product_option_value_id_bin := id_string_to_bin(product_option_value_id) or {
		return handle_error_400(mut ctx, error_id_invalid, 'product_option_value_id')
	}

	p := json.decode(ProductOptionValueRequest, ctx.req.data) or {
		return handle_error_400(mut ctx, 'Could not decode ProductOptionValueRequest',
			err.msg())
	}

	ph := p.hygienise() or {
		if err is InternalError {
			return handle_error_400(mut ctx, err.message, err.details)
		}
		return handle_error_500(mut ctx, 'Unhandled error at ProductOptionValueRequest.hygienise',
			err.msg())
	}

	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	store := model_store_retrieve(mut tx) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Failed to retrieve store', err.msg())
	}

	product_options := model_product_options_retrieve_by_product_ids(mut tx, [
		product_id_bin,
	]) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not retrieve product_option', err.msg())
	}

	product_option_values := model_product_option_values_retrieve(mut tx, [
		product_option_id_bin,
	]) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not retrieve product_option_value', err.msg())
	}

	tx.rollback() or { return handle_error_500(mut ctx, error_transaction_rollback, err.msg()) }

	ph.verify(store.default_locale_id_bin) or {
		if err is InternalError {
			return handle_error_400(mut ctx, err.message, err.details)
		}
		return handle_error_500(mut ctx, 'Unhandled error at ProductOptionValueRequestHygienised.verify',
			err.msg())
	}

	if product_options.len == 0 {
		return handle_error_400(mut ctx, 'product does not exist', 'No product_option exist for the given product id')
	}

	mut found := false
	for i := 0; i < product_options.len; i++ {
		product_option := product_options[i]
		if product_option.product_id_bin == product_id_bin {
			found = true
		}
	}
	if found == false {
		return handle_error_400(mut ctx, 'product_option not found for this product',
			'The specified product_option does not belong to the given product')
	}

	if product_option_values.len == 0 {
		return handle_error_400(mut ctx, 'product_option does not exist', 'No product_option_value exist for the given product_option id')
	}

	// TODO verify product_option_value is in the ids fetched
	found = false
	for i := 0; i < product_option_values.len; i++ {
		product_option_value := product_option_values[i]
		if product_option_value.option_id_bin == product_option_id_bin {
			found = true
		}
	}
	if found == false {
		return handle_error_400(mut ctx, 'product_option_value not found for this product_option',
			'The specified product_option_value does not belong to the given product_option')
	}

	return conduit_product_option_value_update(mut app, mut ctx, product_option_value_id_bin,
		ph)
}

// deletes a product_option_value
@['/admin/products/:product_id/options/:product_option_id/values/:product_option_value_id'; delete]
pub fn (mut app App) admin_product_option_value_delete(mut ctx Context, product_id string, product_option_id string, product_option_value_id string) veb.Result {
	product_id_bin := id_string_to_bin(product_id) or {
		return handle_error_400(mut ctx, error_id_invalid, err.msg())
	}

	product_option_id_bin := id_string_to_bin(product_option_id) or {
		return handle_error_400(mut ctx, error_id_invalid, err.msg())
	}

	product_option_value_id_bin := id_string_to_bin(product_option_value_id) or {
		return handle_error_400(mut ctx, error_id_invalid, err.msg())
	}

	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	product_options := model_product_options_retrieve_by_product_ids(mut tx, [
		product_id_bin,
	]) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not retrieve product_option', err.msg())
	}

	product_option_values := model_product_option_values_retrieve(mut tx, [
		product_option_id_bin,
	]) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not retrieve product_option_value', err.msg())
	}

	tx.rollback() or { return handle_error_500(mut ctx, error_transaction_rollback, err.msg()) }

	if product_options.len == 0 {
		return handle_error_400(mut ctx, 'product does not exist', 'No product_option exist for the given product id')
	}

	mut found := false
	for i := 0; i < product_options.len; i++ {
		product_option := product_options[i]
		if product_option.product_id_bin == product_id_bin {
			found = true
		}
	}
	if found == false {
		return handle_error_400(mut ctx, 'product_option not found for this product',
			'The specified product_option does not belong to the given product')
	}

	if product_option_values.len == 0 {
		return handle_error_400(mut ctx, 'product_option does not exist', 'No product_option_value exist for the given product_option id')
	}

	if product_option_values.len == 1 {
		return handle_error_400(mut ctx, "Can't delete last product_option_value", 'A product_option must have at least one product_option_value')
	}

	// TODO verify product_option_value is in the ids fetched
	found = false
	for i := 0; i < product_option_values.len; i++ {
		product_option_value := product_option_values[i]
		if product_option_value.option_id_bin == product_option_id_bin {
			found = true
		}
	}
	if found == false {
		return handle_error_400(mut ctx, 'product_option_value not found for this product_option',
			'The specified product_option_value does not belong to the given product_option')
	}

	return conduit_product_option_value_delete(mut app, mut ctx, product_option_value_id_bin)
}

// updates the product's seo
@['/admin/products/:product_id/seo/:seo_id'; post]
pub fn (mut app App) admin_product_seo_update(mut ctx Context, product_id string, seo_id string) veb.Result {
	product_id_bin := id_string_to_bin(product_id) or {
		return handle_error_400(mut ctx, error_id_invalid, 'product_id')
	}

	seo_id_bin := id_string_to_bin(seo_id) or {
		return handle_error_400(mut ctx, error_id_invalid, 'seo_id')
	}

	p := json.decode(SEOUpdateRequest, ctx.req.data) or {
		return handle_error_400(mut ctx, 'Could not decode SEOUpdateRequest', err.msg())
	}

	ph := p.hygienise() or {
		if err is InternalError {
			return handle_error_400(mut ctx, err.message, err.details)
		}
		return handle_error_500(mut ctx, 'Unhandled error at SEOUpdateRequest.hygienise',
			err.msg())
	}

	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	// TODO verify product_id exists
	// TODO verify seo_id exists
	// TODO verify seo_id belongs to product_id
	// TODO verify all locale_id exist

	tx.rollback() or { return handle_error_500(mut ctx, error_transaction_rollback, err.msg()) }

	return conduit_product_seo_update(mut app, mut ctx, seo_id_bin, ph)
}
