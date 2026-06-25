module conduit

import einar_hjortdal.firebird
import record
import internal.errors

pub fn region_list(mut tx firebird.ClientTransaction, p RegionRetriveParams) !List[Region] {
	count := record.region_retrieve_count(mut tx, p) or {
		return errors.internal('Failed to retrieve region count', err.msg())
	}

	if count == 0 {
		return List[Region]{}
	}

	regions := record.region_retrieve(mut tx, p) or {
		return errors.internal('Failed to retrieve regions', err.msg())
	}

	if regions.len == 0 {
		return List[Region]{
			count: count
		}
	}

	// TODO fetch taxes

	return List[Region]{
		count: count
		items: regions
	}
}

pub fn region_get(mut tx firebird.ClientTransaction, region_id ID) !record.Region {
	regions := record.region_retrieve(mut tx, RegionRetriveParams{
		ids:    [region_id]
		offset: offset_default
		fetch:  1
		order:  order_default
	}) or { return errors.internal('Failed to retrieve region', err.msg()) }

	if regions.len == 0 {
		return errors.not_found('region not found', 'No region exists with the given id')
	}

	region := regions[0]
	return region
}

pub struct RegionCreateParams {
pub:
	id                 ID
	name               string
	currency_code      string
	includes_tax       bool
	gift_cards_taxable bool
	automatic_taxes    bool
	country_codes      []string
	// taxes
}

fn check_countries_have_no_region(mut tx firebird.ClientTransaction, country_codes []string) ! {
	if country_codes.len == 0 {
		return
	}

	countries := record.country_retrieve(mut tx, CountryRetrieveParams{
		codes:  country_codes
		offset: offset_default
		fetch:  country_codes.len
		order:  order_default
	}) or { return errors.internal('Failed to retrieve country', err.msg()) }

	for i := 0; i < countries.len; i++ {
		country := countries[i]
		if region_id := country.region_id {
			return errors.unprocessable_entity('Failed to create/update region',
				'country `${country.code}` already belongs to region `${region_id}`')
		}
	}
}

// TODO check currency_code, country_codes
fn (p RegionCreateParams) check(mut tx firebird.ClientTransaction) ! {
	count := record.region_retrieve_count(mut tx, record.RegionRetriveParams{
		ids:          [p.id]
		with_deleted: false
		offset:       offset_default
		fetch:        1
		order:        order_default
	}) or { return errors.internal('Failed to retrieve region', err.msg()) }

	if count == 0 {
		return errors.not_found('region not found', 'No region exists with id `${p.id}`')
	}

	check_countries_have_no_region(mut tx, p.country_codes)!
}

struct RegionCreateData {
	region record.RegionCreateParams
	// taxes
}

fn (p RegionCreateParams) parse() RegionCreateData {
	region := record.RegionCreateParams{
		id:                 p.id
		name:               p.name
		currency_code:      p.currency_code
		includes_tax:       p.includes_tax
		gift_cards_taxable: p.gift_cards_taxable
		automatic_taxes:    p.automatic_taxes
		country_codes:      p.country_codes
	}

	return RegionCreateData{
		region: region
	}
}

pub fn region_create(mut tx firebird.ClientTransaction, p RegionCreateParams) ! {
	p.check(mut tx)!
	data := p.parse()
	record.region_create(mut tx, data.region) or {
		return errors.internal('Could not create region', err.msg())
	}
}

pub struct RegionUpdateParams {
pub:
	id                 ID
	name               ?string
	currency_code      ?string
	includes_tax       ?bool
	gift_cards_taxable ?bool
	automatic_taxes    ?bool
	country_codes      ?[]string
	// taxes
}

// TODO check currency_code, country_codes
// TODO for each country_code error if country already in another region
fn (p RegionUpdateParams) check(mut tx firebird.ClientTransaction) ! {
	count := record.region_retrieve_count(mut tx, record.RegionRetriveParams{
		ids:          [p.id]
		with_deleted: false
		offset:       offset_default
		fetch:        1
		order:        order_default
	}) or { return errors.internal('Failed to retrieve region count', err.msg()) }

	if count == 0 {
		return errors.not_found('region not found', 'No region exists with id `${p.id}`')
	}

	if country_codes := p.country_codes {
		check_countries_have_no_region(mut tx, country_codes)!
	}
}

struct RegionUpdateData {
	region record.RegionUpdateParams
	// taxes
}

fn (p RegionUpdateParams) parse() RegionUpdateData {
	region := record.RegionUpdateParams{
		id:                 p.id
		name:               p.name
		currency_code:      p.currency_code
		includes_tax:       p.includes_tax
		gift_cards_taxable: p.gift_cards_taxable
		automatic_taxes:    p.automatic_taxes
		country_codes:      p.country_codes
	}

	return RegionUpdateData{
		region: region
	}
}

pub fn region_update(mut tx firebird.ClientTransaction, p RegionUpdateParams) ! {
	p.check(mut tx)!
	data := p.parse()
	record.region_update(mut tx, data.region) or {
		return errors.internal('Could not update region', err.msg())
	}
}

pub fn region_delete(mut tx firebird.ClientTransaction, region_id ID) ! {
	count := record.region_retrieve_count(mut tx, record.RegionRetriveParams{
		ids:          [region_id]
		with_deleted: false
		offset:       offset_default
		fetch:        1
		order:        order_default
	}) or { return errors.internal('Failed to retrieve region count', err.msg()) }

	if count == 0 {
		return errors.not_found('Could not find region with id `${region_id.string()}`',
			'region does not exist or is already deleted')
	}

	store := store_get(mut tx)!
	if store.default_region_id.string() == region_id.string() {
		return errors.bad_request('Could not delete region', 'Cannot delete default region')
	}

	record.region_delete(mut tx, region_id) or {
		return errors.internal('Could not delete region', err.msg())
	}
}
