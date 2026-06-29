module conduit

import arrays
import einar_hjortdal.firebird
import einar_hjortdal.luuid
import einar_hjortdal.slugify
import record
import internal.common
import internal.errors

pub struct ProductTranslationCreateParams {
pub:
	locale_id   ID
	title       ?string
	subtitle    ?string
	description ?string
}

pub struct ProductOptionValueTranslationCreateParams {
pub:
	locale_id ID
	name      string
}

pub struct ProductOptionValueCreateParams {
pub:
	name         string
	translations ?[]ProductOptionValueTranslationCreateParams
}

pub struct ProductOptionTranslationCreateParams {
pub:
	locale_id ID
	title     string
}

pub struct ProductOptionCreateParams {
pub:
	option_rank  i32
	title        string
	values       []ProductOptionValueCreateParams
	translations ?[]ProductOptionTranslationCreateParams
}

pub struct ProductVariantCreateParams {
	image_id       ?ID
	title          ?string
	ean            ?string
	upc            ?string
	barcode        ?string
	metadata       ?string
	option_values  ?[]i32
	inventory_item ?InventoryItemCreateParams
	money_amounts  ?[]VariantMoneyAmountUpdateParams
}

pub struct ImageTranslationCreateParams {
pub:
	locale_id ID
	alt       string
}

pub struct ImageCreateParams {
pub:
	url          string
	alt          ?string
	translations ?[]ImageTranslationCreateParams
}

pub struct ProductCreateParams {
pub:
	handle            ?string
	title             string
	subtitle          ?string
	description       ?string
	is_giftcard       ?bool
	status            ?string
	discountable      ?bool
	metadata          ?string
	sales_channel_ids ?[]ID
	category_ids      ?[]ID
	translations      ?[]ProductTranslationCreateParams
	seo               ?SEOParams
	options           ?[]ProductOptionCreateParams
	variants          ?[]ProductVariantCreateParams
	thumbnail         ?i32
	images            ?[]ImageCreateParams
}

fn (p ProductCreateParams) check_handle(mut tx firebird.ClientTransaction) ! {
	handle := p.handle or { return }
	count := record.product_retrieve_count(mut tx, record.ProductRetrieveParams{
		handle:       handle
		with_deleted: false
		offset:       offset_default // ignored by count fn
		fetch:        min_fetch      // ignored by count fn
		order:        order_default  // ignored by count fn
	}) or { return errors.internal('Failed to retrieve product count', err.msg()) }

	if count != 0 {
		return errors.unprocessable_entity('handle not unique',
			'A product already exists with the given handle')
	}
}

fn (p ProductCreateParams) check_sales_channel_ids(mut tx firebird.ClientTransaction) ! {
	sales_channel_ids := p.sales_channel_ids or { return }
	sales_channels_count := record.sales_channel_retrieve_count(mut tx, record.SalesChannelRetrieveParams{
		ids:          sales_channel_ids
		with_deleted: false
		offset:       offset_default // ignored by count fn
		fetch:        min_fetch      // ignored by count fn
		order:        order_default  // ignored by count fn
	}) or { return errors.internal('Failed to retrieve sales_channel count', err.msg()) }

	if sales_channels_count != sales_channel_ids.len {
		return errors.unprocessable_entity(errors.id_invalid,
			'One or more sales channel id does not exist')
	}
}

fn (p ProductCreateParams) parse_product(product_id ID) record.ProductCreateParams {
	handle := p.handle or { slugify.default().make(p.title) }

	return record.ProductCreateParams{
		id:           product_id
		handle:       handle
		title:        p.title
		subtitle:     p.subtitle
		description:  p.description
		is_giftcard:  common.bool_or(p.is_giftcard, common.product_is_giftcard_default)
		status:       common.unwrap_option_or(p.status, common.product_status_draft)
		discountable: common.bool_or(p.discountable, common.product_discountable_default)
		metadata:     p.metadata
	}
}

fn (p ProductCreateParams) parse_seo(mut g luuid.Generator, product_id ID) record.ProductSEOCreateParams {
	seo_id := common.new_id(mut g)
	s := p.seo or {
		return record.ProductSEOCreateParams{
			id:         seo_id
			product_id: product_id
		}
	}

	return s.parse_product_create(seo_id, product_id)
}

