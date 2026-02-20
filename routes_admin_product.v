module peony

import json
import veb
import einar_hjortdal.slugify

// lists products
@['/admin/products'; get]
pub fn (mut app App) admin_product_list(mut ctx Context) veb.Result {
	ph := hygienise_retrieve_product_params(ctx.query) or { return ctx.handle_error(err) }

	if ph.fetch.is_set && ph.fetch.v == 0 {
		err := new_error_fetch_zero()
		return ctx.handle_error(err)
	}

	return conduit_products_list(mut app, mut ctx, ph)
}

// create a product
@['/admin/products'; post]
pub fn (mut app App) admin_product_create(mut ctx Context) veb.Result {
	p := json.decode(ProductCreateRequest, ctx.req.data) or {
		perr := new_error_bad_request('Could not decode ProductRequest', err.msg())
		return ctx.handle_error(perr)
	}

	ph := p.hygienise() or { return ctx.handle_error(err) }

	product_id, product_id_bin := app.new_id()

	// generate handle from title if handle is not provided
	mut handle := p.handle or { slugify.default().make(p.title) }

	mut tx := app.start_transaction() or { return ctx.handle_error(err) }

	product_by_handle_count := model_product_retrieve_count(mut tx, RetrieveProductParamsHygienised{
		handle: ZeroString{
			is_set: true
			v:      handle
		}
	}) or {
		tx.rollback() or {}
		perr := new_error_internal('Could not verify handle exists', err.msg())
		return ctx.handle_error(perr)
	}

	if product_by_handle_count > 0 {
		handle = '${handle}-${product_id}'
	}

	store_locales := model_store_locales_retrieve(mut tx) or {
		tx.rollback() or {}
		perr := new_error_internal('Failed to retrieve store locales', err.msg())
		return ctx.handle_error(perr)
	}

	tx.rollback() or {
		perr := new_error_internal(error_transaction_rollback, err.msg())
		return ctx.handle_error(perr)
	}

	// verify all locale_id exist in store locales
	mut store_locales_exist := map[string]bool{}
	for i := 0; i < store_locales.len; i++ {
		locale := store_locales[i]
		store_locales_exist[locale.id] = true
	}

	// TODO the loop to check translation locale_id exists is the same in all translatable objects. Abstract?
	if translations := ph.translations {
		for i := 0; i < translations.len; i++ {
			translation := translations[i]
			locale_id := translation.locale_id
			if store_locales_exist[locale_id] {
				continue
			}
			perr := new_error_bad_request(error_id_invalid, 'translation locale_id')
			return ctx.handle_error(perr)
		}
	}

	if seo := ph.seo {
		if translations := seo.translations {
			for i := 0; i < translations.len; i++ {
				translation := translations[i]
				locale_id := translation.locale_id
				if store_locales_exist[locale_id] {
					continue
				}
				perr := new_error_bad_request(error_id_invalid, 'seo_translation locale_id')
				return ctx.handle_error(perr)
			}
		}
	}

	if images := ph.images {
		for i := 0; i < images.len; i++ {
			image := images[i]
			if translations := image.translations {
				for j := 0; j < translations.len; j++ {
					translation := translations[j]
					locale_id := translation.locale_id
					if store_locales_exist[locale_id] {
						continue
					}
					perr := new_error_bad_request(error_id_invalid, 'image_translation locale_id')
					return ctx.handle_error(perr)
				}
			}
		}
	}

	// if options are provided, verify locale_id are valid
	if options := ph.options {
		for i := 0; i < options.len; i++ {
			option := options[i]
			option_values := option.values

			if translations := p.translations {
				for j := 0; j < translations.len; j++ {
					translation := translations[j]
					locale_id := translation.locale_id
					if store_locales_exist[locale_id] {
						continue
					}
					perr := new_error_bad_request(error_id_invalid, 'option_translation locale_id')
					return ctx.handle_error(perr)
				}
			}

			for j := 0; j < option_values.len; j++ {
				option_value := option_values[j]
				if translations := option_value.translations {
					for k := 0; k < translations.len; k++ {
						translation := translations[k]
						locale_id := translation.locale_id
						if store_locales_exist[locale_id] {
							continue
						}
						perr := new_error_bad_request(error_id_invalid, 'option_value_translation locale_id')
						return ctx.handle_error(perr)
					}
				}
			}
		}
	}

	conduit_product_create(mut app, mut ctx, product_id, product_id_bin, handle, ph) or {
		return ctx.handle_error(err)
	}

	return ctx.handle_created()
}

