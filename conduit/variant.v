module conduit

import arrays
import einar_hjortdal.firebird
import record

fn get_variants_money_amounts(mut tx firebird.Transaction, mut variants_map map[string]record.Variant, variant_ids []record.ID) ! {
	money_amounts := record.variant_money_amount_retrieve(mut tx, variant_ids) or {
		return new_error_internal('Failed to retrieve product_variant_money_amount', err.msg())
	}

	for i := 0; i < money_amounts.len; i++ {
		money_amount := money_amounts[i]
		variant_id := money_amount.variant_id
		old := variants_map[variant_id.string()].money_amounts
		variants_map[variant_id.string()].money_amounts = arrays.concat(old, money_amount)
	}
}

fn get_variants_inventory_items(mut tx firebird.Transaction, mut variants_map map[string]record.Variant, variant_ids []record.ID) ! {
	inventory_items := record.inventory_item_retrieve(mut tx, variant_ids) or {
		return new_error_internal('Failed to retrieve inventory_item', err.msg())
	}

	mut item_map, item_ids := make_identifiable_map(inventory_items)
	get_inventory_items_levels(mut tx, mut item_map, item_ids)!
}

fn get_variants_option_values(mut tx firebird.Transaction, mut variants_map map[string]record.Variant, variant_ids []record.ID) ! {
	option_value_variants := record.product_option_value_variant_retrieve(mut tx, record.ProductOptionValueVariantRetrieveParams{
		variant_ids: variant_ids
	}) or {
		return new_error_internal('Failed to retrieve product_option_value_product_variant',
			err.msg())
	}

	option_values := record.product_option_values_retrieve(mut tx, record.ProductOptionValueRetrieveParams{
		variant_ids: variant_ids
	}) or { return new_error_internal('Failed to retrieve product_option_value', err.msg()) }

	mut value_map, value_ids := make_identifiable_map(option_values)
	get_product_option_values_translations(mut tx, mut value_map, value_ids)!

	mut variant_values_map := map[string][]record.ID{}
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

pub fn variant_get(mut tx firebird.Transaction, variant_id record.ID) !record.Variant {
	variants := record.variant_retrieve(mut tx, record.VariantRetrieveParams{
		ids:          [variant_id]
		with_deleted: false
		offset:       offset_default
		fetch:        1
		order:        order_default
	}) or { return new_error_internal('Could not retrieve product_variant', err.msg()) }

	if variants.len == 0 {
		return new_error_not_found('No variant found',
			'No variant exists with id `${variant_id.string()}`')
	}

	money_amounts := record.variant_money_amount_retrieve(mut tx, [variant_id]) or {
		return new_error_internal('Could not retrieve product_variant_money_amount', err.msg())
	}

	inventory_items := record.inventory_item_retrieve(mut tx, [variant_id]) or {
		return new_error_internal('Could not retrieve inventory_item', err.msg())
	}

	if inventory_items.len == 0 {
		return new_error_internal(error_database_data_malformed, 'inventory_items.len == 0')
	}

	mut inventory_item := inventory_items[0]
	inventory_levels := record.inventory_level_get(mut tx, [inventory_item.id]) or {
		return new_error_internal('Could not retrieve inventory_level', err.msg())
	}

	mut variant := variants[0]
	inventory_item.inventory_levels = inventory_levels
	variant.money_amounts = money_amounts
	variant.inventory_item = inventory_item

	option_value_variants := record.product_option_value_variant_retrieve(mut tx, record.ProductOptionValueVariantRetrieveParams{
		variant_ids: [variant.id]
	}) or {
		return new_error_internal('Could not retrieve product_option_value_variant', err.msg())
	}

	mut option_value_ids := []record.ID{len: option_value_variants.len}
	for i := 0; i < option_value_variants.len; i++ {
		option_value_variant := option_value_variants[i]
		option_value_ids[i] = option_value_variant.option_value_id
	}

	option_values := record.product_option_values_retrieve(mut tx, record.ProductOptionValueRetrieveParams{
		ids: option_value_ids
	}) or { return new_error_internal('Could not retrieve product_option_value', err.msg()) }

	option_value_translations := record.product_option_value_translations_retrieve(mut tx,
		option_value_ids) or {
		return new_error_internal('Could not retrieve product_option_value_translations', err.msg())
	}

	mut option_values_map, _ := make_identifiable_map(option_values)

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

pub struct VariantCreateData {
	variant        record.VariantCreateParams
	option_values  []record.ProductOptionValueVariant
	inventory_item record.InventoryItemCreateParams
	money_amounts  []record.VariantMoneyAmountUpdateParams
}

pub fn variant_create(mut tx firebird.Transaction, p VariantCreateData) ! {
	record.variant_create(mut tx, [p.variant]) or {
		return new_error_internal('Could not create product_variant', err.msg())
	}

	record.product_option_value_variant_update(mut tx, p.option_values) or {
		return new_error_internal('Could not update product_option_value_variant', err.msg())
	}

	record.inventory_item_create(mut tx, [p.inventory_item]) or {
		return new_error_internal('Could not create inventory_item for product_variant', err.msg())
	}

	record.variant_money_amount_update(mut tx, p.money_amounts) or {
		return new_error_internal('Could not update money_amounts', err.msg())
	}
}

pub struct VariantUpdateData {
	variant        record.VariantUpdateParams
	option_values  ?[]record.ProductOptionValueVariant
	inventory_item ?record.InventoryItemUpdateParams
	money_amounts  ?[]record.VariantMoneyAmountUpdateParams
}

pub fn variant_update(mut tx firebird.Transaction, p VariantUpdateData) ! {
	record.variant_update(mut tx, p.variant) or {
		return new_error_internal('Could not update product_variant', err.msg())
	}

	if option_values := p.option_values {
		record.product_option_value_variant_update(mut tx, option_values) or {
			return new_error_internal('Could not update product_option_value_variant', err.msg())
		}
	}

	if inventory_item := p.inventory_item {
		record.inventory_item_update(mut tx, [inventory_item]) or {
			return new_error_internal('Could not update inventory_item', err.msg())
		}
	}

	if money_amounts := p.money_amounts {
		record.variant_money_amount_update(mut tx, money_amounts) or {
			return new_error_internal('Could not update money_amounts', err.msg())
		}
	}
}

fn conduit_variant_delete(mut tx firebird.Transaction, variant_id record.ID) ! {
	record.variant_delete(mut tx, variant_id) or {
		return new_error_internal('Could not delete variant', err.msg())
	}
}

