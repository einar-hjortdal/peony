module peony

import einar_hjortdal.firebird

struct SuiteProductOptionData {
	error                       ?SuiteError
	product_option_translations []ProductOptionTranslation
	product_option_values       []ProductOptionValue
}

fn suite_product_option_data_get(mut tx firebird.Transaction, product_option_ids_bin [][]u8) SuiteProductOptionData {
	if product_option_ids_bin.len == 0 {
		return SuiteProductOptionData{}
	}

	product_option_translations := model_product_option_translations_retrieve(mut tx,
		product_option_ids_bin) or {
		return SuiteProductOptionData{
			error: new_suite_error('Failed to retrieve product_option_translations', err.msg())
		}
	}

	product_option_values := model_product_option_values_retrieve(mut tx, product_option_ids_bin) or {
		return SuiteProductOptionData{
			error: new_suite_error('Failed to retrieve product_option_values', err.msg())
		}
	}

	return SuiteProductOptionData{
		product_option_translations: product_option_translations
		product_option_values:       product_option_values
	}
}
