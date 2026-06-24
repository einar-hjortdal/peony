module conduit

import arrays
import einar_hjortdal.luuid
import einar_hjortdal.firebird
import record
import internal.errors
import internal.common

fn get_variants_money_amounts(mut tx firebird.ClientTransaction, mut variants_map map[string]record.Variant, variant_ids []ID) ! {
	money_amounts := record.variant_money_amount_retrieve(mut tx, variant_ids) or {
		return errors.internal('Failed to retrieve product_variant_money_amount', err.msg())
	}

	for i := 0; i < money_amounts.len; i++ {
		money_amount := money_amounts[i]
		variant_id := money_amount.variant_id
		old := variants_map[variant_id.string()].money_amounts
		variants_map[variant_id.string()].money_amounts = arrays.concat(old, money_amount)
	}
}

fn get_variants_inventory_items(mut tx firebird.ClientTransaction, mut variants_map map[string]record.Variant, variant_ids []ID) ! {
	inventory_items := record.inventory_item_retrieve(mut tx, variant_ids) or {
		return errors.internal('Failed to retrieve inventory_item', err.msg())
	}

	mut item_map, item_ids := common.make_identifiable_map(inventory_items)
	get_item_availability(mut tx, mut item_map, item_ids)!
	get_inventory_items_levels(mut tx, mut item_map, item_ids)!

	for item_id, item in item_map {
		variant_id := item.variant_id.string()
		variants_map[variant_id].inventory_item = item_map[item_id]
	}
}

fn get_variants_option_values(mut tx firebird.ClientTransaction, mut variants_map map[string]record.Variant, variant_ids []ID) ! {
	option_value_variants := record.product_option_value_variant_retrieve(mut tx, record.ProductOptionValueVariantRetrieveParams{
		variant_ids: variant_ids
	}) or {
		return errors.internal('Failed to retrieve product_option_value_product_variant', err.msg())
	}

	option_values := record.product_option_values_retrieve(mut tx, record.ProductOptionValueRetrieveParams{
		variant_ids: variant_ids
	}) or { return errors.internal('Failed to retrieve product_option_value', err.msg()) }

	mut value_map, value_ids := common.make_identifiable_map(option_values)
	get_product_option_values_translations(mut tx, mut value_map, value_ids)!

	mut variant_values_map := map[string][]ID{}
	for i := 0; i < option_value_variants.len; i++ {
		variant_id := option_value_variants[i].variant_id
		value_id := option_value_variants[i].option_value_id
		old := variant_values_map[variant_id.string()]
		variant_values_map[variant_id.string()] = arrays.concat(old, value_id)
	}

	for variant_id_string, variant_value_ids in variant_values_map {
		for i := 0; i < variant_value_ids.len; i++ {
			value_id := variant_value_ids[i]
			value := value_map[value_id.string()]
			old := variants_map[variant_id_string].option_values
			variants_map[variant_id_string].option_values = arrays.concat(old, value)
		}
	}
}

