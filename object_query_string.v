module peony

pub struct UserListQueryParams {
pub:
	ids          ?[]string
	email        ?string
	handle       ?string
	with_deleted ?bool
	offset       ?i32
	fetch        ?i32
	order        ?string
}

fn extract_user_list_request_query(m map[string]string) UserListQueryParams {
	return UserListQueryParams{
		ids:          get_none_array_string(m, 'ids')
		email:        get_none_string(m, 'email')
		handle:       get_none_string(m, 'handle')
		with_deleted: get_none_bool(m, 'with_deleted')
		offset:       get_none_i32(m, 'offset')
		fetch:        get_none_i32(m, 'fetch')
		order:        get_none_string(m, 'order')
	}
}

fn hygienise_user_list_request_query(m map[string]string) !UserListParams {
	p := extract_user_list_request_query(m)

	mut ids := ?[]ID(none)
	if ids_string := p.ids {
		ids = ids_from_array_string(ids_string)!
	}

	return UserListParams{
		ids:          ids
		email:        p.email
		handle:       p.handle
		with_deleted: bool_or(p.with_deleted, false)
		offset:       get_offset_or_default(p.offset)!
		fetch:        get_fetch_or_default(p.fetch)!
		order:        get_order_direction_or_default(p.order)!
	}
}

pub struct RegionListQueryParams {
pub:
	ids          ?[]string
	with_deleted ?bool
	offset       ?i32
	fetch        ?i32
	order        ?string
}

fn extract_region_list_request_query(m map[string]string) RegionListQueryParams {
	return RegionListQueryParams{
		ids:          get_none_array_string(m, 'ids')
		with_deleted: get_none_bool(m, 'with_deleted')
		offset:       get_none_i32(m, 'offset')
		fetch:        get_none_i32(m, 'fetch')
		order:        get_none_string(m, 'order')
	}
}

fn hygienise_region_list_request_query(m map[string]string) !RegionRetriveParams {
	p := extract_region_list_request_query(m)

	mut ids := ?[]ID(none)
	if ids_string := p.ids {
		ids = ids_from_array_string(ids_string)!
	}

	return RegionRetriveParams{
		ids:          ids
		with_deleted: bool_or(p.with_deleted, false)
		offset:       get_offset_or_default(p.offset)!
		fetch:        get_fetch_or_default(p.fetch)!
		order:        get_order_direction_or_default(p.order)!
	}
}

struct CountryListQueryParams {
pub:
	codes  ?[]string
	offset ?i32
	fetch  ?i32
	order  ?string
}

fn extract_retrieve_countries_params(p map[string]string) CountryListQueryParams {
	return CountryListQueryParams{
		codes:  get_none_array_string(p, 'codes')
		offset: get_none_i32(p, 'offset')
		fetch:  get_none_i32(p, 'fetch')
		order:  get_none_string(p, 'order')
	}
}

fn hygienise_country_list_query(m map[string]string) !CountryRetrieveParams {
	p := extract_retrieve_countries_params(m)

	if codes := p.codes {
		for i := 0; i < codes.len; i++ {
			code := codes[i]
			if utf8_str_visible_length(code) > length_country_code {
				return new_error_unprocessable_entity(error_field_too_long, 'country code must be exactly ${length_country_code} UTF8 characters long')
			}
		}
	}

	return CountryRetrieveParams{
		codes:  p.codes
		offset: get_offset_or_default(p.offset)!
		fetch:  get_fetch_or_default(p.fetch)!
		order:  get_order_direction_or_default(p.order)!
	}
}

struct CurrencyListQueryParams {
pub:
	codes  ?[]string
	offset ?i32
	fetch  ?i32
	order  ?string
}

fn extract_retrieve_currencies_params(m map[string]string) CurrencyListQueryParams {
	return CurrencyListQueryParams{
		codes:  get_none_array_string(m, 'codes')
		offset: get_none_i32(m, 'offset')
		fetch:  get_none_i32(m, 'fetch')
		order:  get_none_string(m, 'order')
	}
}

