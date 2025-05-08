module main

import einar_hjortdal.firebird

struct ProductVariant {
	id                 string
	created_at         firebird.DateTime
	updated_at         firebird.DateTime
	deleted_at         firebird.DateTime @[omitempty]
	product_id         string
	sku                string @[omitempty]
	barcode            string @[omitempty]
	ean                string @[omitempty]
	upc                string @[omitempty]
	variant_rank       i32
	inventory_quantity i32
	allow_backorder    bool
	manage_inventory   bool
	hs_code            string @[omitempty]
	origin_country     string @[omitempty]
	mid_code           string @[omitempty]
	weight             i32    @[omitempty]
	length             i32    @[omitempty]
	height             i32    @[omitempty]
	width              i32    @[omitempty]
	title              string
}
