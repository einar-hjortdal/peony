module peony

struct ListRegionParams {
	name   ZeroString
	offset ZeroI32
	fetch  ZeroI32
	order  ZeroString
}

fn extract_retrieve_regions_params(p map[string]string) ListRegionParams {
	return ListRegionParams{
		name:   zero_string(p, 'name')
		offset: zero_i32(p, 'offset')
		fetch:  zero_i32(p, 'fetch')
		order:  zero_string(p, 'order')
	}
}

struct ListCountriesParams {
	offset ZeroI32
	fetch  ZeroI32
	order  ZeroString
}

fn extract_retrieve_countries_params(p map[string]string) ListCountriesParams {
	return ListCountriesParams{
		offset: zero_i32(p, 'offset')
		fetch:  zero_i32(p, 'fetch')
		order:  zero_string(p, 'order')
	}
}

struct RetrieveCurrenciesParams {
	code         ZeroArrayString
	includes_tax ZeroBool
	offset       ZeroI32
	fetch        ZeroI32
	order        ZeroString
}

fn extract_retrieve_currencies_params(m map[string]string) RetrieveCurrenciesParams {
	return RetrieveCurrenciesParams{
		code:         zero_array_string(m, 'code')
		includes_tax: zero_bool(m, 'includes_tax')
		offset:       zero_i32(m, 'offset')
		fetch:        zero_i32(m, 'fetch')
		order:        zero_string(m, 'order')
	}
}

struct LocaleRetrieveParams {
	store_id ZeroString // internal
	offset   ZeroI32
	fetch    ZeroI32
	order    ZeroString
}

fn extract_retrieve_locales_params(m map[string]string) LocaleRetrieveParams {
	return LocaleRetrieveParams{
		store_id: zero_string(m, 'store_id')
		offset:   zero_i32(m, 'offset')
		fetch:    zero_i32(m, 'fetch')
		order:    zero_string(m, 'order')
	}
}

struct ListSalesChannelsParams {
	ids         ZeroArrayString
	name        ZeroString
	description ZeroString
	product_ids ZeroArrayString
	offset      ZeroI32
	fetch       ZeroI32
	order       ZeroString
}

fn extract_retrieve_sales_channels_params(p map[string]string) ListSalesChannelsParams {
	return ListSalesChannelsParams{
		ids:         zero_array_string(p, 'ids')
		name:        zero_string(p, 'name')
		description: zero_string(p, 'description')
		product_ids: zero_array_string(p, 'product_ids')
		offset:      zero_i32(p, 'offset')
		fetch:       zero_i32(p, 'fetch')
		order:       zero_string(p, 'order')
	}
}

struct RetrieveProductVariantParams {
	ids             ZeroArrayString
	product_ids     ZeroArrayString
	allow_backorder ZeroBool
	region_id       ZeroString
	currency_code   ZeroString // TODO join money_amount on id = ma.variant_id
	title           ZeroString
	with_deleted    ZeroBool
	offset          ZeroI32
	fetch           ZeroI32
	order           ZeroString
}

fn extract_retrieve_product_variant_params(m map[string]string) RetrieveProductVariantParams {
	return RetrieveProductVariantParams{
		ids:             zero_array_string(m, 'ids')
		product_ids:     zero_array_string(m, 'product_ids')
		allow_backorder: zero_bool(m, 'allow_backorder')
		region_id:       zero_string(m, 'region_id')
		currency_code:   zero_string(m, 'currency_code')
		title:           zero_string(m, 'title')
		offset:          zero_i32(m, 'offset')
		fetch:           zero_i32(m, 'fetch')
		order:           zero_string(m, 'order')
	}
}

struct RetrieveProductParams {
	ids               ZeroArrayString
	handle            ZeroString
	is_giftcard       ZeroBool
	status            ZeroString
	collection_ids    ZeroArrayString
	type_ids          ZeroArrayString
	tag_ids           ZeroArrayString
	title             ZeroString
	description       ZeroString
	category_ids      ZeroArrayString
	price_list_ids    ZeroArrayString
	sales_channel_ids ZeroArrayString
	region_id         ZeroString
	currency_code     ZeroString
	with_deleted      ZeroBool
	offset            ZeroI32
	fetch             ZeroI32
	order             ZeroString
	cart_id           ZeroString
	locale_id         ZeroString
}

