module conduit

import arrays
import einar_hjortdal.luuid
import einar_hjortdal.firebird
import record
import internal.errors
import internal.common

fn get_variants_money_amounts(mut tx firebird.ClientTransaction, mut variants_map map[string]record.Variant, variant_ids []ID) ! {
	money_amounts := record.variant_money_amount_retrieve(mut tx, variant_ids) or {
		return errors.internal('Failed to retrieve product_variant_money_amount', err.msg())
	}

	for i := 0; i < money_amounts.len; i++ {
		money_amount := money_amounts[i]
		variant_id := money_amount.variant_id
		old := variants_map[variant_id.string()].money_amounts
		variants_map[variant_id.string()].money_amounts = arrays.concat(old, money_amount)
	}
}

fn get_variants_inventory_items(mut tx firebird.ClientTransaction, mut variants_map map[string]record.Variant, variant_ids []ID) ! {
	inventory_items := record.inventory_item_retrieve(mut tx, variant_ids) or {
		return errors.internal('Failed to retrieve inventory_item', err.msg())
	}

	mut item_map, item_ids := common.make_identifiable_map(inventory_items)
	get_item_availability(mut tx, mut item_map, item_ids)!
	get_inventory_items_levels(mut tx, mut item_map, item_ids)!

	for item_id, item in item_map {
		variant_id := item.variant_id.string()
		variants_map[variant_id].inventory_item = item_map[item_id]
	}
}

fn get_variants_option_values(mut tx firebird.ClientTransaction, mut variants_map map[string]record.Variant, variant_ids []ID) ! {
	option_value_variants := record.product_option_value_variant_retrieve(mut tx, record.ProductOptionValueVariantRetrieveParams{
		variant_ids: variant_ids
	}) or {
		return errors.internal('Failed to retrieve product_option_value_product_variant', err.msg())
	}

	option_values := record.product_option_values_retrieve(mut tx, record.ProductOptionValueRetrieveParams{
		variant_ids: variant_ids
	}) or { return errors.internal('Failed to retrieve product_option_value', err.msg()) }

	mut value_map, value_ids := common.make_identifiable_map(option_values)
	get_product_option_values_translations(mut tx, mut value_map, value_ids)!

	mut variant_values_map := map[string][]ID{}
	for i := 0; i < option_value_variants.len; i++ {
		variant_id := option_value_variants[i].variant_id
		value_id := option_value_variants[i].option_value_id
		old := variant_values_map[variant_id.string()]
		variant_values_map[variant_id.string()] = arrays.concat(old, value_id)
	}

	for variant_id_string, variant_value_ids in variant_values_map {
		for i := 0; i < variant_value_ids.len; i++ {
			value_id := variant_value_ids[i]
			value := value_map[value_id.string()]
			old := variants_map[variant_id_string].option_values
			variants_map[variant_id_string].option_values = arrays.concat(old, value)
		}
	}
}

pub fn variant_get(mut tx firebird.ClientTransaction, variant_id ID) !record.Variant {
	variants := record.variant_retrieve(mut tx, record.VariantRetrieveParams{
		ids:          [variant_id]
		with_deleted: false
		offset:       offset_default
		fetch:        1
		order:        order_default
	}) or { return errors.internal('Could not retrieve product_variant', err.msg()) }

	if variants.len == 0 {
		return errors.not_found('No variant found',
			'No variant exists with id `${variant_id.string()}`')
	}

	money_amounts := record.variant_money_amount_retrieve(mut tx, [variant_id]) or {
		return errors.internal('Could not retrieve product_variant_money_amount', err.msg())
	}

	inventory_items := record.inventory_item_retrieve(mut tx, [variant_id]) or {
		return errors.internal('Could not retrieve inventory_item', err.msg())
	}

	if inventory_items.len == 0 {
		return errors.internal(errors.database_malformed, 'inventory_items.len == 0')
	}

	mut inventory_item := inventory_items[0]
	inventory_levels := record.inventory_level_retrieve(mut tx, [inventory_item.id]) or {
		return errors.internal('Could not retrieve inventory_level', err.msg())
	}

	mut variant := variants[0]
	inventory_item.inventory_levels = inventory_levels
	variant.money_amounts = money_amounts
	variant.inventory_item = inventory_item

	option_value_variants := record.product_option_value_variant_retrieve(mut tx, record.ProductOptionValueVariantRetrieveParams{
		variant_ids: [variant.id]
	}) or { return errors.internal('Could not retrieve product_option_value_variant', err.msg()) }

	mut option_value_ids := []ID{len: option_value_variants.len}
	for i := 0; i < option_value_variants.len; i++ {
		option_value_variant := option_value_variants[i]
		option_value_ids[i] = option_value_variant.option_value_id
	}

	option_values := record.product_option_values_retrieve(mut tx, record.ProductOptionValueRetrieveParams{
		ids: option_value_ids
	}) or { return errors.internal('Could not retrieve product_option_value', err.msg()) }

	option_value_translations := record.product_option_value_translations_retrieve(mut tx,
		option_value_ids) or {
		return errors.internal('Could not retrieve product_option_value_translations', err.msg())
	}

	mut option_values_map, _ := common.make_identifiable_map(option_values)

	for i := 0; i < option_value_translations.len; i++ {
		translation := option_value_translations[i]
		option_value_id := translation.option_value_id
		old := option_values_map[option_value_id.string()].translations
		option_values_map[option_value_id.string()].translations = arrays.concat(old, translation)
	}

	mut complete_option_values := []record.ProductOptionValue{len: option_value_ids.len}
	for i := 0; i < option_value_ids.len; i++ {
		option_value_id := option_value_ids[i]
		complete_option_values[i] = option_values_map[option_value_id.string()]
	}

	variant.option_values = complete_option_values

	return variant
}

