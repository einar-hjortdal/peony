# Info

## Design

### Translations

Translation tables define presentation content exposed by the `/store/` API.

Presentation content (eg. title, description...) in each table is in the store's default locale. Translation tables work as overrides. Whenever a client requests a specific `locale_id`, if any override exists it will be utilized.

Example: 
1. Client requests products from the `/store/` endpoints, the request contains a locale_id parameter.
2. Peony always retrieves product rows with their default title, subtitle and description from the product table.
3. Peony retrieves the translation rows from the product_translations table.
4. Peony checks if a translation for the requested locale_id was retrieved, if was: its values override the default values.
5. Peony returns the product objects with the overridden values.

Note: A translation should never be set as an empty string. If a `_translations` table contains only one translation column, this column should not be nullable. If a translations table contains many translation columns, these columns should be nullable. If all of them are null, the row should be deleted.

### Classification

#### Products

##### category

A `category` allows to categorize `product`. A `product` can have many `category`. The 
`category_rank` field allows sorting.

A `category` may have 0 or 1 parent `category`. This allows to build hierarchical structures.

##### product_collection (WIP)

A `product_collection` is a group of `product`. A `product` can be part of many `product_collection`. 
Unlike `category`, a `product_collection` is not hierarchical. These are useful to group together 
products for the purpose of a marketing campaign.

##### product_type (WIP)

A `product_type` is a group of `product`. A `product` can be of one `product_type`. For example: `physical`,
`digital`, `service`. 

A `product_type` is also used to control the tax rates for all `product` that share it. For example: 
a shop may need to apply different taxes to all `product` of `product_type` with value `service`.

#### Posts

##### type

A post may be of type `post` or `page`.

##### topic

A post may have 0 or more `topic`. This is not a hierarchical classification, it is meant to group related 
posts together, analogous to product collections.

### product

#### product_option, product_option_value and product_variant

Each `product` must have at least one `product_variant`.

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

Whenever a `product_variant` is requested, the request may contain a `region_id` parameter.

If it does: the returned `money_amount` will be the ones related to the `region` of the matching `region_id`, 
and the prices in the `prices` object will be in the `currency` of this `region`.

If the request does not contain a `region_id` parameter, the returned `money_amount` will be related 
to the default `region`, and the prices of the `prices` object  will be in the default `currency`.

### Prices

Each `product_variant` must have at least 1 `money_amount` per `region`. This is the *base price*.

A `product_variant` may have one more price if the optional `is_original` flag is set. The `money_amount` 
marked with `is_original` is the *original price*. The original price is used from frontends to display 
a price before any adjustment or sale.

One or more additional prices are set using `price_list`.

Note: whenever a new `region` is created, all existing `product_variant` will have no base price for 
the new `region`.

Note: `is_original` is never `true` when the `money_amount` is part of a `price_list`.

Note: sorting products by price should be handled by the frontend (eg. [Redict Sorted Sets](https://redict.io/docs/data-types/sorted-sets/)).

### Taxes (WIP)

Some entities may have a `tax_rate`. Each `region` must have at least one `tax_rate`. The default `region` 
defines the default `tax_rate`(s). If any other entity has defined `tax_rate` these will be included 
in the calculation according to the `tax_rate.type`.

Each `region` also determines whether prices are tax-inclusive or tax-exclusive. Note that, because
there cannot exist more than one `region` with the same `country`, in order to show prices tax-exclusive
to a select audience, a `price-list` must be used: its `includes_tax` property will override the `includes_tax`
property set on `region`.

### price_list (WIP)

B2B customers may need custom prices: a `price_list` allows to assign prices and taxes to `product_variant` 
that modify or override their regional price and tax settings.

`price_list` are used to set volume pricing: prices only valid when a specific number of variants is 
placed in a cart.

### cart_rule (WIP)

`cart_rule` are used to create behaviors for carts, such behaviors are discounts and gift products. 
`cart_rule` may be automatically applied or applied using a discount code.

A discount may be a percentage, a fixed amount or applied on shipping. A gift product is a product, 
with price of 0, added to the cart when conditions are met: when a total threshold is passed, or when 
a certain number of products or variants are added to the cart (buy X get Y).

Other `cart_rule` conditions: they may only be applied on some products, variants, collections, require 
minimum amount of one item in the cart, have a per-customer usage limit, have a time-window, or reserved 
only to some channel and/or customers.

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

Note: filtering products by availability should be handled by the frontend (eg. [Redict Sorted Sets](https://redict.io/docs/data-types/sorted-sets/)).

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

## Schema

