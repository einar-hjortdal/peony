module peony

import veb

fn conduit_product_variant_get(mut app App, mut ctx Context, ph RetrieveProductVariantParamsHygienised) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	count := model_product_variants_retrieve_count(mut tx, ph) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not retrieve product_variant count', err.msg())
	}

	if count == 0 {
		tx.rollback() or { return handle_error_500(mut ctx, error_transaction_rollback, err.msg()) }
		return handle_error_404(mut ctx, 'No variant exists with the given id', 'count == 0')
	}

	product_variants := model_product_variants_retrieve(mut tx, ph) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not retrieve product_variant', err.msg())
	}

	money_amounts := model_product_variant_money_amount_retrieve(mut tx, ph.ids_bin) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not retrieve product_variant_money_amount',
			err.msg())
	}

	inventory_items := model_inventory_item_retrieve(mut tx, ph.ids_bin) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not retrieve inventory_item ', err.msg())
	}

	if inventory_items.len == 0 {
		tx.rollback() or {}
		return handle_error_500(mut ctx, error_database_data_malformed, 'inventory_item missing')
	}

	mut inventory_item := inventory_items[0]
	inventory_levels := model_inventory_level_get(mut tx, [inventory_item.id_bin]) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not retrieve inventory_level ', err.msg())
	}

	tx.rollback() or { return handle_error_500(mut ctx, error_transaction_rollback, err.msg()) }

	mut product_variant := product_variants[0]
	inventory_item.inventory_levels = inventory_levels
	product_variant.money_amounts = money_amounts
	product_variant.inventory_item = inventory_item

	external_variant := format_variant_response(product_variant)

	return ctx.json(VariantResponseEnvelope{
		variant: external_variant
	})
}

fn conduit_product_variant_create(mut app App, mut ctx Context, product_id_bin []u8, ph VariantCreateRequestHygienised) veb.Result {
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
		// TODO create model_inventory_item_create_default
		model_inventory_item_create(mut tx, inventory_item_id_bin, variant_id_bin, InventoryItemCreateRequestHygienised{}) or {
			tx.rollback() or {}
			return handle_error_500(mut ctx, 'Could not create inventory_item for product_variant',
				err.msg())
		}
	}

	model_product_variant_money_amount_update(mut app, mut tx, variant_id_bin, ph.money_amounts) or {
		tx.rollback() or {} // ignore error
		return handle_error_500(mut ctx, 'Could not update product_variant_money_amount',
			err.msg())
	}

	tx.commit() or { return handle_error_500(mut ctx, error_transaction_rollback, err.msg()) }

	return success(mut ctx)
}

fn conduit_product_variant_update(mut app App, mut ctx Context, product_id_bin []u8, variant_id_bin []u8, ph VariantUpdateRequestHygienised) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	if ph.title != none || ph.ean != none || ph.upc != none || ph.barcode != none {
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
		model_inventory_item_update(mut tx, variant_id_bin, inventory_item) or {
			tx.rollback() or {}
			return handle_error_500(mut ctx, 'Could not update inventory_item', err.msg())
		}
	}

	if money_amounts := ph.money_amounts {
		model_product_variant_money_amount_update(mut app, mut tx, variant_id_bin, money_amounts) or {
			tx.rollback() or {} // ignore error
			return handle_error_500(mut ctx, 'Could not update product_variant_money_amount',
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
