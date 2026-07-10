module peony

import veb
import einar_hjortdal.firebird
import internal.conduit
import internal.errors

// lists regions
// TODO cache
@['/store/regions'; get]
pub fn (mut app App) store_region_list(mut ctx Context) veb.Result {
	p := hygienise_region_list_request_query(ctx.query) or { return ctx.handle_error(err) }

	data := app.with_rollback(fn [p] (mut tx firebird.ClientTransaction) !conduit.List[conduit.Region] {
		return conduit.region_list(mut tx, p)
	}) or { return ctx.handle_error(err) }

	return ctx.handle_ok(RegionResponseListEnvelope{
		regions: format_region_response_list(data.items)
		count:   data.count
		offset:  p.offset
		fetch:   p.fetch
	})
}

// get a region
// TODO cache
@['/store/regions/:region_id'; get]
pub fn (mut app App) store_region_get(mut ctx Context, region_id string) veb.Result {
	parsed_region_id := id_from_string(region_id) or {
		return ctx.handle_error(errors.bad_request(errors.id_invalid, 'region_id'))
	}

	region := app.with_rollback(fn [parsed_region_id] (mut tx firebird.ClientTransaction) !conduit.Region {
		return conduit.region_get(mut tx, parsed_region_id)
	}) or { return ctx.handle_error(err) }

	return ctx.handle_ok(RegionResponseEnvelope{
		region: format_region_response(region)
	})
}
