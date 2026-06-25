module conduit

import arrays
import einar_hjortdal.firebird
import record
import internal.common
import internal.errors

pub struct ProductCreateData {
pub:
	product                   record.ProductCreateParams
	translations              ?[]record.ProductTranslationCreateParams
	seo                       record.ProductSEOCreateParams
	seo_translations          ?[]record.SEOTranslationCreateParams
	options                   []record.ProductOptionCreateParams
	option_translations       ?[]record.ProductOptionTranslationCreateParams
	option_values             []record.ProductOptionValueCreateParams
	option_value_translations ?[]record.ProductOptionValueTranslationCreateParams
	variants                  []record.VariantCreateParams
	inventory_items           []record.InventoryItemCreateParams
	variant_money_amounts     []record.VariantMoneyAmountUpdateParams
	option_value_variant      []record.ProductOptionValueVariant
	category_ids              ?[]ID
	images                    ?[]record.ProductImageCreateParams
	thumbnail_id              ?ID
	sales_channel_ids         []ID
}

fn product_create(mut tx firebird.ClientTransaction, product_id ID, handle string, p ProductCreateData) ! {
	record.product_create(mut tx, p.product) or {
		return errors.internal('Failed to create product', err.msg())
	}

	if translations := p.translations {
		record.product_translation_create(mut tx, translations) or {
			return errors.internal('Failed to update product translations', err.msg())
		}
	}

	record.product_seo_create(mut tx, p.seo) or {
		return errors.internal('Failed to create seo', err.msg())
	}

	if translations := p.seo_translations {
		if translations.len > 0 {
			record.seo_translations_create(mut tx, translations) or {
				return errors.internal('Failed to insert seo_translations', err.msg())
			}
		}
	}

	record.product_option_create(mut tx, p.options) or {
		return errors.internal('Failed to create product_option', err.msg())
	}

	record.product_option_value_create(mut tx, p.option_values) or {
		return errors.internal('Failed to create product_option_value', err.msg())
	}

	if translations := p.option_translations {
		record.product_option_translations_create(mut tx, translations) or {
			return errors.internal('Failed to create product_option_translations', err.msg())
		}
	}

	if translations := p.option_value_translations {
		record.product_option_value_translations_create(mut tx, translations) or {
			return errors.internal('Failed to create product_option_value_translations', err.msg())
		}
	}

	if images := p.images {
		record.product_image_create(mut tx, product_id, images) or {
			return errors.internal('Failed to create product_image', err.msg())
		}
	}

	if thumbnail_id := p.thumbnail_id {
		record.product_thumbnail_update(mut tx, product_id, thumbnail_id) or {
			return errors.internal('Failed to update product thumbnail', err.msg())
		}
	}

	record.product_sales_channel_update(mut tx, product_id, p.sales_channel_ids) or {
		return errors.internal('Failed to update product_sales_channel', err.msg())
	}

	if category_ids := p.category_ids {
		record.category_product_update(mut tx, product_id, category_ids) or {
			return errors.internal('Failed to update product category relation', err.msg())
		}
	}

	record.variant_create(mut tx, p.variants) or {
		return errors.internal('Could not create variants', err.msg())
	}

	record.product_option_value_variant_update(mut tx, p.option_value_variant) or {
		return errors.internal('Failed to create relations in product_option_value_variant',
			err.msg())
	}

	record.variant_money_amount_update(mut tx, p.variant_money_amounts) or {
		return errors.internal('Failed to create variant money_amount', err.msg())
	}

	record.inventory_item_create(mut tx, p.inventory_items) or {
		return errors.internal('Failed to create inventory_item', err.msg())
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
	images := record.product_image_retrieve(mut tx, product_ids) or {
		return errors.internal('Failed to retrieve product_image', err.msg())
	}

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

pub fn product_list_count(mut tx firebird.ClientTransaction, p ProductRetrieveParams) !i64 {
	count := record.product_retrieve_count(mut tx, p) or {
		return errors.internal('Failed to retrieve product count', err.msg())
	}
	return count
}

// TODO: we are fetching option values and their translations twice. once for products, once for variants. This is not efficient, but separating the logic this way also makes sense.
pub fn product_list(mut tx firebird.ClientTransaction, p ProductRetrieveParams) ![]record.Product {
	products := record.product_retrieve(mut tx, p) or {
		return errors.internal('Failed to retrieve product', err.msg())
	}

	if products.len == 0 {
		return []record.Product{}
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
	return complete_products
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
	check_product_id_exists(mut tx, product_id)!

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
