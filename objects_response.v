module main

import time
import einar_hjortdal.firebird

struct PeonySuccess {
	success bool
}

fn new_peony_success() PeonySuccess {
	return PeonySuccess{
		success: true
	}
}

struct PeonyError {
	Error
	message string
	details string
}

fn new_peony_error(message string, details string) PeonyError {
	return PeonyError{
		message: message
		details: details
	}
}

fn login_error() (string, string) {
	return 'Invalid email or password', 'No further details'
}

// count is the number of items in the database
// offset is the number of items skipped
// fetch is the number of items requested
struct ListResponse[T] {
	items  []T
	count  i32
	offset i32
	fetch  i32
}

struct UserResponse {
	id         string
	handle     string
	email      string
	role       string
	created_at firebird.DateTime @[json: 'createdAt']
	updated_at firebird.DateTime @[json: 'updatedAt']
	deleted_at firebird.DateTime @[json: 'deletedAt'; omitempty]
	first_name string            @[json: 'firstName'; omitempty]
	last_name  string            @[json: 'lastName'; omitempty]
}

fn format_user_response(u User) UserResponse {
	return UserResponse{
		id:         u.id
		handle:     u.handle
		email:      u.email
		role:       u.role
		created_at: u.created_at
		updated_at: u.updated_at
		deleted_at: u.deleted_at
		first_name: u.first_name
		last_name:  u.last_name
	}
}

struct ProductResponse {
	id            string
	created_at    time.Time @[json: 'createdAt']
	updated_at    time.Time @[json: 'updatedAt']
	deleted_at    time.Time @[json: 'deletedAt'; omitempty]
	handle        string
	is_giftcard   bool @[json: 'isGiftcard']
	status        string
	thumbnail     string @[omitempty]
	collection_id string @[json: 'collectionId'; omitempty]
	type_id       string @[json: 'typeId'; omitempty]
	discountable  bool
	images        []Image               @[omitempty]
	options       []ProductOption       @[omitempty]
	variants      []Variant             @[omitempty]
	translations  []ProductTranslations @[omitempty]
	// tags         []Tag                 @[omitempty]
}

fn format_product_response(p Product) ProductResponse {
	return ProductResponse{
		id:            p.id
		created_at:    p.created_at.Time
		updated_at:    p.updated_at.Time
		deleted_at:    p.deleted_at.Time
		handle:        p.handle
		is_giftcard:   p.is_giftcard
		status:        p.status
		thumbnail:     p.thumbnail
		collection_id: p.collection_id
		type_id:       p.type_id
		discountable:  p.discountable
		images:        p.images
		options:       p.options
		variants:      p.variants
		translations:  p.translations
		// tags:          p.tags
	}
}
