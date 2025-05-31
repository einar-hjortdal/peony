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
	name   string
	offset i32
	fetch  i32
	order  string
}

fn build_list_regions_query(p ListRegionParams) (string, []firebird.Value) {
	base_query := 'SELECT 
	UUID_TO_CHAR(id),
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
	if p.name != '' {
		conditions += "
			WHERE name LIKE '%' || ? || '%'"
		params = arrays.concat(params, p.name)
	}

	mut sorting := ''
	if p.offset != 0 {
		sorting += '
			OFFSET ? ROWS'
		params = arrays.concat(params, p.offset)
	}
	if p.fetch != 0 {
		sorting += '
			FETCH NEXT ? ROWS ONLY'
		params = arrays.concat(params, p.fetch)
	}
	sorting += '
		ORDER BY name ${parse_order(p.order)}'
	return '${base_query}${conditions}${sorting}', params
}

fn (mut app App) list_regions(p ListRegionParams) ![]Region {
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

fn (mut app App) retrieve_region_by_id(id string) !Region {
	mut tx := app.fb.start_transaction(firebird.isolation_level_read_commited)!
	data := tx.execute('SELECT 
		UUID_TO_CHAR(id),
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
		FROM region WHERE id = CHAR_TO_UUID(?)',
		id)!

	if data.rows.len == 0 {
		return error(format_error_message('No region found'))
	}

	return parse_region(data.rows[0].values)!
}

fn (mut app App) add_country(country_id string, region_id string) ! {
	mut tx := app.fb.start_transaction(firebird.isolation_level_read_commited)!
	tx.execute('UPDATE country SET region_id = ? WHERE id = CHAR_TO_UUID(?)', region_id,
		country_id)!
	tx.commit()!
}

fn (mut app App) remove_country(country_id string, region_id string) ! {
	mut tx := app.fb.start_transaction(firebird.isolation_level_read_commited)!
	tx.execute('UPDATE country SET region_id = NULL WHERE region_id = CHAR_TO_UUID(?) AND code = ?',
		region_id, country_id)!
	tx.commit()!
}

fn add_countries(mut tx firebird.Transaction, country_ids []string, region_id string) ! {
	if country_ids.len == 0 {
		return
	}
	tx.execute('UPDATE country SET region_id = CHAR_TO_UUID(?) WHERE UUID_TO_CHAR(id) IN (${get_placeholders(country_ids)})',
		...country_ids)!
}

struct CreateRegionData {
	name          string
	currency_code string
	tax_rate      f32
	tax_code      string @[omitempty]
	countries     []string
	includes_tax  bool @[omitempty]
}

fn build_create_region_query(d CreateRegionData, id string) (string, []firebird.Value) {
	mut columns := ['name', 'currency_code', 'tax_rate']
	mut params := [firebird.Value(id), d.name, d.currency_code, d.tax_rate]
	if d.tax_code != '' {
		columns = arrays.concat(columns, 'tax_code')
		params = arrays.concat(params, d.tax_code)
	}
	if d.includes_tax {
		columns = arrays.concat(columns, 'includes_tax')
		params = arrays.concat(params, d.includes_tax)
	}

	return 'INSERT INTO region (id, ${get_columns(columns)}) VALUES (CHAR_TO_UUID(?), ${get_placeholders(columns)})', params
}

fn (mut app App) create_region(d CreateRegionData) !string {
	id := app.luuid_generator.v1()
	mut tx := app.fb.start_transaction(firebird.isolation_level_read_commited)!
	create_region(mut tx, id, d) or {
		tx.rollback()!
		return err
	}

	add_countries(mut tx, d.countries, id) or {
		tx.rollback()!
		return err
	}

	tx.commit()!
	return id
}

fn create_region(mut tx firebird.Transaction, id string, d CreateRegionData) ! {
	query, params := build_create_region_query(d, id)
	tx.execute(query, ...params)!
}
