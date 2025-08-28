module peony

import einar_hjortdal.firebird

struct SuiteProductData {
	error                  ?SuiteError
	product_options        []ProductOption
	product_translations   []ProductTranslation
	product_images         []ProductImage
	product_sales_channels []ProductSalesChannel
	product_variants       []ProductVariant
}

fn suite_product_data_get(mut tx firebird.Transaction, product_ids_bin [][]u8) SuiteProductData {
	if product_ids_bin.len == 0 {
		return SuiteProductData{}
	}

	product_options := model_product_options_retrieve_by_product_ids(mut tx, product_ids_bin) or {
		return SuiteProductData{
			error: new_suite_error('Failed to retrieve product_option', err.msg())
		}
	}

	product_translations := model_product_translation_retrieve(mut tx, product_ids_bin) or {
		return SuiteProductData{
			error: new_suite_error('Failed to retrieve product_translation', err.msg())
		}
	}

	product_images := model_product_image_retrieve(mut tx, product_ids_bin) or {
		return SuiteProductData{
			error: new_suite_error('Failed to retrieve product_image', err.msg())
		}
	}

	product_sales_channels := model_product_sales_channel_retrieve(mut tx, product_ids_bin) or {
		return SuiteProductData{
			error: new_suite_error('Failed to retrieve product_sales_channel', err.msg())
		}
	}

	product_variants := model_product_variants_retrieve_by_product_ids(mut tx, product_ids_bin) or {
		return SuiteProductData{
			error: new_suite_error('Failed to retrieve product_variant', err.msg())
		}
	}

	return SuiteProductData{
		product_options:        product_options
		product_translations:   product_translations
		product_images:         product_images
		product_sales_channels: product_sales_channels
		product_variants:       product_variants
	}
}
