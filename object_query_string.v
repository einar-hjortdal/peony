module peony

import internal.conduit

// Whenever a translateable resource is requested, the request may contain a LocaleContextQueryParams.
// If translations exist for the resource requested, the resource will use them.
pub struct LocaleContextQueryParams {
pub:
	locale_id ?string
}

fn extract_locale_context_query_params(m map[string]string) LocaleContextQueryParams {
	return LocaleContextQueryParams{
		locale_id: get_none_string(m, 'locale_id')
	}
}

fn hygienise_locale_context_query_params(m map[string]string) !LocaleContext {
	p := extract_locale_context_query_params(m)
	mut locale_id := ?ID(none)
	if id_string := p.locale_id {
		locale_id = id_from_string(id_string)!
	}

	return LocaleContext{
		locale_id: locale_id
	}
}

// WIP
// The information contained by PriceContextQueryParams is utilized to calculate prices and their presentation.
pub struct PriceContextQueryParams {
pub:
	cart_id   ?string
	region_id ?string
}

struct PriceContextQueryParamsHygienised {
	cart_id   ?ID
	region_id ?ID
}

fn extract_price_context_query_params(m map[string]string) PriceContextQueryParams {
	return PriceContextQueryParams{
		cart_id:   get_none_string(m, 'cart_id')
		region_id: get_none_string(m, 'region_id')
	}
}

fn hygienise_price_context_query_params(m map[string]string) !PriceContextQueryParamsHygienised {
	p := extract_price_context_query_params(m)
	mut cart_id := ?ID(none)
	if id_string := p.cart_id {
		cart_id = id_from_string(id_string)!
	}

	mut region_id := ?ID(none)
	if id_string := p.region_id {
		region_id = id_from_string(id_string)!
	}

	return PriceContextQueryParamsHygienised{
		cart_id:   cart_id
		region_id: region_id
	}
}

pub struct APIKeyListQueryParams {
pub:
	ids          ?[]string
	with_deleted ?bool
	offset       ?i32
	fetch        ?i32
	order        ?string
}

fn extract_api_key_list_query_params(m map[string]string) APIKeyListQueryParams {
	return APIKeyListQueryParams{
		ids:          get_none_array_string(m, 'ids')
		with_deleted: get_none_bool(m, 'with_deleted')
		offset:       get_none_i32(m, 'offset')
		fetch:        get_none_i32(m, 'fetch')
		order:        get_none_string(m, 'order')
	}
}

fn hygienise_api_key_list_query_params(m map[string]string) !conduit.APIKeyRetrieveParams {
	p := extract_api_key_list_query_params(m)

	mut ids := ?[]ID(none)
	if ids_string := p.ids {
		ids = ids_from_array_string(ids_string)!
	}

	return conduit.APIKeyRetrieveParams{
		ids:          ids
		with_deleted: bool_or(p.with_deleted, false)
		offset:       get_offset_or_default(p.offset)!
		fetch:        get_fetch_or_default(p.fetch)!
		order:        get_order_direction_or_default(p.order)!
	}
}

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

