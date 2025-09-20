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

One `country` can only be in one `region`. One `region` can only have one `currency`. Therefore one 
`country` can only have one `currency`. By default, a `store` has no `region`.

A `product_variant` can be given many `money_amount`. If a `region` is created, a `product_variant` 
can have a `money_amount` that is related to a `region`. In this case, if the customer is from this 
`region`, the regional `money_amount` is prioritized: the customer will get the regional `money_amount` 
in its currency.

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

## Schema