// get a product by id
@['/admin/products/:product_id'; get]
pub fn (mut app App) admin_product_get(mut ctx Context, product_id string) veb.Result {
	product_id_bin := id_string_to_bin(product_id) or {
		perr := new_error_bad_request(error_id_invalid, 'product_id')
		return ctx.handle_error(perr)
	}

	ph := RetrieveProductParamsHygienised{
		ids:     ZeroArrayString{
			is_set: true
		}
		ids_bin: [product_id_bin]
	}

	return conduit_products_get_by_id(mut app, mut ctx, ph)
}

// updates a product
@['/admin/products/:product_id'; post]
pub fn (mut app App) admin_product_update(mut ctx Context, product_id string) veb.Result {
	product_id_bin := id_string_to_bin(product_id) or {
		perr := new_error_bad_request(error_id_invalid, 'product_id')
		return ctx.handle_error(perr)
	}

	p := json.decode(ProductUpdateRequest, ctx.req.data) or {
		perr := new_error_bad_request('Could not decode ProductUpdateRequest', err.msg())
		return ctx.handle_error(perr)
	}

	ph := p.hygienise() or { return ctx.handle_error(err) }

	mut tx := app.start_transaction() or { return ctx.handle_error(err) }

	mut handle := ?string(none)
	if new_handle := ph.handle {
		product_by_handle_count := model_product_retrieve_count(mut tx, RetrieveProductParamsHygienised{
			handle: ZeroString{
				is_set: true
				v:      new_handle
			}
		}) or {
			tx.rollback() or {}
			perr := new_error_internal('Could not verify handle exists', err.msg())
			return ctx.handle_error(perr)
		}

		if product_by_handle_count > 0 {
			handle = '${new_handle}-${product_id}' // TODO use
		}
	}

	seo := model_product_seo_retrieve(mut tx, [product_id_bin]) or {
		tx.rollback() or {}
		perr := new_error_internal('Could not retrieve seo', err.msg())
		return ctx.handle_error(perr)
	}

	mut images_diff := []ProductImageUpdateParams{}
	if images := ph.images {
		if images.len > 0 {
			images_diff = []ProductImageUpdateParams{len: images.len}

			// gather existing images from database
			existing_images := model_product_image_retrieve(mut tx, [
				product_id_bin,
			]) or {
				tx.rollback() or {}
				perr := new_error_internal('Failed to retrieve product_images', err.msg())
				return ctx.handle_error(perr)
			}

			// build map for fast lookup
			mut existing_images_map := map[string]ProductImage{}
			for i := 0; i < existing_images.len; i++ {
				image := existing_images[i]
				id := image.id
				existing_images_map[id] = image
			}

			for i := 0; i < images.len; i++ {
				image := images[i]
				if id := image.id {
					// handle update existing
					// if id in images does not exist return bad request
					if id !in existing_images_map {
						tx.rollback() or {}
						perr := new_error_bad_request(error_id_invalid, 'image with id ${id} does not exist')
						return ctx.handle_error(perr)
					}

					existing_image := existing_images_map[id]
					images_diff[i] = ProductImageUpdateParams{
						id:           id
						id_bin:       image.id_bin
						url:          existing_image.url
						alt:          image.alt
						translations: image.translations
					}
				} else {
					// handle new image
					id, id_bin := app.new_id()
					url := image.url or {
						tx.rollback() or {}
						perr := new_error_bad_request(error_field_empty, 'A new image must have a url')
						return ctx.handle_error(perr)
					}

					images_diff[i] = ProductImageUpdateParams{
						id:           id
						id_bin:       id_bin
						url:          url
						alt:          image.alt
						translations: image.translations
					}
				}
			}
		}
	}

	// store := model_store_retrieve(mut tx) or {
	// 	tx.rollback() or {}
	// 	return handle_error_500(mut ctx, 'Failed to retrieve store', err.msg())
	// }

	if _ := ph.translations {
		// TODO verify provided locale_id exist in database
	}

	if _ := ph.seo {
		// TODO verify all locale_id exist
	}
	// if seo_translations := ph.seo_translations {
	// 	// TODO verify provided locale_id exist in database
	// }

	tx.rollback() or {
		perr := new_error_internal(error_transaction_rollback, err.msg())
		return ctx.handle_error(perr)
	}

	if seo.len == 0 {
		perr := new_error_internal(error_database_data_malformed, 'Missing product seo for product with id ${product_id}')
		return ctx.handle_error(perr)
	}

	product_seo := seo[0]

	product_update_params := ProductUpdateParams{
		product_id:     product_id
		product_id_bin: product_id_bin
		title:          ph.title
		subtitle:       ph.subtitle
		description:    ph.description
		handle:         handle
		is_giftcard:    ph.is_giftcard
		status:         ph.status
		type_id:        ph.type_id
		type_id_bin:    ph.type_id_bin
		discountable:   ph.discountable
		metadata:       ph.metadata
	}

	return conduit_product_update(mut app, mut ctx, product_id_bin, product_seo.id_bin,
		images_diff, product_update_params, ph)
}

