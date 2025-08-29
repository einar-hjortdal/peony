module peony

import arrays
import veb

fn handle_suite_error(mut ctx Context, se SuiteError) veb.Result {
	return handle_error_500(mut ctx, se.message, se.details)
}

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
		id := translation.product_option_value_id
		old := product_option_values_map[id].translations
		product_option_values_map[id].translations = arrays.concat(old, translation)
	}
}

fn assign_product_option_values(product_option_values []ProductOptionValue, product_option_values_map map[string]ProductOptionValue, mut product_options_map map[string]ProductOption, mut product_variants_map map[string]ProductVariant) {
	for i := 0; i < product_option_values.len; i++ {
		product_option_value := product_option_values[i]
		id := product_option_value.id
		option_id := product_option_value.option_id
		variant_id := product_option_value.variant_id
		complete_product_option_value := product_option_values_map[id]

		option_old := product_options_map[option_id].values
		product_options_map[option_id].values = arrays.concat(option_old, complete_product_option_value)

		variant_old := product_variants_map[variant_id].option_values
		product_variants_map[variant_id].option_values = arrays.concat(variant_old, complete_product_option_value)
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

fn assign_product_images(product_images []ProductImage, mut products_map map[string]Product) {
	for i := 0; i < product_images.len; i++ {
		product_image := product_images[i]
		product_id := product_image.product_id
		old := products_map[product_id].images
		products_map[product_id].images = arrays.concat(old, product_image)
	}
}

fn assign_product_sales_channels(product_sales_channels []ProductSalesChannel, sales_channels_map map[string]SalesChannel, mut products_map map[string]Product) {
	for i := 0; i < product_sales_channels.len; i++ {
		product_id := product_sales_channels[i].product_id
		sales_channel_id := product_sales_channels[i].sales_channel_id
		sales_channel := sales_channels_map[sales_channel_id]
		old := products_map[product_id].sales_channels
		products_map[product_id].sales_channels = arrays.concat(old, sales_channel)
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
