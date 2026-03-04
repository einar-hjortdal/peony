module peony

// TODO cache for store endpoints:
// store items in redis after retrieving from db
// intercept conduit calls to get cached items instead if they exist, otherwise cache them
// when data is modified, invalidate cache

// TODO cache for admin endpoints:
// cache locales
// first attempt to read cached locales from redict
// if redict does not have cached locales, read all locales from database, serialize a blob and set it in redict
// this allows:
// when requesting locales, all locales can be sent without db queries
// when updating translations: accept map with locale_code keys, match to id at validation.
// accepting a map makes more sense than accepting an array, as translations have no order.