fn (p ProductCreateParams) parse_seo_translations(seo_id ID) ?[]record.SEOTranslationCreateParams {
	seo := p.seo or { return none }
	translations := seo.translations or { return none }
	if translations.len == 0 {
		return none
	}

	mut res := []record.SEOTranslationCreateParams{len: 0, cap: translations.len}
	for _, translation in translations {
		res << translation.parse(seo_id)
	}
	return res
}

fn (p ProductCreateParams) parse_options(mut g luuid.Generator, product_id ID) []record.ProductOptionCreateParams {
	options := p.options or {
		default_option := record.ProductOptionCreateParams{
			id:          common.new_id(mut g)
			product_id:  product_id
			option_rank: common.product_option_rank_default
			title:       common.product_option_title_default
		}
		return [default_option]
	}

	mut res := []record.ProductOptionCreateParams{len: 0, cap: options.len}
	for option_rank, option in options {
		res << record.ProductOptionCreateParams{
			id:          common.new_id(mut g)
			product_id:  product_id
			option_rank: i32(option_rank)
			title:       option.title
		}
	}
	return res
}

fn (p ProductCreateParams) parse_option_translations(parsed_options []record.ProductOptionCreateParams) ?[]record.ProductOptionTranslationCreateParams {
	options := p.options or { return none }

	mut n_translations := 0
	for _, option in options {
		translations := option.translations or { continue }
		n_translations += translations.len
	}

	if n_translations == 0 {
		return none
	}

	mut res := []record.ProductOptionTranslationCreateParams{len: 0, cap: n_translations}
	for index, option in options {
		translations := option.translations or { continue }
		for _, translation in translations {
			res << record.ProductOptionTranslationCreateParams{
				product_option_id: parsed_options[index].id
				locale_id:         translation.locale_id
				title:             translation.title
			}
		}
	}
	return res
}

fn (p ProductCreateParams) parse_option_values(mut g luuid.Generator, parsed_options []record.ProductOptionCreateParams) ![]record.ProductOptionValueCreateParams {
	if parsed_options.len == 0 {
		return errors.internal('Expected at least one option',
			'ProductCreateParams.parse_option_values received empty parsed_options array')
	}

	options := p.options or {
		option := parsed_options[0]
		default_option_value := record.ProductOptionValueCreateParams{
			id:         common.new_id(mut g)
			option_id:  option.id
			value_rank: common.product_option_value_rank_default
			name:       common.product_option_value_name_default
		}
		return [default_option_value]
	}

	mut n_values := 0
	for _, option in options {
		n_values += option.values.len
	}

	mut res := []record.ProductOptionValueCreateParams{len: 0, cap: n_values}
	for i, option in options {
		parsed_option := parsed_options[i]
		for value_rank, value in option.values {
			res << record.ProductOptionValueCreateParams{
				id:         common.new_id(mut g)
				option_id:  parsed_option.id
				value_rank: i32(value_rank)
				name:       value.name
			}
		}
	}
	return res
}

fn (p ProductCreateParams) parse_option_value_translations(parsed_values []record.ProductOptionValueCreateParams) ?[]record.ProductOptionValueTranslationCreateParams {
	options := p.options or { return none }

	mut n_translations := 0
	for _, option in options {
		values := option.values
		for _, value in values {
			translations := value.translations or { continue }
			n_translations += translations.len
		}
	}

	if n_translations == 0 {
		return none
	}

	mut res := []record.ProductOptionValueTranslationCreateParams{len: 0, cap: n_translations}
	mut value_index := 0
	for _, option in options {
		for _, value in option.values {
			translations := value.translations or {
				value_index++
				continue
			}

			for translation in translations {
				res << record.ProductOptionValueTranslationCreateParams{
					product_option_value_id: parsed_values[value_index].id
					locale_id:               translation.locale_id
					name:                    translation.name
				}
			}
			value_index++
		}
	}
	return res
}

fn (p ProductCreateParams) parse_translations(product_id ID, translations []ProductTranslationCreateParams) []record.ProductTranslationCreateParams {
	mut res := []record.ProductTranslationCreateParams{len: 0, cap: translations.len}
	for _, translation in translations {
		res << record.ProductTranslationCreateParams{
			product_id:  product_id
			locale_id:   translation.locale_id
			title:       translation.title
			subtitle:    translation.subtitle
			description: translation.description
		}
	}
	return res
}

