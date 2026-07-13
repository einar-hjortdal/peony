module conduit

import arrays
import einar_hjortdal.firebird
import einar_hjortdal.luuid
import einar_hjortdal.slugify
import record
import internal.common
import internal.errors
import objects

fn parse_option_values(option_value_ids []ID, variant_id ID) []record.ProductOptionValueVariant {
	mut res := []record.ProductOptionValueVariant{len: option_value_ids.len}
	for i := 0; i < option_value_ids.len; i++ {
		res[i] = record.ProductOptionValueVariant{
			option_value_id: option_value_ids[i]
			variant_id:      variant_id
		}
	}
	return res
}

fn parse_product_translations(product_id ID, translations []ProductTranslationCreateParams) []record.ProductTranslationCreateParams {
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

fn parse_seo_translations(seo_id ID, translations []SEOTranslationParams) []record.SEOTranslationCreateParams {
	mut res := []record.SEOTranslationCreateParams{len: 0, cap: translations.len}
	for _, translation in translations {
		res << translation.parse(seo_id)
	}
	return res
}

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
	title        string
	values       []ProductOptionValueCreateParams
	translations ?[]ProductOptionTranslationCreateParams
}

pub struct ProductVariantCreateParams {
pub:
	title          ?string
	ean            ?string
	upc            ?string
	barcode        ?string
	metadata       ?string
	option_values  ?[]i32
	inventory_item ?InventoryItemCreateParams
	money_amounts  ?[]VariantMoneyAmountUpdateParams
	image          ?i32
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
	check_product_handle(mut tx, handle)!
}

fn (p ProductCreateParams) check_sales_channel_ids(mut tx firebird.ClientTransaction) ! {
	sales_channel_ids := p.sales_channel_ids or { return }
	sales_channels_count := record.sales_channel_retrieve_count(mut tx, record.SalesChannelRetrieveParams{
		ids:          sales_channel_ids
		with_deleted: false
		offset:       objects.offset_default // ignored by count fn
		fetch:        objects.min_fetch      // ignored by count fn
		order:        objects.order_default  // ignored by count fn
	}) or { return errors.internal('Failed to retrieve sales_channel count', err.msg()) }

	if sales_channels_count != sales_channel_ids.len {
		return errors.unprocessable_entity(errors.id_invalid,
			'One or more sales channel id does not exist')
	}
}

