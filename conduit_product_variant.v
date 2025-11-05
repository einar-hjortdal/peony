module peony

import arrays
import log
import veb

fn conduit_product_variants_get(mut app App, mut ctx Context, ph RetrieveProductVariantParamsHygienised) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	count := model_product_variants_retrieve_count(mut tx, ph) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not retrieve product_variant count', err.msg())
	}

	if count == 0 {
		tx.rollback() or {}
		return ctx.json(VariantResponseListEnvelope{
			offset: get_offset_amount(ph.offset)
			fetch:  ph.fetch.v
		})
	}

	product_variants := model_product_variants_retrieve(mut tx, ph) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not retrieve variants', err.msg())
	}

	mut variant_map, variant_ids_bin := make_product_variant_map(product_variants)
	inventory_items := model_inventory_item_retrieve(mut tx, variant_ids_bin) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not retrieve inventory_item ', err.msg())
	}

	mut inventory_item_map, inventory_item_ids_bin := make_inventory_item_map(inventory_items)
	inventory_levels := model_inventory_level_get(mut tx, inventory_item_ids_bin) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not retrieve inventory_levels ', err.msg())
	}

	for i := 0; i < inventory_levels.len; i++ {
		inventory_level := inventory_levels[i]
		inventory_item_id := inventory_levels[i].inventory_item_id
		inventory_item_levels := inventory_item_map[inventory_item_id].inventory_levels
		new_levels := arrays.concat(inventory_item_levels, inventory_level)
		inventory_item_map[inventory_item_id].inventory_levels = new_levels
	}

	mut complete_inventory_items := []InventoryItem{len: inventory_items.len}
	for i := 0; i < inventory_items.len; i++ {
		id := inventory_items[i].id
		complete_inventory_items[i] = inventory_item_map[id]
	}

	for i := 0; i < complete_inventory_items.len; i++ {
		inventory_item := complete_inventory_items[i]
		id := inventory_item.variant_id
		variant_map[id].inventory_item = inventory_item
	}

	// rebuild array using same sorting as original array
	mut complete_product_variants := []ProductVariant{len: product_variants.len}
	for i := 0; i < product_variants.len; i++ {
		id := product_variants[i].id
		complete_product_variants[i] = variant_map[id]
	}

	tx.rollback() or { return handle_error_500(mut ctx, error_transaction_rollback, err.msg()) }

	product_variants_availability := get_product_variants_availability(GetProductVariantsAvailabilityParams{
		product_variants: complete_product_variants
	})

	mut external_variants := []ProductVariantResponse{len: complete_product_variants.len}
	for i := 0; i < complete_product_variants.len; i++ {
		external_variants[i] = format_product_variant_response_admin(complete_product_variants[i],
			product_variants_availability) or {
			log.error('Failed to format ProductVariantResponse: ${err}')
			return handle_error_500(mut ctx, error_database_data_malformed, err.msg())
		}
	}

	return ctx.json(VariantResponseListEnvelope{
		variants: external_variants
		count:    count
		offset:   get_offset_amount(ph.offset)
		fetch:    ph.fetch.v
	})
}

fn conduit_product_variant_get(mut app App, mut ctx Context, ph RetrieveProductVariantParamsHygienised) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	count := model_product_variants_retrieve_count(mut tx, ph) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not retrieve product_variant count', err.msg())
	}

	if count == 0 {
		tx.rollback() or {}
		return handle_error_404(mut ctx, 'No variant exists with the given id', 'count == 0')
	}

	product_variants := model_product_variants_retrieve(mut tx, ph) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not retrieve variants', err.msg())
	}

	mut product_variant := product_variants[0]
	inventory_items := model_inventory_item_retrieve(mut tx, [product_variant.id_bin]) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not retrieve inventory_item ', err.msg())
	}

	if inventory_items.len == 0 {
		tx.rollback() or {}
		return handle_error_500(mut ctx, error_database_data_malformed, 'inventory_item missing')
	}

	mut inventory_item := inventory_items[0]
	inventory_item.inventory_levels = model_inventory_level_get(mut tx, [inventory_item.id_bin]) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not retrieve inventory_level ', err.msg())
	}

	product_variant.inventory_item = inventory_item

	tx.rollback() or { return handle_error_500(mut ctx, error_transaction_rollback, err.msg()) }

	product_variants_availability := get_product_variants_availability(GetProductVariantsAvailabilityParams{
		product_variants: [product_variant]
	})

	external_variant := format_product_variant_response_admin(product_variant, product_variants_availability) or {
		log.error('Failed to format ProductVariantResponse: ${err}')
		return handle_error_500(mut ctx, error_database_data_malformed, err.msg())
	}

	return ctx.json(VariantResponseEnvelope{
		variant: external_variant
	})
}