fn (p ProductCreateParams) parse_variants(mut g luuid.Generator, product_id ID) []record.VariantCreateParams {
	variants := p.variants or {
		default_variant := record.VariantCreateParams{
			id:           common.new_id(mut g)
			product_id:   product_id
			variant_rank: common.variant_rank_default
		}
		return [default_variant]
	}

	mut res := []record.VariantCreateParams{len: 0, cap: variants.len}
	for variant_rank, variant in variants {
		res << record.VariantCreateParams{
			id:           common.new_id(mut g)
			image_id:     variant.image_id
			title:        variant.title
			ean:          variant.ean
			upc:          variant.upc
			barcode:      variant.barcode
			metadata:     variant.metadata
			variant_rank: i32(variant_rank)
		}
	}
	return res
}

// assumes options and variants are ordered (as returned by ProductCreateParams.parse_options and ProductCreateParams.parse_option_values)
fn (p ProductCreateParams) parse_option_value_variants(parsed_variants []record.VariantCreateParams, parsed_options []record.ProductOptionCreateParams, parsed_option_values []record.ProductOptionValueCreateParams) ![]record.ProductOptionValueVariant {
	if parsed_variants.len == 0 {
		return errors.internal('Expected at least one option',
			'ProductCreateParams.parse_option_value_variants received empty parsed_variants array')
	}

	if parsed_option_values.len == 0 {
		return errors.internal('Expected at least one option',
			'ProductCreateParams.parse_option_value_variants received empty parsed_option_values array')
	}

	variants := p.variants or {
		return [
			record.ProductOptionValueVariant{
				option_value_id: parsed_option_values[0].id
				variant_id:      parsed_variants[0].id
			},
		]
	}

	if variants.len == 0 {
		return errors.internal('Expected at least one variant',
			'ProductCreateParams.parse_option_value_variants received ProductCreateParams.variants array, which should have been rejected')
	}

	mut option_id_to_index := map[string]i32{}
	for _, option in parsed_options {
		option_id_to_index[option.id.string()] = option.option_rank
	}

	mut option_index_value_ids := map[i32][]ID{}
	for _, value in parsed_option_values {
		option_index := option_id_to_index[value.option_id.string()]
		if option_index !in option_index_value_ids {
			option_index_value_ids[option_index] = []ID{len: 0, cap: 4} // TODO sane default, use const
		}
		option_index_value_ids[option_index] << value.id
	}

	mut res := []record.ProductOptionValueVariant{len: 0, cap: variants.len * parsed_options.len}
	for variant_rank, variant in variants {
		variant_id := parsed_variants[variant_rank].id
		for option_index, value_index in variant.option_values {
			res << record.ProductOptionValueVariant{
				option_value_id: option_index_value_ids[option_index][value_index]
				variant_id:      variant_id
			}
		}
	}
	return res
}

fn (p ProductCreateParams) parse_inventory_items(mut g luuid.Generator, parsed_variants []record.VariantCreateParams) ![]record.InventoryItemCreateParams {
	if parsed_variants.len == 0 {
		return errors.internal('Expected at least one option',
			'ProductCreateParams.parse_option_value_variants received empty parsed_variants array')
	}

	variants := p.variants or {
		return [
			record.InventoryItemCreateParams{
				id:                common.new_id(mut g)
				variant_id:        parsed_variants[0].id
				requires_shipping: common.inventory_item_requires_shipping_default
				manage_inventory:  common.inventory_item_manage_inventory_default
				allow_backorder:   common.inventory_item_allow_backorder_default
			},
		]
	}

	mut res := []record.InventoryItemCreateParams{len: 0, cap: variants.len}
	for variant_index, variant in variants {
		variant_id := parsed_variants[variant_index].id
		item := variant.inventory_item or {
			res << record.InventoryItemCreateParams{
				id:                common.new_id(mut g)
				variant_id:        variant_id
				requires_shipping: common.inventory_item_requires_shipping_default
				manage_inventory:  common.inventory_item_manage_inventory_default
				allow_backorder:   common.inventory_item_allow_backorder_default
			}
			continue
		}

		res << record.InventoryItemCreateParams{
			id:                common.new_id(mut g)
			variant_id:        variant_id
			sku:               item.sku
			origin_country:    item.origin_country
			hs_code:           item.hs_code
			mid_code:          item.mid_code
			material:          item.material
			weight:            item.weight
			length:            item.length
			height:            item.height
			width:             item.width
			requires_shipping: common.unwrap_option_or(item.requires_shipping,
				common.inventory_item_requires_shipping_default)
			manage_inventory:  common.unwrap_option_or(item.manage_inventory,
				common.inventory_item_manage_inventory_default)
			allow_backorder:   common.unwrap_option_or(item.allow_backorder,
				common.inventory_item_allow_backorder_default)
		}
	}
	return res
}

