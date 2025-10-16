module peony

import arrays
import einar_hjortdal.firebird

struct SuiteProductOptionData {
	product_options                      []ProductOption
	product_option_ids_bin               [][]u8
	product_option_translations          []ProductOptionTranslation
	product_option_values                []ProductOptionValue
	product_option_value_ids_bin         [][]u8
	product_option_value_translations    []ProductOptionValueTranslation
	product_option_value_product_variant []ProductOptionValueProductVariant
mut:
	product_options_map       map[string]ProductOption
	product_option_values_map map[string]ProductOptionValue
}

fn suite_product_option_data_get(mut tx firebird.Transaction, product_ids_bin [][]u8) !SuiteProductOptionData {
	// TODO provide to suite
	locale_id_bin := []u8{}

	product_options := model_product_options_retrieve_by_product_ids(mut tx, locale_id_bin,
		product_ids_bin) or {
		return new_internal_error('Failed to retrieve product_option', err.msg())
	}

	product_options_map, product_option_ids_bin := make_product_option_map(product_options)

	if product_option_ids_bin.len == 0 {
		return SuiteProductOptionData{}
	}

	product_option_translations := model_product_option_translations_retrieve(mut tx,
		product_option_ids_bin) or {
		return new_internal_error('Failed to retrieve product_option_translations', err.msg())
	}

	product_option_values := model_product_option_values_retrieve(mut tx, locale_id_bin,
		product_option_ids_bin) or {
		return new_internal_error('Failed to retrieve product_option_values', err.msg())
	}

	mut product_option_values_map, product_option_value_ids_bin := make_product_option_value_map(product_option_values)
	mut product_option_value_translations := []ProductOptionValueTranslation{}
	mut product_option_value_product_variant := []ProductOptionValueProductVariant{}

	if product_option_value_ids_bin.len > 0 {
		product_option_value_translations = model_product_option_value_translations_retrieve(mut tx,
			product_option_value_ids_bin) or {
			return new_internal_error('Failed to retrieve product_option_value_translations',
				err.msg())
		}

		product_option_value_product_variant = model_product_option_value_product_variant_retrieve(mut tx,
			product_option_value_ids_bin) or {
			return new_internal_error('Failed to retrieve product_option_value_product_variant',
				err.msg())
		}
	}

	return SuiteProductOptionData{
		product_options:                      product_options
		product_option_ids_bin:               product_option_ids_bin
		product_option_translations:          product_option_translations
		product_option_values:                product_option_values
		product_option_value_ids_bin:         product_option_value_ids_bin
		product_option_value_translations:    product_option_value_translations
		product_option_value_product_variant: product_option_value_product_variant
		product_options_map:                  product_options_map
		product_option_values_map:            product_option_values_map
	}
}

fn (mut s SuiteProductOptionData) assign_product_option_translations() {
	for i := 0; i < s.product_option_translations.len; i++ {
		translation := s.product_option_translations[i]
		id := translation.product_option_id
		old := s.product_options_map[id].translations
		s.product_options_map[id].translations = arrays.concat(old, translation)
	}
}

fn (mut s SuiteProductOptionData) assign_product_option_value_translations() {
	for i := 0; i < s.product_option_value_translations.len; i++ {
		translation := s.product_option_value_translations[i]
		id := translation.product_option_value_id
		old := s.product_option_values_map[id].translations
		s.product_option_values_map[id].translations = arrays.concat(old, translation)
	}
}

fn (mut s SuiteProductOptionData) assign_product_option_values() {
	for i := 0; i < s.product_option_values.len; i++ {
		product_option_value := s.product_option_values[i]
		id := product_option_value.id
		option_id := product_option_value.option_id

		complete_product_option_value := s.product_option_values_map[id]

		option_old := s.product_options_map[option_id].values
		s.product_options_map[option_id].values = arrays.concat(option_old, complete_product_option_value)
	}
}

fn (mut s SuiteProductOptionData) build_product_options() {
	s.assign_product_option_translations()
	s.assign_product_option_value_translations()
	s.assign_product_option_values()
}

// verifies that the provided array of product_option_value ids is valid for a new or updated variant.
// To be valid:
// - All ids must exist in the database.
// - There must be one id for each product_option that exists for the given product.
// - Ids must belong to different product_option.
// - There cannot exist a product_variant with the same product_option_value already.
fn (mut s SuiteProductOptionData) verify_product_option_value_ids(provided_option_value_ids []string, provided_option_value_ids_bin [][]u8) ! {
	s.build_product_options()
	mut options := []ProductOption{len: s.product_options_map.len}
	mut idx := 0
	for _, option in s.product_options_map {
		options[idx] = option
		idx++
	}

	mut existing_option_value_map := map[string]ProductOptionValue{}
	mut value_i := 0
	for i := 0; i < options.len; i++ {
		values := options[i].values
		for j := 0; j < values.len; j++ {
			value := values[j]
			id := value.id
			existing_option_value_map[id] = value
			value_i++
		}
	}

	for i := 0; i < provided_option_value_ids.len; i++ {
		option_value_id := provided_option_value_ids[i]
		if option_value_id !in existing_option_value_map {
			return new_internal_error(error_id_invalid, 'One of the option_value_id does not exist or does not belong to this product')
		}
	}

	// Verify there is exactly one id for each product_option
	mut option_value_parent_id_map := map[string]bool{}
	for i := 0; i < provided_option_value_ids.len; i++ {
		option_value_id := provided_option_value_ids[i]
		option_id := existing_option_value_map[option_value_id].option_id
		if option_id in option_value_parent_id_map {
			return new_internal_error('Duplicate value for product_option', 'Exactly one value for each product_option must be provided')
		}
		option_value_parent_id_map[option_id] = true
	}
	if option_value_parent_id_map.len != options.len {
		return new_internal_error('Value missing for product_option', 'Exactly one value for each product_option must be provided')
	}

	// Verify one variant with the same product_option_value does not exist already
	mut product_variant_product_option_value_map := map[string][][]u8{}
	for i := 0; i < s.product_option_value_product_variant.len; i++ {
		product_option_value_product_variant := s.product_option_value_product_variant[i]

		product_variant_id := product_option_value_product_variant.variant_id
		product_option_value_id_bin := product_option_value_product_variant.option_value_id_bin

		old := product_variant_product_option_value_map[product_variant_id]
		new := arrays.concat(old, product_option_value_id_bin)
		product_variant_product_option_value_map[product_variant_id] = new
	}

	for _, product_option_value_ids_bin in product_variant_product_option_value_map {
		mut variant_exists := true
		for i := 0; i < product_option_value_ids_bin.len; i++ {
			product_option_value_id_bin := product_option_value_ids_bin[i]
			if !provided_option_value_ids_bin.contains(product_option_value_id_bin) {
				variant_exists = false
				break
			}
		}
		if variant_exists {
			return new_internal_error('Variant already exists', 'A variant with the same product_option_value combination already exists.')
		}
	}
}