fn (p ProductCreateParams) parse_product(product_id ID) record.ProductCreateParams {
	handle := p.handle or { slugify.default().make(p.title) } // TODO could be duplicate, need check or better default

	return record.ProductCreateParams{
		id:           product_id
		handle:       handle
		title:        p.title
		subtitle:     p.subtitle
		description:  p.description
		is_giftcard:  common.bool_or(p.is_giftcard, objects.product_is_giftcard_default)
		status:       common.unwrap_option_or(p.status, objects.product_status_draft)
		discountable: common.bool_or(p.discountable, objects.product_discountable_default)
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

	return parse_seo_translations(seo_id, translations)
}

fn (p ProductCreateParams) parse_options(mut g luuid.Generator, product_id ID) []record.ProductOptionCreateParams {
	options := p.options or {
		default_option := record.ProductOptionCreateParams{
			id:          common.new_id(mut g)
			product_id:  product_id
			option_rank: objects.product_option_rank_default
			title:       objects.product_option_title_default
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
			value_rank: objects.product_option_value_rank_default
			name:       objects.product_option_value_name_default
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

fn (p ProductCreateParams) parse_variants(mut g luuid.Generator, product_id ID) []record.VariantCreateParams {
	variants := p.variants or {
		default_variant := record.VariantCreateParams{
			id:           common.new_id(mut g)
			product_id:   product_id
			variant_rank: objects.variant_rank_default
		}
		return [default_variant]
	}

	mut res := []record.VariantCreateParams{len: 0, cap: variants.len}
	for variant_rank, variant in variants {
		res << record.VariantCreateParams{
			id:           common.new_id(mut g)
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
fn (p ProductCreateParams) parse_option_value_variants(
	parsed_variants []record.VariantCreateParams,
	parsed_options []record.ProductOptionCreateParams,
	parsed_option_values []record.ProductOptionValueCreateParams) ![]record.ProductOptionValueVariant {
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
			option_index_value_ids[option_index] = []ID{len: 0, cap: 4} // TODO scan for n
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
				requires_shipping: objects.inventory_item_requires_shipping_default
				manage_inventory:  objects.inventory_item_manage_inventory_default
				allow_backorder:   objects.inventory_item_allow_backorder_default
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
				requires_shipping: objects.inventory_item_requires_shipping_default
				manage_inventory:  objects.inventory_item_manage_inventory_default
				allow_backorder:   objects.inventory_item_allow_backorder_default
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
				objects.inventory_item_requires_shipping_default)
			manage_inventory:  common.unwrap_option_or(item.manage_inventory,
				objects.inventory_item_manage_inventory_default)
			allow_backorder:   common.unwrap_option_or(item.allow_backorder,
				objects.inventory_item_allow_backorder_default)
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
		offset:       objects.offset_default
		fetch:        objects.max_fetch // TODO limit 250 regions or refactor? or make const internal_max_fetch = max_i32?
		order:        objects.order_default
	}) or { return errors.internal('Failed to retrieve region', err.msg()) }

	variants := p.variants or {
		mut res := []record.VariantMoneyAmountUpdateParams{len: 0, cap: regions.len}
		for _, region in regions {
			res << record.VariantMoneyAmountUpdateParams{
				variant_id:      parsed_variants[0].id
				region_id:       region.id
				money_amount_id: common.new_id(mut g)
				amount:          objects.money_amount_default_amount
				is_original:     objects.money_amount_default_is_original
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
					amount:          objects.money_amount_default_amount
					is_original:     objects.money_amount_default_is_original
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

fn (p ProductCreateParams) parse_images(mut g luuid.Generator) ![]record.ImageCreateParams {
	images := p.images or {
		return errors.internal('failed to parse images for creation',
			'ProductCreateParams.parse_images was used when p.images was none')
	}

	mut res := []record.ImageCreateParams{len: 0, cap: images.len}
	for _, image in images {
		image_id := common.new_id(mut g)
		res << record.ImageCreateParams{
			id:  image_id
			url: image.url
			alt: image.alt
		}
	}
	return res
}

fn (p ProductCreateParams) parse_product_images(product_id ID, parsed_images []record.ImageCreateParams) ![]record.ProductImageCreateParams {
	images := p.images or {
		return errors.internal('failed to parse product images for creation',
			'ProductCreateParams.parse_product_images was used when p.images was none')
	}

	if images.len != parsed_images.len {
		return errors.internal('failed to parse product images for creation',
			'mismatch images.len and parsed_images.len')
	}

	mut res := []record.ProductImageCreateParams{len: 0, cap: parsed_images.len}
	for image_rank, image in parsed_images {
		res << record.ProductImageCreateParams{
			product_id: product_id
			image_id:   image.id
			image_rank: i32(image_rank)
		}
	}
	return res
}

fn (p ProductCreateParams) has_image_translations() bool {
	images := p.images or { return false }
	for _, image in images {
		if image.translations != none { return true }
	}
	return false
}

fn (p ProductCreateParams) parse_image_translations(parsed_images []record.ImageCreateParams) ![]record.ImageTranslationCreateParams {
	images := p.images or {
		return errors.internal('failed to parse product images for creation',
			'ProductCreateParams.parse_product_images was used when p.images was none')
	}

	if images.len != parsed_images.len {
		return errors.internal('failed to parse product images for creation',
			'mismatch images.len and parsed_images.len')
	}

	mut n_translations := 0
	for _, image in images {
		if translations := image.translations {
			n_translations += translations.len
		}
	}

	mut res := []record.ImageTranslationCreateParams{len: 0, cap: n_translations}
	for index, image in images {
		image_id := parsed_images[index].id
		translations := image.translations or { continue }

		for _, translation in translations {
			res << record.ImageTranslationCreateParams{
				image_id:  image_id
				locale_id: translation.locale_id
				alt:       translation.alt
			}
		}
	}
	return res
}

fn (p ProductCreateParams) variant_has_image() bool {
	variants := p.variants or { return false }

	for _, variant in variants {
		if variant.image == none {
			continue
		}
		return true
	}
	return false
}

fn (p ProductCreateParams) parse_variant_images(
	parsed_variants []record.VariantCreateParams,
	parsed_images []record.ImageCreateParams) ![]record.VariantImage {
	variants := p.variants or {
		return errors.internal('failed to parse variant image',
			'ProductCreateParams.parse_variant_images was used when p.variants was none')
	}

	images := p.images or {
		return errors.internal('failed to parse variant image',
			'ProductCreateParams.parse_variant_images was used when p.images was none')
	}

	if images.len != parsed_images.len {
		return errors.internal('failed to parse variant image',
			'mismatch images.len and parsed_images.len')
	}

	mut n_relations := 0
	for _, variant in variants {
		if variant.image == none {
			continue
		}
		n_relations++
	}

	mut res := []record.VariantImage{len: 0, cap: n_relations}
	for variant_rank, variant in variants {
		image_rank := variant.image or { continue }

		res << record.VariantImage{
			variant_id: parsed_variants[variant_rank].id
			image_id:   parsed_images[image_rank].id
		}
	}
	return res
}

// TODO all checks
pub fn product_create(mut tx firebird.ClientTransaction, mut g luuid.Generator, p ProductCreateParams) !ID {
	p.check_handle(mut tx)!

	product_id := common.new_id(mut g)
	product := p.parse_product(product_id)
	record.product_create(mut tx, product) or {
		return errors.internal('Failed to create product', err.msg())
	}

	if translations := p.translations {
		t := parse_product_translations(product_id, translations)
		record.product_translation_create(mut tx, t) or {
			return errors.internal('Failed to update product translations', err.msg())
		}
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

	if _ := p.images {
		images := p.parse_images(mut g)!
		record.image_create(mut tx, images) or {
			return errors.internal('Failed to create image', err.msg())
		}

		if p.has_image_translations() {
			parsed_image_translations := p.parse_image_translations(images)!
			record.image_translation_create(mut tx, parsed_image_translations) or {
				return errors.internal('Failed to create product_translations', err.msg())
			}
		}

		parsed_product_images := p.parse_product_images(product_id, images)!
		record.product_image_create(mut tx, parsed_product_images) or {
			return errors.internal('Failed to create product_image', err.msg())
		}

		mut thumbnail_id := images[0].id
		if thumbnail_index := p.thumbnail {
			thumbnail_id = images[thumbnail_index].id
		}

		record.product_thumbnail_update(mut tx, product_id, thumbnail_id) or {
			return errors.internal('Failed to update product thumbnail', err.msg())
		}

		if p.variant_has_image() {
			variant_images := p.parse_variant_images(variants, images)!
			record.variant_image_update(mut tx, variant_images) or {
				return errors.internal('Failed to update variant image', err.msg())
			}
		}
	}

	if category_ids := p.category_ids {
		record.category_product_update(mut tx, product_id, category_ids) or {
			return errors.internal('Failed to update product category relation', err.msg())
		}
	}

	return product_id
}

pub struct ProductImageUpdateParams {
pub:
	id           ?ID
	url          ?string
	alt          ?string
	translations ?[]ImageTranslationCreateParams
}

pub struct ProductOptionValueUpdateParams {
pub:
	id           ?ID
	name         ?string
	translations ?[]ProductOptionValueTranslationCreateParams
}

pub struct ProductOptionUpdateParams {
pub:
	id           ?ID
	title        ?string
	values       ?[]ProductOptionValueUpdateParams
	translations ?[]ProductOptionTranslationCreateParams
}

pub struct ProductVariantUpdateParams {
pub:
	id             ?ID
	product_id     ID
	title          ?string
	ean            ?string
	upc            ?string
	barcode        ?string
	metadata       ?string
	option_values  ?[]i32
	inventory_item ?InventoryItemUpdateParams
	money_amounts  ?[]VariantMoneyAmountUpdateParams
	image          ?i32
}

pub struct ProductUpdateParams {
pub:
	id                ID
	title             ?string
	subtitle          ?string
	description       ?string
	handle            ?string
	is_giftcard       ?bool
	status            ?string
	discountable      ?bool
	metadata          ?string
	sales_channel_ids ?[]ID
	category_ids      ?[]ID
	translations      ?[]ProductTranslationCreateParams
	thumbnail         ?i32
	images            ?[]ProductImageUpdateParams
	seo               ?SEOParams
	options           ?[]ProductOptionUpdateParams
	variants          ?[]ProductVariantUpdateParams
	// type_id           ?ID
	// tag_ids           ?[]ID
}

fn (p ProductUpdateParams) check_handle(mut tx firebird.ClientTransaction) ! {
	handle := p.handle or { return }
	check_product_handle(mut tx, handle)!
}

fn (p ProductUpdateParams) parse_product() record.ProductUpdateParams {
	return record.ProductUpdateParams{
		id:           p.id
		title:        p.title
		subtitle:     p.subtitle
		description:  p.description
		handle:       p.handle
		is_giftcard:  p.is_giftcard
		status:       p.status
		discountable: p.discountable
		metadata:     p.metadata
		// type_id:      p.type_id
	}
}

fn (p ProductUpdateParams) parse_seo(mut tx firebird.ClientTransaction, seo SEOParams) !record.SEOUpdateParams {
	seos := record.product_seo_retrieve(mut tx, [p.id]) or {
		return errors.internal('Failed to retrieve seo', err.msg())
	}

	if seos.len == 0 {
		return errors.internal(errors.database_malformed,
			'Missing seo for product with id `${p.id.string()}`')
	}

	current := seos[0]

	return record.SEOUpdateParams{
		id:          current.id
		title:       common.unwrap_option_or_option(seo.title, current.title)
		description: common.unwrap_option_or_option(seo.description, current.description)
	}
}

fn (p ProductUpdateParams) parse_options(
	mut tx firebird.ClientTransaction, mut g luuid.Generator) ![]record.ProductOptionUpdateParams {
	options := p.options or {
		return errors.internal('failed to parse product options',
			'ProductUpdateParams.parse_options was used when p.options was none')
	}

	current_options := record.product_option_retrieve(mut tx, [p.id]) or {
		return errors.internal('failed to retrieve product_option', err.msg())
	}

	current_map, _ := common.make_identifiable_map(current_options)

	mut res := []record.ProductOptionUpdateParams{len: 0, cap: options.len}
	for option_rank, option in options {
		option_id := option.id or {
			title := option.title or {
				return errors.internal('failed to parse product options',
					'ProductUpdateParams.parse_options detected a new option with title == none')
			}

			res << record.ProductOptionUpdateParams{
				id:          common.new_id(mut g)
				product_id:  p.id
				option_rank: i32(option_rank)
				title:       title
			}
			continue
		}

		current := current_map[option_id.string()]
		res << record.ProductOptionUpdateParams{
			id:          option_id
			product_id:  p.id
			option_rank: i32(option_rank)
			title:       common.unwrap_option_or(option.title, current.title)
		}
	}
	return res
}

fn (p ProductUpdateParams) updates_option_translations() bool {
	options := p.options or { return false }
	for _, option in options {
		if option.translations != none { return true }
	}
	return false
}

fn (p ProductUpdateParams) update_option_translations(
	mut tx firebird.ClientTransaction,
	parsed_options []record.ProductOptionUpdateParams) ! {
	options := p.options or {
		return errors.internal('failed to parse product option translations',
			'ProductUpdateParams.update_option_translations was used when p.options was none')
	}

	mut n_option_updated := 0
	mut n_translations := 0
	for _, option in options {
		translations := option.translations or { continue }
		n_option_updated++
		n_translations += translations.len
	}

	mut option_ids := []ID{len: 0, cap: n_option_updated}
	mut option_translations := []record.ProductOptionTranslationCreateParams{len: 0, cap: n_translations}
	for option_rank, option in options {
		translations := option.translations or { continue }
		option_id := parsed_options[option_rank].id
		option_ids << option_id
		for _, translation in translations {
			option_translations << record.ProductOptionTranslationCreateParams{
				product_option_id: option_id
				locale_id:         translation.locale_id
				title:             translation.title
			}
		}
	}

	record.product_option_translations_update(mut tx, option_ids, option_translations) or {
		return errors.internal('failed to update product_option_translations', err.msg())
	}
}

fn (p ProductUpdateParams) updates_option_values() bool {
	options := p.options or { return false }
	for _, option in options {
		if option.values != none { return true }
	}
	return false
}

fn (p ProductUpdateParams) parse_option_values(
	mut tx firebird.ClientTransaction,
	mut g luuid.Generator,
	parsed_options []record.ProductOptionUpdateParams) ![]record.ProductOptionValueUpdateParams {
	options := p.options or {
		return errors.internal('failed to parse product option values',
			'ProductUpdateParams.parse_options was used when p.options was none')
	}

	current_values := record.product_option_values_retrieve(mut tx, record.ProductOptionValueRetrieveParams{
		product_ids: [p.id]
	}) or { return errors.internal('failed to retrieve option values', err.msg()) }

	current_map, _ := common.make_identifiable_map(current_values)

	mut n_values := 0
	for _, option in options {
		if values := option.values {
			n_values += values.len
		}
	}

	mut res := []record.ProductOptionValueUpdateParams{len: 0, cap: n_values}
	for option_rank, option in options {
		values := option.values or { continue }
		parsed_option := parsed_options[option_rank]
		for value_rank, value in values {
			value_id := value.id or {
				name := value.name or {
					return errors.internal('failed to parse product option values',
						'ProductUpdateParams.parse_option_values detected a new option value with name == none')
				}

				res << record.ProductOptionValueUpdateParams{
					id:         common.new_id(mut g)
					option_id:  parsed_option.id
					value_rank: i32(value_rank)
					name:       name
				}
				continue
			}

			current := current_map[value_id.string()]
			res << record.ProductOptionValueUpdateParams{
				id:         value_id
				option_id:  parsed_option.id
				value_rank: i32(value_rank)
				name:       common.unwrap_option_or(value.name, current.name)
			}
		}
	}
	return res
}

fn (p ProductUpdateParams) updates_option_value_translations() bool {
	options := p.options or { return false }
	for _, option in options {
		values := option.values or { continue }
		for _, value in values {
			if value.translations != none {
				return true
			}
		}
	}
	return false
}

fn (p ProductUpdateParams) update_option_value_translations(
	mut tx firebird.ClientTransaction,
	parsed_option_values []record.ProductOptionValueUpdateParams) ! {
	options := p.options or {
		return errors.internal('failed to parse product option value translations',
			'ProductUpdateParams.update_option_value_translations was used when p.options was none')
	}

	mut n_option_value_updated := 0
	mut n_translations := 0
	for _, option in options {
		values := option.values or { continue }
		for _, value in values {
			translations := value.translations or { continue }
			n_option_value_updated++
			n_translations += translations.len
		}
	}

	mut option_value_index := 0 // parsed_option_values is flat
	mut option_value_ids := []ID{len: 0, cap: n_option_value_updated}
	mut option_value_translations := []record.ProductOptionValueTranslationCreateParams{len: 0, cap: n_translations}
	for _, option in options {
		values := option.values or { continue }
		for _, value in values {
			translations := value.translations or {
				option_value_index++
				continue
			}

			option_value_id := parsed_option_values[option_value_index].id
			option_value_ids << option_value_id
			for _, translation in translations {
				option_value_translations << record.ProductOptionValueTranslationCreateParams{
					product_option_value_id: option_value_id
					locale_id:               translation.locale_id
					name:                    translation.name
				}
			}
			option_value_index++
		}
	}

	record.product_option_value_translations_update(mut tx, option_value_ids,
		option_value_translations) or {
		return errors.internal('failed to update option_value_translations', err.msg())
	}
}

fn (p ProductUpdateParams) parse_variants(
	mut tx firebird.ClientTransaction,
	mut g luuid.Generator) ![]record.VariantUpdateParams {
	variants := p.variants or {
		return errors.internal('failed to parse variants',
			'ProductUpdateParams.parse_variants was used when p.variants was none')
	}

	current_variants := record.variant_retrieve(mut tx, record.VariantRetrieveParams{
		product_ids:  [p.id]
		with_deleted: false
		offset:       objects.offset_default
		fetch:        objects.max_fetch
		order:        objects.order_default
	}) or { return errors.internal('failed to retrieve variants', err.msg()) }

	current_map, _ := common.make_identifiable_map(current_variants)

	mut res := []record.VariantUpdateParams{len: 0, cap: variants.len}
	for variant_rank, variant in variants {
		variant_id := variant.id or {
			res << record.VariantUpdateParams{
				id:           common.new_id(mut g)
				product_id:   p.id
				title:        variant.title
				barcode:      variant.barcode
				ean:          variant.ean
				upc:          variant.upc
				variant_rank: i32(variant_rank)
				metadata:     variant.metadata
			}
			continue
		}

		current := current_map[variant_id.string()]
		res << record.VariantUpdateParams{
			id:           variant_id
			product_id:   p.id
			title:        common.unwrap_option_or_option(variant.title, current.title)
			barcode:      common.unwrap_option_or_option(variant.barcode, current.barcode)
			ean:          common.unwrap_option_or_option(variant.ean, current.ean)
			upc:          common.unwrap_option_or_option(variant.upc, current.upc)
			variant_rank: i32(variant_rank)
			metadata:     common.unwrap_option_or_option(variant.metadata, current.metadata)
		}
	}
	return res
}

fn (p ProductUpdateParams) updates_option_value_variants() bool {
	variants := p.variants or { return false }
	for _, variant in variants {
		if variant.option_values != none {
			return true
		}
	}
	return false
}

fn (p ProductUpdateParams) parse_option_value_variants(
	variant_ids []ID,
	parsed_options []record.ProductOptionUpdateParams,
	parsed_option_values []record.ProductOptionValueUpdateParams) ![]record.ProductOptionValueVariant {
	variants := p.variants or {
		return errors.internal('failed to parse option value variant relations',
			'ProductUpdateParams.parse_option_value_variants was used when p.variants was none')
	}

	mut option_id_to_rank := map[string]i32{}
	for _, option in parsed_options {
		option_id_to_rank[option.id.string()] = option.option_rank
	}

	mut option_rank_value_ids := map[i32][]ID{}
	for _, value in parsed_option_values {
		option_index := option_id_to_rank[value.option_id.string()]
		if option_index !in option_rank_value_ids {
			option_rank_value_ids[option_index] = []ID{len: 0, cap: 4} // TODO scan for n
		}
		option_rank_value_ids[option_index] << value.id
	}

	mut res := []record.ProductOptionValueVariant{len: 0, cap: variants.len * parsed_options.len}
	for variant_rank, variant in variants {
		option_values := variant.option_values or { continue }
		variant_id := variant_ids[variant_rank]
		for option_rank, value_rank in option_values {
			res << record.ProductOptionValueVariant{
				option_value_id: option_rank_value_ids[option_rank][value_rank]
				variant_id:      variant_id
			}
		}
	}
	return res
}

fn (p ProductUpdateParams) parse_images(
	mut tx firebird.ClientTransaction,
	mut g luuid.Generator) ![]record.ProductImageUpdateParams {
	images := p.images or {
		return errors.internal('failed to parse product images',
			'ProductUpdateParams.parse_images was used when p.images was none')
	}

	current_images := record.product_image_retrieve(mut tx, record.ProductImageRetrieveParams{
		product_ids: [p.id]
	}) or { return errors.internal('failed to retrieve product images', err.msg()) }

	mut current_map := map[string]ProductImage{}
	for _, image in current_images {
		current_map[image.id.string()] = image
	}

	mut res := []record.ProductImageUpdateParams{len: 0, cap: images.len}
	for image_rank, image in images {
		image_id := image.id or {
			url := image.url or {
				return errors.internal('failed to parse product images',
					'ProductUpdateParams.parse_images detected a new image with no url')
			}

			res << record.ProductImageUpdateParams{
				id:         common.new_id(mut g)
				url:        url
				alt:        image.alt
				image_rank: i32(image_rank)
			}
			continue
		}

		current := current_map[image_id.string()]
		res << record.ProductImageUpdateParams{
			id:         image_id
			url:        common.unwrap_option_or(image.url, current.url)
			alt:        common.unwrap_option_or_option(image.alt, current.alt)
			image_rank: i32(image_rank)
		}
	}
	return res
}

fn (p ProductUpdateParams) parse_thumbnail(mut tx firebird.ClientTransaction) !record.ProductImage {
	image_rank := p.thumbnail or {
		return errors.internal('failed to parse thumbnail',
			'ProductUpdateParams.parse_thumbnail was used when p.thumbnail was none')
	}

	current_images := record.product_image_retrieve(mut tx, record.ProductImageRetrieveParams{
		product_ids: [p.id]
	}) or { return errors.internal('failed to retrieve product images', err.msg()) }

	if image_rank > current_images.len - 1 {
		return errors.internal('failed to parse thumbnail',
			'ProductUpdateParams.parse_thumbnail detected an image rank larger than existing')
	}

	return current_images[image_rank]
}

fn (p ProductUpdateParams) updates_variant_images() bool {
	variants := p.variants or { return false }
	for _, variant in variants {
		if variant.image != none { return true }
	}
	return false
}

fn (p ProductUpdateParams) parse_variant_images(mut tx firebird.ClientTransaction, variant_ids []ID) ![]record.VariantImage {
	variants := p.variants or {
		return errors.internal('failed to parse variant image',
			'ProductUpdateParams.parse_variant_images was used when p.variants was none')
	}

	current_images := record.product_image_retrieve(mut tx, record.ProductImageRetrieveParams{
		product_ids: [p.id]
	}) or { return errors.internal('failed to retrieve product images', err.msg()) }

	mut n_updates := 0
	for _, variant in variants {
		if variant.image != none {
			n_updates++
		}
	}

	mut res := []record.VariantImage{len: 0, cap: n_updates}
	for variant_rank, variant in variants {
		image_rank := variant.image or { continue }
		if image_rank > current_images.len - 1 {
			return errors.internal('failed to parse variant image',
				'ProductUpdateParams.parse_variant_images detected an image rank larger than existing')
		}

		variant_id := variant_ids[variant_rank]
		image_id := current_images[image_rank].id
		res << record.VariantImage{
			variant_id: variant_id
			image_id:   image_id
		}
	}
	return res
}

fn (p ProductUpdateParams) updates_inventory_items() bool {
	variants := p.variants or { return false }
	for _, variant in variants {
		if variant.inventory_item != none {
			return true
		}
	}
	return false
}

fn (p ProductUpdateParams) parse_inventory_items(
	mut tx firebird.ClientTransaction,
	mut g luuid.Generator,
	variant_ids []ID) ![]record.InventoryItemUpdateParams {
	variants := p.variants or {
		return errors.internal('failed to parse inventory items',
			'ProductUpdateParams.parse_inventory_items was used when p.variants was none')
	}

	current_items := record.inventory_item_retrieve(mut tx, variant_ids) or {
		return errors.internal('failed to retrieve inventory_item', err.msg())
	}

	mut variant_item := map[string]record.InventoryItem{}
	for _, item in current_items {
		variant_item[item.variant_id.string()] = item
	}

	mut n_item_updated := 0
	for _, variant in variants {
		if variant.inventory_item != none {
			n_item_updated++
		}
	}

	mut res := []record.InventoryItemUpdateParams{len: 0, cap: n_item_updated}
	for variant_rank, variant in variants {
		item := variant.inventory_item or { continue }
		variant_id := variant_ids[variant_rank]
		if current := variant_item[variant_id.string()] {
			res << record.InventoryItemUpdateParams{
				id:                current.id
				variant_id:        variant_id
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
				requires_shipping: common.bool_or(item.requires_shipping, current.requires_shipping)
				manage_inventory:  common.bool_or(item.manage_inventory, current.manage_inventory)
				allow_backorder:   common.bool_or(item.allow_backorder, current.allow_backorder)
			}
			continue
		}

		res << record.InventoryItemUpdateParams{
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
			requires_shipping: common.bool_or(item.requires_shipping,
				objects.inventory_item_requires_shipping_default)
			manage_inventory:  common.bool_or(item.manage_inventory,
				objects.inventory_item_manage_inventory_default)
			allow_backorder:   common.bool_or(item.allow_backorder,
				objects.inventory_item_allow_backorder_default)
		}
	}
	return res
}

fn (p ProductUpdateParams) updates_money_amounts() bool {
	variants := p.variants or { return false }
	for _, variant in variants {
		if variant.money_amounts != none {
			return true
		}
	}
	return false
}

fn (p ProductUpdateParams) parse_money_amounts(mut g luuid.Generator, variant_ids []ID) ![]record.VariantMoneyAmountUpdateParams {
	variants := p.variants or {
		return errors.internal('failed to parse money amounts',
			'ProductUpdateParams.parse_money_amounts was used when p.variants was none')
	}

	mut n_money_amounts := 0
	for _, variant in variants {
		money_amounts := variant.money_amounts or { continue }
		n_money_amounts += money_amounts.len
	}

	mut res := []record.VariantMoneyAmountUpdateParams{len: 0, cap: n_money_amounts}
	for variant_rank, variant in variants {
		money_amounts := variant.money_amounts or { continue }
		for _, money_amount in money_amounts {
			res << record.VariantMoneyAmountUpdateParams{
				variant_id:      variant_ids[variant_rank]
				region_id:       money_amount.region_id
				money_amount_id: common.new_id(mut g)
				amount:          money_amount.amount
				is_original:     money_amount.is_original
			}
		}
	}
	return res
}

pub fn product_update(mut tx firebird.ClientTransaction, mut g luuid.Generator, p ProductUpdateParams) ! {
	p.check_handle(mut tx)!
	check_product_id_exists(mut tx, p.id)!

	product := p.parse_product()
	record.product_update(mut tx, product) or {
		return errors.internal('Failed to update product', err.msg())
	}

	if translations := p.translations {
		record.product_translation_delete(mut tx, p.id) or {
			return errors.internal('Failed to delete product translations', err.msg())
		}

		if translations.len > 0 {
			t := parse_product_translations(p.id, translations)
			record.product_translation_create(mut tx, t) or {
				return errors.internal('Failed to create product translations', err.msg())
			}
		}
	}

	if seo := p.seo {
		s := p.parse_seo(mut tx, seo)!
		record.seo_update(mut tx, s) or {
			return errors.internal('Could not update seo', err.msg())
		}

		if translations := seo.translations {
			record.product_seo_translations_delete(mut tx, p.id) or {
				return errors.internal('Failed to delete seo translations', err.msg())
			}

			if translations.len > 0 {
				t := parse_seo_translations(s.id, translations)
				record.seo_translations_create(mut tx, t)!
			}
		}
	}

	if p.images != none {
		parsed_images := p.parse_images(mut tx, mut g)!
		record.product_image_update(mut tx, p.id, parsed_images) or {
			return errors.internal('failed to update product images', err.msg())
		}
	}

	if p.thumbnail != none {
		thumbnail := p.parse_thumbnail(mut tx)!
		record.product_thumbnail_update(mut tx, p.id, thumbnail.id) or {
			return errors.internal('Failed to update thumbnail', err.msg())
		}
	}

	mut variant_ids := []ID{}
	if p.variants == none {
		current_variants := record.variant_retrieve(mut tx, record.VariantRetrieveParams{
			product_ids:  [p.id]
			with_deleted: false
			offset:       objects.offset_default
			fetch:        objects.max_fetch
			order:        objects.order_default
		}) or { return errors.internal('failed to retrieve variants', err.msg()) }

		variant_ids = []ID{len: 0, cap: current_variants.len}
		for _, variant in current_variants {
			variant_ids << variant.id
		}
	} else {
		parsed_variants := p.parse_variants(mut tx, mut g)!
		record.product_variant_update(mut tx, p.id, parsed_variants) or {
			return errors.internal('failed to update variant', err.msg())
		}

		variant_ids = []ID{len: 0, cap: parsed_variants.len}
		for _, variant in parsed_variants {
			variant_ids << variant.id
		}

		if p.updates_variant_images() {
			variant_images := p.parse_variant_images(mut tx, variant_ids)!
			record.variant_image_update(mut tx, variant_images) or {
				return errors.internal('failed to update variant image', err.msg())
			}
		}

		if p.updates_inventory_items() {
			inventory_items := p.parse_inventory_items(mut tx, mut g, variant_ids)!
			record.inventory_item_update(mut tx, inventory_items) or {
				return errors.internal('Failed to update inventory items', err.msg())
			}
		}

		if p.updates_money_amounts() {
			money_amounts := p.parse_money_amounts(mut g, variant_ids)!
			record.variant_money_amount_update(mut tx, money_amounts) or {
				return errors.internal('Failed to update inventory items', err.msg())
			}
		}
	}

	if p.options != none {
		parsed_options := p.parse_options(mut tx, mut g)!
		record.product_option_update(mut tx, parsed_options) or {
			return errors.internal('Could not update product_option', err.msg())
		}

		if p.updates_option_translations() {
			p.update_option_translations(mut tx, parsed_options)!
		}

		if p.updates_option_values() {
			parsed_option_values := p.parse_option_values(mut tx, mut g, parsed_options)!
			record.product_option_value_update(mut tx, parsed_option_values) or {
				return errors.internal('Could not update product_option_value', err.msg())
			}

			if p.updates_option_value_translations() {
				p.update_option_value_translations(mut tx, parsed_option_values)!
			}

			if p.updates_option_value_variants() {
				option_value_variants := p.parse_option_value_variants(variant_ids, parsed_options,
					parsed_option_values)!
				record.product_option_value_variant_update(mut tx, option_value_variants) or {
					return errors.internal('Failed to update relations in product_option_value_variant',
						err.msg())
				}
			}
		}
	}

	if sales_channel_ids := p.sales_channel_ids {
		record.product_sales_channel_update(mut tx, p.id, sales_channel_ids) or {
			return errors.internal('Failed to update product sales channel', err.msg())
		}
	}

	if category_ids := p.category_ids {
		record.category_product_update(mut tx, p.id, category_ids) or {
			return errors.internal('Failed to update product category relation', err.msg())
		}
	}
}

pub fn product_delete(mut tx firebird.ClientTransaction, product_id ID) ! {
	check_product_id_exists(mut tx, product_id)!
	record.product_delete(mut tx, product_id) or {
		return errors.internal('Failed to delete product', err.msg())
	}
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

	for _, option_id in option_ids {
		option := options_map[option_id.string()]
		product_id := option.product_id
		products_map[product_id.string()].options << option
	}
}

fn get_products_variants(mut tx firebird.ClientTransaction, mut products_map map[string]record.Product, product_ids []ID) ! {
	// TODO loop for pagination
	variants := record.variant_retrieve(mut tx, record.VariantRetrieveParams{
		product_ids:  product_ids
		with_deleted: false
		offset:       objects.offset_default
		fetch:        objects.max_fetch
		order:        objects.order_default
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
		offset:       objects.offset_default
		fetch:        1
		order:        objects.order_default
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
		status:           objects.product_status_published
		sales_channel_id: sales_channel_id
		with_deleted:     false
		offset:           objects.offset_default
		fetch:            1
		order:            objects.order_default
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
