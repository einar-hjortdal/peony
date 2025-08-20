module peony

import einar_hjortdal.firebird

struct InventoryItem {
	id                string
	id_bin            []u8
	created_at        firebird.DateTime
	updated_at        firebird.DateTime
	deleted_at        firebird.NullDateTime
	requires_shipping bool
}

struct InventoryLevel {
}

// product_variant_inventory_item relation
