module conduit

import einar_hjortdal.firebird
import record
import arrays

fn get_product_option_translations(mut tx firebird.ClientTransaction, mut options_map map[string]record.ProductOption, option_ids []ID) ! {
	translations := record.product_option_translations_retrieve(mut tx, option_ids) or {
		return new_error_internal('Failed to retrieve product_option_translations', err.msg())
	}

	for i := 0; i < translations.len; i++ {
		translation := translations[i]
		option_id := translation.product_option_id
		old := options_map[option_id.string()].translations
		options_map[option_id.string()].translations = arrays.concat(old, translation)
	}
}

fn get_product_option_values_translations(mut tx firebird.ClientTransaction, mut value_map map[string]record.ProductOptionValue, value_ids []ID) ! {
	translations := record.product_option_value_translations_retrieve(mut tx, value_ids) or {
		return new_error_internal('Failed to retrieve product_option_value_translations', err.msg())
	}

	for i := 0; i < translations.len; i++ {
		translation := translations[i]
		value_id := translation.option_value_id
		old := value_map[value_id.string()].translations
		value_map[value_id.string()].translations = arrays.concat(old, translation)
	}
}

fn get_product_option_values(mut tx firebird.ClientTransaction, mut options_map map[string]record.ProductOption, option_ids []ID) ! {
	values := record.product_option_values_retrieve(mut tx, record.ProductOptionValueRetrieveParams{
		option_ids: option_ids
	}) or { return new_error_internal('Failed to retrieve product_option_values', err.msg()) }

	mut value_map, value_ids := make_identifiable_map(values)
	get_product_option_values_translations(mut tx, mut value_map, value_ids)!

	for i := 0; i < values.len; i++ {
		value := values[i]
		value_id := value.id
		option_id := value.option_id
		complete_value := value_map[value_id.string()]
		old := options_map[option_id.string()].values
		options_map[option_id.string()].values = arrays.concat(old, complete_value)
	}
}
