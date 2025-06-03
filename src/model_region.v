module main

import arrays
import einar_hjortdal.firebird

struct Region {
	id                 string
	id_bin             []u8 @[json: '-']
	name               string
	created_at         firebird.DateTime
	updated_at         firebird.DateTime
	deleted_at         firebird.DateTime @[omitempty]
	currency_code      string
	tax_rate           f32
	tax_code           string @[omitempty]
	includes_tax       bool
	gift_cards_taxable bool
	automatic_taxes    bool
}

fn parse_region(v []firebird.Value) !Region {
	id_bin, _ := v[0].get_array_u8()!
	name, _ := v[1].get_string()!
	created_at, _ := v[2].get_date_time()!
	updated_at, _ := v[3].get_date_time()!
	deleted_at, _ := v[4].get_date_time()!
	currency_code, _ := v[5].get_string()!
	tax_rate, _ := v[6].get_f32()!
	tax_code, _ := v[7].get_string()!
	includes_tax, _ := v[8].get_bool()!
	gift_cards_taxable, _ := v[9].get_bool()!
	automatic_taxes, _ := v[10].get_bool()!

	id := id_bin_to_string(id_bin)!

	return Region{
		id:                 id
		id_bin:             id_bin
		name:               name
		created_at:         created_at
		updated_at:         updated_at
		deleted_at:         deleted_at
		currency_code:      currency_code
		tax_rate:           tax_rate
		tax_code:           tax_code
		includes_tax:       includes_tax
		gift_cards_taxable: gift_cards_taxable
		automatic_taxes:    automatic_taxes
	}
}

struct ListRegionParams {
	name   ZeroString
	offset ZeroI32
	fetch  ZeroI32
	order  ZeroString
}

fn extract_retrieve_regions_params(p map[string]string) ListRegionParams {
	return ListRegionParams{
		name:   zero_string(p, 'name')
		offset: zero_i32(p, 'offset')
		fetch:  zero_i32(p, 'fetch')
		order:  zero_string(p, 'order')
	}
}

fn build_list_regions_query(p ListRegionParams) (string, []firebird.Value) {
	base_query := 'SELECT
		id,
		name,
		created_at,
		updated_at,
		deleted_at,
		currency_code,
		tax_rate,
		tax_code,
		includes_tax,
		gift_cards_taxable,
		automatix_taxes
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

	return '${base_query}${conditions}${sorting}', params
}

fn (mut app App) retrieve_regions(p ListRegionParams) ![]Region {
	mut tx := app.fb.start_transaction(firebird.isolation_level_read_commited)!
	query, params := build_list_regions_query(p)
	data := tx.execute(query, ...params)!
	tx.rollback()!

	mut regions := []Region{}
	for i := 0; i < data.rows.len; i++ {
		region := parse_region(data.rows[i].values)!
		regions = arrays.concat(regions, region)
	}
	return regions
}

fn (mut app App) retrieve_region_by_id(id_bin []u8) !Region {
	mut tx := app.fb.start_transaction(firebird.isolation_level_read_commited)!
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

fn (mut app App) add_country(code string, region_id string) ! {
	region_id_bin := id_string_to_bin(region_id)!
	mut tx := app.fb.start_transaction(firebird.isolation_level_read_commited)!
	tx.execute('UPDATE country SET region_id = ? WHERE code = ?', region_id_bin, code) or {
		tx.rollback()!
		return err
	}
	tx.commit()!
}

fn (mut app App) remove_country(code string, region_id string) ! {
	region_id_bin := id_string_to_bin(region_id)!
	mut tx := app.fb.start_transaction(firebird.isolation_level_read_commited)!
	tx.execute('UPDATE country SET region_id = NULL WHERE code = ? AND region_id = ?',
		code, region_id_bin) or {
		tx.rollback()!
		return err
	}
	tx.commit()!
}

struct CreateRegionData {
	name          string
	currency_code string
	tax_rate      f32
	tax_code      string @[omitempty]
	country_codes []string
	includes_tax  bool @[omitempty]
}

fn build_create_region_query(d CreateRegionData, id_bin []u8) (string, []firebird.Value) {
	mut columns := ['id', 'name', 'currency_code', 'tax_rate']
	mut params := [firebird.Value(id_bin), d.name, d.currency_code, d.tax_rate]
	if d.tax_code != '' {
		columns = arrays.concat(columns, 'tax_code')
		params = arrays.concat(params, d.tax_code)
	}
	if d.includes_tax {
		columns = arrays.concat(columns, 'includes_tax')
		params = arrays.concat(params, d.includes_tax)
	}

	return 'INSERT INTO region (${get_columns(columns)}) VALUES (${get_placeholders(columns)})', params
}

fn (mut app App) create_region(d CreateRegionData) !(string, []u8) {
	id, id_bin := app.new_id()!
	mut tx := app.fb.start_transaction(firebird.isolation_level_read_commited)!

	query, params := build_create_region_query(d, id_bin)
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