fn (p ProductCreateParams) parse_money_amounts(mut tx firebird.ClientTransaction, mut g luuid.Generator, parsed_variants []record.VariantCreateParams) ![]record.VariantMoneyAmountUpdateParams {
	if parsed_variants.len == 0 {
		return errors.internal('Expected at least one variant',
			'ProductCreateParams.parse_money_amounts received parsed_variants array')
	}

	regions := record.region_retrieve(mut tx, record.RegionRetriveParams{
		with_deleted: false
		offset:       offset_default
		fetch:        max_fetch // limit 250 regions or refactor? or make const internal_max_fetch = max_i32?
		order:        order_default
	}) or { return errors.internal('Failed to retrieve region', err.msg()) }

	variants := p.variants or {
		mut res := []record.VariantMoneyAmountUpdateParams{len: 0, cap: regions.len}
		for _, region in regions {
			res << record.VariantMoneyAmountUpdateParams{
				variant_id:      parsed_variants[0].id
				region_id:       region.id
				money_amount_id: common.new_id(mut g)
				amount:          common.money_amount_default_amount
				is_original:     common.money_amount_default_is_original
			}
		}
		return res
	}

	// one original price (optional), one base price per variant per region
	mut res := []record.VariantMoneyAmountUpdateParams{len: 0, cap: 2 * variants.len * regions.len}
	for variant_index, variant in p.variants {
		money_amounts := variant.money_amounts or {
			for _, region in regions {
				res << record.VariantMoneyAmountUpdateParams{
					variant_id:      parsed_variants[variant_index].id
					region_id:       region.id
					money_amount_id: common.new_id(mut g)
					amount:          common.money_amount_default_amount
					is_original:     common.money_amount_default_is_original
				}
			}
			continue
		}

		for _, ma in money_amounts {
			res << record.VariantMoneyAmountUpdateParams{
				variant_id:      parsed_variants[variant_index].id
				region_id:       ma.region_id
				money_amount_id: common.new_id(mut g)
				amount:          ma.amount
				is_original:     ma.is_original
			}
		}
	}

	return res
}

fn (p ProductCreateParams) parse_sales_channel_ids(mut tx firebird.ClientTransaction) ![]ID {
	sales_channels := p.sales_channel_ids or {
		store := record.store_retrieve(mut tx) or {
			return errors.internal('Failed to retrieve store', err.msg())
		}

		return [store.default_sales_channel_id]
	}

	return sales_channels
}

fn (p ProductCreateParams) parse_images(mut g luuid.Generator) ![]record.ProductImageCreateParams {
	images := p.images or {
		return errors.internal('failed to parse product images for creation',
			'ProductCreateParams.arse_images was used when p.images was none')
	}

	mut res := []record.ProductImageCreateParams{len: 0, cap: images.len}
	for image_rank, image in images {
		image_id := common.new_id(mut g)
		res << record.ProductImageCreateParams{
			id:           image_id
			url:          image.url
			alt:          image.alt
			image_rank:   i32(image_rank)
			translations: p.parse_image_translations(image_id, image.translations)
		}
	}
	return res
}

// TODO refactor to take parsed_images []record.ProductImageCreateParams parameter instead (new endpoints)
fn (p ProductCreateParams) parse_image_translations(image_id ID, translations ?[]ImageTranslationCreateParams) ?[]record.ImageTranslationCreateParams {
	ts := translations or { return none }
	mut res := []record.ImageTranslationCreateParams{len: 0, cap: ts.len}
	for _, translation in ts {
		res << record.ImageTranslationCreateParams{
			image_id:  image_id
			locale_id: translation.locale_id
			alt:       translation.alt
		}
	}
	return res
}