pub struct VariantMoneyAmountUpdateParams {
pub:
	region_id   ID
	amount      i32
	is_original bool
}

pub struct InventoryItemCreateParams {
pub:
	id                ID
	variant_id        ID
	sku               ?string
	origin_country    ?string
	hs_code           ?string
	mid_code          ?string
	material          ?string
	weight            ?i32
	length            ?i32
	height            ?i32
	width             ?i32
	requires_shipping bool
	manage_inventory  bool
	allow_backorder   bool
}

pub struct VariantCreateParams {
pub:
	id               ID
	product_id       ID
	image_id         ?ID
	title            ?string
	ean              ?string
	upc              ?string
	barcode          ?string
	metadata         ?string
	variant_rank     i32
	option_value_ids []ID
	inventory_item   InventoryItemCreateParams
	money_amounts    ?[]VariantMoneyAmountUpdateParams
}

fn (p VariantCreateParams) check_image_id(mut tx firebird.ClientTransaction) ! {
	image_id := p.image_id or { return }
	images := record.product_image_retrieve(mut tx, [p.product_id]) or {
		return errors.internal('Failed to retrieve product_image', err.msg())
	}

	for i := 0; i < images.len; i++ {
		image := images[i]
		if image.id.string() == image_id.string() { return }
	}

	return errors.unprocessable_entity(errors.id_invalid,
		'image_id does not exist or does not belong to product')
}

fn (p VariantCreateParams) check_money_amount_region(mut tx firebird.ClientTransaction) ! {
	money_amounts := p.money_amounts or { return }
	mut given_ids := map[string]ID{}
	for i := 0; i < money_amounts.len; i++ {
		id := money_amounts[i].region_id
		given_ids[id.string()] = id
	}
	mut ids := given_ids.values()

	count_existing := record.region_retrieve_count(mut tx, record.RegionRetriveParams{
		ids:          ids
		with_deleted: false
		offset:       offset_default // ignored by count fn
		fetch:        max_fetch      // ignored by count fn
		order:        order_default  // ignored by count fn
	}) or { return errors.internal('Failed to retrieve region', err.msg()) }

	if count_existing != ids.len {
		// TODO return which are missing for nice error?
		return errors.unprocessable_entity(errors.id_invalid,
			'money_amount region_id does not exist')
	}

	// check there is one given_id for each existing region
	count_region := record.region_retrieve_count(mut tx, record.RegionRetriveParams{
		with_deleted: false
		offset:       offset_default // ignored by count fn
		fetch:        max_fetch      // ignored by count fn
		order:        order_default  // ignored by count fn
	}) or { return errors.internal('Failed to retrieve region', err.msg()) }

	if count_region != ids.len {
		return errors.unprocessable_entity('Regional price missing',
			'Every region must have one price')
	}
}