fn hygienise_currency_list_query(m map[string]string) !CurrencyRetrieveParams {
	p := extract_retrieve_currencies_params(m)

	if codes := p.codes {
		for i := 0; i < codes.len; i++ {
			code := codes[i]
			if utf8_str_visible_length(code) > length_currency_code {
				return new_error_unprocessable_entity(error_field_too_long, 'currency code must be exactly ${length_currency_code} UTF8 characters long')
			}
		}
	}

	return CurrencyRetrieveParams{
		codes:  p.codes
		offset: get_offset_or_default(p.offset)!
		fetch:  get_fetch_or_default(p.fetch)!
		order:  get_order_direction_or_default(p.order)!
	}
}

struct LocaleListQueryParams {
pub:
	ids    ?[]string
	offset ?i32
	fetch  ?i32
	order  ?string
}

fn extract_locale_retrieve_params(m map[string]string) LocaleListQueryParams {
	return LocaleListQueryParams{
		ids:    get_none_array_string(m, 'ids')
		offset: get_none_i32(m, 'offset')
		fetch:  get_none_i32(m, 'fetch')
		order:  get_none_string(m, 'order')
	}
}

fn hygienise_retrieve_locale_params(m map[string]string) !LocaleRetrieveParams {
	p := extract_locale_retrieve_params(m)

	mut ids := ?[]ID(none)
	if ids_string := p.ids {
		ids = ids_from_array_string(ids_string)!
	}

	return LocaleRetrieveParams{
		ids:    ids
		offset: get_offset_or_default(p.offset)!
		fetch:  get_fetch_or_default(p.fetch)!
		order:  get_order_direction_or_default(p.order)!
	}
}

struct SalesChannelListQueryParams {
pub:
	ids    ?[]string
	offset ?i32
	fetch  ?i32
	order  ?string
}

fn extract_sales_channels_list_query_params(m map[string]string) SalesChannelListQueryParams {
	return SalesChannelListQueryParams{
		ids:    get_none_array_string(m, 'ids')
		offset: get_none_i32(m, 'offset')
		fetch:  get_none_i32(m, 'fetch')
		order:  get_none_string(m, 'order')
	}
}

fn hygienise_sales_channels_list_query_params(m map[string]string) !SalesChannelRetrieveParams {
	p := extract_sales_channels_list_query_params(m)

	mut ids := ?[]ID(none)
	if ids_string := p.ids {
		ids = ids_from_array_string(ids_string)!
	}

	return SalesChannelRetrieveParams{
		ids:    ids
		offset: get_offset_or_default(p.offset)!
		fetch:  get_fetch_or_default(p.fetch)!
		order:  get_order_direction_or_default(p.order)!
	}
}

struct RetrieveProductVariantParams {
pub:
	ids             ZeroArrayString
	product_ids     ZeroArrayString
	allow_backorder ZeroBool
	region_id       ZeroString
	title           ZeroString
	with_deleted    ZeroBool
	offset          ZeroI32
	fetch           ZeroI32
	order           ZeroString
}

struct RetrieveProductVariantParamsHygienised {
	ids             ZeroArrayString
	ids_bin         [][]u8
	product_ids     ZeroArrayString
	product_ids_bin [][]u8
	allow_backorder ZeroBool
	region_id       ZeroString
	region_id_bin   []u8
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
		offset:          zero_i32(m, 'offset')
		fetch:           zero_i32(m, 'fetch')
		order:           zero_string(m, 'order')
	}
}

pub struct ProductListRequestQuery {
pub:
	ids               ZeroArrayString
	handle            ZeroString
	is_giftcard       ZeroBool
	status            ZeroString
	type_ids          ZeroArrayString
	tag_ids           ZeroArrayString
	title             ZeroString
	description       ZeroString
	category_ids      ZeroArrayString
	price_list_ids    ZeroArrayString
	sales_channel_ids ZeroArrayString
	region_id         ZeroString
	with_deleted      ZeroBool
	offset            ZeroI32
	fetch             ZeroI32
	order             ZeroString
	cart_id           ZeroString
	locale_id         ZeroString
}

