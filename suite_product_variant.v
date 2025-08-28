module peony

import einar_hjortdal.firebird

struct SuiteProductVariantData {
	error           ?SuiteError
	money_amounts   []MoneyAmount
	inventory_items []InventoryItem
}

fn suite_product_variant_data_get(mut tx firebird.Transaction, product_variant_ids_bin [][]u8) SuiteProductVariantData {
	money_amounts := model_product_variant_money_amount_retrieve(mut tx, product_variant_ids_bin) or {
		return SuiteProductVariantData{
			error: new_suite_error('Failed to retrieve product_variant_money_amount',
				err.msg())
		}
	}

	inventory_items := model_inventory_item_retrieve(mut tx, product_variant_ids_bin) or {
		return SuiteProductVariantData{
			error: new_suite_error('Failed to retrieve inventory_items', err.msg())
		}
	}

	return SuiteProductVariantData{
		money_amounts:   money_amounts
		inventory_items: inventory_items
	}
}