fn (p VariantCreateParams) check_option_values(mut tx firebird.ClientTransaction) ! {
	// check given option_value ids exist
	option_values := record.product_option_values_retrieve(mut tx, record.ProductOptionValueRetrieveParams{
		ids:         p.option_value_ids
		product_ids: [p.product_id]
	}) or { return errors.internal('Failed to retrieve product_option_value', err.msg()) }

	if option_values.len != p.option_value_ids.len {
		return errors.unprocessable_entity(errors.id_invalid,
			'product_option_value id does not exist or does not belong to the product')
	}

	// check each value belongs to different option
	mut option_ids := map[string]common.Empty{}
	for i := 0; i < option_values.len; i++ {
		option_id := option_values[i].option_id.string()
		if option_id in option_ids {
			return errors.unprocessable_entity(errors.id_invalid,
				'one or more option_value share the same option parent')
		}
		option_ids[option_id] = common.Empty{}
	}

	// check number of value matches the number of options on the product
	options := record.product_option_retrieve(mut tx, [p.product_id]) or {
		return errors.internal('Failed to retrieve product_option', err.msg())
	}

	if options.len != p.option_value_ids.len {
		return errors.unprocessable_entity('option_values amount not correct',
			'Expected one option_value for each option that exists for the product')
	}

	// check combination is unique
	value_variants := record.product_option_value_variant_retrieve(mut tx, record.ProductOptionValueVariantRetrieveParams{
		option_value_ids: p.option_value_ids
	}) or { return errors.internal('Failed to retrieve product_option_value_variant', err.msg()) }

	mut counts := map[string]int{}
	for i := 0; i < value_variants.len; i++ {
		vv := value_variants[i]
		counts[vv.variant_id.string()]++
	}

	for _, count in counts {
		if count == p.option_value_ids.len {
			return errors.unprocessable_entity('duplicate variant',
				'A variant with the same option values already exists')
		}
	}
}

fn (p VariantCreateParams) check(mut tx firebird.ClientTransaction) ! {
	check_product_id_exists(mut tx, p.product_id)!
	p.check_image_id(mut tx)!
	p.check_money_amount_region(mut tx)!
	p.check_option_values(mut tx)!
}

fn (p VariantCreateParams) parse_variant() !record.VariantCreateParams {
	return record.VariantCreateParams{
		id:           p.id
		product_id:   p.product_id
		image_id:     p.image_id
		title:        p.title
		barcode:      p.barcode
		ean:          p.ean
		upc:          p.upc
		metadata:     p.metadata
		variant_rank: p.variant_rank
	}
}

fn (p VariantCreateParams) parse_inventory_item() record.InventoryItemCreateParams {
	ii := p.inventory_item
	return record.InventoryItemCreateParams{
		id:                ii.id
		variant_id:        ii.variant_id
		sku:               ii.sku
		origin_country:    ii.origin_country
		hs_code:           ii.hs_code
		mid_code:          ii.mid_code
		material:          ii.material
		weight:            ii.weight
		length:            ii.length
		height:            ii.height
		width:             ii.width
		requires_shipping: ii.requires_shipping
		manage_inventory:  ii.manage_inventory
		allow_backorder:   ii.allow_backorder
	}
}

fn (p VariantCreateParams) parse_money_amounts(mut tx firebird.ClientTransaction, mut g luuid.Generator) ![]record.VariantMoneyAmountUpdateParams {
	regions := record.region_retrieve(mut tx, record.RegionRetriveParams{
		with_deleted: false
		offset:       offset_default
		fetch:        max_fetch // limit 250 regions or refactor? or make const internal_max_fetch = max_i32?
		order:        order_default
	}) or { return errors.internal('Failed to retrieve region', err.msg()) }

	// at max one base and one original per region
	mut res := []record.VariantMoneyAmountUpdateParams{len: 0, cap: 2 * regions.len}

	money_amounts := p.money_amounts or {
		for _, region in regions {
			res << record.VariantMoneyAmountUpdateParams{
				variant_id:      p.id
				region_id:       region.id
				money_amount_id: common.new_id(mut g)
				amount:          common.money_amount_default_amount
				is_original:     common.money_amount_default_is_original
			}
		}
		return res
	}

	mut covered := map[string]common.Empty{}
	for ma in money_amounts {
		region_id := ma.region_id
		res << record.VariantMoneyAmountUpdateParams{
			variant_id:      p.id
			region_id:       region_id
			money_amount_id: common.new_id(mut g)
			amount:          ma.amount
			is_original:     ma.is_original
		}

		if ma.is_original {
			covered[region_id.string()] = common.Empty{}
		}
	}

	for _, region in regions {
		if region.id.string() in covered {
			continue
		}

		res << record.VariantMoneyAmountUpdateParams{
			variant_id:      p.id
			region_id:       region.id
			money_amount_id: common.new_id(mut g)
			amount:          common.money_amount_default_amount
			is_original:     common.money_amount_default_is_original
		}
	}
	return res
}