fn extract_product_list_request_query(m map[string]string) ProductListRequestQuery {
	return ProductListRequestQuery{
		cart_id:           zero_string(m, 'cart_id')
		category_ids:      zero_array_string(m, 'category_ids')
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
		type_ids:          zero_array_string(m, 'type_id')
		locale_id:         zero_string(m, 'locale_id')
	}
}

// ProductListRequestQueryStore allows filtering and sorting preoducts.
//
// # Fields
//
// ## ids
// Exact match on product IDs. Most efficient lookup.
//
// ## handle
// Exact match on product handle. Less efficient than ids.
//
// ## is_giftcard
// Filters by gift card status. (TODO)
//
// ## type_ids
// Exact match on product type IDs. (TODO)
//
// ## tag_ids
// Exact match on product tag IDs. (TODO)
//
// ## category_ids
// Exact match on product category IDs.
//
// ## price_list_ids
// Applies price lists for price resolution. Priority rules apply if multiple. (TODO)
//
// ## sales_channel_id
// Filters by availability in the provided sales channels. Defaults to the store's default sales_channel.
//
// ## region_id
// Determines currency for returned prices. Defaults to the store's default region.
//
// ## locale_id
// Returns translated fields if available. Defaults to the store's default locale.
//
// ## offset
// Pagination offset.
//
// ## fetch
// Maximum number of products to return. Cannot exceed 100.
//
// ## order
// See constants: `order_asc`, `order_desc`.
//
// ## cart_id
// Enables cart‑aware price resolution. (TODO)
//
// Note: it is recommended to use a frontend search engine for enhanced user experience (pattern matching, matching handles to ids, searching among translations, sorting by price, filtering by availability, etc.)
pub struct ProductListRequestQueryStore {
pub:
	ids               ZeroArrayString
	handle            ZeroString
	is_giftcard       ZeroBool
	type_ids          ZeroArrayString
	tag_ids           ZeroArrayString
	category_ids      ZeroArrayString
	price_list_ids    ZeroArrayString
	sales_channel_ids ZeroArrayString // TODO this should be one not an array
	region_id         ZeroString
	offset            ZeroI32
	fetch             ZeroI32
	order             ZeroString
	cart_id           ZeroString
	locale_id         ZeroString
}

fn extract_product_list_request_query_store(m map[string]string) ProductListRequestQueryStore {
	return ProductListRequestQueryStore{
		cart_id:           zero_string(m, 'cart_id')
		category_ids:      zero_array_string(m, 'category_ids')
		fetch:             zero_i32(m, 'fetch')
		handle:            zero_string(m, 'handle')
		ids:               zero_array_string(m, 'id')
		is_giftcard:       zero_bool(m, 'is_giftcard')
		offset:            zero_i32(m, 'offset')
		order:             zero_string(m, 'order')
		price_list_ids:    zero_array_string(m, 'price_list_id')
		region_id:         zero_string(m, 'region_id')
		sales_channel_ids: zero_array_string(m, 'sales_channel_id')
		tag_ids:           zero_array_string(m, 'tag_id')
		type_ids:          zero_array_string(m, 'type_id')
		locale_id:         zero_string(m, 'locale_id')
	}
}

// TODO change sales_channel_ids ZeroArrayString to sales_channel_id ZeroString
// there can only be one sales_channel in price context
pub struct ProductGetRequestQueryStore {
pub:
	price_list_ids    ZeroArrayString
	sales_channel_ids ZeroArrayString
	region_id         ZeroString
	cart_id           ZeroString
	locale_id         ZeroString
}

