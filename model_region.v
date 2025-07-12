module main

import arrays
import einar_hjortdal.firebird

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

fn parse_region(v []firebird.Value) !Region {
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

	return Region{
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

fn do_retrieve_regions(mut tx firebird.Transaction, p ListRegionParams) ![]Region {
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
	mut params := []firebird.Value{}
	mut conditions := ''
	if p.name.is_set {
		conditions = appendln(conditions, "WHERE name LIKE '%' || ? || '%'")
		params = arrays.concat(params, p.name.v)
	}

	mut sorting := ''
	sorting = appendln(sorting, 'ORDER BY name ${get_sorting_order(p.order)}')

	if p.offset.is_set {
		sorting = appendln(sorting, 'OFFSET ? ROWS')
		params = arrays.concat(params, p.offset.v)
	}

	sorting = appendln(sorting, 'FETCH NEXT ? ROWS ONLY')
	params = arrays.concat(params, get_fetch_amount(p.fetch))

	data := tx.execute('${base_query}${conditions}${sorting}', ...params)!
	mut regions := []Region{}
	for i := 0; i < data.rows.len; i++ {
		region := parse_region(data.rows[i].values)!
		regions = arrays.concat(regions, region)
	}

	return regions
}

fn (mut app App) retrieve_region_by_id(id_bin []u8) !Region {
	mut tx := app.start_transaction()!
	data := tx.execute('SELECT 
		id,
		name
		created_at
		updated_at
		deleted_at
		currency_code
		tax_rate
		tax_code
		includes_tax
		gift_cards_taxable
		automatic_taxes
		FROM region WHERE id = ?',
		id_bin) or {
		tx.rollback()!
		return err
	}
	tx.rollback()!

	if data.rows.len == 0 {
		return error(format_error_message('No region found'))
	}

	return parse_region(data.rows[0].values)!
}

// fn (mut app App) add_country(code string, region_id string) ! {
// 	region_id_bin := id_string_to_bin(region_id)!
// 	mut tx := app.start_transaction()!
// 	tx.execute('UPDATE country SET region_id = ? WHERE code = ?', region_id_bin, code) or {
// 		tx.rollback()!
// 		return err
// 	}
// 	tx.commit()!
// }

// fn (mut app App) remove_country(code string, region_id string) ! {
// 	region_id_bin := id_string_to_bin(region_id)!
// 	mut tx := app.start_transaction()!
// 	tx.execute('UPDATE country SET region_id = NULL WHERE code = ? AND region_id = ?',
// 		code, region_id_bin) or {
// 		tx.rollback()!
// 		return err
// 	}
// 	tx.commit()!
// }

fn build_create_region_query(d CreateRegionRequest, id_bin []u8) !(string, []firebird.Value) {
	mut columns := ['id', 'name', 'currency_code']
	mut params := [firebird.Value(id_bin), d.name, d.currency_code]

	rate_id_bin := id_string_to_bin(d.rate_id)!

	columns = arrays.concat(columns, 'rate_id')
	params = arrays.concat(params, rate_id_bin)

	if includes_tax := d.includes_tax {
		columns = arrays.concat(columns, 'includes_tax')
		params = arrays.concat(params, includes_tax)
	}

	return 'INSERT INTO region (${get_columns(columns)}) VALUES (${get_placeholders(columns)})', params
}

fn (mut app App) create_region(d CreateRegionRequest) !(string, []u8) {
	id, id_bin := app.new_id()!
	mut tx := app.start_transaction()!

	query, params := build_create_region_query(d, id_bin)!
	tx.execute(query, ...params) or {
		tx.rollback()!
		return err
	}

	tx.execute('UPDATE country SET region_id = ? WHERE code IN (${get_placeholders(d.country_codes)})',
		...d.country_codes) or {
		tx.rollback()!
		return err
	}

	tx.commit()!
	return id, id_bin
}
