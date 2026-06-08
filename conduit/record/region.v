module record

import arrays
import einar_hjortdal.firebird

pub struct Region {
pub:
	id                 ID
	name               string
	created_at         firebird.DateTime
	updated_at         firebird.DateTime
	deleted_at         ?firebird.DateTime
	currency_code      string
	includes_tax       bool
	gift_cards_taxable bool
	automatic_taxes    bool
pub mut:
	tax_rates []TaxRate
}

pub fn (r Region) id() ID {
	return r.id
}

pub struct RegionRetriveParams {
pub:
	ids          ?[]ID
	with_deleted bool
	offset       i32
	fetch        i32
	order        string
}

pub fn region_retrieve_conditions(p RegionRetriveParams) (string, []firebird.Value) {
	mut conditions := []string{}
	mut params := []firebird.Value{}

	if ids := p.ids {
		conditions = arrays.concat(conditions, 'id IN (${get_placeholders(ids)})')
		params = arrays.concat(params, ...ids_bytes(ids))
	}

	if !p.with_deleted {
		conditions = arrays.concat(conditions, 'deleted_at is NULL')
	}

	return get_where_conditions(conditions), params
}

pub fn region_retrieve_count(mut tx firebird.Transaction, p RegionRetriveParams) !i64 {
	conditions, params := region_retrieve_conditions(p)
	data := tx.execute('SELECT COUNT(*) FROM region ${conditions}', ...params)!
	rows := data.rows()
	values := rows[0].values() // should always return one row
	count, _ := values[0].get_i64()! // should always return one column
	return count
}

pub fn region_retrieve(mut tx firebird.Transaction, p RegionRetriveParams) ![]Region {
	query := 'SELECT
		id,
		name,
		created_at,
		updated_at,
		deleted_at,
		currency_code,
		includes_tax,
		gift_cards_taxable,
		automatic_taxes
		FROM region'

	mut conditions, mut params := region_retrieve_conditions(p)

	mut sorting := 'ORDER BY created_at ${p.order} 
		OFFSET ? ROWS
		FETCH NEXT ? ROWS ONLY'
	params = arrays.concat(params, p.offset, p.fetch)

	data := tx.execute('${query} ${conditions} ${sorting}', ...params)!

	rows := data.rows()

	mut regions := []Region{len: rows.len}
	for i := 0; i < rows.len; i++ {
		v := rows[i].values()

		id_bin, _ := v[0].get_array_u8()!
		name, _ := v[1].get_string()!
		created_at, _ := v[2].get_date_time()!
		updated_at, _ := v[3].get_date_time()!
		deleted_at := v[4].get_null_date_time()!
		currency_code, _ := v[5].get_string()!
		includes_tax, _ := v[6].get_bool()!
		gift_cards_taxable, _ := v[7].get_bool()!
		automatic_taxes, _ := v[8].get_bool()!

		id := id_from_bytes(id_bin)!

		regions[i] = Region{
			id:                 id
			name:               name
			created_at:         created_at
			updated_at:         updated_at
			deleted_at:         deleted_at.none_value()
			currency_code:      currency_code
			includes_tax:       includes_tax
			gift_cards_taxable: gift_cards_taxable
			automatic_taxes:    automatic_taxes
		}
	}

	return regions
}

pub struct RegionCreateParams {
pub:
	name               string
	currency_code      string
	includes_tax       bool
	gift_cards_taxable bool
	automatic_taxes    bool
	country_codes      []string
}

// TODO handle tax rate: f32 is provided, create tax rate and add relation.
pub fn region_create(mut tx firebird.Transaction, region_id ID, p RegionCreateParams) ! {
	mut columns := [
		'id',
		'name',
		'currency_code',
		'includes_tax',
		'gift_cards_taxable',
		'automatic_taxes',
	]
	mut params := [
		firebird.Value(region_id.bytes()),
		p.name,
		p.currency_code,
		p.includes_tax,
		p.gift_cards_taxable,
		p.automatic_taxes,
	]

	tx.execute('INSERT INTO region (${get_columns(columns)}) VALUES (${get_placeholders(columns)})',
		...params)!

	tx.execute('UPDATE country SET region_id = ? WHERE code IN (${get_placeholders(p.country_codes)})',
		...p.country_codes)!
}

pub struct RegionUpdateParams {
pub:
	name               ?string
	currency_code      ?string
	includes_tax       ?bool
	gift_cards_taxable ?bool
	automatic_taxes    ?bool
	country_codes      ?[]string
}

pub fn region_update(mut tx firebird.Transaction, region_id ID, p RegionUpdateParams) ! {
	mut columns := []string{}
	mut params := []firebird.Value{}

	if name := p.name {
		columns = arrays.concat(columns, 'name')
		params = arrays.concat(params, name)
	}

	if currency_code := p.currency_code {
		columns = arrays.concat(columns, 'currency_code')
		params = arrays.concat(params, currency_code)
	}

	if automatic_taxes := p.automatic_taxes {
		columns = arrays.concat(columns, 'automatic_taxes')
		params = arrays.concat(params, automatic_taxes)
	}

	if includes_tax := p.includes_tax {
		columns = arrays.concat(columns, 'includes_tax')
		params = arrays.concat(params, includes_tax)
	}

	params = arrays.concat(params, region_id.bytes())

	tx.execute('UPDATE region SET ${get_set_columns_with_updated_at(columns)} WHERE id = ?',
		...params)!

	if country_codes := p.country_codes {
		tx.execute('UPDATE country SET region_id = ? WHERE code IN (${get_placeholders(country_codes)})',
			...country_codes)!
	}
}

pub fn region_delete(mut tx firebird.Transaction, region_id ID) ! {
	tx.execute('UPDATE region SET deleted_at = CURRENT_TIMESTAMP WHERE id = ?', region_id.bytes())!
}