fn hygienise_product_get_request_query_store(m map[string]string, product_id string) !RetrieveProductParamsHygienised {
	ids := ZeroArrayString{
		is_set: true
		v:      [product_id]
	}

	id_bin := id_string_to_bin(product_id) or {
		return new_error_bad_request(error_id_invalid, 'product_id')
	}

	cart_id := zero_string(m, 'cart_id')
	cart_id_bin := zero_id_string_to_id_bin(cart_id) or {
		return new_error_bad_request(error_id_invalid, 'cart_id')
	}

	sales_channel_ids := zero_array_string(m, 'sales_channel_id')
	sales_channel_ids_bin := zero_array_id_string_to_array_id_bin(sales_channel_ids) or {
		return new_error_bad_request(error_id_invalid, 'sales_channel_id')
	}

	region_id := zero_string(m, 'region_id')
	region_id_bin := zero_id_string_to_id_bin(region_id) or {
		return new_error_bad_request(error_id_invalid, 'region_id')
	}

	locale_id := zero_string(m, 'locale_id')
	locale_id_bin := zero_id_string_to_id_bin(locale_id) or {
		return new_error_bad_request(error_id_invalid, 'locale_id')
	}

	return RetrieveProductParamsHygienised{
		ids:                   ids
		ids_bin:               [id_bin]
		region_id:             region_id
		region_id_bin:         region_id_bin
		cart_id:               cart_id
		cart_id_bin:           cart_id_bin
		sales_channel_ids:     sales_channel_ids
		sales_channel_ids_bin: sales_channel_ids_bin
		locale_id:             locale_id
		locale_id_bin:         locale_id_bin
	}
}

// handles expects a string that is a single handle, or many comma-separated handles.
pub struct CategoryListQueryParams {
pub:
	ids                ?[]string
	handle             ?string
	is_active          ?bool
	is_internal        ?bool
	product_ids        ?[]string
	parent_category_id ?string
	with_deleted       ?bool
	offset             ?i32
	fetch              ?i32
	order              ?string
}

fn extract_category_list_request_query(m map[string]string) CategoryListQueryParams {
	return CategoryListQueryParams{
		ids:                get_none_array_string(m, 'ids')
		handle:             get_none_string(m, 'handle')
		is_active:          get_none_bool(m, 'is_active')
		is_internal:        get_none_bool(m, 'is_internal')
		product_ids:        get_none_array_string(m, 'product_ids')
		parent_category_id: get_none_string(m, 'parent_category_id')
		with_deleted:       get_none_bool(m, 'with_deleted')
		offset:             get_none_i32(m, 'offset')
		fetch:              get_none_i32(m, 'fetch')
		order:              get_none_string(m, 'order')
	}
}

fn hygienise_category_list_request_query(m map[string]string) !CategoryRetrieveParams {
	p := extract_category_list_request_query(m)

	mut ids := ?[]ID(none)
	if ids_string := p.ids {
		ids = ids_from_array_string(ids_string)!
	}

	mut parent_category_id := ?ID(none)
	if id_string := p.parent_category_id {
		parent_category_id = id_from_string(id_string)!
	}

	mut product_ids := ?[]ID(none)
	if ids_string := p.product_ids {
		product_ids = ids_from_array_string(ids_string)!
	}

	return CategoryRetrieveParams{
		ids:                ids
		handle:             p.handle
		is_active:          p.is_active
		is_internal:        p.is_active
		product_ids:        product_ids
		parent_category_id: parent_category_id
		with_deleted:       bool_or(p.with_deleted, false)
		offset:             get_offset_or_default(p.offset)!
		fetch:              get_fetch_or_default(p.fetch)!
		order:              get_order_direction_or_default(p.order)!
	}
}