// deletes a product
@['/admin/products/:product_id'; delete]
pub fn (mut app App) admin_products_id_delete(mut ctx Context, product_id string) veb.Result {
	product_id_bin := id_string_to_bin(product_id) or {
		perr := new_error_bad_request(error_id_invalid, 'product_id')
		return ctx.handle_error(perr)
	}
	return conduit_product_delete(mut app, mut ctx, product_id_bin)
}

// creates a product variant
@['/admin/products/:product_id/variants/'; post]
pub fn (mut app App) admin_variant_create(mut ctx Context, product_id string) veb.Result {
	product_id_bin := id_string_to_bin(product_id) or {
		perr := new_error_bad_request(error_id_invalid, err.msg())
		return ctx.handle_error(perr)
	}

	p := json.decode(VariantCreateRequest, ctx.req.data) or {
		perr := new_error_bad_request('Could not decode VariantRequest ', err.msg())
		return ctx.handle_error(perr)
	}

	ph := p.hygienise() or { return ctx.handle_error(err) }

	if title := ph.title {
		if title == '' {
			perr := new_error_bad_request('title is required', 'title not provided')
			return ctx.handle_error(perr)
		}
	} else {
		perr := new_error_bad_request('title is required', 'title not provided')
		return ctx.handle_error(perr)
	}

	if inventory_item := ph.inventory_item {
		if inventory_item.sku == none && inventory_item.origin_country == none
			&& inventory_item.hs_code == none && inventory_item.mid_code == none
			&& inventory_item.material == none && inventory_item.weight == none
			&& inventory_item.length == none && inventory_item.height == none
			&& inventory_item.width == none && inventory_item.manage_inventory == none
			&& inventory_item.requires_shipping == none {
			perr := new_error_bad_request(error_empty_object, 'InventoryItemCreateRequest')
			return ctx.handle_error(perr)
		}
	}

	mut tx := app.start_transaction() or { return ctx.handle_error(err) }

	regions := model_region_retrieve(mut tx, RegionRetriveParams{}) or {
		tx.rollback() or {}
		perr := new_error_internal('Failed to retrieve region', err.msg())
		return ctx.handle_error(perr)
	}

	if money_amounts := ph.money_amounts {
		verify_money_amounts(money_amounts, regions) or {
			tx.rollback() or {}
			return ctx.handle_error(err)
		}
	}

	mut product_option_data := suite_product_option_data_get(mut tx, [
		product_id_bin,
	]) or {
		tx.rollback() or {}
		return ctx.handle_error(err)
	}

	product_option_data.verify_product_option_value_ids(ph.option_value_ids, ph.option_value_ids_bin) or {
		tx.rollback() or {}
		return ctx.handle_error(err)
	}

	tx.rollback() or {
		perr := new_error_internal(error_transaction_rollback, err.msg())
		return ctx.handle_error(perr)
	}

	return conduit_product_variant_create(mut app, mut ctx, product_id_bin, ph)
}

