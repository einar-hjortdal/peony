module peony

import arrays
import einar_hjortdal.firebird

// a region will eventually affect:
// - discounts
// - gift cards
// - payment providers
// - fulfillment providers
// and will be associated with:
// - carts
// - orders
struct Region {
	id                 string
	id_bin             []u8
	name               string
	created_at         firebird.DateTime
	updated_at         firebird.DateTime
	deleted_at         firebird.NullDateTime
	currency_code      string
	includes_tax       bool
	gift_cards_taxable bool
	automatic_taxes    bool
mut:
	tax_rates []TaxRate
}

struct RegionRetriveParams {
	filter_by_id        bool
	ids_bin             [][]u8
	filter_by_name      bool
	name                string
	include_deleted     bool
	use_offset          bool
	offset              i32
	use_fetch           bool
	fetch               i32
	use_order_direction bool
	order_direction     string
}

fn conditions_region_retrieve(p RegionRetriveParams) (string, []firebird.Value) {
	mut conditions := []string{}
	mut params := []firebird.Value{}

	if p.filter_by_id {
		conditions = arrays.concat(conditions, 'id IN (${get_placeholders(p.ids_bin)})')
		params = arrays.concat(params, ...workaround_24757(p.ids_bin))
	}

	if p.filter_by_name {
		conditions = arrays.concat(conditions, "name LIKE '%' || ? || '%'")
		params = arrays.concat(params, p.name)
	}

	if !p.include_deleted {
		conditions = arrays.concat(conditions, 'deleted_at is NULL')
	}

	return get_where_conditions(conditions), params
}

fn model_region_retrieve_count(mut tx firebird.Transaction, p RegionRetriveParams) !i64 {
	conditions, params := conditions_region_retrieve(p)
	data := tx.execute('SELECT COUNT(*) FROM region ${conditions}', ...params)!
	rows := data.rows()
	values := rows[0].values() // should always return one row
	count, _ := values[0].get_i64()! // should always return one column
	return count
}

fn model_region_retrieve(mut tx firebird.Transaction, p RegionRetriveParams) ![]Region {
	base_query := 'SELECT
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

	mut conditions, mut params := conditions_region_retrieve(p)

	mut order_direction := order_direction_default
	if p.use_order_direction {
		order_direction = p.order_direction
	}

	mut sorting := 'ORDER BY name ${order_direction}'

	if p.use_offset {
		sorting = appendln(sorting, 'OFFSET ? ROWS')
		params = arrays.concat(params, p.offset)
	}

	if p.use_fetch {
		sorting = appendln(sorting, 'FETCH NEXT ? ROWS ONLY')
		params = arrays.concat(params, p.fetch)
	}

	data := tx.execute('${base_query} ${conditions} ${sorting}', ...params)!

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

		id := id_bin_to_string(id_bin)!

		regions[i] = Region{
			id:                 id
			id_bin:             id_bin
			name:               name
			created_at:         created_at
			updated_at:         updated_at
			deleted_at:         deleted_at
			currency_code:      currency_code
			includes_tax:       includes_tax
			gift_cards_taxable: gift_cards_taxable
			automatic_taxes:    automatic_taxes
		}
	}

	return regions
}

// TODO handle tax rate: f32 is provided, create tax rate and add relation.
fn model_region_create(mut tx firebird.Transaction, region_id_bin []u8, d RegionCreateRequest) ! {
	mut columns := ['id', 'currency_code', 'name']
	mut params := [firebird.Value(region_id_bin), d.currency_code, d.name]

	if automatic_taxes := d.automatic_taxes {
		columns = arrays.concat(columns, 'automatic_taxes')
		params = arrays.concat(params, automatic_taxes)
	}

	if includes_tax := d.includes_tax {
		columns = arrays.concat(columns, 'includes_tax')
		params = arrays.concat(params, includes_tax)
	}

	tx.execute('INSERT INTO region (${get_columns(columns)}) VALUES (${get_placeholders(columns)})',
		...params)!

	// workaround_24757
	params = []firebird.Value{len: d.country_codes.len, init: firebird.Null{}}
	for i := 0; i < d.country_codes.len; i++ {
		params[i] = d.country_codes[i]
	}
	tx.execute('UPDATE country SET region_id = ? WHERE code IN (${get_placeholders(d.country_codes)})',
		...params)!
}

fn model_region_update(mut tx firebird.Transaction, region_id_bin []u8, d RegionUpdateRequest) ! {
	mut columns := []string{}
	mut params := []firebird.Value{}

	if name := d.name {
		columns = arrays.concat(columns, 'name')
		params = arrays.concat(params, name)
	}

	if currency_code := d.currency_code {
		columns = arrays.concat(columns, 'currency_code')
		params = arrays.concat(params, currency_code)
	}

	if automatic_taxes := d.automatic_taxes {
		columns = arrays.concat(columns, 'automatic_taxes')
		params = arrays.concat(params, automatic_taxes)
	}

	if includes_tax := d.includes_tax {
		columns = arrays.concat(columns, 'includes_tax')
		params = arrays.concat(params, includes_tax)
	}

	params = arrays.concat(params, region_id_bin)

	tx.execute('UPDATE region SET ${get_set_columns_with_updated_at(columns)} WHERE id = ?',
		...params)!

	// workaround_24757
	if country_codes := d.country_codes {
		params = []firebird.Value{len: country_codes.len, init: firebird.Null{}}
		for i := 0; i < country_codes.len; i++ {
			params[i] = country_codes[i]
		}
		tx.execute('UPDATE country SET region_id = ? WHERE code IN (${get_placeholders(country_codes)})',
			...params)!
	}
}

fn model_region_delete(mut tx firebird.Transaction, region_id_bin []u8) ! {
	tx.execute('UPDATE region SET deleted_at = CURRENT_TIMESTAMP WHERE id = ?', region_id_bin)!
}