pub fn variant_get(mut tx firebird.ClientTransaction, variant_id ID) !record.Variant {
	variants := record.variant_retrieve(mut tx, record.VariantRetrieveParams{
		ids:          [variant_id]
		with_deleted: false
		offset:       offset_default
		fetch:        1
		order:        order_default
	}) or { return errors.internal('Could not retrieve product_variant', err.msg()) }

	if variants.len == 0 {
		return errors.not_found('No variant found',
			'No variant exists with id `${variant_id.string()}`')
	}

	money_amounts := record.variant_money_amount_retrieve(mut tx, [variant_id]) or {
		return errors.internal('Could not retrieve product_variant_money_amount', err.msg())
	}

	inventory_items := record.inventory_item_retrieve(mut tx, [variant_id]) or {
		return errors.internal('Could not retrieve inventory_item', err.msg())
	}

	if inventory_items.len == 0 {
		return errors.internal(error_database_data_malformed, 'inventory_items.len == 0')
	}

	mut inventory_item := inventory_items[0]
	inventory_levels := record.inventory_level_retrieve(mut tx, [inventory_item.id]) or {
		return errors.internal('Could not retrieve inventory_level', err.msg())
	}

	mut variant := variants[0]
	inventory_item.inventory_levels = inventory_levels
	variant.money_amounts = money_amounts
	variant.inventory_item = inventory_item

	option_value_variants := record.product_option_value_variant_retrieve(mut tx, record.ProductOptionValueVariantRetrieveParams{
		variant_ids: [variant.id]
	}) or { return errors.internal('Could not retrieve product_option_value_variant', err.msg()) }

	mut option_value_ids := []ID{len: option_value_variants.len}
	for i := 0; i < option_value_variants.len; i++ {
		option_value_variant := option_value_variants[i]
		option_value_ids[i] = option_value_variant.option_value_id
	}

	option_values := record.product_option_values_retrieve(mut tx, record.ProductOptionValueRetrieveParams{
		ids: option_value_ids
	}) or { return errors.internal('Could not retrieve product_option_value', err.msg()) }

	option_value_translations := record.product_option_value_translations_retrieve(mut tx,
		option_value_ids) or {
		return errors.internal('Could not retrieve product_option_value_translations', err.msg())
	}

	mut option_values_map, _ := common.make_identifiable_map(option_values)

	for i := 0; i < option_value_translations.len; i++ {
		translation := option_value_translations[i]
		option_value_id := translation.option_value_id
		old := option_values_map[option_value_id.string()].translations
		option_values_map[option_value_id.string()].translations = arrays.concat(old, translation)
	}

	mut complete_option_values := []record.ProductOptionValue{len: option_value_ids.len}
	for i := 0; i < option_value_ids.len; i++ {
		option_value_id := option_value_ids[i]
		complete_option_values[i] = option_values_map[option_value_id.string()]
	}

	variant.option_values = complete_option_values

	return variant
}

// TO decide: do I create ids in routes or in conduit?
pub struct VariantMoneyAmountUpdateParams {
pub:
	// variant_id      ID // missing
	region_id ID
	// money_amount_id ID // missing
	amount      i32
	is_original ?bool
}

pub struct InventoryLevelCreateParams {
pub:
	inventory_item_id ID // missing
	stock_location_id ID
	stocked_quantity  i32
}

pub struct InventoryItemCreateParams {
pub:
	// id                ID // missing
	// variant_id        ID // missing
	sku               ?string
	origin_country    ?string
	hs_code           ?string
	mid_code          ?string
	material          ?string
	weight            ?i32
	length            ?i32
	height            ?i32
	width             ?i32
	requires_shipping bool
	manage_inventory  bool
	allow_backorder   bool
	inventory_levels  ?[]InventoryLevelCreateParams
}

pub struct VariantCreateParams {
pub:
	id             ID
	product_id     ID
	image_id       ?ID
	title          ?string
	ean            ?string
	upc            ?string
	barcode        ?string
	metadata       ?string
	variant_rank   i32
	option_values  []ID
	inventory_item ?InventoryItemCreateParams
	money_amounts  ?[]VariantMoneyAmountUpdateParams
}

fn (p VariantCreateParams) check_money_amount_region(mut tx firebird.ClientTransaction) ! {
	money_amounts := p.money_amounts or { return }
	mut given_ids := map[string]ID{}
	for i := 0; i < money_amounts.len; i++ {
		id := money_amounts[i].region_id
		given_ids[id.string()] = id
	}
	mut ids := given_ids.values()

	count := record.region_retrieve_count(mut tx, record.RegionRetriveParams{
		ids:          ids
		with_deleted: false
		offset:       offset_default // ignored by count fn
		fetch:        max_fetch      // ignored by count fn
		order:        order_default  // ignored by count fn
	}) or { return errors.internal('Failed to retrieve region', err.msg()) }

	if count != ids.len {
		// TODO return which are missing for nice error?
		return errors.unprocessable_entity(error_id_invalid,
			'money_amount region_id does not exist')
	}
}

