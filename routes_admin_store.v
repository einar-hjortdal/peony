module peony

import net.http
import veb
import json

// gets store details
@['/admin/store/'; get]
fn (mut app App) admin_store_get(mut ctx Context) veb.Result {
	internal_store := app.store_retrieve() or {
		ctx.res.set_status(http.Status.internal_server_error)
		return ctx.json(new_peony_error('Failed to retrieve store data', err.msg()))
	}

	external_store := format_store_response(internal_store)

	return ctx.json(external_store)
}

// updates store details
@['/admin/store/:id'; post]
fn (mut app App) admin_store_post(mut ctx Context, id string) veb.Result {
	id_bin := id_string_to_bin(id) or {
		ctx.res.set_status(http.Status.bad_request)
		return ctx.json(new_peony_error('Malformed id', err.msg()))
	}

	p := json.decode(StoreRequest, ctx.req.data) or {
		ctx.res.set_status(http.Status.bad_request)
		return ctx.json(new_peony_error('Could not decode NewStoreData', err.msg()))
	}

	default_locale_id_bin := option_id_string_to_id_bin(p.default_locale_id) or {
		return handle_error(mut ctx, http.Status.bad_request, 'Invalid locale id', err.msg())
	}

	locale_ids_bin := option_array_id_string_to_array_id_bin(p.locale_ids) or {
		return handle_error(mut ctx, http.Status.bad_request, 'Invalid locale id', err.msg())
	}

	default_stock_location_id_bin := option_id_string_to_id_bin(p.default_stock_location_id) or {
		return handle_error(mut ctx, http.Status.bad_request, 'Invalid stock location id',
			err.msg())
	}

	default_sales_channel_id_bin := option_id_string_to_id_bin(p.default_sales_channel_id) or {
		return handle_error(mut ctx, http.Status.bad_request, 'Invalid sales channel id',
			err.msg())
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
