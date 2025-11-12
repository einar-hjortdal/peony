# Info

## Design

### Translations

Translation tables define the text values exposed by the `/store/` API. Each translation column in these 
tables may be set to null when a locale hasn’t provided its own version of that string. To assemble 
the final display text, the peony app must:
1. Load the default translations by looking up `store.default_locale_id`
2. When a client requests a specific `locale_id`, fetch those rows and override the default translations 
  with the non-null fields of the requested translation.

When creating new records, peony must enforce that all required presentation strings in the default 
locale are non-null.

Although updating `store.default_locale_id` is rare, it carries three important implications:
- Existing translations for the newly chosen default `locale_id` are utilized immediately.
- All existing translations for the previous default `locale_id` are preserved.
- Any null values in the new default locale will surface as missing until backfilled.

Note: A translation should never be set as an empty string. If a `_translations` table contains only 
one translation column, this column should not be nullable. To remove a translation, delete a row. If 
a translations table contains many translation columns, these columns should be nullable. If all of 
them are null, the row should be deleted.

### product

#### product_option, product_option_value and product_variant

Each `product` must have at least one `product_variant`.

#### product_category

A `product_category` allows to categorize `product`. A `product` can have many `product_category`. A 
`product_category` can describe a hierarchical structure thanks to the `parent_category_id` field. The 
`category_rank` field allows for sorting.

#### product_collection (WIP)

A `product_collection` is a group of `product`. A `product` can be part of many `product_collection`. 
Unlike `product_category`, a `product_collection` is not hierarchical. These are useful to group together 
products for the purpose of a marketing campaign.

#### product_type (WIP)

A `product_type` is a group of `product`. A `product` can be of one `product_type`. For example: `physical`,
`digital`, `service`. 

A `product_type` is also used to control the tax rates for all `product` that share it. For example: 
a shop may need to apply different taxes to all `product` of `product_type` with value `service`.

### metadata

Some resources contain a `metadata` field. The admin frontend can give any data to peony using this 
field, and the data will be stored in the database. This field will be available on `/store/` endpoints, 
allowing customization when presenting data.

Note: currently this field is stored as a string in the database, without any validation or processing. 
Eventually, (when Firebird will support it) this field will be handled as JSON. For a smooth transition 
when such change happens it is best to only assign valid JSON value (an object, array, string, number, 
boolean or null).

### Countries, regions, currencies and prices

peony uses a multi‑currency architecture: typically, there is one base price for each supported currency, 
and this base price can be overridden by a `price_list` according to its conditions.

A `region` is a group of one or more `country`.

One `country` can only be in one `region`. One `region` can only have one `currency`. Therefore one 
`country` can only have one `currency`. 

By default, a `store` has one `region`, this region determines the default `currency`. 

There can be many `region` with the same `currency`.

A `product_variant` may have a `money_amount` that is related to a `region`.

When a `product_variant` is requested, the request may contain a `region_id` parameter.

If it does: `money_amount` related to the `region` of the matching `region_id` are considered in the
price calculation, and the price will be in the `currency` of this region.

If the request does not contain a `region_id` parameter, `money_amount` of the default `region` are 
considered when calculating the price, and the price will be in the `currency` of this region.

### Taxes (WIP)

Some entities may have a `tax_rate`. Each `region` must have at least one `tax_rate`. The default `region` 
defines the default `tax_rate`(s). If any other entity has defined `tax_rate` these will be included 
in the calculation according to the `tax_rate.type`.

Each `region` also determines whether prices are tax-inclusive or tax-exclusive. Note that, because
there cannot exist more than one `region` with the same `country`, in order to show prices tax-exclusive
to a select audience, a `price-list` must be used: its `includes_tax` property will override the `includes_tax`
property set on `region`.

### `product`, `product_variant`, `inventory_item` and `inventory_level`

A `product` represents a good or service offered by the `store`

A `product_variant` represents a version of a `product` that has one or more `option`. A `product_variant` 
is available to the `/store/` endpoints.

A `inventory_item` represents a the physical attributes of a `product_variant`. These attributes are 
used for inventory tracking and fulfillment. The `manage_inventory` field specifies whether the inventory 
of this item is tracked. A `inventory_item` is not available to the `/store/` endpoints.

A `inventory_level` is the amount of `inventory_item` in one `stock_location`.
- `stocked_quantity` is the amount of `inventory_item` located at the `stock_location`.
- `reserved_quantity` is the amount of `inventory_item` located at the `stock_location` that is not 
  available to be ordered. This must be subtracted from `stocked_quantity` to determine the amount of 
  `inventory_item` that can be ordered.

### Inventory management

By default, peony manages the inventory of each `product_variant`.
- A `product_variant` is always considered *purchasable* if peony does not manage its inventory.
- A `product_variant` is considered *purchasable* if `stocked_quantity` is more than its `reserved_quantity`.

A `reservation_item` is one `inventory_item` that is part of a `reserved_quantity`. This is used when 
  an order has been created but has not been fulfilled yet.

Each `product_variant` has exactly one `inventory_item`.

### Posts (WIP)

A `post` is typically a blog entry, an article, etc.

A `page` is a `post` that is independent. Typically a `page` is an about page, a landing page, a terms 
of service page, etc.

Each `post` may have one or more `post_tag` that categorizes it.

## Schema

