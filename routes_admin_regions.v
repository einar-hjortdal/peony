module peony

import net.http
import veb
import json

// lists regions
@['/admin/regions'; get]
pub fn (mut app App) admin_regions_get(mut ctx Context) veb.Result {
	// TODO validate params
	p := extract_retrieve_regions_params(ctx.query)
	return conduit_region_list(mut app, mut ctx, p)
}

// creates a region
@['/admin/regions/'; post]
pub fn (mut app App) admin_regions_post(mut ctx Context) veb.Result {
	data := json.decode(RegionRequest, ctx.req.data) or {
		return handle_error(mut ctx, http.Status.bad_request, 'Could not decode RegionRequest',
			err.msg())
	}

	if data.country_codes.len == 0 {
		return handle_error(mut ctx, http.Status.bad_request, 'A region must have at least one country',
			'country_code is an empty array')
	}

	rate_id_bin := id_string_to_bin(data.rate_id) or {
		return handle_error(mut ctx, http.Status.bad_request, error_invalid_id, err.msg())
	}

	hygienised := RegionRequestHygienised{
		automatic_taxes: data.automatic_taxes
		country_codes:   data.country_codes
		currency_code:   data.currency_code
		includes_tax:    data.includes_tax
		name:            data.name
		rate_id:         data.rate_id
		rate_id_bin:     rate_id_bin
	}

	return conduit_region_create(mut app, mut ctx, hygienised)
}

// get a region
@['/admin/regions/:region_id'; get]
pub fn (mut app App) admin_regions_region_id_get(mut ctx Context, region_id string) veb.Result {
	id_bin := id_string_to_bin(region_id) or {
		return handle_error(mut ctx, http.Status.bad_request, error_invalid_id, err.msg())
	}
	return conduit_region_get_by_id(mut app, mut ctx, id_bin)
}

// updates a region
@['/admin/regions/:region_id'; post]
pub fn (mut app App) admin_regions_region_id_post(mut ctx Context, region_id string) veb.Result {
	region_id_bin := id_string_to_bin(region_id) or {
		return handle_error(mut ctx, http.Status.bad_request, error_invalid_id, err.msg())
	}

	data := json.decode(RegionRequest, ctx.req.data) or {
		return handle_error(mut ctx, http.Status.bad_request, 'Could not decode RegionRequest',
			err.msg())
	}

	if data.country_codes.len == 0 {
		return handle_error(mut ctx, http.Status.bad_request, 'A region must have at least one country',
			'country_code is an empty array')
	}

	rate_id_bin := id_string_to_bin(data.rate_id) or {
		return handle_error(mut ctx, http.Status.bad_request, error_invalid_id, err.msg())
	}

	hygienised := RegionRequestHygienised{
		automatic_taxes: data.automatic_taxes
		country_codes:   data.country_codes
		currency_code:   data.currency_code
		includes_tax:    data.includes_tax
		name:            data.name
		rate_id:         data.rate_id
		rate_id_bin:     rate_id_bin
	}

	return conduit_region_update(mut app, mut ctx, region_id_bin, hygienised)
}
