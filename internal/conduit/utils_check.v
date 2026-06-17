module conduit

import einar_hjortdal.firebird
import internal.common
import internal.errors

// input validation that requires database access

// TODO further abstract? now requests store_locales each time a translation is created/updated (many times per payload)
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
