module peony

import veb
import json

// lists product_category
@['/admin/product-categories'; get]
pub fn (mut app App) admin_product_category_list(mut ctx Context) veb.Result {
	query_params := extract_product_category_get_request_params(ctx.query)

	p := hygienise_product_category_get_request_query(query_params) or {
		if err is InternalError {
			return handle_error_400(mut ctx, err.message, err.details)
		}
		return handle_error_500(mut ctx, 'Unhandled error at hygienise_product_category_params',
			err.msg())
	}

	return conduit_product_category_list(mut app, mut ctx, p)
}

// creates product_category
@['/admin/product-categories'; post]
pub fn (mut app App) admin_product_category_create(mut ctx Context) veb.Result {
	p := json.decode(ProductCategoryRequest, ctx.req.data) or {
		return handle_error_400(mut ctx, 'Could not decode ProductCategoryRequest', err.msg())
	}

	translations := p.translations or {
		return handle_error_400(mut ctx, 'Translations missing', 'Provide at least one translation')
	}

	if translations.len == 0 {
		return handle_error_400(mut ctx, 'Translations missing', 'Provide at least one translation')
	}

	if translations.len == 1 {
		// TODO verify it is default locale
	}

	mut parent_category_id_bin := []u8{}
	if parent_category_id := p.parent_category_id {
		parent_category_id_bin = id_string_to_bin(parent_category_id) or {
			return handle_error_400(mut ctx, error_id_invalid, 'parent_category_id')
		}
	}

	ph := ProductCategoryRequestHygienised{
		handle:                 p.handle
		is_internal:            p.is_internal
		is_active:              p.is_active
		parent_category_id:     p.parent_category_id
		parent_category_id_bin: parent_category_id_bin
		metadata:               p.metadata
	}

	mut pcth := []ProductCategoryTranslationRequestHygienised{len: translations.len}
	for i := 0; i < translations.len; i++ {
		translation := translations[i]
		locale_id_bin := id_string_to_bin(translation.locale_id) or {
			return handle_error_400(mut ctx, error_id_invalid, 'locale_id')
		}
		pcth[i] = ProductCategoryTranslationRequestHygienised{
			locale_id:     translation.locale_id
			locale_id_bin: locale_id_bin
			name:          translation.name
			description:   translation.description
		}
	}

	return conduit_product_category_create(mut app, mut ctx, ph, pcth)
}

// get a product_category by its id
@['/admin/product-categories/:product_category_id'; get]
pub fn (mut app App) admin_product_category_get(mut ctx Context, product_category_id string) veb.Result {
	product_category_id_bin := id_string_to_bin(product_category_id) or {
		return handle_error_400(mut ctx, error_id_invalid, 'product_category_id')
	}

	query_params := extract_product_category_list_request_query(ctx.query)

	p := hygienise_product_category_list_request_query(query_params) or {
		if err is InternalError {
			return handle_suite_error(mut ctx, err)
		}
		return handle_error_unhandled(mut ctx, err.msg(), 'hygienise_product_category_list_request_query')
	}

	return conduit_product_category_get(mut app, mut ctx, product_category_id_bin, p)
}

// updates a product_category
@['/admin/product-categories/:product_category_id'; post]
pub fn (mut app App) admin_product_category_update(mut ctx Context, product_category_id string) veb.Result {
	product_category_id_bin := id_string_to_bin(product_category_id) or {
		return handle_error_400(mut ctx, error_id_invalid, 'product_category_id')
	}

	p := json.decode(ProductCategoryRequest, ctx.req.data) or {
		return handle_error_400(mut ctx, 'Could not decode ProductCategoryRequest', err.msg())
	}

	if p.translations == none && p.handle == none && p.is_internal == none && p.is_active == none
		&& p.parent_category_id == none && p.metadata == none {
		return handle_error_400(mut ctx, error_empty_object, 'ProductCategoryRequest')
	}

	mut parent_category_id_bin := []u8{}
	if parent_category_id := p.parent_category_id {
		parent_category_id_bin = id_string_to_bin(parent_category_id) or {
			return handle_error_400(mut ctx, error_id_invalid, 'product_category_id')
		}
	}

	mut ph := ProductCategoryRequestHygienised{
		handle:                 p.handle
		is_internal:            p.is_internal
		is_active:              p.is_active
		parent_category_id:     p.parent_category_id
		parent_category_id_bin: parent_category_id_bin
		metadata:               p.metadata
	}

	if translations := p.translations {
		mut pcth := []ProductCategoryTranslationRequestHygienised{len: translations.len}
		for i := 0; i < translations.len; i++ {
			translation := translations[i]
			locale_id_bin := id_string_to_bin(translation.locale_id) or {
				return handle_error_400(mut ctx, error_id_invalid, 'locale_id')
			}
			pcth[i] = ProductCategoryTranslationRequestHygienised{
				locale_id:     translation.locale_id
				locale_id_bin: locale_id_bin
				name:          translation.name
				description:   translation.description
			}
		}
		ph.translations = pcth
	}

	return conduit_product_category_update(mut app, mut ctx, product_category_id_bin,
		ph)
}

// deletes a product_category
@['/admin/product-categories/:product_category_id'; delete]
pub fn (mut app App) admin_product_category_delete(mut ctx Context, product_category_id string) veb.Result {
	product_category_id_bin := id_string_to_bin(product_category_id) or {
		return handle_error_400(mut ctx, error_id_invalid, 'product_category_id')
	}

	return conduit_product_category_delete(mut app, mut ctx, product_category_id_bin)
}
