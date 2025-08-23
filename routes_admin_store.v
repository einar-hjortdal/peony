module peony

import veb
import json

// gets store details
@['/admin/store/'; get]
pub fn (mut app App) admin_store_get(mut ctx Context) veb.Result {
	return conduit_store_get(mut app, mut ctx)
}

// updates store details
@['/admin/store/:id'; post]
pub fn (mut app App) admin_store_post(mut ctx Context, id string) veb.Result {
	id_bin := id_string_to_bin(id) or {
		return handle_error_400(mut ctx, error_id_invalid, err.msg())
	}

	p := json.decode(StoreRequest, ctx.req.data) or {
		return handle_error_400(mut ctx, 'Could not decode NewStoreData', err.msg())
	}

	default_locale_id_bin := option_id_string_to_id_bin(p.default_locale_id) or {
		return handle_error_400(mut ctx, error_id_invalid, 'default_locale_id')
	}

	locale_ids_bin := option_array_id_string_to_array_id_bin(p.locale_ids) or {
		return handle_error_400(mut ctx, error_id_invalid, 'locale_id')
	}

	default_stock_location_id_bin := option_id_string_to_id_bin(p.default_stock_location_id) or {
		return handle_error_400(mut ctx, error_id_invalid, 'default_stock_location_id')
	}

	default_sales_channel_id_bin := option_id_string_to_id_bin(p.default_sales_channel_id) or {
		return handle_error_400(mut ctx, error_id_invalid, 'default_sales_channel_id')
	}

	ph := StoreRequestHygienised{
		name:                          p.name
		default_locale_id:             p.default_locale_id
		default_locale_id_bin:         default_locale_id_bin
		default_currency_code:         p.default_currency_code
		default_stock_location_id:     p.default_stock_location_id
		default_stock_location_id_bin: default_stock_location_id_bin
		default_sales_channel_id:      p.default_sales_channel_id
		default_sales_channel_id_bin:  default_sales_channel_id_bin
		locale_ids:                    p.locale_ids
		locale_ids_bin:                locale_ids_bin
		currency_codes:                p.currency_codes
	}

	return conduit_store_update(mut app, mut ctx, id_bin, ph)
}
