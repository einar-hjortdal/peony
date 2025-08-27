module peony

fn make_product_map(p []Product) (map[string]Product, [][]u8) {
	mut m := map[string]Product{}
	mut a := [][]u8{len: p.len}
	for i := 0; i < p.len; i++ {
		id := p[i].id
		id_bin := p[i].id_bin
		m[id] = p[i]
		a[i] = id_bin
	}
	return m, a
}

fn make_product_variant_map(p []ProductVariant) (map[string]ProductVariant, [][]u8) {
	mut m := map[string]ProductVariant{}
	mut a := [][]u8{len: p.len}
	for i := 0; i < p.len; i++ {
		id := p[i].id
		id_bin := p[i].id_bin
		m[id] = p[i]
		a[i] = id_bin
	}
	return m, a
}

fn make_inventory_item_map(p []InventoryItem) (map[string]InventoryItem, [][]u8) {
	mut m := map[string]InventoryItem{}
	mut a := [][]u8{len: p.len}
	for i := 0; i < p.len; i++ {
		id := p[i].id
		id_bin := p[i].id_bin
		m[id] = p[i]
		a[i] = id_bin
	}
	return m, a
}

fn make_sales_channel_map(p []SalesChannel) (map[string]SalesChannel, [][]u8) {
	mut m := map[string]SalesChannel{}
	mut a := [][]u8{len: p.len}
	for i := 0; i < p.len; i++ {
		id := p[i].id
		id_bin := p[i].id_bin
		m[id] = p[i]
		a[i] = id_bin
	}
	return m, a
}