// TODO consider moving all id generation here. pass variant id as fn parameter or return it.
// id generation should be in one location alone, and it probably belongs here.
// TODO should defaults be set here? Sometimes we are forced to set them here, we're not forced to set them in the routes.
pub fn variant_create(mut tx firebird.ClientTransaction, mut g luuid.Generator, p VariantCreateParams) ! {
	p.check(mut tx)!

	variant := p.parse_variant()!
	option_values := parse_option_values(p.option_value_ids, p.id)
	inventory_item := p.parse_inventory_item()
	money_amounts := p.parse_money_amounts(mut tx, mut g)!

	record.variant_create(mut tx, [variant]) or {
		return errors.internal('Could not create product_variant', err.msg())
	}

	record.product_option_value_variant_update(mut tx, option_values) or {
		return errors.internal('Could not update product_option_value_variant', err.msg())
	}

	record.inventory_item_create(mut tx, [inventory_item]) or {
		return errors.internal('Could not create inventory_item for product_variant', err.msg())
	}

	record.variant_money_amount_update(mut tx, money_amounts) or {
		return errors.internal('Could not update money_amounts', err.msg())
	}
}

pub struct InventoryItemUpdateParams {
pub:
	// id                ID TODO fetch and add
	variant_id        ID
	sku               ?string
	origin_country    ?string
	hs_code           ?string
	mid_code          ?string
	material          ?string
	weight            ?i32
	length            ?i32
	height            ?i32
	width             ?i32
	requires_shipping ?bool
	manage_inventory  ?bool
	allow_backorder   ?bool
}

pub struct VariantUpdateParams {
pub:
	id               ID
	product_id       ID
	image_id         ?ID
	title            ?string
	barcode          ?string
	ean              ?string
	upc              ?string
	metadata         ?string
	option_value_ids ?[]ID
	inventory_item   ?InventoryItemUpdateParams
	money_amounts    ?[]VariantMoneyAmountUpdateParams
}

struct VariantUpdateData {
	variant        record.VariantUpdateParams
	option_values  ?[]record.ProductOptionValueVariant
	inventory_item ?record.InventoryItemUpdateParams
	money_amounts  ?[]record.VariantMoneyAmountUpdateParams
}

fn (p VariantUpdateParams) parse_variant(mut tx firebird.ClientTransaction) !record.VariantUpdateParams {
	variants := record.variant_retrieve(mut tx, record.VariantRetrieveParams{
		ids:          [p.id]
		with_deleted: false
		offset:       offset_default
		fetch:        min_fetch
		order:        order_default
	}) or { return errors.internal('Failed to retrieve variant', err.msg()) }

	if variants.len == 0 {
		return errors.not_found('Variant not found', 'variants.len == 0')
	}

	current := variants[0]

	return record.VariantUpdateParams{
		id:           p.id
		product_id:   current.product_id
		image_id:     common.unwrap_option_or_option(p.image_id, current.image_id)
		title:        common.unwrap_option_or_option(p.title, current.title)
		barcode:      common.unwrap_option_or_option(p.barcode, current.barcode)
		ean:          common.unwrap_option_or_option(p.ean, current.ean)
		upc:          common.unwrap_option_or_option(p.upc, current.upc)
		metadata:     common.unwrap_option_or_option(p.metadata, current.metadata)
		variant_rank: current.variant_rank
	}
}