pub fn product_create(mut tx firebird.ClientTransaction, mut g luuid.Generator, p ProductCreateParams) !ID {
	p.check_handle(mut tx)!

	product_id := common.new_id(mut g)
	product := p.parse_product(product_id)
	record.product_create(mut tx, product) or {
		return errors.internal('Failed to create product', err.msg())
	}

	seo := p.parse_seo(mut g, product_id)
	record.product_seo_create(mut tx, seo) or {
		return errors.internal('Failed to create seo', err.msg())
	}

	if seo_translations := p.parse_seo_translations(seo.id) {
		record.seo_translations_create(mut tx, seo_translations) or {
			return errors.internal('Failed to create seo_translation', err.msg())
		}
	}

	options := p.parse_options(mut g, product_id)
	record.product_option_create(mut tx, options) or {
		return errors.internal('Failed to create product_option', err.msg())
	}

	if option_translations := p.parse_option_translations(options) {
		mut option_ids := []ID{len: 0, cap: options.len}
		for _, option in options {
			option_ids << option.id
		}
		record.product_option_translations_update(mut tx, option_ids, option_translations) or {
			return errors.internal('Failed to create product_option_translations', err.msg())
		}
	}

	option_values := p.parse_option_values(mut g, options)!
	record.product_option_value_create(mut tx, option_values) or {
		return errors.internal('Failed to create product_option_value', err.msg())
	}

	if option_value_translations := p.parse_option_value_translations(option_values) {
		mut option_value_ids := []ID{len: 0, cap: option_values.len}
		for _, value in option_values {
			option_value_ids << value.id
		}
		record.product_option_value_translations_update(mut tx, option_value_ids,
			option_value_translations) or {
			return errors.internal('Failed to create product_option_value_translations', err.msg())
		}
	}

	variants := p.parse_variants(mut g, product_id)
	record.variant_create(mut tx, variants) or {
		return errors.internal('Could not create variants', err.msg())
	}

	option_value_variants := p.parse_option_value_variants(variants, options, option_values)!
	record.product_option_value_variant_update(mut tx, option_value_variants) or {
		return errors.internal('Failed to create relations in product_option_value_variant',
			err.msg())
	}

	inventory_items := p.parse_inventory_items(mut g, variants)!
	record.inventory_item_create(mut tx, inventory_items) or {
		return errors.internal('Failed to create inventory_item', err.msg())
	}

	money_amounts := p.parse_money_amounts(mut tx, mut g, variants)!
	record.variant_money_amount_update(mut tx, money_amounts) or {
		return errors.internal('Failed to create variant money_amount', err.msg())
	}

	sales_channel_ids := p.parse_sales_channel_ids(mut tx)!
	record.product_sales_channel_update(mut tx, product_id, sales_channel_ids) or {
		return errors.internal('Failed to update product_sales_channel', err.msg())
	}

	if translations := p.translations {
		t := p.parse_translations(product_id, translations)
		record.product_translation_create(mut tx, t) or {
			return errors.internal('Failed to update product translations', err.msg())
		}
	}

	if _ := p.images {
		parsed_images := p.parse_images(mut g)!
		record.product_image_create(mut tx, product_id, parsed_images) or {
			return errors.internal('Failed to create product_image', err.msg())
		}

		mut thumbnail_id := parsed_images[0].id
		if thumbnail_index := p.thumbnail {
			thumbnail_id = parsed_images[thumbnail_index].id
		}

		record.product_thumbnail_update(mut tx, product_id, thumbnail_id) or {
			return errors.internal('Failed to update product thumbnail', err.msg())
		}
	}

	// TODO independent image endpoint refactor, split concerns of translation updates
	// if image_translations := p.parse_image_translations() {
	// }

	if category_ids := p.category_ids {
		record.category_product_update(mut tx, product_id, category_ids) or {
			return errors.internal('Failed to update product category relation', err.msg())
		}
	}

	return product_id
}

fn get_products_translations(mut tx firebird.ClientTransaction, mut products_map map[string]record.Product, product_ids []ID) ! {
	translations := record.product_translations_retrieve(mut tx, product_ids) or {
		return errors.internal('Failed to retrieve product_translation', err.msg())
	}

	for i := 0; i < translations.len; i++ {
		translation := translations[i]
		product_id := translation.product_id
		old := products_map[product_id.string()].translations
		products_map[product_id.string()].translations = arrays.concat(old, translation)
	}
}

fn get_products_seo(mut tx firebird.ClientTransaction, mut products_map map[string]record.Product, product_ids []ID) ! {
	product_seo := record.product_seo_retrieve(mut tx, product_ids) or {
		return errors.internal('Failed to retrieve seo', err.msg())
	}

	mut seo_map, seo_ids := common.make_identifiable_map(product_seo)
	translations := record.seo_translation_retrieve(mut tx, seo_ids) or {
		return errors.internal('Failed to retrieve seo_translations', err.msg())
	}

	for i := 0; i < translations.len; i++ {
		translation := translations[i]
		seo_id := translation.seo_id
		old := seo_map[seo_id.string()].translations
		seo_map[seo_id.string()].translations = arrays.concat(old, translation)
	}

	for i := 0; i < product_seo.len; i++ {
		seo := product_seo[i]
		product_id := seo.product_id
		seo_id := seo.id
		products_map[product_id.string()].seo = seo_map[seo_id.string()]
	}
}

