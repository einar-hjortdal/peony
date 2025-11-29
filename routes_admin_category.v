module peony

import veb
import json

// lists product_category
@['/admin/product-categories'; get]
pub fn (mut app App) admin_product_category_list(mut ctx Context) veb.Result {
	query_params := extract_product_category_list_request_query(ctx.query)

	p := hygienise_product_category_list_request_query(query_params) or {
		if err is InternalError {
			return handle_error_400(mut ctx, err.message, err.details)
		}
		return handle_error_500(mut ctx, 'Unhandled error at hygienise_product_category_params',
			err.msg())
	}

	return conduit_category_list(mut app, mut ctx, p)
}

// creates product_category
@['/admin/product-categories'; post]
pub fn (mut app App) admin_product_category_create(mut ctx Context) veb.Result {
	p := json.decode(CategoryCreateRequest, ctx.req.data) or {
		return handle_error_400(mut ctx, 'Could not decode CategoryCreateRequest', err.msg())
	}

	ph := p.hygienise() or {
		if err is InternalError {
			return handle_error_400(mut ctx, err.message, err.details)
		}
		return handle_error_unhandled(mut ctx, err.msg(), 'CategoryCreateRequest.hygienise')
	}

	for i := 0; i < p.translations.len; i++ {
		// TODO verify default locale is in array
		// TODO verify locale_ids exist
	}

	return conduit_category_create(mut app, mut ctx, ph)
}

// get a product_category by its id
@['/admin/product-categories/:product_category_id'; get]
pub fn (mut app App) admin_product_category_get(mut ctx Context, product_category_id string) veb.Result {
	product_category_id_bin := id_string_to_bin(product_category_id) or {
		return handle_error_400(mut ctx, error_id_invalid, 'product_category_id')
	}

	query_params := extract_product_category_get_request_params(ctx.query)

	p := hygienise_product_category_get_request_query(query_params, product_category_id_bin) or {
		if err is InternalError {
			return handle_suite_error(mut ctx, err)
		}
		return handle_error_unhandled(mut ctx, err.msg(), 'hygienise_product_category_list_request_query')
	}

	return conduit_category_get(mut app, mut ctx, p)
}

// updates a product_category
@['/admin/product-categories/:product_category_id'; post]
pub fn (mut app App) admin_product_category_update(mut ctx Context, product_category_id string) veb.Result {
	product_category_id_bin := id_string_to_bin(product_category_id) or {
		return handle_error_400(mut ctx, error_id_invalid, 'product_category_id')
	}

	p := json.decode(CategoryUpdateRequest, ctx.req.data) or {
		return handle_error_400(mut ctx, 'Could not decode CategoryUpdateRequest', err.msg())
	}

	ph := p.hygienise() or {
		if err is InternalError {
			return handle_error_400(mut ctx, err.message, err.details)
		}
		return handle_error_unhandled(mut ctx, err.msg(), 'CategoryUpdateRequest.hygienise')
	}

	if _ := ph.parent_category_id {
		// TODO verify ph.parent_category_id exists
	}

	if _ := ph.translations {
		// TODO verify ids
	}

	if _ := ph.seo_translations {
		// TODO verify ids
	}

	return conduit_category_update(mut app, mut ctx, product_category_id_bin, ph)
}

// deletes a product_category
@['/admin/product-categories/:product_category_id'; delete]
pub fn (mut app App) admin_product_category_delete(mut ctx Context, product_category_id string) veb.Result {
	product_category_id_bin := id_string_to_bin(product_category_id) or {
		return handle_error_400(mut ctx, error_id_invalid, 'product_category_id')
	}

	return conduit_product_category_delete(mut app, mut ctx, product_category_id_bin)
}
