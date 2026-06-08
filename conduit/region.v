module conduit

import einar_hjortdal.firebird
import record

pub fn region_list_count(mut tx firebird.Transaction, p RegionRetriveParams) !i64 {
	count := record.region_retrieve_count(mut tx, p) or {
		return new_error_internal('Failed to retrieve region count', err.msg())
	}
	return count
}

pub fn region_list(mut tx firebird.Transaction, p RegionRetriveParams) ![]record.Region {
	regions := record.region_retrieve(mut tx, p) or {
		return new_error_internal('Failed to retrieve regions', err.msg())
	}

	// TODO fetch taxes
	return regions
}

pub fn region_get_by_id(mut tx firebird.Transaction, region_id ID) !record.Region {
	regions := record.region_retrieve(mut tx, RegionRetriveParams{
		ids:    [region_id]
		offset: offset_default
		fetch:  1
		order:  order_default
	}) or { return new_error_internal('Failed to retrieve region', err.msg()) }

	if regions.len == 0 {
		return new_error_not_found('region not found', 'No region exists with the given id')
	}

	region := regions[0]
	return region
}

pub fn region_create(mut tx firebird.Transaction, region_id ID, p record.RegionCreateParams) ! {
	record.region_create(mut tx, region_id, p) or {
		return new_error_internal('Could not create region', err.msg())
	}
}

pub fn region_update(mut tx firebird.Transaction, region_id ID, p record.RegionUpdateParams) ! {
	record.region_update(mut tx, region_id, p) or {
		return new_error_internal('Could not update region', err.msg())
	}
}

pub fn region_delete(mut tx firebird.Transaction, region_id ID) ! {
	record.region_delete(mut tx, region_id) or {
		return new_error_internal('Could not delete region', err.msg())
	}
}
