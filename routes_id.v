module peony

import veb

// returns a new [lexical_uuid](https://github.com/einar-hjortdal/lexical_uuid)
@['/admin/id'; get]
pub fn (mut app App) admin_id_get(mut ctx Context) veb.Result {
	id := app.gen_id()
	return ctx.json(IDResponseEnvelope{ id: id.string() })
}

// returns a new [lexical_uuid](https://github.com/einar-hjortdal/lexical_uuid)
@['/store/id'; get]
pub fn (mut app App) store_id_get(mut ctx Context) veb.Result {
	id := app.gen_id()
	return ctx.json(IDResponseEnvelope{ id: id.string() })
}
