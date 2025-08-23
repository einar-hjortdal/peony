module peony

import veb
import json

// lists product_category
@['/admin/product-categories'; get]
pub fn (mut app App) admin_product_category_list(mut ctx Context) veb.Result {
	p := extract_retrieve_product_category_params(ctx.query)

	ids_bin := zero_array_id_string_to_array_id_bin(p.ids) or {
		return handle_error_400(mut ctx, error_id_invalid, 'ids_bin')
	}

	parent_category_ids_bin := zero_array_id_string_to_array_id_bin(p.parent_category_ids) or {
		return handle_error_400(mut ctx, error_id_invalid, 'parent_category_ids')
	}

	ph := ProductCategoryRetrieveParamsHygienised{
		ids:                     p.ids
		ids_bin:                 ids_bin
		handles:                 p.handles
		is_active:               p.is_active
		is_internal:             p.is_internal
		parent_category_ids:     p.parent_category_ids
		parent_category_id_bins: parent_category_ids_bin
		with_deleted:            p.with_deleted
		offset:                  p.offset
		fetch:                   p.fetch
		order:                   p.order
	}

	return conduit_product_category_list(mut app, mut ctx, ph)
}

// creates product_category
@['/admin/product-categories'; post]
pub fn (mut app App) admin_product_category_create(mut ctx Context) veb.Result {
	p := json.decode(ProductCategoryRequest, ctx.req.data) or {
		return handle_error_400(mut ctx, 'Could not decode ProductCategoryRequest', err.msg())
	}

	mut parent_category_id_bin := []u8{}
	if parent_category_id := p.parent_category_id {
		parent_category_id_bin = id_string_to_bin(parent_category_id) or {
			return handle_error_400(mut ctx, error_id_invalid, 'parent_category_id')
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
		for i := 0; translations.len; i++ {
			translation := translations[i]
			locale_id_bin := id_string_to_bin(translation.locale_id) or {
				return handle_error_400(mut ctx, error_id_invalid, 'locale_id')
			}
			pcth[i] = ProductCategoryTranslationRequestHygienised{
				locale_id:     translation.locale_id
				locale_id_bin: locale_id_bin
				name:          translation.name
			}
		}
		ph.translations = pcth
	}

	return conduit_product_category_create(mut app, mut ctx, ph)
}

// get a product_category by its id
@['/admin/product-categories/:product_category_id'; get]
pub fn (mut app App) admin_product_category_get(mut ctx Context, product_category_id string) veb.Result {
	product_category_id_bin := id_string_to_bin(product_category_id) or {
		return handle_error_400(mut ctx, error_id_invalid, 'product_category_id')
	}

	return conduit_product_category_get(mut app, mut ctx, product_category_id_bin)
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

	// TODO implement
	return conduit_product_category_delete(mut app, mut ctx, product_category_id_bin)
}