fn get_products_images(mut tx firebird.ClientTransaction, mut products_map map[string]record.Product, product_ids []ID) ! {
	images := record.product_image_retrieve(mut tx, record.ProductImageRetrieveParams{
		product_ids: product_ids
	}) or { return errors.internal('Failed to retrieve product_image', err.msg()) }

	if images.len == 0 {
		return
	}

	mut images_map, image_ids := common.make_identifiable_map(images)

	translations := record.image_translation_retrieve(mut tx, image_ids) or {
		return errors.internal('Failed to retrieve image_translation', err.msg())
	}

	for i := 0; i < translations.len; i++ {
		translation := translations[i]
		image_id := translation.image_id
		old := images_map[image_id.string()].translations
		images_map[image_id.string()].translations = arrays.concat(old, translation)
	}

	for i := 0; i < images.len; i++ {
		image_id := images[i].id
		image := images_map[image_id.string()]
		product_id := image.product_id
		old := products_map[product_id.string()].images
		products_map[product_id.string()].images = arrays.concat(old, image)
	}
}

fn get_products_sales_channels(mut tx firebird.ClientTransaction, mut products_map map[string]record.Product, product_ids []ID) ! {
	sales_channels := record.product_sales_channel_retrieve(mut tx, product_ids) or {
		return errors.internal('Failed to retrieve product_sales_channel', err.msg())
	}

	for i := 0; i < sales_channels.len; i++ {
		product_id := sales_channels[i].product_id
		channel_id := sales_channels[i].sales_channel_id
		old := products_map[product_id.string()].sales_channels_ids
		products_map[product_id.string()].sales_channels_ids = arrays.concat(old, channel_id)
	}
}

fn get_products_categories(mut tx firebird.ClientTransaction, mut products_map map[string]record.Product, product_ids []ID) ! {
	category_products := record.category_product_retrieve(mut tx, record.CategoryProductRetrieveParams{
		product_ids: product_ids
	}) or { return errors.internal('Failed to retrieve category_product', err.msg()) }

	for i := 0; i < category_products.len; i++ {
		category_id := category_products[i].category_id
		product_id := category_products[i].product_id
		old := products_map[product_id.string()].category_ids
		products_map[product_id.string()].category_ids = arrays.concat(old, category_id)
	}
}

fn get_products_options(mut tx firebird.ClientTransaction, mut products_map map[string]record.Product, product_ids []ID) ! {
	options := record.product_option_retrieve(mut tx, product_ids) or {
		return errors.internal('Failed to retrieve product_option', err.msg())
	}

	mut options_map, option_ids := common.make_identifiable_map(options)
	get_product_option_translations(mut tx, mut options_map, option_ids)!
	get_product_option_values(mut tx, mut options_map, option_ids)!
}

fn get_products_variants(mut tx firebird.ClientTransaction, mut products_map map[string]record.Product, product_ids []ID) ! {
	// TODO loop for pagination
	variants := record.variant_retrieve(mut tx, record.VariantRetrieveParams{
		product_ids:  product_ids
		with_deleted: false
		offset:       offset_default
		fetch:        max_fetch
		order:        order_default
	}) or { return errors.internal('Failed to retrieve product_variant', err.msg()) }

	mut variants_map, variant_ids_bin := common.make_identifiable_map(variants)
	get_variants_money_amounts(mut tx, mut variants_map, variant_ids_bin)!
	get_variants_inventory_items(mut tx, mut variants_map, variant_ids_bin)!
	get_variants_option_values(mut tx, mut variants_map, variant_ids_bin)!

	for i := 0; i < variants.len; i++ {
		variant_id := variants[i].id
		variant := variants_map[variant_id.string()]
		product_id := variant.product_id
		old := products_map[product_id.string()].variants
		products_map[product_id.string()].variants = arrays.concat(old, variant)
	}
}