fn hygienise_user_list_request_query(m map[string]string) !conduit.UserListParams {
	p := extract_user_list_request_query(m)

	mut ids := ?[]ID(none)
	if ids_string := p.ids {
		ids = ids_from_array_string(ids_string)!
	}

	return conduit.UserListParams{
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

fn hygienise_region_list_request_query(m map[string]string) !conduit.RegionRetriveParams {
	p := extract_region_list_request_query(m)

	mut ids := ?[]ID(none)
	if ids_string := p.ids {
		ids = ids_from_array_string(ids_string)!
	}

	return conduit.RegionRetriveParams{
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

fn hygienise_country_list_query(m map[string]string) !conduit.CountryRetrieveParams {
	p := extract_retrieve_countries_params(m)

	if codes := p.codes {
		for i := 0; i < codes.len; i++ {
			code := codes[i]
			if utf8_str_visible_length(code) > length_country_code {
				return new_error_unprocessable_entity(error_field_too_long,
					'country code must be exactly ${length_country_code} UTF8 characters long')
			}
		}
	}

	return conduit.CountryRetrieveParams{
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

fn hygienise_currency_list_query(m map[string]string) !conduit.CurrencyRetrieveParams {
	p := extract_retrieve_currencies_params(m)

	if codes := p.codes {
		for i := 0; i < codes.len; i++ {
			code := codes[i]
			if utf8_str_visible_length(code) > length_currency_code {
				return new_error_unprocessable_entity(error_field_too_long,
					'currency code must be exactly ${length_currency_code} UTF8 characters long')
			}
		}
	}

	return conduit.CurrencyRetrieveParams{
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

fn hygienise_retrieve_locale_params(m map[string]string) !conduit.LocaleRetrieveParams {
	p := extract_locale_retrieve_params(m)

	mut ids := ?[]ID(none)
	if ids_string := p.ids {
		ids = ids_from_array_string(ids_string)!
	}

	return conduit.LocaleRetrieveParams{
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

fn hygienise_sales_channels_list_query_params(m map[string]string) !conduit.SalesChannelRetrieveParams {
	p := extract_sales_channels_list_query_params(m)

	mut ids := ?[]ID(none)
	if ids_string := p.ids {
		ids = ids_from_array_string(ids_string)!
	}

	return conduit.SalesChannelRetrieveParams{
		ids:    ids
		offset: get_offset_or_default(p.offset)!
		fetch:  get_fetch_or_default(p.fetch)!
		order:  get_order_direction_or_default(p.order)!
	}
}

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

fn hygienise_category_list_request_query(m map[string]string) !conduit.CategoryRetrieveParams {
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

	return conduit.CategoryRetrieveParams{
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

pub struct ProductListQueryParams {
pub:
	ids              ?[]string
	handle           ?string
	is_giftcard      ?bool
	status           ?string
	category_ids     ?[]string
	sales_channel_id ?string
	with_deleted     ?bool
	offset           ?i32
	fetch            ?i32
	order            ?string
	// title            ?string
	// description      ?string
	// type_ids         ?[]string
	// tag_ids          ?[]string
}

fn extract_product_list_query_params(m map[string]string) ProductListQueryParams {
	return ProductListQueryParams{
		ids:              get_none_array_string(m, 'ids')
		handle:           get_none_string(m, 'handle')
		is_giftcard:      get_none_bool(m, 'is_giftcard')
		status:           get_none_string(m, 'status')
		category_ids:     get_none_array_string(m, 'category_ids')
		sales_channel_id: get_none_string(m, 'sales_channel_id')
		with_deleted:     get_none_bool(m, 'with_deleted')
		offset:           get_none_i32(m, 'offset')
		fetch:            get_none_i32(m, 'fetch')
		order:            get_none_string(m, 'order')
	}
}

fn hygienise_product_list_query_params(m map[string]string) !conduit.ProductRetrieveParams {
	p := extract_product_list_query_params(m)

	mut ids := ?[]ID(none)
	if ids_string := p.ids {
		ids = ids_from_array_string(ids_string)!
	}

	mut category_ids := ?[]ID(none)
	if ids_string := p.category_ids {
		category_ids = ids_from_array_string(ids_string)!
	}

	mut sales_channel_id := ?ID(none)
	if id_string := p.sales_channel_id {
		sales_channel_id = id_from_string(id_string)!
	}

	return conduit.ProductRetrieveParams{
		ids:              ids
		handle:           p.handle
		is_giftcard:      p.is_giftcard
		status:           p.status
		category_ids:     category_ids
		sales_channel_id: sales_channel_id
		with_deleted:     bool_or(p.with_deleted, false)
		offset:           get_offset_or_default(p.offset)!
		fetch:            get_fetch_or_default(p.fetch)!
		order:            get_order_direction_or_default(p.order)!
	}
}

// ProductListQueryParamsStore allows filtering and sorting preoducts.
//
// # Fields
//
// ## ids
// Comma-separated product ids. Exact match on product IDs. Most efficient lookup.
//
// ## handle
// Exact match on product handle. Less efficient than ids.
//
// ## is_giftcard
// Filters gift cards.
//
// ## category_ids
// Exact match on product category IDs.
//
// ## offset
// Pagination offset.
//
// ## fetch
// Maximum number of products to return. Cannot exceed 100.
//
// ## order
// See constants: `order_asc`, `order_desc`.
pub struct ProductListQueryParamsStore {
pub:
	ids          ?[]string
	handle       ?string
	is_giftcard  ?bool
	category_ids ?[]string
	offset       ?i32
	fetch        ?i32
	order        ?string
}

fn extract_product_list_query_params_store(m map[string]string) ProductListQueryParamsStore {
	return ProductListQueryParamsStore{
		ids:          get_none_array_string(m, 'ids')
		handle:       get_none_string(m, 'handle')
		is_giftcard:  get_none_bool(m, 'is_giftcard')
		category_ids: get_none_array_string(m, 'category_ids')
		offset:       get_none_i32(m, 'offset')
		fetch:        get_none_i32(m, 'fetch')
		order:        get_none_string(m, 'order')
	}
}

fn hygienise_product_list_query_params_store(m map[string]string, sales_channel_id ID) !conduit.ProductRetrieveParams {
	p := extract_product_list_query_params_store(m)

	mut ids := ?[]ID(none)
	if ids_string := p.ids {
		ids = ids_from_array_string(ids_string)!
	}

	mut category_ids := ?[]ID(none)
	if ids_string := p.category_ids {
		category_ids = ids_from_array_string(ids_string)!
	}

	return conduit.ProductRetrieveParams{
		ids:              ids
		handle:           p.handle
		is_giftcard:      p.is_giftcard
		category_ids:     category_ids
		sales_channel_id: sales_channel_id
		offset:           get_offset_or_default(p.offset)!
		fetch:            get_fetch_or_default(p.fetch)!
		order:            get_order_direction_or_default(p.order)!
	}
}

struct VariantListQueryParams {
pub:
	ids             ?[]string
	product_ids     ?[]string
	allow_backorder ?bool
	with_deleted    ?bool
	offset          ?i32
	fetch           ?i32
	order           ?string
}

fn extract_variant_list_query_params(m map[string]string) VariantListQueryParams {
	return VariantListQueryParams{
		ids:             get_none_array_string(m, 'ids')
		product_ids:     get_none_array_string(m, 'product_ids')
		allow_backorder: get_none_bool(m, 'allow_backorder')
		with_deleted:    get_none_bool(m, 'with_deleted')
		offset:          get_none_i32(m, 'offset')
		fetch:           get_none_i32(m, 'fetch')
		order:           get_none_string(m, 'order')
	}
}
