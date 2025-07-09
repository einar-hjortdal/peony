module main

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

struct RetrieveLocalesParams {
	offset ZeroI32
	fetch  ZeroI32
	order  ZeroString
}

fn extract_retrieve_locales_params(m map[string]string) RetrieveLocalesParams {
	return RetrieveLocalesParams{
		offset: zero_i32(m, 'offset')
		fetch:  zero_i32(m, 'fetch')
		order:  zero_string(m, 'order')
	}
}

struct RetrieveProductParams {
	id               ZeroArrayString
	handle           ZeroString
	is_giftcard      ZeroBool
	status           ZeroString
	collection_id    ZeroArrayString
	type_id          ZeroArrayString
	tag_id           ZeroArrayString
	title            ZeroString
	description      ZeroString
	category_id      ZeroArrayString
	price_list_id    ZeroArrayString
	sales_channel_id ZeroArrayString
	region_id        ZeroString
	currency_code    ZeroString
	offset           ZeroI32
	fetch            ZeroI32
	order            ZeroString
	cart_id          ZeroString
}

fn extract_retrieve_admin_products_params(m map[string]string) RetrieveProductParams {
	return RetrieveProductParams{
		category_id:      zero_array_string(m, 'category_id')
		collection_id:    zero_array_string(m, 'collection_id')
		description:      zero_string(m, 'description')
		fetch:            zero_i32(m, 'fetch')
		handle:           zero_string(m, 'handle')
		id:               zero_array_string(m, 'id')
		is_giftcard:      zero_bool(m, 'is_giftcard')
		offset:           zero_i32(m, 'offset')
		order:            zero_string(m, 'order')
		price_list_id:    zero_array_string(m, 'price_list_id')
		sales_channel_id: zero_array_string(m, 'sales_channel_id')
		status:           zero_string(m, 'status')
		tag_id:           zero_array_string(m, 'tag_id')
		title:            zero_string(m, 'title')
		type_id:          zero_array_string(m, 'type_id')
	}
}

fn extract_retrieve_store_products_params(m map[string]string) RetrieveProductParams {
	return RetrieveProductParams{
		cart_id:          zero_string(m, 'cart_id')
		category_id:      zero_array_string(m, 'category_id')
		collection_id:    zero_array_string(m, 'collection_id')
		currency_code:    zero_string(m, 'currency_code')
		description:      zero_string(m, 'description')
		fetch:            zero_i32(m, 'fetch')
		handle:           zero_string(m, 'handle')
		id:               zero_array_string(m, 'id')
		is_giftcard:      zero_bool(m, 'is_giftcard')
		offset:           zero_i32(m, 'offset')
		order:            zero_string(m, 'order')
		price_list_id:    zero_array_string(m, 'price_list_id')
		region_id:        zero_string(m, 'region_id')
		sales_channel_id: zero_array_string(m, 'sales_channel_id')
		status:           zero_string(m, 'status')
		tag_id:           zero_array_string(m, 'tag_id')
		title:            zero_string(m, 'title')
		type_id:          zero_array_string(m, 'type_id')
	}
}
