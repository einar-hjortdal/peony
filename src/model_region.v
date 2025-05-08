module main

import arrays
import einar_hjortdal.firebird

struct Region {
	id              string
	name            string
	created_at      firebird.DateTime
	updated_at      firebird.DateTime
	deleted_at      firebird.DateTime @[omitempty]
	currency_code   string
	tax_rate        f32
	tax_code        string @[omitempty]
	includes_tax    bool
	automatic_taxes bool
}

struct ListRegionParams {
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
	automatix_taxes
	FROM region'
	mut params := []firebird.Value{}
	mut conditions := ''
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

fn (mut app App) list_regions(p ListRegionParams) ! {
	mut tx := app.fb.start_transaction(firebird.isolation_level_read_commited)!
	query, params := build_list_regions_query(p)
	tx.execute(query, ...params)!
	tx.rollback()!
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