// retrieves a product_variant by its id
@['/admin/products/:product_id/variants/:variant_id'; get]
pub fn (mut app App) admin_variants_id_get(mut ctx Context, product_id string, variant_id string) veb.Result {
	_ := id_string_to_bin(product_id) or {
		perr := new_error_bad_request(error_id_invalid, 'product_id')
		return ctx.handle_error(perr)
	}

	variant_id_bin := id_string_to_bin(variant_id) or {
		perr := new_error_bad_request(error_id_invalid, 'variant_id')
		return ctx.handle_error(perr)
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
		perr := new_error_bad_request(error_id_invalid, 'product_id')
		return ctx.handle_error(perr)
	}

	variant_id_bin := id_string_to_bin(variant_id) or {
		perr := new_error_bad_request(error_id_invalid, 'variant_id')
		return ctx.handle_error(perr)
	}

	p := json.decode(VariantUpdateRequest, ctx.req.data) or {
		perr := new_error_bad_request('Could not decode VariantRequest', err.msg())
		return ctx.handle_error(perr)
	}

	ph := p.hygienise() or { return ctx.handle_error(err) }

	if inventory_item := ph.inventory_item {
		if inventory_item.sku == none && inventory_item.origin_country == none
			&& inventory_item.hs_code == none && inventory_item.mid_code == none
			&& inventory_item.material == none && inventory_item.weight == none
			&& inventory_item.length == none && inventory_item.height == none
			&& inventory_item.width == none && inventory_item.manage_inventory == none
			&& inventory_item.requires_shipping == none {
			perr := new_error_bad_request(error_empty_object, 'InventoryItemUpdateRequest')
			return ctx.handle_error(perr)
		}
	}

	mut tx := app.start_transaction() or { return ctx.handle_error(err) }

	if money_amounts := ph.money_amounts {
		regions := model_region_retrieve(mut tx, RegionRetriveParams{}) or {
			tx.rollback() or {}
			perr := new_error_internal('Failed to retrieve region', err.msg())
			return ctx.handle_error(perr)
		}

		verify_money_amounts(money_amounts, regions) or {
			tx.rollback() or {}
			return ctx.handle_error(err)
		}
	}

	if option_value_ids := ph.option_value_ids {
		mut product_option_data := suite_product_option_data_get(mut tx, [
			product_id_bin,
		]) or {
			tx.rollback() or {}
			return ctx.handle_error(err)
		}

		product_option_data.verify_product_option_value_ids(option_value_ids, ph.option_value_ids_bin) or {
			return ctx.handle_error(err)
		}
	}

	tx.rollback() or {
		perr := new_error_internal(error_transaction_rollback, err.msg())
		return ctx.handle_error(perr)
	}

	return conduit_product_variant_update(mut app, mut ctx, product_id_bin, variant_id_bin,
		ph)
}

// deletes a product variant
@['/admin/products/:product_id/variants/:variant_id'; delete]
pub fn (mut app App) admin_variants_id_delete(mut ctx Context, product_id string, variant_id string) veb.Result {
	product_id_bin := id_string_to_bin(product_id) or {
		perr := new_error_bad_request(error_id_invalid, 'product_id')
		return ctx.handle_error(perr)
	}

	variant_id_bin := id_string_to_bin(variant_id) or {
		perr := new_error_bad_request(error_id_invalid, 'variant_id')
		return ctx.handle_error(perr)
	}

	mut tx := app.start_transaction() or { return ctx.handle_error(err) }

	ph := RetrieveProductVariantParamsHygienised{
		product_ids:     ZeroArrayString{
			is_set: true
		}
		product_ids_bin: [product_id_bin]
	}

	count := model_product_variants_retrieve_count(mut tx, ph) or {
		tx.rollback() or {}
		perr := new_error_internal('Could not retrieve variants', err.msg())
		return ctx.handle_error(perr)
	}

	if count == 0 {
		tx.rollback() or {
			perr := new_error_internal(error_transaction_rollback, err.msg())
			return ctx.handle_error(perr)
		}
		perr := new_error_internal('product_variant does not exist', 'count == 0')
		return ctx.handle_error(perr)
	}

	product_variants := model_product_variants_retrieve(mut tx, ph) or {
		tx.rollback() or {}
		perr := new_error_internal('Could not retrieve product_variant', err.msg())
		return ctx.handle_error(perr)
	}

	tx.rollback() or {
		perr := new_error_internal(error_transaction_rollback, err.msg())
		return ctx.handle_error(perr)
	}

	for i := 0; i < product_variants.len; i++ {
		if product_variants[i].id_bin != variant_id_bin {
			continue
		}

		if product_variants.len == 1 {
			perr := new_error_bad_request('Cannot delete product_variant', 'A product must have at least 1 variant')
			return ctx.handle_error(perr)
		}

		inventory_item_id_bin := product_variants[i].inventory_item.id_bin
		return conduit_product_variant_delete(mut app, mut ctx, variant_id_bin, inventory_item_id_bin)
	}

	perr := new_error_not_found('no product_variant exists with given id', 'not found in variants')
	return ctx.handle_error(perr)
}
