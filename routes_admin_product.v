module peony

import json
import veb
import einar_hjortdal.slugify

// lists products
@['/admin/products'; get]
pub fn (mut app App) admin_product_list(mut ctx Context) veb.Result {
	p := hygienise_product_list_query_params(ctx.query) or { return ctx.handle_error(err) }

	return conduit_product_list(mut app, mut ctx, p)
}

// create a product
@['/admin/products'; post]
pub fn (mut app App) admin_product_create(mut ctx Context) veb.Result {
	p := json.decode(ProductCreateRequest, ctx.req.data) or {
		perr := new_error_bad_request('Could not decode ProductRequest', err.msg())
		return ctx.handle_error(perr)
	}

	ph := p.hygienise() or { return ctx.handle_error(err) }

	product_id := app.gen_id()

	// generate handle from title if handle is not provided
	mut handle := p.handle or { slugify.default().make(p.title) }

	mut tx := app.start_transaction() or { return ctx.handle_error(err) }

	product_by_handle_count := model_product_retrieve_count(mut tx, ProductRetrieveParams{
		handle: handle
		fetch:  1
		offset: 0
		order:  order_direction_default
	}) or {
		tx.rollback() or {}
		perr := new_error_internal('Could not verify handle exists', err.msg())
		return ctx.handle_error(perr)
	}

	if product_by_handle_count > 0 {
		handle = '${handle}-${product_id.string()}'
		if utf8_str_visible_length(handle) > max_length_handle {
			tx.rollback() or {}
			perr := new_error_unprocessable_entity(error_field_too_long,
				error_handle_fallback_too_long)
			return ctx.handle_error(perr)
		}
	}

	store_locales := model_store_locales_retrieve(mut tx) or {
		tx.rollback() or {}
		perr := new_error_internal('Failed to retrieve store locales', err.msg())
		return ctx.handle_error(perr)
	}

	// verify all locale_id exist in store locales
	mut store_locales_exist := map[string]bool{}
	for i := 0; i < store_locales.len; i++ {
		locale := store_locales[i]
		store_locales_exist[locale.id.string()] = true
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

			if translations := option.translations {
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
						perr := new_error_bad_request(error_id_invalid,
							'option_value_translation locale_id')
						return ctx.handle_error(perr)
					}
				}
			}
		}
	}

	conduit_product_create(mut app, mut ctx, mut tx, product_id.string(), product_id.bytes(),
		handle, ph) or {
		tx.rollback() or {}
		return ctx.handle_error(err)
	}

	tx.commit() or {
		perr := new_error_internal(error_transaction_commit, err.msg())
		return ctx.handle_error(perr)
	}

	product := conduit_product_get_by_id(mut app, mut ctx, ProductRetrieveParams{
		ids:    [product_id]
		fetch:  1
		offset: 0
		order:  order_direction_default
	}) or { return ctx.handle_error(err) }

	return ctx.handle_created(ProductResponseEnvelope{
		product: product
	})
}

// get a product by id
@['/admin/products/:product_id'; get]
pub fn (mut app App) admin_product_get(mut ctx Context, product_id string) veb.Result {
	parsed_product_id := id_from_string(product_id) or {
		perr := new_error_bad_request(error_id_invalid, 'product_id')
		return ctx.handle_error(perr)
	}

	product := conduit_product_get_by_id(mut app, mut ctx, ProductRetrieveParams{
		ids:    [parsed_product_id]
		fetch:  1
		offset: 0
		order:  order_direction_default
	}) or { return ctx.handle_error(err) }

	return ctx.handle_ok(ProductResponseEnvelope{
		product: product
	})
}