fn (p VariantCreateParams) check_option_values(mut tx firebird.ClientTransaction) ! {
	// check given option_value ids exist
	option_values := record.product_option_values_retrieve(mut tx, record.ProductOptionValueRetrieveParams{
		ids:         p.option_values
		product_ids: [p.product_id]
	}) or { return errors.internal('Failed to retrieve product_option_value', err.msg()) }

	if option_values.len != p.option_values.len {
		return errors.unprocessable_entity(error_id_invalid,
			'product_option_value id does not exist or does not belong to the product')
	}

	// check each value belongs to different option
	mut option_ids := map[string]common.Empty{}
	for i := 0; i < option_values.len; i++ {
		option_id := option_values[i].option_id.string()
		if option_id in option_ids {
			return errors.unprocessable_entity(error_id_invalid,
				'one or more option_value share the same option parent')
		}
		option_ids[option_id] = common.Empty{}
	}

	// check number of value matches the number of options on the product
	options := record.product_option_retrieve(mut tx, [p.product_id]) or {
		return errors.internal('Failed to retrieve product_option', err.msg())
	}

	if options.len != p.option_values.len {
		return errors.unprocessable_entity('option_values amount not correct',
			'Expected one option_value for each option that exists for the product')
	}

	// check combination is unique
	value_variants := record.product_option_value_variant_retrieve(mut tx, record.ProductOptionValueVariantRetrieveParams{
		option_value_ids: p.option_values
	}) or { return errors.internal('Failed to retrieve product_option_value_variant', err.msg()) }

	mut counts := map[string]int{}
	for i := 0; i < value_variants.len; i++ {
		vv := value_variants[i]
		counts[vv.variant_id.string()]++
	}

	for _, count in counts {
		if count == p.option_values.len {
			return errors.unprocessable_entity('duplicate variant',
				'A variant with the same option values already exists')
		}
	}
}

fn (p VariantCreateParams) check(mut tx firebird.ClientTransaction) ! {
	p.check_money_amount_region(mut tx)!
	p.check_option_values(mut tx)!
}

fn (p VariantCreateParams) parse(mut g luuid.Generator) VariantCreateData {
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

	variants := model_variant_retrieve(mut tx, rvph) or {
		tx.rollback() or {}
		perr := errors.internal('Could not retrieve variants after creation', err.msg())
		return ctx.handle_error(perr)
	}

	if variants.len != 1 {
		tx.rollback() or {}
		perr := errors.internal('Could not retrieve created variant', 'varaints.len != 1')
		return ctx.handle_error(perr)
	}
}

struct VariantCreateData {
	variant          record.VariantCreateParams
	option_values    []record.ProductOptionValueVariant
	inventory_item   record.InventoryItemCreateParams
	inventory_levels ?[]record.InventoryLevelCreateParams
	money_amounts    []record.VariantMoneyAmountUpdateParams
}

// TODO rewrite params, handle inventory levels
pub fn variant_create(mut tx firebird.ClientTransaction, mut g luuid.Generator, p VariantCreateParams) ! {
	p.check(mut tx)!
	data := p.parse(mut g)

	record.variant_create(mut tx, [data.variant]) or {
		return errors.internal('Could not create product_variant', err.msg())
	}

	record.product_option_value_variant_update(mut tx, data.option_values) or {
		return errors.internal('Could not update product_option_value_variant', err.msg())
	}

	record.inventory_item_create(mut tx, [data.inventory_item]) or {
		return errors.internal('Could not create inventory_item for product_variant', err.msg())
	}

	if inventory_levels := data.inventory_levels {
		record.inventory_level_create(mut tx, inventory_levels) or {
			return errors.internal('Could not create inventory_level', err.msg())
		}
	}

	record.variant_money_amount_update(mut tx, data.money_amounts) or {
		return errors.internal('Could not update money_amounts', err.msg())
	}
}

pub struct VariantUpdateData {
	variant        record.VariantUpdateParams
	option_values  ?[]record.ProductOptionValueVariant
	inventory_item ?record.InventoryItemUpdateParams
	money_amounts  ?[]record.VariantMoneyAmountUpdateParams
}

pub fn variant_update(mut tx firebird.ClientTransaction, p VariantUpdateData) ! {
	record.variant_update(mut tx, p.variant) or {
		return errors.internal('Could not update product_variant', err.msg())
	}

	if option_values := p.option_values {
		record.product_option_value_variant_update(mut tx, option_values) or {
			return errors.internal('Could not update product_option_value_variant', err.msg())
		}
	}

	if inventory_item := p.inventory_item {
		record.inventory_item_update(mut tx, [inventory_item]) or {
			return errors.internal('Could not update inventory_item', err.msg())
		}
	}

	if money_amounts := p.money_amounts {
		record.variant_money_amount_update(mut tx, money_amounts) or {
			return errors.internal('Could not update money_amounts', err.msg())
		}
	}
}

fn variant_delete(mut tx firebird.ClientTransaction, variant_id ID) ! {
	record.variant_delete(mut tx, variant_id) or {
		return errors.internal('Could not delete variant', err.msg())
	}
}
