module peony

import einar_hjortdal.firebird

struct SuiteProductOptionData {
	product_option_translations       []ProductOptionTranslation
	product_option_values             []ProductOptionValue
	product_option_value_ids_bin      [][]u8
	product_option_value_translations []ProductOptionValueTranslation
mut:
	product_option_values_map map[string]ProductOptionValue
}

fn suite_product_option_data_get(mut tx firebird.Transaction, product_option_ids_bin [][]u8) !SuiteProductOptionData {
	if product_option_ids_bin.len == 0 {
		return SuiteProductOptionData{}
	}

	product_option_translations := model_product_option_translations_retrieve(mut tx,
		product_option_ids_bin) or {
		return new_internal_error('Failed to retrieve product_option_translations', err.msg())
	}

	// TODO provide to suite
	locale_id_bin := []u8{}

	product_option_values := model_product_option_values_retrieve(mut tx, locale_id_bin,
		product_option_ids_bin) or {
		return new_internal_error('Failed to retrieve product_option_values', err.msg())
	}

	mut product_option_values_map, product_option_value_ids_bin := make_product_option_value_map(product_option_values)
	mut product_option_value_translations := []ProductOptionValueTranslation{}
	if product_option_value_ids_bin.len > 0 {
		product_option_value_translations = model_product_option_value_translations_retrieve(mut tx,
			product_option_value_ids_bin) or {
			return new_internal_error('Failed to retrieve product_option_value_translations',
				err.msg())
		}
	}

	return SuiteProductOptionData{
		product_option_translations:       product_option_translations
		product_option_values:             product_option_values
		product_option_values_map:         product_option_values_map
		product_option_value_ids_bin:      product_option_value_ids_bin
		product_option_value_translations: product_option_value_translations
	}
}
