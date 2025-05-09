module main

import arrays
import einar_hjortdal.firebird

struct Region {
	id                 string
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
	id, _ := firebird.get_string(v[0])!
	name, _ := firebird.get_string(v[1])!
	created_at, _ := firebird.get_date_time(v[2])!
	updated_at, _ := firebird.get_date_time(v[3])!
	deleted_at, _ := firebird.get_date_time(v[4])!
	currency_code, _ := firebird.get_string(v[5])!
	tax_rate, _ := firebird.get_f32(v[6])!
	tax_code, _ := firebird.get_string(v[7])!
	includes_tax, _ := firebird.get_bool(v[8])!
	gift_cards_taxable, _ := firebird.get_bool(v[9])!
	automatic_taxes, _ := firebird.get_bool(v[10])!

	return Region{
		id:                 id
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
		id
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
		id)!
	if data.rows.len == 0 {
		return error(format_error_message('No region found'))
	}
	return parse_region(data.rows[0].values)!
}

fn add_countries(mut tx firebird.Transaction, country_ids []string, region_id string) ! {
	if country_ids.len == 0 {
		return
	}
	tx.execute('UPDATE country SET region_id = ? WHERE id IN (${get_placeholders(country_ids)})',
		...arrays.append([region_id], country_ids))!
}

fn (mut app App) add_country(country_id string, region_id string) ! {
	mut tx := app.fb.start_transaction(firebird.isolation_level_read_commited)!
	tx.execute('UPDATE country SET region_id = ? WHERE id = ?', region_id, country_id)!
	tx.commit()!
}

fn (mut app App) remove_country(country_id string, region_id string) ! {
	mut tx := app.fb.start_transaction(firebird.isolation_level_read_commited)!
	tx.execute('UPDATE country SET region_id = NULL WHERE region_id = ? AND code = ?',
		region_id, country_id)!
	tx.commit()!
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
	mut columns := ['id', 'name', 'currency_code', 'tax_rate']
	mut params := [firebird.Value(id), d.name, d.currency_code, d.tax_rate]
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
