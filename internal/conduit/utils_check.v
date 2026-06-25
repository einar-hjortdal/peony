module conduit

import einar_hjortdal.firebird
import internal.common
import internal.errors
import record

// input validation that requires database access

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
			return errors.unprocessable_entity(errors.msg_id_invalid,
				'locale_id does not exist or is not enabled: `$locale_id`')
		}
	}
}

fn check_product_id_exists(mut tx firebird.ClientTransaction, product_id ID) ! {
	count := record.product_retrieve_count(mut tx, record.ProductRetrieveParams{
		ids:          [product_id]
		with_deleted: false
		offset:       offset_default // ignored by count fn
		fetch:        max_fetch      // ignored by count fn
		order:        order_default  // ignored by count fn	
	}) or { return errors.internal('Failed to retrieve product', err.msg()) }

	if count == 0 {
		return errors.not_found('No product exists with id `${product_id.string()}`', 'count == 0')
	}
}

fn check_variant_id_exists(mut tx firebird.ClientTransaction, variant_id ID) ! {
	count := record.variant_retrieve_count(mut tx, record.VariantRetrieveParams{
		ids:          [variant_id]
		with_deleted: false
		offset:       offset_default // ignored by count fn
		fetch:        max_fetch      // ignored by count fn
		order:        order_default  // ignored by count fn	
	}) or { return errors.internal('Failed to retrieve product', err.msg()) }

	if count == 0 {
		return errors.not_found('No variant exists with id `${variant_id.string()}`', 'count == 0')
	}
}