fn extract_retrieve_admin_products_params(m map[string]string) RetrieveProductParams {
	return RetrieveProductParams{
		category_ids:      zero_array_string(m, 'category_ids')
		collection_ids:    zero_array_string(m, 'collection_ids')
		description:       zero_string(m, 'description')
		fetch:             zero_i32(m, 'fetch')
		handle:            zero_string(m, 'handle')
		ids:               zero_array_string(m, 'id')
		is_giftcard:       zero_bool(m, 'is_giftcard')
		offset:            zero_i32(m, 'offset')
		order:             zero_string(m, 'order')
		price_list_ids:    zero_array_string(m, 'price_list_id')
		sales_channel_ids: zero_array_string(m, 'sales_channel_id')
		status:            zero_string(m, 'status')
		tag_ids:           zero_array_string(m, 'tag_id')
		title:             zero_string(m, 'title')
		type_ids:          zero_array_string(m, 'type_id')
		locale_id:         zero_string(m, 'locale_id')
	}
}

fn extract_retrieve_store_products_params(m map[string]string) RetrieveProductParams {
	return RetrieveProductParams{
		cart_id:           zero_string(m, 'cart_id')
		category_ids:      zero_array_string(m, 'category_ids')
		collection_ids:    zero_array_string(m, 'collection_id')
		currency_code:     zero_string(m, 'currency_code')
		description:       zero_string(m, 'description')
		fetch:             zero_i32(m, 'fetch')
		handle:            zero_string(m, 'handle')
		ids:               zero_array_string(m, 'id')
		is_giftcard:       zero_bool(m, 'is_giftcard')
		offset:            zero_i32(m, 'offset')
		order:             zero_string(m, 'order')
		price_list_ids:    zero_array_string(m, 'price_list_id')
		region_id:         zero_string(m, 'region_id')
		sales_channel_ids: zero_array_string(m, 'sales_channel_id')
		status:            zero_string(m, 'status')
		tag_ids:           zero_array_string(m, 'tag_id')
		title:             zero_string(m, 'title')
		type_ids:          zero_array_string(m, 'type_id')
		locale_id:         zero_string(m, 'locale_id')
	}
}

fn extract_retrieve_store_products_by_id_params(m map[string]string, id_string string) RetrieveProductParams {
	id := ZeroArrayString{
		v:      [id_string]
		is_set: true
	}

	return RetrieveProductParams{
		cart_id:           zero_string(m, 'cart_id')
		currency_code:     zero_string(m, 'currency_code')
		ids:               id
		region_id:         zero_string(m, 'region_id')
		sales_channel_ids: zero_array_string(m, 'sales_channel_id')
		locale_id:         zero_string(m, 'locale_id')
	}
}

// handles expects a string that is a single handle, or many comma-separated handles.
// parent_category_ids expects a string that is a single id, or many comma-separated ids. All children
// of these will be returned.
struct ProductCategoryParams {
	ids                 ZeroArrayString
	handles             ZeroArrayString
	is_active           ZeroBool
	is_internal         ZeroBool
	product_ids         ZeroArrayString
	parent_category_ids ZeroArrayString
	with_deleted        ZeroBool
	offset              ZeroI32
	fetch               ZeroI32
	order               ZeroString
	locale_id           ZeroString
}

fn extract_retrieve_product_category_params(m map[string]string) ProductCategoryParams {
	return ProductCategoryParams{
		ids:                 zero_array_string(m, 'ids')
		handles:             zero_array_string(m, 'handle')
		is_active:           zero_bool(m, 'is_active')
		is_internal:         zero_bool(m, 'is_internal')
		product_ids:         zero_array_string(m, 'product_ids')
		parent_category_ids: zero_array_string(m, 'parent_category_id')
		with_deleted:        zero_bool(m, 'with_deleted')
		offset:              zero_i32(m, 'offset')
		fetch:               zero_i32(m, 'fetch')
		order:               zero_string(m, 'order')
		locale_id:           zero_string(m, 'locale_id')
	}
}
