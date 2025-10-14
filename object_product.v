module peony

import einar_hjortdal.firebird

struct Product {
	id           string
	id_bin       []u8
	created_at   firebird.DateTime
	updated_at   firebird.DateTime
	deleted_at   firebird.NullDateTime
	handle       string
	is_giftcard  bool
	status       string
	thumbnail    firebird.NullString
	type_id_bin  firebird.NullArrayU8
	discountable bool
	metadata     firebird.NullString
	title        firebird.NullString
	subtitle     firebird.NullString
	description  firebird.NullString
mut:
	categories     []ProductCategory
	images         []ProductImage
	options        []ProductOption
	sales_channels []SalesChannel
	translations   []ProductTranslation
	variants       []ProductVariant
	// tags         []Tag
}

struct ProductRequest {
	handle            ?string
	is_giftcard       ?bool @[json: 'isGiftcard']
	status            ?string
	thumbnail         ?string
	type_id           ?string @[json: 'typeId']
	discountable      ?bool
	metadata          ?string   @[raw]
	tag_ids           ?[]string @[json: 'tagIds']
	sales_channel_ids ?[]string @[json: 'salesChannelIds']
	category_ids      ?[]string @[json: 'categoryIds']
	collection_ids    ?[]string @[json: 'collectionIds']
	translations      ?[]ProductTranslationRequest
	options           ?[]ProductOptionRequest
	images            ?[]ImageRequest
}

struct ProductRequestHygienised {
	handle                ?string
	is_giftcard           ?bool
	status                ?string
	thumbnail             ?string
	type_id               ?string
	type_id_bin           []u8
	discountable          ?bool
	metadata              ?string
	tag_ids               ?[]string
	tag_ids_bin           [][]u8
	sales_channel_ids     ?[]string
	sales_channel_ids_bin [][]u8
	category_ids          ?[]string
	category_ids_bin      [][]u8
	collection_ids        ?[]string
	collection_ids_bin    [][]u8
mut:
	options      ?[]ProductOptionRequestHygienised
	translations ?[]ProductTranslationRequestHygienised
	images       ?[]ImageRequestHygienised
}

fn (p ProductRequest) hygienise() !ProductRequestHygienised {
	type_id_bin := option_id_string_to_id_bin(p.type_id) or {
		return new_internal_error(error_id_invalid, 'type_id')
	}

	tag_ids_bin := option_array_id_string_to_array_id_bin(p.tag_ids) or {
		return new_internal_error(error_id_invalid, 'tag_id')
	}

	sales_channel_ids_bin := option_array_id_string_to_array_id_bin(p.sales_channel_ids) or {
		return new_internal_error(error_id_invalid, 'sales_channel_id')
	}

	category_ids_bin := option_array_id_string_to_array_id_bin(p.category_ids) or {
		return new_internal_error(error_id_invalid, 'category_id')
	}

	collection_id_bin := option_array_id_string_to_array_id_bin(p.collection_ids) or {
		return new_internal_error(error_id_invalid, 'collection_id')
	}

	mut ph := ProductRequestHygienised{
		handle:                p.handle
		is_giftcard:           p.is_giftcard
		status:                p.status
		thumbnail:             p.thumbnail
		type_id:               p.type_id
		type_id_bin:           type_id_bin
		discountable:          p.discountable
		metadata:              p.metadata
		tag_ids:               p.tag_ids
		tag_ids_bin:           tag_ids_bin
		sales_channel_ids:     p.sales_channel_ids
		sales_channel_ids_bin: sales_channel_ids_bin
		category_ids:          p.category_ids
		category_ids_bin:      category_ids_bin
		collection_ids:        p.collection_ids
		collection_ids_bin:    collection_id_bin
	}

	if options := p.options {
		mut h := []ProductOptionRequestHygienised{len: options.len}
		for i := 0; i < options.len; i++ {
			h[i] = hygienise_product_option_request(options[i])!
		}
		ph.options = h
	}

	if translations := p.translations {
		mut h := []ProductTranslationRequestHygienised{len: translations.len}
		for i := 0; i < translations.len; i++ {
			h[i] = hygienise_product_translation_request(translations[i])!
		}
		ph.translations = h
	}

	if images := p.images {
		mut h := []ImageRequestHygienised{}
		for i := 0; i < images.len; i++ {
			h[i] = hygienise_image_request(images[i])!
		}
		ph.images = h
	}

	return ph
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
