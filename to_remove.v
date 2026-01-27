module peony

import veb
import json

pub struct ProductOptionListEnvelope {
	options []ProductOptionResponse
	count   i64
	offset  i32
	fetch   i32 @[omitempty]
}

fn conduit_product_option_list(mut app App, mut ctx Context, product_id_bin []u8) veb.Result {
	// return options and their values
	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	mut product_option_data := suite_product_option_data_get(mut tx, [
		product_id_bin,
	]) or {
		tx.rollback() or {}
		if err is InternalError {
			return handle_suite_error(mut ctx, err)
		}
		return handle_error_unhandled(mut ctx, err.msg(), 'suite_product_option_data_get')
	}

	tx.rollback() or { return handle_error_500(mut ctx, error_transaction_rollback, err.msg()) }

	product_options := product_option_data.build_product_options()

	mut external_product_options := []ProductOptionResponse{len: product_options.len}
	for i := 0; i < product_options.len; i++ {
		external_product_options[i] = format_product_option_response(product_options[i])
	}

	// TODO count, offset, fetch
	return ctx.json(ProductOptionListEnvelope{
		options: external_product_options
	})
}

fn conduit_product_option_create(mut app App, mut ctx Context, product_id string, product_id_bin []u8, ph ProductOptionCreateRequestHygienised) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	_, product_option_id_bin := app.new_id()
	mut product_option_value_ids_bin := [][]u8{len: ph.values.len}
	for i := 0; ph.values.len; i++ {
		_, product_option_value_ids_bin[i] = app.new_id()
	}

	model_product_option_create(mut tx, product_id_bin, product_option_id_bin, product_option_value_ids_bin,
		ph) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not create product_option', err.msg())
	}

	tx.commit() or { return handle_error_500(mut ctx, error_transaction_commit, err.msg()) }

	return success(mut ctx)
}

fn conduit_product_option_update(mut app App, mut ctx Context, product_id string, product_id_bin []u8, product_option_id string, product_option_id_bin []u8, ph ProductOptionUpdateRequestHygienised) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	model_product_option_update(mut tx, product_option_id_bin, ph) or {
		tx.rollback() or {} // ignore error
		return handle_error_500(mut ctx, 'Could not create product_option', err.msg())
	}

	tx.commit() or { return handle_error_500(mut ctx, error_transaction_commit, err.msg()) }

	return success(mut ctx)
}

// returns an error when attempting to delete options if more than one variant exist
// require user to delete all variants manually first, then allow deletion of any option
// TODO move these checks to route? It is input validation, right?
fn conduit_product_option_delete(mut app App, mut ctx Context, product_id string, product_id_bin []u8, product_option_id string, product_option_id_bin []u8) veb.Result {
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
		tx.rollback() or {} // ignore error
		return handle_error_500(mut ctx, 'Could not delee product_option: could not retrieve product_variant',
			err.msg())
	}

	if count > 1 {
		tx.rollback() or {} // ignore error
		return handle_error_400(mut ctx, 'Could not delete product_option: there exist more than one product_variant',
			'more than one variant exist')
	}

	model_product_option_delete(mut tx, product_option_id_bin) or {
		tx.rollback() or {} // ignore error
		return handle_error_400(mut ctx, 'Could not delete product_option', err.msg())
	}

	tx.commit() or { return handle_error_500(mut ctx, error_transaction_commit, err.msg()) }

	return success(mut ctx)
}

// TODO translations struct transformed the same was in conduit_product_option_value_update, maybe abstract
fn conduit_product_option_value_create(mut app App, mut ctx Context, product_option_id_bin []u8, ph ProductOptionValueRequestHygienised) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	_, product_option_value_id_bin := app.new_id()

	model_product_option_value_create(mut tx, product_option_id_bin, product_option_value_id_bin) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not create product_option_value', err.msg())
	}

	if translations := ph.translations {
		mut p := []ProductOptionValueTranslationUpdateParams{len: translations.len}
		for i := 0; i < translations.len; i++ {
			translation := translations[i]
			p[i] = ProductOptionValueTranslationUpdateParams{
				locale_id_bin: translation.locale_id_bin
				name:          translation.name
			}
		}

		model_product_option_value_translations_update(mut tx, product_option_value_id_bin,
			p) or {
			tx.rollback() or {}
			return handle_error_500(mut ctx, 'Could not update product_option_value_translations',
				err.msg())
		}
	}

	tx.commit() or { return handle_error_500(mut ctx, error_transaction_commit, err.msg()) }

	return success(mut ctx)
}

fn conduit_product_option_value_update(mut app App, mut ctx Context, product_option_value_id_bin []u8, ph ProductOptionValueUpdateRequestHygienised) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	if name := ph.name {
		p := ProductOptionValueUpdateParams{
			name: name
		}
		model_product_option_value_update(mut tx, product_option_value_id_bin, p) or {
			tx.rollback() or {}
			return handle_error_500(mut ctx, 'Could not update product_option_value',
				err.msg())
		}
	}

	if translations := ph.translations {
		mut p := []ProductOptionValueTranslationUpdateParams{len: translations.len}
		for i := 0; i < translations.len; i++ {
			translation := translations[i]
			p[i] = ProductOptionValueTranslationUpdateParams{
				locale_id_bin: translation.locale_id_bin
				name:          translation.name
			}
		}

		model_product_option_value_translations_update(mut tx, product_option_value_id_bin,
			p) or {
			tx.rollback() or {}
			return handle_error_500(mut ctx, 'Could not update product_option_value_translations',
				err.msg())
		}
	}

	tx.commit() or { return handle_error_500(mut ctx, error_transaction_commit, err.msg()) }

	return success(mut ctx)
}

fn conduit_product_option_value_delete(mut app App, mut ctx Context, product_option_value_id_bin []u8) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	model_product_option_value_delete(mut tx, product_option_value_id_bin) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not delete product_option_value', err.msg())
	}

	tx.commit() or { return handle_error_500(mut ctx, error_transaction_commit, err.msg()) }

	return success(mut ctx)
}

// lists a product's options and their values
// TODO deprecate
@['/admin/products/:product_id/options'; get]
pub fn (mut app App) admin_products_id_options_get(mut ctx Context, product_id string) veb.Result {
	product_id_bin := id_string_to_bin(product_id) or {
		return handle_error_400(mut ctx, error_id_invalid, err.msg())
	}

	return conduit_product_option_list(mut app, mut ctx, product_id_bin)
}

// creates a product option
// TODO deprecate
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

	// store := model_store_retrieve(mut tx) or {
	// 	tx.rollback() or {}
	// 	return handle_error_500(mut ctx, 'Failed to retrieve store', err.msg())
	// }

	tx.rollback() or { return handle_error_500(mut ctx, error_transaction_rollback, err.msg()) }

	ph.verify() or {
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
// TODO deprecate
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
// TODO deprecate
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

	// store := model_store_retrieve(mut tx) or {
	// 	tx.rollback() or {}
	// 	return handle_error_500(mut ctx, 'Failed to retrieve store', err.msg())
	// }

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

	ph.verify() or {
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

	p := json.decode(ProductOptionValueUpdateRequest, ctx.req.data) or {
		return handle_error_400(mut ctx, 'Could not decode ProductOptionValueUpdateRequest',
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

	// TODO locale ids exist
	// store := model_store_retrieve(mut tx) or {
	// 	tx.rollback() or {}
	// 	return handle_error_500(mut ctx, 'Failed to retrieve store', err.msg())
	// }

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

	ph.verify() or {
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