// Note: we are fetching option values and their translations twice. once for products, once for variants. This is not efficient.
pub fn product_list(mut tx firebird.ClientTransaction, p ProductRetrieveParams) !List[Product] {
	count := record.product_retrieve_count(mut tx, p) or {
		return errors.internal('Failed to retrieve product count', err.msg())
	}

	if count == 0 {
		return List[Product]{}
	}

	products := record.product_retrieve(mut tx, p) or {
		return errors.internal('Failed to retrieve product', err.msg())
	}

	if products.len == 0 {
		return List[Product]{
			count: count
		}
	}

	mut products_map, product_ids := common.make_identifiable_map(products)
	get_products_translations(mut tx, mut products_map, product_ids)!
	get_products_seo(mut tx, mut products_map, product_ids)!
	get_products_images(mut tx, mut products_map, product_ids)!
	get_products_sales_channels(mut tx, mut products_map, product_ids)!
	get_products_categories(mut tx, mut products_map, product_ids)!
	get_products_options(mut tx, mut products_map, product_ids)!
	get_products_variants(mut tx, mut products_map, product_ids)!

	// sort complete products
	mut complete_products := []record.Product{len: products.len}
	for i := 0; products.len; i++ {
		id := products[i].id
		complete_products[i] = products_map[id.string()]
	}

	return List[Product]{
		count: count
		items: complete_products
	}
}

pub fn product_get(mut tx firebird.ClientTransaction, product_id ID) !record.Product {
	products := record.product_retrieve(mut tx, ProductRetrieveParams{
		ids:          [product_id]
		with_deleted: false
		offset:       offset_default
		fetch:        1
		order:        order_default
	}) or { return errors.internal('Failed to retrieve products data', err.msg()) }

	if products.len == 0 {
		return errors.not_found('No product exists with the given id', 'products.len == 0')
	}

	mut products_map := {
		product_id.string(): products[0]
	}
	product_ids := [product_id]
	get_products_translations(mut tx, mut products_map, product_ids)!
	get_products_seo(mut tx, mut products_map, product_ids)!
	get_products_images(mut tx, mut products_map, product_ids)!
	get_products_sales_channels(mut tx, mut products_map, product_ids)!
	get_products_categories(mut tx, mut products_map, product_ids)!
	get_products_options(mut tx, mut products_map, product_ids)!
	get_products_variants(mut tx, mut products_map, product_ids)!
	return products_map[product_id.string()]
}

pub fn product_get_store(mut tx firebird.ClientTransaction, product_id ID, sales_channel_id ID) !record.Product {
	products := record.product_retrieve(mut tx, ProductRetrieveParams{
		ids:              [product_id]
		status:           common.product_status_published
		sales_channel_id: sales_channel_id
		with_deleted:     false
		offset:           offset_default
		fetch:            1
		order:            order_default
	}) or { return errors.internal('Failed to retrieve products data', err.msg()) }

	if products.len == 0 {
		return errors.not_found('No product exists with the given id', 'products.len == 0')
	}

	mut products_map := {
		product_id.string(): products[0]
	}
	product_ids := [product_id]
	get_products_translations(mut tx, mut products_map, product_ids)!
	get_products_seo(mut tx, mut products_map, product_ids)!
	get_products_images(mut tx, mut products_map, product_ids)!
	get_products_sales_channels(mut tx, mut products_map, product_ids)!
	get_products_categories(mut tx, mut products_map, product_ids)!
	get_products_options(mut tx, mut products_map, product_ids)!
	get_products_variants(mut tx, mut products_map, product_ids)!
	return products_map[product_id.string()]
}

pub struct ProductUpdateData {
pub:
	product                   record.ProductUpdateParams
	translations              ?[]record.ProductTranslationCreateParams
	seo                       ?record.SEOUpdateParams
	seo_translations          ?[]record.SEOTranslationCreateParams
	images                    ?[]record.ProductImageCreateParams
	thumbnail_id              ?ID
	sales_channel_ids         ?[]ID
	category_ids              ?[]ID
	options                   ?[]record.ProductOptionUpdateParams
	option_translations       ?record.ProductOptionTranslationUpdateParams
	option_values             ?[]record.ProductOptionValueUpdateParams
	option_value_translations ?record.ProductOptionValueTranslationUpdateParams
	option_value_variant      ?[]record.ProductOptionValueVariant
	variants                  ?[]record.VariantUpdateParams
	inventory_items           ?[]record.InventoryItemUpdateParams
	variant_money_amounts     ?[]record.VariantMoneyAmountUpdateParams
}