fn (p VariantUpdateParams) parse_inventory_item(mut tx firebird.ClientTransaction, item InventoryItemUpdateParams) !record.InventoryItemUpdateParams {
	inventory_items := record.inventory_item_retrieve(mut tx, [p.id]) or {
		return errors.internal('Failed to retrieve inventory_item', err.msg())
	}

	if inventory_items.len == 0 {
		return errors.internal(errors.database_malformed,
			'No inventory item for variant with id `${p.id.string()}`')
	}

	current := inventory_items[0]

	return record.InventoryItemUpdateParams{
		id:                current.id
		variant_id:        current.variant_id
		sku:               common.unwrap_option_or_option(item.sku, current.sku)
		origin_country:    common.unwrap_option_or_option(item.origin_country,
			current.origin_country)
		hs_code:           common.unwrap_option_or_option(item.hs_code, current.hs_code)
		mid_code:          common.unwrap_option_or_option(item.mid_code, current.mid_code)
		material:          common.unwrap_option_or_option(item.material, current.material)
		weight:            common.unwrap_option_or_option(item.weight, current.weight)
		length:            common.unwrap_option_or_option(item.length, current.length)
		height:            common.unwrap_option_or_option(item.height, current.height)
		width:             common.unwrap_option_or_option(item.width, current.width)
		requires_shipping: common.unwrap_option_or(item.requires_shipping,
			current.requires_shipping)
		manage_inventory:  common.unwrap_option_or(item.manage_inventory, current.manage_inventory)
		allow_backorder:   common.unwrap_option_or(item.allow_backorder, current.allow_backorder)
	}
}

fn (p VariantUpdateParams) parse_money_amounts(mut g luuid.Generator, money_amounts []VariantMoneyAmountUpdateParams) []record.VariantMoneyAmountUpdateParams {
	mut res := []record.VariantMoneyAmountUpdateParams{len: 0, cap: money_amounts.len}
	for _, ma in money_amounts {
		res << record.VariantMoneyAmountUpdateParams{
			variant_id:      p.id
			region_id:       ma.region_id
			money_amount_id: common.new_id(mut g)
			amount:          ma.amount
			is_original:     ma.is_original
		}
	}
	return res
}

pub fn variant_update(mut tx firebird.ClientTransaction, mut g luuid.Generator, p VariantUpdateParams) ! {
	check_variant_id_exists(mut tx, p.id)!
	check_product_id_exists(mut tx, p.product_id)!
	// TODO check validity of money_amounts (region_id exist, 1 base price per region)
	// check option values exist, one value per option, no duplicates
	// check image id exists

	variant := p.parse_variant(mut tx)!
	record.variant_update(mut tx, variant) or {
		return errors.internal('Could not update product_variant', err.msg())
	}

	if option_value_ids := p.option_value_ids {
		parsed_option_values := parse_option_values(option_value_ids, p.id)
		record.product_option_value_variant_update(mut tx, parsed_option_values) or {
			return errors.internal('Could not update product_option_value_variant', err.msg())
		}
	}

	if inventory_item := p.inventory_item {
		parsed_inventory_item := p.parse_inventory_item(mut tx, inventory_item)!
		record.inventory_item_update(mut tx, [parsed_inventory_item]) or {
			return errors.internal('Could not update inventory_item', err.msg())
		}
	}

	if money_amounts := p.money_amounts {
		parsed_money_amounts := p.parse_money_amounts(mut g, money_amounts)
		record.variant_money_amount_update(mut tx, parsed_money_amounts) or {
			return errors.internal('Could not update money_amounts', err.msg())
		}
	}
}

pub fn variant_delete(mut tx firebird.ClientTransaction, product_id ID, variant_id ID) ! {
	check_product_id_exists(mut tx, product_id)!
	check_variant_id_exists(mut tx, variant_id)!

	mut count := record.variant_retrieve_count(mut tx, record.VariantRetrieveParams{
		ids:          [variant_id]
		product_ids:  [product_id]
		with_deleted: false
		offset:       offset_default // ignored by count fn
		fetch:        max_fetch      // ignored by count fn
		order:        order_default  // ignored by count fn	
	}) or { return errors.internal('Failed to retrieve variant count', err.msg()) }

	if count == 0 {
		return errors.not_found('variant `${variant_id.string()}` does not belong to product `${product_id.string()}`',
			'product and variant exist, but are not related')
	}

	count = record.variant_retrieve_count(mut tx, record.VariantRetrieveParams{
		product_ids:  [product_id]
		with_deleted: false
		offset:       offset_default // ignored by count fn
		fetch:        max_fetch      // ignored by count fn
		order:        order_default  // ignored by count fn	
	}) or { return errors.internal('Failed to retrieve variant count', err.msg()) }

	if count == 1 {
		return errors.unprocessable_entity('Cannot delete last variant of product `${product_id.string()}`',
			'A product must have at least one variant')
	}

	record.variant_delete(mut tx, variant_id) or {
		return errors.internal('Could not delete variant', err.msg())
	}
}