// updates a product
@['/admin/products/:product_id'; post]
pub fn (mut app App) admin_product_update(mut ctx Context, product_id string) veb.Result {
	parsed_product_id := id_from_string(product_id) or {
		perr := new_error_unprocessable_entity(error_id_invalid, 'product_id')
		return ctx.handle_error(perr)
	}

	p := json.decode(ProductUpdateRequest, ctx.req.data) or {
		perr := new_error_bad_request('Could not decode ProductUpdateRequest', err.msg())
		return ctx.handle_error(perr)
	}

	ph := p.hygienise() or { return ctx.handle_error(err) }

	mut tx := app.start_transaction() or { return ctx.handle_error(err) }

	// verify the product actually exists
	pr := ProductRetrieveParams{
		ids:    [parsed_product_id]
		fetch:  1
		offset: 0
		order:  order_direction_default
	}

	count := model_product_retrieve_count(mut tx, pr) or {
		tx.rollback() or {}
		perr := new_error_internal('Could not retrieve product count by id', err.msg())
		return ctx.handle_error(perr)
	}

	if count == 0 {
		tx.rollback() or {}
		perr := new_error_internal('The product with id ${product_id} does not exist', 'count == 0')
		return ctx.handle_error(perr)
	}

	// get data to diff
	products := model_product_retrieve(mut tx, pr) or {
		tx.rollback() or {}
		perr := new_error_internal('Could not retrieve product by id', err.msg())
		return ctx.handle_error(perr)
	}

	product := products[0]

	seo := model_product_seo_retrieve(mut tx, [parsed_product_id.bytes()]) or {
		tx.rollback() or {}
		perr := new_error_internal('Could not retrieve seo', err.msg())
		return ctx.handle_error(perr)
	}

	mut handle := product.handle
	if new_handle := ph.handle {
		product_by_handle_count := model_product_retrieve_count(mut tx, ProductRetrieveParams{
			handle: new_handle
			fetch:  1
			offset: 0
			order:  order_direction_default
		}) or {
			tx.rollback() or {}
			perr := new_error_internal('Could not retrieve products by handle', err.msg())
			return ctx.handle_error(perr)
		}

		if product_by_handle_count > 0 {
			handle = '${new_handle}-${product_id}'
			if utf8_str_visible_length(new_handle) > max_length_handle {
				tx.rollback() or {}
				perr := new_error_unprocessable_entity(error_field_too_long,
					error_handle_fallback_too_long)
				return ctx.handle_error(perr)
			}
		}
	}

	product_diff := ProductUpdateParams{
		product_id:     product_id
		product_id_bin: parsed_product_id.bytes()
		title:          unwrap_option_or(ph.title, product.title)
		subtitle:       unwrap_option_or(ph.subtitle, product.subtitle.value)
		description:    unwrap_option_or(ph.description, product.description.value)
		handle:         handle
		is_giftcard:    unwrap_option_or(ph.is_giftcard, product.is_giftcard)
		status:         unwrap_option_or(ph.status, product.status)
		type_id:        unwrap_option_or(ph.type_id, product.type_id)
		type_id_bin:    unwrap_option_or(ph.type_id_bin, product.type_id_bin)
		discountable:   unwrap_option_or(ph.discountable, product.discountable)
		metadata:       unwrap_option_or(ph.metadata, product.metadata.value)
	}

	mut images_diff := []ProductImageUpdateParams{}
	if images := ph.images {
		if images.len > 0 {
			images_diff = []ProductImageUpdateParams{len: images.len}

			// gather existing images from database
			existing_images := model_product_image_retrieve(mut tx, [
				parsed_product_id.bytes(),
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
				id := image.id or {
					// handle new image
					id, id_bin := app.new_id()
					url := image.url or {
						tx.rollback() or {}
						perr := new_error_bad_request(error_field_empty,
							'A new image must have a url')
						return ctx.handle_error(perr)
					}

					images_diff[i] = ProductImageUpdateParams{
						id:           id
						id_bin:       id_bin
						url:          url
						alt:          image.alt // TODO string_value(image.alt)
						image_rank:   i
						translations: image.translations
					}
					continue
				}

				// handle update existing
				// if id in images does not exist return bad request
				if id !in existing_images_map {
					tx.rollback() or {}
					perr := new_error_bad_request(error_id_invalid,
						'image with id ${id} does not exist')
					return ctx.handle_error(perr)
				}

				existing_image := existing_images_map[id]
				images_diff[i] = ProductImageUpdateParams{
					id:           id
					id_bin:       image.id_bin
					url:          existing_image.url
					alt:          image.alt // TODO string_value(image.alt)
					image_rank:   i
					translations: image.translations
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

	if seo.len == 0 {
		perr := new_error_internal(error_database_data_malformed,
			'Missing product seo for product with id ${product_id}')
		tx.rollback() or {}
		return ctx.handle_error(perr)
	}

	product_seo := seo[0]

	conduit_product_update(mut app, mut ctx, mut tx, product_seo.id_bin, product_diff, images_diff,
		ph) or {
		tx.rollback() or {}
		return ctx.handle_error(err)
	}

	tx.commit() or {
		perr := new_error_internal(error_transaction_commit, err.msg())
		return ctx.handle_error(perr)
	}

	updated_product := conduit_product_get_by_id(mut app, mut ctx, ProductRetrieveParams{
		ids:    [parsed_product_id]
		fetch:  1
		offset: 0
		order:  order_direction_default
	}) or { return ctx.handle_error(err) }

	return ctx.handle_ok(ProductResponseEnvelope{
		product: updated_product
	})
}

// deletes a product
@['/admin/products/:product_id'; delete]
pub fn (mut app App) admin_products_id_delete(mut ctx Context, product_id string) veb.Result {
	product_id_bin := id_string_to_bin(product_id) or {
		perr := new_error_bad_request(error_id_invalid, 'product_id')
		return ctx.handle_error(perr)
	}
	conduit_product_delete(mut app, mut ctx, product_id_bin) or { return ctx.handle_error(err) }
	return ctx.handle_deleted()
}

// creates a variant
@['/admin/products/:product_id/variants/'; post]
pub fn (mut app App) variant_create(mut ctx Context, product_id string) veb.Result {
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
		if inventory_item.is_empty() {
			perr := new_error_bad_request(error_empty_object, 'InventoryItemCreateRequest')
			return ctx.handle_error(perr)
		}
	}

	mut tx := app.start_transaction() or { return ctx.handle_error(err) }

	regions := model_region_retrieve(mut tx, RegionRetriveParams{
		fetch: max_fetch
		order: order_direction_default
	}) or {
		tx.rollback() or {}
		perr := new_error_internal('Failed to retrieve region', err.msg())
		return ctx.handle_error(perr)
	}

	if regional_prices := p.regional_prices {
		// verify region ids exist
		mut regions_map := map[string]bool{}
		for i := 0; i < regions.len; i++ {
			region := regions[i]
			regions_map[region.id.string()] = true
		}

		region_ids := regional_prices.keys()
		for i := 0; i < region_ids.len; i++ {
			region_id := region_ids[i]
			if regions_map[region_id] {
				continue
			}
			perr := new_error_unprocessable_entity(error_id_invalid,
				'regional_prices contains a region id that does not exist')
			return ctx.handle_error(perr)
		}
	}

	mut product_option_data := suite_product_option_data_get(mut tx, [
		product_id_bin,
	]) or {
		tx.rollback() or {}
		return ctx.handle_error(err)
	}

	product_option_data.verify_product_option_value_ids(ph.option_value_ids,
		ph.option_value_ids_bin) or {
		tx.rollback() or {}
		return ctx.handle_error(err)
	}

	variant_id, variant_id_bin := app.new_id()
	conduit_variant_create(mut app, mut ctx, mut tx, product_id, product_id_bin, variant_id,
		variant_id_bin, ph) or {
		tx.rollback() or {}
		return ctx.handle_error(err)
	}

	rvph := RetrieveProductVariantParamsHygienised{
		ids:     ZeroArrayString{
			is_set: true
		}
		ids_bin: [variant_id_bin]
	}

	variants := model_product_variants_retrieve(mut tx, rvph) or {
		tx.rollback() or {}
		perr := new_error_internal('Could not retrieve variants after creation', err.msg())
		return ctx.handle_error(perr)
	}

	if variants.len != 1 {
		tx.rollback() or {}
		perr := new_error_internal('Could not retrieve created variant', 'varaints.len != 1')
		return ctx.handle_error(perr)
	}

	tx.commit() or {
		perr := new_error_internal(error_transaction_commit, err.msg())
		return ctx.handle_error(perr)
	}

	variant := variants[0]
	external_variant := format_variant_response(variant)
	return ctx.handle_created(VariantResponseEnvelope{
		variant: external_variant
	})
}

// retrieves a variant by its id
@['/admin/products/:product_id/variants/:variant_id'; get]
pub fn (mut app App) variant_get(mut ctx Context, product_id string, variant_id string) veb.Result {
	product_id_bin := id_string_to_bin(product_id) or {
		perr := new_error_bad_request(error_id_invalid, 'product_id')
		return ctx.handle_error(perr)
	}

	_ := id_string_to_bin(variant_id) or {
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
		tx.rollback() or {}
		perr := new_error_internal('variants for the product do not exist', 'count == 0')
		return ctx.handle_error(perr)
	}

	variants := model_product_variants_retrieve(mut tx, ph) or {
		tx.rollback() or {}
		perr := new_error_internal('Could not retrieve variants', err.msg())
		return ctx.handle_error(perr)
	}

	tx.rollback() or {}

	for i := 0; i < variants.len; i++ {
		variant := variants[i]
		if variant.id != variant_id {
			continue
		}

		external_variant := format_variant_response(variant)
		return ctx.handle_ok(VariantResponseEnvelope{
			variant: external_variant
		})
	}

	perr := new_error_not_found('variant does not exist with the given id',
		'not found in existing variants for the product')
	return ctx.handle_error(perr)
}

// updates a variant
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
		if inventory_item.is_empty() {
			perr := new_error_bad_request(error_empty_object, 'InventoryItemUpdateRequest')
			return ctx.handle_error(perr)
		}
	}

	mut tx := app.start_transaction() or { return ctx.handle_error(err) }

	rpvph := RetrieveProductVariantParamsHygienised{
		product_ids:     ZeroArrayString{
			is_set: true
		}
		product_ids_bin: [product_id_bin]
	}

	count := model_product_variants_retrieve_count(mut tx, rpvph) or {
		tx.rollback() or {}
		perr := new_error_internal('Could not retrieve variants', err.msg())
		return ctx.handle_error(perr)
	}

	if count == 0 {
		tx.rollback() or {}
		perr := new_error_internal('variants for the product do not exist', 'count == 0')
		return ctx.handle_error(perr)
	}

	variants := model_product_variants_retrieve(mut tx, rpvph) or {
		tx.rollback() or {}
		perr := new_error_internal('Could not retrieve variants', err.msg())
		return ctx.handle_error(perr)
	}

	mut found := false
	mut variant := ProductVariant{}
	for i := 0; i < variants.len; i++ {
		v := variants[i]
		if v.id != variant_id {
			continue
		}
		found = true
		variant = v
		break
	}

	if !found {
		perr := new_error_not_found('variant does not exist with the given id',
			'not found in existing variants for the product')
		return ctx.handle_error(perr)
	}

	if regional_prices := p.regional_prices {
		regions := model_region_retrieve(mut tx, RegionRetriveParams{}) or {
			tx.rollback() or {}
			perr := new_error_internal('Failed to retrieve region', err.msg())
			return ctx.handle_error(perr)
		}

		// verify region ids exist
		mut regions_map := map[string]bool{}
		for i := 0; i < regions.len; i++ {
			region := regions[i]
			regions_map[region.id.string()] = true
		}

		region_ids := regional_prices.keys()
		for i := 0; i < region_ids.len; i++ {
			region_id := region_ids[i]
			if regions_map[region_id] {
				continue
			}
			tx.rollback() or {}
			perr := new_error_unprocessable_entity(error_id_invalid,
				'regional_prices contains a region id that does not exist')
			return ctx.handle_error(perr)
		}
	}

	if option_value_ids := ph.option_value_ids {
		mut product_option_data := suite_product_option_data_get(mut tx, [
			product_id_bin,
		]) or {
			tx.rollback() or {}
			return ctx.handle_error(err)
		}

		product_option_data.verify_product_option_value_ids(option_value_ids,
			ph.option_value_ids_bin) or { return ctx.handle_error(err) }
	}

	conduit_variant_update(mut app, mut ctx, mut tx, product_id_bin, variant_id, variant_id_bin,
		variant, ph) or {
		tx.rollback() or {}
		return ctx.handle_error(err)
	}

	updated_variant := conduit_variant_get(mut app, mut ctx, mut tx, product_id, product_id_bin, RetrieveProductVariantParamsHygienised{
		ids:     ZeroArrayString{
			v:      [variant_id]
			is_set: true
		}
		ids_bin: [variant_id_bin]
	}) or {
		tx.rollback() or {}
		return ctx.handle_error(err)
	}

	tx.commit() or {
		perr := new_error_internal(error_transaction_rollback, err.msg())
		return ctx.handle_error(perr)
	}

	return ctx.handle_ok(VariantResponseEnvelope{
		variant: format_variant_response(updated_variant)
	})
}

// deletes a variant
@['/admin/products/:product_id/variants/:variant_id'; delete]
pub fn (mut app App) variant_delete(mut ctx Context, product_id string, variant_id string) veb.Result {
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
		tx.rollback() or {}
		perr := new_error_internal('variants for the product do not exist', 'count == 0')
		return ctx.handle_error(perr)
	}

	if count == 1 {
		tx.rollback() or {}
		perr := new_error_bad_request('cannot delete last variant', 'count == 1')
		return ctx.handle_error(perr)
	}

	variants := model_product_variants_retrieve(mut tx, ph) or {
		tx.rollback() or {}
		perr := new_error_internal('Could not retrieve variants', err.msg())
		return ctx.handle_error(perr)
	}

	mut found := false
	for i := 0; i < variants.len; i++ {
		variant := variants[i]
		if variant.id != variant_id {
			continue
		}
		found = true
		break
	}

	if !found {
		perr := new_error_not_found('variant does not exist with the given id',
			'not found in existing variants for the product')
		return ctx.handle_error(perr)
	}

	conduit_variant_delete(mut app, mut ctx, mut tx, variant_id_bin) or {
		tx.rollback() or {}
		return ctx.handle_error(err)
	}

	tx.commit() or {
		tx.rollback() or {}
		perr := new_error_internal(error_transaction_commit, err.msg())
		return ctx.handle_error(perr)
	}

	return ctx.handle_deleted()
}

