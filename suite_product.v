module peony

import einar_hjortdal.firebird

struct SuiteProductData {
	SuiteProductOptionData
	SuiteProductVariantData
	product_translations       []ProductTranslation
	category_product           []CategoryProduct
	product_images             []ProductImage
	product_image_ids_bin      [][]u8
	product_image_translations []ImageTranslation
	product_sales_channels     []ProductSalesChannel
	variants                   []ProductVariant
	variant_ids_bin            [][]u8
	product_seo                []ProductSEO
	product_seo_ids_bin        [][]u8
	product_seo_translations   []SEOTranslation
mut:
	product_images_map map[string]ProductImage
	variants_map       map[string]ProductVariant
	product_seo_map    map[string]ProductSEO
}

fn suite_product_data_get(mut tx firebird.Transaction, product_ids []ID) !SuiteProductData {
	if product_ids.len == 0 {
		return SuiteProductData{}
	}

	product_ids_bin := ids_bytes(product_ids) // TODO remove

	product_options_data := suite_product_option_data_get(mut tx, product_ids_bin) or {
		return new_error_internal('Failed to retrieve product_options', err.msg())
	}

	product_translations := model_product_translations_retrieve(mut tx, product_ids_bin) or {
		return new_error_internal('Failed to retrieve product_translation', err.msg())
	}

	cprp := CategoryProductRetrieveParams{
		product_ids_bin: product_ids_bin
	}
	category_product := model_category_product_retrieve(mut tx, cprp) or {
		return new_error_internal('Failed to retrieve category_product', err.msg())
	}

	product_images := model_product_image_retrieve(mut tx, product_ids_bin) or {
		return new_error_internal('Failed to retrieve product_image', err.msg())
	}

	mut images_map := map[string]ProductImage{}
	mut image_ids_bin := [][]u8{len: product_images.len}
	for i := 0; i < product_images.len; i++ {
		image := product_images[i]
		id := image.id
		id_bin := image.id_bin
		images_map[id] = image
		image_ids_bin[i] = id_bin
	}

	mut image_translations := []ImageTranslation{}
	if image_ids_bin.len > 0 {
		image_translations = model_image_translation_retrieve(mut tx, image_ids_bin) or {
			return new_error_internal('Failed to retrieve image_translation', err.msg())
		}
	}

	product_sales_channels := model_product_sales_channel_retrieve(mut tx, product_ids_bin) or {
		return new_error_internal('Failed to retrieve product_sales_channel', err.msg())
	}

	// TODO loop for pagination
	variants := model_variant_retrieve(mut tx, VariantRetrieveParams{
		product_ids:  [product_ids]
		with_deleted: false
		offset:       offset_default
		fetch:        max_fetch
		order:        order_default
	}) or { return new_error_internal('Failed to retrieve product_variant', err.msg()) }

	variants_map, variant_ids_bin := make_product_variant_map(variants)
	variants_data := suite_product_variant_data_get(mut tx, variant_ids_bin)!

	seo := model_product_seo_retrieve(mut tx, product_ids_bin) or {
		return new_error_internal('Failed to retrieve seo', err.msg())
	}

	mut seo_ids_bin := [][]u8{len: seo.len}
	mut seo_map := map[string]ProductSEO{}
	for i := 0; i < seo.len; i++ {
		id := seo[i].id
		id_bin := seo[i].id_bin
		seo_map[id] = seo[i]
		seo_ids_bin[i] = id_bin
	}

	seo_translations := model_seo_translation_retrieve(mut tx, seo_ids_bin) or {
		return new_error_internal('Failed to retrieve seo_translations', err.msg())
	}

	return SuiteProductData{
		SuiteProductOptionData:     product_options_data
		SuiteProductVariantData:    variants_data
		product_translations:       product_translations
		category_product:           category_product
		product_images:             product_images
		product_image_ids_bin:      image_ids_bin
		product_images_map:         images_map
		product_image_translations: image_translations
		product_sales_channels:     product_sales_channels
		variants:                   variants
		variants_map:               variants_map
		variant_ids_bin:            variant_ids_bin
		product_seo:                seo
		product_seo_map:            seo_map
		product_seo_ids_bin:        seo_ids_bin
		product_seo_translations:   seo_translations
	}
}

