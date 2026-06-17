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

	data := app.with_rollback(fn [p] (mut tx firebird.ClientTransaction) !ListReturn {
		count := conduit.region_list_count(mut tx, p)!
		if count == 0 {
			return ListReturn{}
		}

		regions := conduit.region_list(mut tx, p)
		return ListReturn{
			count: count
			items: regions
		}
	}) or { return ctx.handle_error() }

	if data.count == 0 {
		tx.rollback() or {}
		return ctx.json(RegionResponseListEnvelope{
			offset: p.offset
			fetch:  p.fetch
		})
	}

	mut external_regions := []RegionResponse{len: data.items.len}
	for i := 0; i < data.items.len; i++ {
		external_regions[i] = format_region_response(data.items[i])
	}

	return ctx.handle_ok(RegionResponseListEnvelope{
		regions: external_regions
		count:   count
		offset:  p.offset
		fetch:   p.fetch
	})
}

// get a region
// TODO cache
@['/store/regions/:region_id'; get]
pub fn (mut app App) store_region_get(mut ctx Context, region_id string) veb.Result {
	parsed_region_id := id_from_string(region_id) or {
		perr := new_error_bad_request(error_id_invalid, 'region_id')
		return ctx.handle_error(perr)
	}

	region := app.with_rollback(fn [parsed_region_id] (mut tx firebird.ClientTransaction) !conduit.Region {
		return conduit.region_get(mut tx, parsed_region_id)
	}) or { return ctx.handle_error() }

	return ctx.handle_ok(RegionResponseEnvelope{
		regions: format_region_response(region)
	})
}


