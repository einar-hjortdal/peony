module main

import einar_hjortdal.firebird

struct TaxRate {
	id            string
	id_bin        []u8
	created_at    firebird.DateTime
	updated_at    firebird.DateTime
	deleted_at    firebird.DateTime
	rate          f32
	code          string
	name          string
	region_id     string
	region_id_bin []u8
}