fn product_translations_update(mut tx firebird.ClientTransaction, product_id ID, p []record.ProductTranslationCreateParams) ! {
	record.product_translation_delete(mut tx, product_id) or {
		return errors.internal('Failed to delete existing product_translation', err.msg())
	}

	if p.len > 0 {
		record.product_translation_create(mut tx, p) or {
			return errors.internal('Failed to create product_translation', err.msg())
		}
	}
}

fn product_seo_translations_update(mut tx firebird.ClientTransaction, product_id ID, p []record.SEOTranslationCreateParams) ! {
	record.product_seo_translations_delete(mut tx, product_id) or {
		return errors.internal('Could not delete seo_translations', err.msg())
	}

	if p.len > 0 {
		record.seo_translations_create(mut tx, p) or {
			return errors.internal('Could not update seo_translations', err.msg())
		}
	}
}

fn product_images_update(mut tx firebird.ClientTransaction, product_id ID, images []record.ProductImageCreateParams) ! {
	record.product_thumbnail_delete(mut tx, product_id) or {
		return errors.internal('Failed to delete product thumbnail', err.msg())
	}

	record.product_image_delete(mut tx, product_id) or {
		return errors.internal('Failed to delete product images', err.msg())
	}

	if images.len > 0 {
		record.product_image_update(mut tx, product_id, images) or {
			return errors.internal('Failed to update product images', err.msg())
		}
	}
}

pub fn product_update(mut tx firebird.ClientTransaction, p ProductUpdateData) ! {
	check_product_id_exists(mut tx, p.product.id)!

	// always update the product row for `updated_at`
	record.product_update(mut tx, p.product) or {
		return errors.internal('Failed to update product', err.msg())
	}

	if translations := p.translations {
		product_translations_update(mut tx, p.product.id, translations)!
	}

	if seo := p.seo {
		record.seo_update(mut tx, seo) or {
			return errors.internal('Could not update seo', err.msg())
		}
	}

	if translations := p.seo_translations {
		product_seo_translations_update(mut tx, p.product.id, translations)!
	}

	if images := p.images {
		product_images_update(mut tx, p.product.id, images)!
	}

	if thumbnail_id := p.thumbnail_id {
		record.product_thumbnail_update(mut tx, p.product.id, thumbnail_id) or {
			return errors.internal('Failed to update product thumbnail', err.msg())
		}
	}

	if sales_channel_ids := p.sales_channel_ids {
		record.product_sales_channel_update(mut tx, p.product.id, sales_channel_ids) or {
			return errors.internal('Failed to update product sales channel', err.msg())
		}
	}

	if category_ids := p.category_ids {
		record.category_product_update(mut tx, p.product.id, category_ids) or {
			return errors.internal('Failed to update product category relation', err.msg())
		}
	}

	if options := p.options {
		record.product_option_update(mut tx, options) or {
			return errors.internal('Could not update product_option', err.msg())
		}
	}

	if translations := p.option_translations {
		record.product_option_translations_update(mut tx, translations) or {
			return errors.internal('Could not update product_option_translations', err.msg())
		}
	}

	if option_values := p.option_values {
		record.product_option_value_update(mut tx, option_values) or {
			return errors.internal('Could not update product_option_value', err.msg())
		}
	}

	if translations := p.option_value_translations {
		record.product_option_value_translations_update(mut tx, translations) or {
			return errors.internal('Could not update option_value_translations', err.msg())
		}
	}

	if variants := p.variants {
		record.product_variant_update(mut tx, p.product.id, variants) or {
			return errors.internal('Failed to update variants', err.msg())
		}
	}

	if inventory_items := p.inventory_items {
		record.inventory_item_update(mut tx, inventory_items) or {
			return errors.internal('Failed to update inventory items', err.msg())
		}

		record.inventory_item_sync_delete(mut tx, p.product.id) or {
			return errors.internal('Failed to delete inventory items', err.msg())
		}
	}

	if option_value_variant := p.option_value_variant {
		record.product_option_value_variant_update(mut tx, option_value_variant) or {
			return errors.internal('Failed to update product_option_value_variant', err.msg())
		}
	}

	if variant_money_amounts := p.variant_money_amounts {
		record.variant_money_amount_update(mut tx, variant_money_amounts) or {
			return errors.internal('Failed to update variant_money_amount', err.msg())
		}
	}
}

pub fn product_delete(mut tx firebird.ClientTransaction, product_id ID) ! {
	check_product_id_exists(mut tx, product_id)!
	record.product_delete(mut tx, product_id) or {
		return errors.internal('Failed to delete product', err.msg())
	}
}
