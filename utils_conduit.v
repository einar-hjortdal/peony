module peony

import arrays

fn assign_product_option_translations(product_option_translations []ProductOptionTranslation, mut product_options_map map[string]ProductOption) {
	for i := 0; i < product_option_translations.len; i++ {
		translation := product_option_translations[i]
		id := translation.product_option_id
		old := product_options_map[id].translations
		product_options_map[id].translations = arrays.concat(old, translation)
	}
}

fn assign_product_option_value_translations(product_option_value_translations []ProductOptionValueTranslation, mut product_option_values_map map[string]ProductOptionValue) {
	for i := 0; i < product_option_value_translations.len; i++ {
		translation := product_option_value_translations[i]
		id := translation.option_value_id
		old := product_option_values_map[id].translations
		product_option_values_map[id].translations = arrays.concat(old, translation)
	}
}

fn assign_product_option_values(product_option_values []ProductOptionValue, product_option_value_product_variant []ProductOptionValueProductVariant, product_option_values_map map[string]ProductOptionValue, mut product_options_map map[string]ProductOption, mut product_variants_map map[string]ProductVariant) {
	mut product_option_value_product_variant_map := map[string][]string{}
	for i := 0; i < product_option_value_product_variant.len; i++ {
		product_option_value_id := product_option_value_product_variant[i].option_value_id
		variant_id := product_option_value_product_variant[i].variant_id
		old_variants := product_option_value_product_variant_map[product_option_value_id]
		new_variants := arrays.concat(old_variants, variant_id)
		product_option_value_product_variant_map[product_option_value_id] = new_variants
	}

	for product_option_value_id, product_variant_ids in product_option_value_product_variant_map {
		product_option_value := product_option_values_map[product_option_value_id]
		for i := 0; i < product_variant_ids.len; i++ {
			product_variant_id := product_variant_ids[i]
			mut product_variant := product_variants_map[product_variant_id]
			values_old := product_variant.option_values
			values_new := arrays.concat(values_old, product_option_value)
			product_variant.option_values = values_new
			product_variants_map[product_variant_id] = product_variant
		}
	}

	for i := 0; i < product_option_values.len; i++ {
		product_option_value := product_option_values[i]
		id := product_option_value.id
		option_id := product_option_value.option_id

		complete_product_option_value := product_option_values_map[id]

		option_old := product_options_map[option_id].values
		product_options_map[option_id].values = arrays.concat(option_old, complete_product_option_value)
	}
}

fn assign_product_options(product_options []ProductOption, product_options_map map[string]ProductOption, mut products_map map[string]Product) {
	for i := 0; i < product_options.len; i++ {
		option := product_options[i]
		option_id := option.id
		product_id := option.product_id
		complete_product_option := product_options_map[option_id]

		old := products_map[product_id].options
		products_map[product_id].options = arrays.concat(old, complete_product_option)
	}
}

fn assign_product_translations(product_translations []ProductTranslation, mut products_map map[string]Product) {
	for i := 0; i < product_translations.len; i++ {
		translation := product_translations[i]
		product_id := translation.product_id
		old := products_map[product_id].translations
		products_map[product_id].translations = arrays.concat(old, translation)
	}
}

fn assign_product_category_ids(pcps []ProductCategoryProduct, mut products_map map[string]Product) {
	for i := 0; i < pcps.len; i++ {
		pcp := pcps[i]
		product_id := pcp.product_id
		old_ids := products_map[product_id].category_ids
		old_ids_bin := products_map[product_id].category_ids_bin
		new_ids := arrays.concat(old_ids, pcp.product_category_id)
		new_ids_bin := arrays.concat(old_ids_bin, pcp.product_category_id_bin)
		products_map[product_id].category_ids = new_ids
		products_map[product_id].category_ids_bin = new_ids_bin
	}
}

