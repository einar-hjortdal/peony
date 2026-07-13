module common

pub interface Translation {
	locale_id() ID
}

pub interface Translatable {
	translations() ?[]Translation
}
