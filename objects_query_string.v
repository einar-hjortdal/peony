module main

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
}

fn extract_retrieve_products_params(m map[string]string) RetrieveProductParams {
	return RetrieveProductParams{
		id:               zero_array_string(m, 'id')
		handle:           zero_string(m, 'handle')
		is_giftcard:      zero_bool(m, 'is_giftcard')
		status:           zero_string(m, 'status')
		collection_id:    zero_array_string(m, 'collection_id')
		type_id:          zero_array_string(m, 'type_id')
		tag_id:           zero_array_string(m, 'tag_id')
		title:            zero_string(m, 'title')
		description:      zero_string(m, 'description')
		category_id:      zero_array_string(m, 'category_id')
		price_list_id:    zero_array_string(m, 'price_list_id')
		sales_channel_id: zero_array_string(m, 'sales_channel_id')
		region_id:        zero_string(m, 'region_id') // TODO used by /store/
		currency_code:    zero_string(m, 'currency_code') // TODO used by /store/
		offset:           zero_i32(m, 'offset')
		fetch:            zero_i32(m, 'fetch')
		order:            zero_string(m, 'order')
	}
}
