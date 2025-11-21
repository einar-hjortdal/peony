module peony

import einar_hjortdal.firebird

struct SuiteProductData {
	SuiteProductOptionData
	SuiteProductVariantData
	product_translations     []ProductTranslation
	product_category_product []ProductCategoryProduct
	product_images           []ProductImage
	product_sales_channels   []ProductSalesChannel
	product_variants         []ProductVariant
	product_variant_ids_bin  [][]u8
	seo_translations         []ProductSEOTranslation
mut:
	product_variants_map map[string]ProductVariant
}

fn suite_product_data_get(mut tx firebird.Transaction, product_ids_bin [][]u8) !SuiteProductData {
	if product_ids_bin.len == 0 {
		return SuiteProductData{}
	}

	// locale_id_bin := [][]u8{} // TODO provide request context

	product_options_data := suite_product_option_data_get(mut tx, product_ids_bin)!

	product_translations := model_product_translation_retrieve(mut tx, product_ids_bin) or {
		return new_internal_error('Failed to retrieve product_translation', err.msg())
	}

	pcpp := ProductCategoryProductRetrieveParams{
		product_ids_bin: product_ids_bin
	}
	product_category_product := model_product_category_product_retrieve(mut tx, pcpp) or {
		return new_internal_error('Failed to retrieve product_category_product', err.msg())
	}

	product_images := model_product_image_retrieve(mut tx, []u8{}, product_ids_bin) or {
		return new_internal_error('Failed to retrieve product_image', err.msg())
	}
	// TODO image translations

	product_sales_channels := model_product_sales_channel_retrieve(mut tx, product_ids_bin) or {
		return new_internal_error('Failed to retrieve product_sales_channel', err.msg())
	}

	product_variants := model_product_variants_retrieve_by_product_ids(mut tx, product_ids_bin) or {
		return new_internal_error('Failed to retrieve product_variant', err.msg())
	}

	product_variants_map, product_variant_ids_bin := make_product_variant_map(product_variants)
	variants_data := suite_product_variant_data_get(mut tx, product_variant_ids_bin)!

	seo_translations := model_product_seo_retrieve(mut tx, product_ids_bin) or {
		return new_internal_error('Failed to retrieve seo_translations', err.msg())
	}

	return SuiteProductData{
		SuiteProductOptionData:   product_options_data
		SuiteProductVariantData:  variants_data
		product_translations:     product_translations
		product_category_product: product_category_product
		product_images:           product_images
		product_sales_channels:   product_sales_channels
		product_variants:         product_variants
		product_variants_map:     product_variants_map
		product_variant_ids_bin:  product_variant_ids_bin
		seo_translations:         seo_translations
	}
}