struct RetrieveProductParamsHygienised {
	ids                   ZeroArrayString
	ids_bin               [][]u8
	handle                ZeroString
	is_giftcard           ZeroBool
	status                ZeroString
	type_ids              ZeroArrayString
	type_ids_bin          [][]u8
	tag_ids               ZeroArrayString
	tag_ids_bin           [][]u8
	category_ids          ZeroArrayString
	category_ids_bin      [][]u8
	price_list_ids        ZeroArrayString
	price_list_ids_bin    [][]u8
	sales_channel_ids     ZeroArrayString
	sales_channel_ids_bin [][]u8
	region_id             ZeroString
	region_id_bin         []u8
	with_deleted          ZeroBool
	offset                ZeroI32
	fetch                 ZeroI32
	order                 ZeroString
	cart_id               ZeroString
	cart_id_bin           []u8
	locale_id             ZeroString
	locale_id_bin         []u8
}

fn hygienise_retrieve_product_params(m map[string]string) !RetrieveProductParamsHygienised {
	ids := zero_array_string(m, 'ids')
	ids_bin := zero_array_id_string_to_array_id_bin(ids) or {
		return new_error_bad_request(error_id_invalid, 'product_id')
	}

	price_list_ids := zero_array_string(m, 'price_list_ids')
	price_list_ids_bin := zero_array_id_string_to_array_id_bin(price_list_ids) or {
		return new_error_bad_request(error_id_invalid, 'price_list_id')
	}

	tag_ids := zero_array_string(m, 'tag_id')
	tag_ids_bin := zero_array_id_string_to_array_id_bin(tag_ids) or {
		return new_error_bad_request(error_id_invalid, 'tag_id')
	}

	type_ids := zero_array_string(m, 'type_id')
	type_ids_bin := zero_array_id_string_to_array_id_bin(type_ids) or {
		return new_error_bad_request(error_id_invalid, 'type_id')
	}

	region_id := zero_string(m, 'region_id')
	region_id_bin := zero_id_string_to_id_bin(region_id) or {
		return new_error_bad_request(error_id_invalid, 'region_id')
	}

	category_ids := zero_array_string(m, 'category_ids')
	category_ids_bin := zero_array_id_string_to_array_id_bin(category_ids) or {
		return new_error_bad_request(error_id_invalid, 'category_id')
	}

	sales_channel_ids := zero_array_string(m, 'sales_channel_ids')
	sales_channel_ids_bin := zero_array_id_string_to_array_id_bin(sales_channel_ids) or {
		return new_error_bad_request(error_id_invalid, 'sales_channel_id')
	}

	locale_id := zero_string(m, 'locale_id')
	locale_id_bin := zero_id_string_to_id_bin(locale_id) or {
		return new_error_bad_request(error_id_invalid, 'locale_id')
	}

	cart_id := zero_string(m, 'cart_id')
	cart_id_bin := zero_id_string_to_id_bin(cart_id) or {
		return new_error_bad_request(error_id_invalid, 'cart_id')
	}

	return RetrieveProductParamsHygienised{
		ids:                   ids
		ids_bin:               ids_bin
		handle:                zero_string(m, 'handle')
		is_giftcard:           zero_bool(m, 'is_giftcard')
		status:                zero_string(m, 'status')
		type_ids:              type_ids
		type_ids_bin:          type_ids_bin
		tag_ids:               tag_ids
		tag_ids_bin:           tag_ids_bin
		category_ids:          category_ids
		category_ids_bin:      category_ids_bin
		price_list_ids:        price_list_ids
		price_list_ids_bin:    price_list_ids_bin
		sales_channel_ids:     sales_channel_ids
		sales_channel_ids_bin: sales_channel_ids_bin
		region_id:             region_id
		region_id_bin:         region_id_bin
		with_deleted:          zero_bool(m, 'with_deleted')
		offset:                zero_i32(m, 'offset')
		fetch:                 zero_i32(m, 'fetch')
		order:                 zero_string(m, 'order')
		cart_id:               cart_id
		cart_id_bin:           cart_id_bin
		locale_id:             locale_id
		locale_id_bin:         locale_id_bin
	}
}

