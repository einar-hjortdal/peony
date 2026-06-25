module peony

import veb
import einar_hjortdal.firebird
import internal.conduit
import internal.errors

// gets store details
@['/admin/store/'; get]
pub fn (mut app App) admin_store_get(mut ctx Context) veb.Result {
	store := app.with_rollback(fn (mut tx firebird.ClientTransaction) !conduit.Store {
		return conduit.store_get(mut tx)
	}) or { return ctx.handle_error(err) }

	return ctx.handle_ok(StoreResponseEnvelope{
		store: format_store_response(store)
	})
}

// updates store details
@['/admin/store/:store_id'; post]
pub fn (mut app App) admin_store_post(mut ctx Context, store_id string) veb.Result {
	parsed_store_id := id_from_string(store_id) or {
		return ctx.handle_error(errors.bad_request(errors.id_invalid, 'store_id'))
	}

	p := hygienise_store_request(ctx.req.data, parsed_store_id) or { return ctx.handle_error(err) }

	store := app.with_commit(fn [p] (mut tx firebird.ClientTransaction) !conduit.Store {
		conduit.store_update(mut tx, p)!
		return conduit.store_get(mut tx)
	}) or { return ctx.handle_error(err) }

	return ctx.handle_ok(StoreResponseEnvelope{
		store: format_store_response(store)
	})
}
