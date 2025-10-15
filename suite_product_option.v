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

	product_options := model_product_options_retrieve_by_product_ids(mut tx, product_ids_bin) or {
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
