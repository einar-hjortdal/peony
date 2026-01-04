module peony

// TODO query string parameters are not object_, they're route_
pub struct UserListRequestQuery {
pub:
	ids          ZeroArrayString
	email        ZeroString
	handle       ZeroString
	with_deleted ZeroBool
	offset       ZeroI32
	fetch        ZeroI32
	order        ZeroString
}

fn extract_user_list_request_query(m map[string]string) UserListRequestQuery {
	return UserListRequestQuery{
		ids:          zero_array_string(m, 'ids')
		email:        zero_string(m, 'email')
		handle:       zero_string(m, 'handle')
		with_deleted: zero_bool(m, 'with_deleted')
		offset:       zero_i32(m, 'offset')
		fetch:        zero_i32(m, 'fetch')
		order:        zero_string(m, 'order')
	}
}

pub struct RegionListRequestQuery {
pub:
	ids          ZeroArrayString
	name         ZeroString
	with_deleted ZeroBool
	offset       ZeroI32
	fetch        ZeroI32
	order        ZeroString
}

fn extract_region_list_request_query(m map[string]string) RegionListRequestQuery {
	return RegionListRequestQuery{
		ids:          zero_array_string(m, 'ids')
		name:         zero_string(m, 'name')
		with_deleted: zero_bool(m, 'with_deleted')
		offset:       zero_i32(m, 'offset')
		fetch:        zero_i32(m, 'fetch')
		order:        zero_string(m, 'order')
	}
}

struct ListCountriesParams {
pub:
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
pub:
	codes  ZeroArrayString
	offset ZeroI32
	fetch  ZeroI32
	order  ZeroString
}

fn extract_retrieve_currencies_params(m map[string]string) RetrieveCurrenciesParams {
	return RetrieveCurrenciesParams{
		codes:  zero_array_string(m, 'codes')
		offset: zero_i32(m, 'offset')
		fetch:  zero_i32(m, 'fetch')
		order:  zero_string(m, 'order')
	}
}

struct LocaleRetrieveParams {
pub:
	ids    ZeroArrayString
	offset ZeroI32
	fetch  ZeroI32
	order  ZeroString
}

struct ListSalesChannelsParams {
pub:
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

fn extract_retrieve_product_variant_params(m map[string]string) RetrieveProductVariantParams {
	return RetrieveProductVariantParams{
		ids:             zero_array_string(m, 'ids')
		product_ids:     zero_array_string(m, 'product_ids')
		allow_backorder: zero_bool(m, 'allow_backorder')
		region_id:       zero_string(m, 'region_id')
		title:           zero_string(m, 'title')
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
	collection_ids    ZeroArrayString
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
		collection_ids:    zero_array_string(m, 'collection_id')
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

pub struct ProductListRequestQueryStore {
pub:
	ids               ZeroArrayString
	handle            ZeroString
	is_giftcard       ZeroBool
	collection_ids    ZeroArrayString
	type_ids          ZeroArrayString
	tag_ids           ZeroArrayString
	title             ZeroString
	description       ZeroString
	category_ids      ZeroArrayString
	price_list_ids    ZeroArrayString
	sales_channel_ids ZeroArrayString
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
		collection_ids:    zero_array_string(m, 'collection_id')
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
		tag_ids:           zero_array_string(m, 'tag_id')
		title:             zero_string(m, 'title')
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
		return new_internal_error(error_id_invalid, 'product_id')
	}

	cart_id := zero_string(m, 'cart_id')
	cart_id_bin := zero_id_string_to_id_bin(cart_id) or {
		return new_internal_error(error_id_invalid, 'cart_id')
	}

	sales_channel_ids := zero_array_string(m, 'sales_channel_id')
	sales_channel_ids_bin := zero_array_id_string_to_array_id_bin(sales_channel_ids) or {
		return new_internal_error(error_id_invalid, 'sales_channel_id')
	}

	region_id := zero_string(m, 'region_id')
	region_id_bin := zero_id_string_to_id_bin(region_id) or {
		return new_internal_error(error_id_invalid, 'region_id')
	}

	locale_id := zero_string(m, 'locale_id')
	locale_id_bin := zero_id_string_to_id_bin(locale_id) or {
		return new_internal_error(error_id_invalid, 'locale_id')
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

pub struct ProductCategoryGetRequestQuery {
pub:
	locale_id ZeroString
}

fn extract_category_get_request_params(m map[string]string) ProductCategoryGetRequestQuery {
	return ProductCategoryGetRequestQuery{
		locale_id: zero_string(m, 'locale_id')
	}
}

// handles expects a string that is a single handle, or many comma-separated handles.
pub struct ProductCategoryListRequestQuery {
pub:
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

fn extract_category_list_request_query(m map[string]string) ProductCategoryListRequestQuery {
	return ProductCategoryListRequestQuery{
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

// TODO extract locale_id to separate struct (request context)
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
		return new_internal_error(error_id_invalid, 'product_id')
	}

	collection_ids := zero_array_string(m, 'collection_ids')
	collection_ids_bin := zero_array_id_string_to_array_id_bin(collection_ids) or {
		return new_internal_error(error_id_invalid, 'collection_id')
	}

	price_list_ids := zero_array_string(m, 'price_list_ids')
	price_list_ids_bin := zero_array_id_string_to_array_id_bin(price_list_ids) or {
		return new_internal_error(error_id_invalid, 'price_list_id')
	}

	tag_ids := zero_array_string(m, 'tag_id')
	tag_ids_bin := zero_array_id_string_to_array_id_bin(tag_ids) or {
		return new_internal_error(error_id_invalid, 'tag_id')
	}

	type_ids := zero_array_string(m, 'type_id')
	type_ids_bin := zero_array_id_string_to_array_id_bin(type_ids) or {
		return new_internal_error(error_id_invalid, 'type_id')
	}

	region_id := zero_string(m, 'region_id')
	region_id_bin := zero_id_string_to_id_bin(region_id) or {
		return new_internal_error(error_id_invalid, 'region_id')
	}

	category_ids := zero_array_string(m, 'category_ids')
	category_ids_bin := zero_array_id_string_to_array_id_bin(category_ids) or {
		return new_internal_error(error_id_invalid, 'category_id')
	}

	sales_channel_ids := zero_array_string(m, 'sales_channel_ids')
	sales_channel_ids_bin := zero_array_id_string_to_array_id_bin(sales_channel_ids) or {
		return new_internal_error(error_id_invalid, 'sales_channel_id')
	}

	locale_id := zero_string(m, 'locale_id')
	locale_id_bin := zero_id_string_to_id_bin(locale_id) or {
		return new_internal_error(error_id_invalid, 'locale_id')
	}

	cart_id := zero_string(m, 'cart_id')
	cart_id_bin := zero_id_string_to_id_bin(cart_id) or {
		return new_internal_error(error_id_invalid, 'cart_id')
	}

	return RetrieveProductParamsHygienised{
		ids:                   ids
		ids_bin:               ids_bin
		handle:                zero_string(m, 'handle')
		is_giftcard:           zero_bool(m, 'is_giftcard')
		status:                zero_string(m, 'status')
		collection_ids:        collection_ids
		collection_ids_bin:    collection_ids_bin
		type_ids:              type_ids
		type_ids_bin:          type_ids_bin
		tag_ids:               tag_ids
		tag_ids_bin:           tag_ids_bin
		title:                 zero_string(m, 'title')
		description:           zero_string(m, 'description')
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
