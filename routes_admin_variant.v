module peony

import veb
import einar_hjortdal.firebird
import internal.conduit
import internal.errors

// retrieves a variant by its id
@['/admin/variants/:variant_id'; get]
pub fn (mut app App) variant_get(mut ctx Context, variant_id string) veb.Result {
	parsed_variant_id := id_from_string(variant_id) or {
		return ctx.handle_error(errors.bad_request(errors.id_invalid, 'variant_id'))
	}

	variant := app.with_rollback(fn [parsed_variant_id] (mut tx firebird.ClientTransaction) !conduit.Variant {
		return conduit.variant_get(mut tx, parsed_variant_id)
	}) or { return ctx.handle_error(err) }

	return ctx.handle_ok(VariantResponseEnvelope{
		variant: format_variant_response(variant)
	})
}
