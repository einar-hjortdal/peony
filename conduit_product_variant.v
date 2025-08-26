module peony

import log
import veb

fn conduit_product_variants_get(mut app App, mut ctx Context, ph RetrieveProductVariantParamsHygienised) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	product_variants, count := model_product_variants_retrieve(mut tx, ph) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not retrieve variants', err.msg())
	}

	// build map for efficient lookups
	mut variant_map := map[string]ProductVariant{}
	mut variant_ids_bin := [][]u8{len: product_variants.len}
	for i := 0; i < product_variants.len; i++ {
		id := product_variants[i].id
		id_bin := product_variants[i].id_bin
		variant_map[id] = product_variants[i]
		variant_ids_bin[i] = id_bin
	}

	inventory_items := model_inventory_item_retrieve(mut tx, variant_ids_bin) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not retrieve inventory_item ', err.msg())
	}

	mut inventory_item_map := map[string]InventoryItem{}
	mut inventory_item_ids_bin := [][]u8{len: inventory_items.len}
	for i := 0; i < inventory_items.len; i++ {
		id := inventory_items[i].id
		id_bin := inventory_items[i].id_bin
		inventory_item_map[id] = inventory_items[i]
		inventory_item_ids_bin[i] = id_bin
	}

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
	mut complete_variants := []ProductVariant{len: product_variants.len}
	for i := 0; i < product_variants.len; i++ {
		id := product_variants[i].id
		complete_variants[i] = variant_map[id]
	}

	tx.rollback() or { return handle_error_500(mut ctx, error_transaction_rollback, err.msg()) }

	mut external_variants := []ProductVariantResponse{len: complete_variants.len}
	for i := 0; i < complete_variants.len; i++ {
		external_variants[i] = format_product_variant_response_admin(complete_variants[i]) or {
			log.error('Failed to format ProductVariantResponse: ${err}')
			return handle_error_500(mut ctx, error_database_data_malformed, err.msg())
		}
	}

	r := VariantResponseListEnvelope{
		variants: external_variants
		count:    count
		offset:   get_offset_amount(ph.offset)
		fetch:    get_fetch_amount(ph.fetch)
	}

	return ctx.json(r)
}

fn conduit_product_variant_get(mut app App, mut ctx Context, ph RetrieveProductVariantParamsHygienised) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	product_variants, count := model_product_variants_retrieve(mut tx, ph) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not retrieve product_variant', err.msg())
	}

	if count == 0 {
		tx.rollback() or {}
		return handle_error_404(mut ctx, 'No variant exists with the given id', 'count == 0')
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

	inventory_item := inventory_items[0]
	inventory_item.inventory_levels = model_inventory_level_get(mut tx, [inventory_item.id_bin]) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not retrieve inventory_level ', err.msg())
	}

	product_variant.inventory_item = inventory_item

	tx.rollback() or { return handle_error_500(mut ctx, error_transaction_rollback, err.msg()) }

	external_variant := format_product_variant_response_admin(product_variant) or {
		log.error('Failed to format ProductVariantResponse: ${err}')
		return handle_error_500(mut ctx, error_database_data_malformed, err.msg())
	}

	r := VariantResponseEnvelope{
		variant: external_variant
	}

	return ctx.json(r)
}

fn conduit_product_variant_create(mut app App, mut ctx Context, product_id_bin []u8, p ProductVariantRequest, povh []ProductOptionValueRequestHygienised) veb.Result {
	_, variant_id_bin := app.new_id()
	_, inventory_item_id_bin := app.new_id()

	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	model_product_variant_create(mut tx, product_id_bin, variant_id_bin, p) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not create product_variant', err.msg())
	}

	model_inventory_item_create(mut tx, inventory_item_id_bin, variant_id_bin) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not create inventory_item for product_variant',
			err.msg())
	}

	if povh.len != 0 {
		mut ids_bin := [][]u8{len: povh.len}
		for i := 0; i < povh.len; i++ {
			_, id_bin := app.new_id()
			ids_bin[i] = id_bin
		}

		model_product_option_values_create(mut tx, variant_id_bin, povh, ids_bin) or {
			tx.rollback() or {}
			return handle_error_500(mut ctx, 'Could not create product_option_value or product_option_value_translation',
				err.msg())
		}
	}

	tx.commit() or { return handle_error_500(mut ctx, error_transaction_rollback, err.msg()) }

	return ctx.json(new_peony_success())
}

fn conduit_product_variant_update(mut app App, mut ctx Context, product_id_bin []u8, variant_id_bin []u8, p ProductVariantRequest, povh []ProductOptionValueRequestHygienised, mah []MoneyAmountRequestHygienised) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	if p.title != none || p.ean != none || p.upc != none || p.barcode != none
		|| p.variant_rank != none {
		do_update_product_variant(mut tx, variant_id_bin, p) or {
			tx.rollback() or {} // ignore error
			return handle_error_500(mut ctx, 'Could not update product_variant', err.msg())
		}
	}

	if povh.len != 0 {
		model_product_option_value_update(mut tx, variant_id_bin, povh) or {
			tx.rollback() or {}
			return handle_error_500(mut ctx, 'Could not update product_option_value',
				err.msg())
		}
	}

	if mah.len != 0 {
		do_update_product_variant_money_amount(mut app, mut tx, variant_id_bin, mah) or {
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
