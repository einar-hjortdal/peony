module peony

import arrays
import einar_hjortdal.firebird

struct SuiteProductVariantData {
	money_amounts          []VariantMoneyAmount
	inventory_items        []InventoryItem
	inventory_item_ids_bin [][]u8
	inventory_levels       []InventoryLevel
mut:
	inventory_item_map map[string]InventoryItem
}

fn suite_product_variant_data_get(mut tx firebird.Transaction, product_variant_ids_bin [][]u8) !SuiteProductVariantData {
	if product_variant_ids_bin.len == 0 {
		return SuiteProductVariantData{}
	}

	money_amounts := model_variant_money_amount_retrieve(mut tx, product_variant_ids_bin) or {
		return new_error_internal('Failed to retrieve product_variant_money_amount', err.msg())
	}

	inventory_items := model_inventory_item_retrieve(mut tx, product_variant_ids_bin) or {
		return new_error_internal('Failed to retrieve inventory_item', err.msg())
	}

	mut inventory_item_map, inventory_item_ids_bin := make_inventory_item_map(inventory_items)

	inventory_levels := model_inventory_level_get(mut tx, inventory_item_ids_bin) or {
		return new_error_internal('Failed to retrieve inventory_level', err.msg())
	}

	return SuiteProductVariantData{
		money_amounts:          money_amounts
		inventory_items:        inventory_items
		inventory_item_ids_bin: inventory_item_ids_bin
		inventory_item_map:     inventory_item_map
		inventory_levels:       inventory_levels
	}
}

fn (mut s SuiteProductVariantData) assign_inventory_levels() {
	for i := 0; i < s.inventory_levels.len; i++ {
		inventory_level := s.inventory_levels[i]
		inventory_item_id := s.inventory_levels[i].inventory_item_id
		inventory_item_levels := s.inventory_item_map[inventory_item_id].inventory_levels
		new_levels := arrays.concat(inventory_item_levels, inventory_level)
		s.inventory_item_map[inventory_item_id].inventory_levels = new_levels
	}
}
