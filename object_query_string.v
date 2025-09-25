module peony

struct ZeroString {
	v      string
	is_set bool
}

fn zero_string(m map[string]string, k string) ZeroString {
	if k in m {
		return ZeroString{
			v:      m[k]
			is_set: true
		}
	}
	return ZeroString{}
}

struct ZeroArrayString {
	v      []string
	is_set bool
}

fn zero_array_string(m map[string]string, k string) ZeroArrayString {
	s := zero_string(m, k)
	if s.is_set {
		return ZeroArrayString{
			v:      s.v.split(',')
			is_set: true
		}
	}
	return ZeroArrayString{}
}

struct ZeroI32 {
	v      i32
	is_set bool
}

fn zero_i32(m map[string]string, k string) ZeroI32 {
	s := zero_string(m, k)
	if s.is_set {
		return ZeroI32{
			v:      s.v.i32()
			is_set: true
		}
	}
	return ZeroI32{}
}

struct ZeroBool {
	v      bool
	is_set bool
}

fn zero_bool(m map[string]string, k string) ZeroBool {
	s := zero_string(m, k)
	if s.is_set {
		if s.v == '' {
			return ZeroBool{
				v:      true
				is_set: true
			}
		}

		return ZeroBool{
			v:      parse_bool(s.v)
			is_set: true
		}
	}
	return ZeroBool{}
}

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
	offset ZeroI32
	fetch  ZeroI32
	order  ZeroString
}

fn extract_retrieve_locales_params(m map[string]string) LocaleRetrieveParams {
	return LocaleRetrieveParams{
		offset: zero_i32(m, 'offset')
		fetch:  zero_i32(m, 'fetch')
		order:  zero_string(m, 'order')
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

struct ListSalesChannelsParamsHygienised {
	ids             ZeroArrayString
	ids_bin         [][]u8
	name            ZeroString
	description     ZeroString
	product_ids     ZeroArrayString
	product_ids_bin [][]u8
	offset          ZeroI32
	fetch           ZeroI32
	order           ZeroString
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

struct RetrieveProductVariantParamsHygienised {
	ids             ZeroArrayString
	ids_bin         [][]u8
	product_ids     ZeroArrayString
	product_ids_bin [][]u8
	allow_backorder ZeroBool
	region_id       ZeroString
	region_id_bin   []u8
	currency_code   ZeroString
	title           ZeroString
	with_deleted    ZeroBool
	offset          ZeroI32
	fetch           ZeroI32
	order           ZeroString
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

struct RetrieveProductParamsHygienised {
	ids                   ZeroArrayString
	ids_bin               [][]u8
	handle                ZeroString
	is_giftcard           ZeroBool
	status                ZeroString
	collection_ids        ZeroArrayString
	collection_ids_bin    [][]u8
	type_ids              ZeroArrayString
	type_ids_bin          [][]u8
	tag_ids               ZeroArrayString
	tag_ids_bin           [][]u8
	title                 ZeroString
	description           ZeroString
	category_ids          ZeroArrayString
	category_ids_bin      [][]u8
	price_list_ids        ZeroArrayString
	price_list_ids_bin    [][]u8
	sales_channel_ids     ZeroArrayString
	sales_channel_ids_bin [][]u8
	region_id             ZeroString
	region_id_bin         []u8
	currency_code         ZeroString
	with_deleted          ZeroBool
	offset                ZeroI32
	fetch                 ZeroI32
	order                 ZeroString
	cart_id               ZeroString
	cart_id_bin           []u8
	locale_id             ZeroString
	locale_id_bin         []u8
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

struct ProductCategoryParamsHygienised {
	ids                     ZeroArrayString
	ids_bin                 [][]u8
	handles                 ZeroArrayString
	is_active               ZeroBool
	is_internal             ZeroBool
	product_ids             ZeroArrayString
	product_ids_bin         [][]u8
	parent_category_ids     ZeroArrayString
	parent_category_id_bins [][]u8
	with_deleted            ZeroBool
	offset                  ZeroI32
	fetch                   ZeroI32
	order                   ZeroString
	locale_id               ZeroString
	locale_id_bin           []u8
}

fn hygienise_product_category_params(p ProductCategoryParams) !ProductCategoryParamsHygienised {
	ids_bin := zero_array_id_string_to_array_id_bin(p.ids) or {
		return new_internal_error(error_id_invalid, 'ids')
	}

	parent_category_ids_bin := zero_array_id_string_to_array_id_bin(p.parent_category_ids) or {
		return new_internal_error(error_id_invalid, 'parent_category_ids')
	}

	product_ids_bin := zero_array_id_string_to_array_id_bin(p.product_ids) or {
		return new_internal_error(error_id_invalid, 'product_ids')
	}

	return ProductCategoryParamsHygienised{
		ids:                     p.ids
		ids_bin:                 ids_bin
		handles:                 p.handles
		is_active:               p.is_active
		is_internal:             p.is_internal
		parent_category_ids:     p.parent_category_ids
		parent_category_id_bins: parent_category_ids_bin
		product_ids:             p.product_ids
		product_ids_bin:         product_ids_bin
		with_deleted:            p.with_deleted
		offset:                  p.offset
		fetch:                   p.fetch
		order:                   p.order
	}
}