fn assign_product_images(product_images []ProductImage, mut products_map map[string]Product) {
	for i := 0; i < product_images.len; i++ {
		product_image := product_images[i]
		product_id := product_image.product_id
		old := products_map[product_id].images
		products_map[product_id].images = arrays.concat(old, product_image)
	}
}

fn assign_product_sales_channel_ids(pscs []ProductSalesChannel, mut products_map map[string]Product) {
	for i := 0; i < pscs.len; i++ {
		psc := pscs[i]
		product_id := psc.product_id
		old_ids := products_map[product_id].sales_channels_ids
		old_ids_bin := products_map[product_id].sales_channels_ids_bin
		new_ids := arrays.concat(old_ids, psc.sales_channel_id)
		new_ids_bin := arrays.concat(old_ids_bin, psc.sales_channel_id_bin)
		products_map[product_id].sales_channels_ids = new_ids
		products_map[product_id].sales_channels_ids_bin = new_ids_bin
	}
}

fn assign_product_variant_money_amounts(money_amounts []MoneyAmount, mut product_variants_map map[string]ProductVariant) {
	for i := 0; i < money_amounts.len; i++ {
		money_amount := money_amounts[i]
		variant_id := id_bin_to_string(money_amount.variant_id_bin.value) or { panic(err) } // database corrupted
		old := product_variants_map[variant_id].money_amounts
		product_variants_map[variant_id].money_amounts = arrays.concat(old, money_amount)
	}
}

fn assign_inventory_items(inventory_items []InventoryItem, mut product_variants_map map[string]ProductVariant) {
	for i := 0; i < inventory_items.len; i++ {
		inventory_item := inventory_items[i]
		variant_id := inventory_item.variant_id
		product_variants_map[variant_id].inventory_item = inventory_item
	}
}

fn assign_product_variants(product_variants []ProductVariant, product_variants_map map[string]ProductVariant, mut products_map map[string]Product) {
	for i := 0; i < product_variants.len; i++ {
		variant_id := product_variants[i].id
		variant := product_variants_map[variant_id]
		product_id := variant.product_id
		old := products_map[product_id].variants
		products_map[product_id].variants = arrays.concat(old, variant)
	}
}

fn assign_seo_translations(seo_translations []ProductSEOTranslation, mut products_map map[string]Product) {
	for i := 0; i < seo_translations.len; i++ {
		translation := seo_translations[i]
		product_id := translation.product_id
		old := products_map[product_id].seo_translations
		products_map[product_id].seo_translations = arrays.concat(old, translation)
	}
}

fn assign_products_data(mut products_data SuiteProductData, mut products_map map[string]Product) {
	assign_product_variant_money_amounts(products_data.money_amounts, mut products_data.product_variants_map)
	assign_inventory_items(products_data.inventory_items, mut products_data.product_variants_map)

	// TODO variant_image

	assign_product_option_translations(products_data.product_option_translations, mut
		products_data.product_options_map)
	assign_product_option_value_translations(products_data.product_option_value_translations, mut
		products_data.product_option_values_map)

	assign_product_option_values(products_data.product_option_values, products_data.product_option_value_product_variant,
		products_data.product_option_values_map, mut products_data.product_options_map, mut
		products_data.product_variants_map)

	assign_product_options(products_data.product_options, products_data.product_options_map, mut
		products_map)

	assign_product_translations(products_data.product_translations, mut products_map)

	assign_product_category_ids(products_data.product_category_product, mut products_map)

	assign_product_images(products_data.product_images, mut products_map)

	assign_product_sales_channel_ids(products_data.product_sales_channels, mut products_map)

	assign_product_variants(products_data.product_variants, products_data.product_variants_map, mut
		products_map)

	assign_seo_translations(products_data.seo_translations, mut products_map)
}

fn assign_product_data(mut product_data SuiteProductData, mut product Product) {
	product_id := product.id
	mut product_map := {
		product_id: product
	}
	assign_products_data(mut product_data, mut product_map)
	product = product_map[product.id]
}
