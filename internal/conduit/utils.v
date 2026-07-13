module conduit

import einar_hjortdal.firebird
import einar_hjortdal.luuid
import internal.common
import internal.errors
import record
import objects

pub type ID = common.ID

pub fn new_id(mut g luuid.Generator) ID {
	return common.new_id(mut g)
}

pub fn id_from_string(s string) !ID {
	return common.id_from_string(s)
}

pub struct List[T] {
pub:
	count i64
	items []T
}

// TODO further abstract? now requests store_locales each time a translation is created/updated (many times per payload).
// Low priority: this is just needed on admin create/update requests, performance and efficiency are not critical.
// instead: gather all locale_id and select from locale. count must match or some don't exist -> error
fn check_translation_locale_ids(mut tx firebird.ClientTransaction, translations []common.Translation) ! {
	if translations.len == 0 {
		return
	}

	store_locales := store_locale_list(mut tx)!
	store_locales_map, _ := common.make_identifiable_map(store_locales)
	for i := 0; i < translations.len; i++ {
		translation := translations[i]
		locale_id := translation.locale_id().string()
		if locale_id !in store_locales_map {
			return errors.unprocessable_entity(errors.id_invalid,
				'locale_id does not exist or is not enabled: `$locale_id`')
		}
	}
}

fn check_product_id_exists(mut tx firebird.ClientTransaction, product_id ID) ! {
	count := record.product_retrieve_count(mut tx, record.ProductRetrieveParams{
		ids:          [product_id]
		with_deleted: false
		offset:       objects.offset_default // ignored by count fn
		fetch:        objects.max_fetch      // ignored by count fn
		order:        objects.order_default  // ignored by count fn	
	}) or { return errors.internal('Failed to retrieve product', err.msg()) }

	if count == 0 {
		return errors.not_found('No product exists with id `${product_id.string()}`', 'count == 0')
	}
}

fn check_variant_id_exists(mut tx firebird.ClientTransaction, variant_id ID) ! {
	count := record.variant_retrieve_count(mut tx, record.VariantRetrieveParams{
		ids:          [variant_id]
		with_deleted: false
		offset:       objects.offset_default // ignored by count fn
		fetch:        objects.max_fetch      // ignored by count fn
		order:        objects.order_default  // ignored by count fn	
	}) or { return errors.internal('Failed to retrieve product', err.msg()) }

	if count == 0 {
		return errors.not_found('No variant exists with id `${variant_id.string()}`', 'count == 0')
	}
}

fn check_money_amount_regions(mut tx firebird.ClientTransaction, p []VariantMoneyAmountUpdateParams) ! {
	mut given_ids := map[string]ID{}
	for i := 0; i < p.len; i++ {
		id := p[i].region_id
		given_ids[id.string()] = id
	}
	mut ids := given_ids.values()

	count_existing := record.region_retrieve_count(mut tx, record.RegionRetriveParams{
		ids:          ids
		with_deleted: false
		offset:       objects.offset_default // ignored by count fn
		fetch:        objects.max_fetch      // ignored by count fn
		order:        objects.order_default  // ignored by count fn
	}) or { return errors.internal('Failed to retrieve region', err.msg()) }

	if count_existing != ids.len {
		// TODO return which are missing for nice error?
		return errors.unprocessable_entity(errors.id_invalid,
			'money_amount region_id does not exist')
	}

	// check there is one given_id for each existing region
	count_region := record.region_retrieve_count(mut tx, record.RegionRetriveParams{
		with_deleted: false
		offset:       objects.offset_default // ignored by count fn
		fetch:        objects.max_fetch      // ignored by count fn
		order:        objects.order_default  // ignored by count fn
	}) or { return errors.internal('Failed to retrieve region', err.msg()) }

	if count_region != ids.len {
		return errors.unprocessable_entity('Regional price missing',
			'Every region must have one price')
	}
}

fn check_option_values(mut tx firebird.ClientTransaction, product_id ID, option_value_ids []ID) ! {
	// check given option_value ids exist
	option_values := record.product_option_values_retrieve(mut tx, record.ProductOptionValueRetrieveParams{
		ids:         option_value_ids
		product_ids: [product_id]
	}) or { return errors.internal('Failed to retrieve product_option_value', err.msg()) }

	if option_values.len != option_value_ids.len {
		return errors.unprocessable_entity(errors.id_invalid,
			'product_option_value id does not exist or does not belong to the product')
	}

	// check each value belongs to different option
	mut option_ids := map[string]common.Empty{}
	for i := 0; i < option_values.len; i++ {
		option_id := option_values[i].option_id.string()
		if option_id in option_ids {
			return errors.unprocessable_entity(errors.id_invalid,
				'one or more option_value share the same option parent')
		}
		option_ids[option_id] = common.Empty{}
	}

	// check number of value matches the number of options on the product
	options := record.product_option_retrieve(mut tx, [product_id]) or {
		return errors.internal('Failed to retrieve product_option', err.msg())
	}

	if options.len != option_value_ids.len {
		return errors.unprocessable_entity('option_values amount not correct',
			'Expected one option_value for each option that exists for the product')
	}

	// check combination is unique
	value_variants := record.product_option_value_variant_retrieve(mut tx, record.ProductOptionValueVariantRetrieveParams{
		option_value_ids: option_value_ids
	}) or { return errors.internal('Failed to retrieve product_option_value_variant', err.msg()) }

	mut counts := map[string]int{}
	for i := 0; i < value_variants.len; i++ {
		vv := value_variants[i]
		counts[vv.variant_id.string()]++
	}

	for _, count in counts {
		if count == option_value_ids.len {
			return errors.unprocessable_entity('duplicate variant',
				'A variant with the same option values already exists')
		}
	}
}

fn check_image_id_belongs_to_product(mut tx firebird.ClientTransaction, product_id ID, image_id ID) ! {
	images := record.product_image_retrieve(mut tx, record.ProductImageRetrieveParams{
		image_ids:   [image_id]
		product_ids: [product_id]
	}) or { return errors.internal('Failed to retrieve product_image', err.msg()) }

	for i := 0; i < images.len; i++ {
		image := images[i]
		if image.id.string() == image_id.string() {
			return
		}
	}

	return errors.unprocessable_entity(errors.id_invalid,
		'image_id does not exist or does not belong to product')
}

fn check_product_handle(mut tx firebird.ClientTransaction, handle string) ! {
	count := record.product_retrieve_count(mut tx, record.ProductRetrieveParams{
		handle:       handle
		with_deleted: false
		offset:       objects.offset_default // ignored by count fn
		fetch:        objects.min_fetch      // ignored by count fn
		order:        objects.order_default  // ignored by count fn
	}) or { return errors.internal('Failed to retrieve product count', err.msg()) }

	if count != 0 {
		return errors.unprocessable_entity('handle not unique',
			'A product already exists with the given handle')
	}
}