fn conduit_product_variant_create(mut app App, mut ctx Context, product_id_bin []u8, ph ProductVariantRequestHygienised) veb.Result {
	_, variant_id_bin := app.new_id()
	_, inventory_item_id_bin := app.new_id()

	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	model_product_variant_create(mut tx, product_id_bin, variant_id_bin, ph) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not create product_variant', err.msg())
	}

	if inventory_item := ph.inventory_item {
		model_inventory_item_create(mut tx, inventory_item_id_bin, variant_id_bin, inventory_item) or {
			tx.rollback() or {}
			return handle_error_500(mut ctx, 'Could not create inventory_item for product_variant',
				err.msg())
		}
	} else {
		model_inventory_item_create(mut tx, inventory_item_id_bin, variant_id_bin, InventoryItemRequest{}) or {
			tx.rollback() or {}
			return handle_error_500(mut ctx, 'Could not create inventory_item for product_variant',
				err.msg())
		}
	}

	if money_amounts := ph.money_amounts {
		model_product_variant_money_amount_update(mut app, mut tx, variant_id_bin, money_amounts) or {
			tx.rollback() or {} // ignore error
			return handle_error_500(mut ctx, 'Could not update product_variant money_amount',
				err.msg())
		}
	}

	tx.commit() or { return handle_error_500(mut ctx, error_transaction_rollback, err.msg()) }

	return success(mut ctx)
}

fn conduit_product_variant_update(mut app App, mut ctx Context, product_id_bin []u8, variant_id_bin []u8, ph ProductVariantRequestHygienised) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	if ph.title != none || ph.ean != none || ph.upc != none || ph.barcode != none
		|| ph.variant_rank != none {
		model_product_variant_update(mut tx, variant_id_bin, ph) or {
			tx.rollback() or {} // ignore error
			return handle_error_500(mut ctx, 'Could not update product_variant', err.msg())
		}
	}

	if ph.option_value_ids_bin.len > 0 {
		model_product_option_value_product_variant_update(mut tx, variant_id_bin, ph.option_value_ids_bin) or {
			tx.rollback() or {}
			return handle_error_500(mut ctx, 'Could not update product_option_value',
				err.msg())
		}
	}

	if inventory_item := ph.inventory_item {
		model_product_variant_inventory_item_update(mut tx, variant_id_bin, inventory_item) or {
			tx.rollback() or {}
			return handle_error_500(mut ctx, 'Could not update inventory_item', err.msg())
		}
	}

	if money_amounts := ph.money_amounts {
		model_product_variant_money_amount_update(mut app, mut tx, variant_id_bin, money_amounts) or {
			tx.rollback() or {} // ignore error
			return handle_error_500(mut ctx, 'Could not update product_variant money_amount',
				err.msg())
		}
	}

	tx.commit() or { return handle_error_500(mut ctx, error_transaction_commit, err.msg()) }

	return success(mut ctx)
}

fn conduit_product_variant_delete(mut app App, mut ctx Context, variant_id_bin []u8, inventory_item_id_bin []u8) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	model_product_variant_delete(mut tx, variant_id_bin) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not delete product_variant', err.msg())
	}

	model_inventory_item_delete(mut tx, inventory_item_id_bin) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not delete inventory_item', err.msg())
	}

	tx.commit() or { return handle_error_500(mut ctx, error_transaction_commit, err.msg()) }

	return success(mut ctx)
}
