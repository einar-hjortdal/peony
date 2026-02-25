module peony

import veb

fn conduit_product_variant_get(mut app App, mut ctx Context, ph RetrieveProductVariantParamsHygienised) veb.Result {
	mut tx := app.start_transaction() or { return ctx.handle_error(err) }

	count := model_product_variants_retrieve_count(mut tx, ph) or {
		tx.rollback() or {}
		perr := new_error_internal('Could not retrieve product_variant count', err.msg())
		return ctx.handle_error(perr)
	}

	if count == 0 {
		tx.rollback() or {
			perr := new_error_internal(error_transaction_rollback, err.msg())
			return ctx.handle_error(perr)
		}
		perr := new_error_not_found('No variant exists with the given id', 'count == 0')
		return ctx.handle_error(perr)
	}

	product_variants := model_product_variants_retrieve(mut tx, ph) or {
		tx.rollback() or {}
		perr := new_error_internal('Could not retrieve product_variant', err.msg())
		return ctx.handle_error(perr)
	}

	money_amounts := model_variant_money_amount_retrieve(mut tx, ph.ids_bin) or {
		tx.rollback() or {}
		perr := new_error_internal('Could not retrieve product_variant_money_amount',
			err.msg())
		return ctx.handle_error(perr)
	}

	inventory_items := model_inventory_item_retrieve(mut tx, ph.ids_bin) or {
		tx.rollback() or {}
		perr := new_error_internal('Could not retrieve inventory_item', err.msg())
		return ctx.handle_error(perr)
	}

	if inventory_items.len == 0 {
		tx.rollback() or {}
		perr := new_error_internal(error_database_data_malformed, 'inventory_items.len == 0')
		return ctx.handle_error(perr)
	}

	mut inventory_item := inventory_items[0]
	inventory_levels := model_inventory_level_get(mut tx, [inventory_item.id_bin]) or {
		tx.rollback() or {}
		perr := new_error_internal('Could not retrieve inventory_level', err.msg())
		return ctx.handle_error(perr)
	}

	tx.rollback() or {
		perr := new_error_internal(error_transaction_rollback, err.msg())
		return ctx.handle_error(perr)
	}

	mut product_variant := product_variants[0]
	inventory_item.inventory_levels = inventory_levels
	product_variant.money_amounts = money_amounts
	product_variant.inventory_item = inventory_item

	external_variant := format_variant_response(product_variant)

	return ctx.json(VariantResponseEnvelope{
		variant: external_variant
	})
}

fn conduit_product_variant_create(mut app App, mut ctx Context, product_id string, product_id_bin []u8, ph VariantCreateRequestHygienised) veb.Result {
	variant_id, variant_id_bin := app.new_id()
	_, inventory_item_id_bin := app.new_id()

	mut tx := app.start_transaction() or { return ctx.handle_error(err) }

	variant_to_create := VariantCreateParams{
		product_id:     product_id
		product_id_bin: product_id_bin
		variant_id:     variant_id
		variant_id_bin: variant_id_bin
		image_id:       '' // TODO
		image_id_bin:   [] // TODO
		title:          string_value(ph.title)
		barcode:        string_value(ph.barcode)
		ean:            string_value(ph.ean)
		upc:            string_value(ph.upc)
		metadata:       string_value(ph.metadata)
		variant_rank:   0 // Explicit
	}
	variants_to_create := [variant_to_create]
	model_variant_create(mut tx, variants_to_create) or {
		tx.rollback() or {}
		perr := new_error_internal('Could not create product_variant', err.msg())
		return ctx.handle_error(perr)
	}

	if inventory_item := ph.inventory_item {
		// model_inventory_item_create(mut tx) or {
		// 	tx.rollback() or {}
		// 	perr := new_error_internal('Could not create inventory_item for product_variant',
		// 		err.msg())
		// 	return ctx.handle_error(perr)
		// }
	} else {
		// TODO create model_inventory_item_create_default
		// model_inventory_item_create(mut tx, inventory_item_id_bin, variant_id_bin, InventoryItemCreateRequestHygienised{}) or {
		// 	tx.rollback() or {}
		// 	perr := new_error_internal('Could not create inventory_item for product_variant',
		// 		err.msg())
		// 	return ctx.handle_error(perr)
		// }
	}

	if _ := ph.money_amounts {
		// TODO	update variant money amounts
	} else {
		// TODO	create default variant money amounts
	}

	tx.commit() or {
		perr := new_error_internal(error_transaction_rollback, err.msg())
		return ctx.handle_error(perr)
	}

	return success(mut ctx)
}

fn conduit_product_variant_update(mut app App, mut ctx Context, product_id_bin []u8, variant_id_bin []u8, ph VariantUpdateRequestHygienised) veb.Result {
	mut tx := app.start_transaction() or { return ctx.handle_error(err) }

	if ph.title != none || ph.ean != none || ph.upc != none || ph.barcode != none {
		model_product_variant_update(mut tx, variant_id_bin, ph) or {
			tx.rollback() or {} // ignore error		
			perr := new_error_internal('Could not update product_variant', err.msg())
			return ctx.handle_error(perr)
		}
	}

	if ph.option_value_ids_bin.len > 0 {
		model_product_option_value_variant_update(mut tx, variant_id_bin, ph.option_value_ids_bin) or {
			tx.rollback() or {}
			perr := new_error_internal('Could not update product_option_value', err.msg())
			return ctx.handle_error(perr)
		}
	}

	if inventory_item := ph.inventory_item {
		model_inventory_item_update(mut tx, variant_id_bin, inventory_item) or {
			tx.rollback() or {}
			perr := new_error_internal('Could not update inventory_item', err.msg())
			return ctx.handle_error(perr)
		}
	}

	if _ := ph.money_amounts {
		// TODO	update variant money amounts
	}

	tx.commit() or {
		perr := new_error_internal(error_transaction_commit, err.msg())
		return ctx.handle_error(perr)
	}

	return success(mut ctx)
}

fn conduit_product_variant_delete(mut app App, mut ctx Context, variant_id_bin []u8, inventory_item_id_bin []u8) veb.Result {
	mut tx := app.start_transaction() or { return ctx.handle_error(err) }

	model_product_variant_delete(mut tx, variant_id_bin) or {
		tx.rollback() or {}
		perr := new_error_internal('Could not delete product_variant', err.msg())
		return ctx.handle_error(perr)
	}

	model_inventory_item_delete(mut tx, inventory_item_id_bin) or {
		tx.rollback() or {}
		perr := new_error_internal('Could not delete inventory_item', err.msg())
		return ctx.handle_error(perr)
	}

	tx.commit() or {
		perr := new_error_internal(error_transaction_commit, err.msg())
		return ctx.handle_error(perr)
	}

	return success(mut ctx)
}
