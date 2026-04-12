# Info

## Design

*WIP*
### Tasks performed by the worker:

- sending emails
- order post-processing (invoices, fulfillment...)
- scheduled tasks (database cleanup...)
- search engine indexing 
  TODO decide: leave it up to API consumers or integrate with worker? integration is more consistent with the objective of the project. If integration is chosen: store endpoints should query the data from the search engine instead of the database, invalidation and re-indexing can be done as soon as data changes. List database queries can be simplified. No adapter interface.

*WIP*
### Data layers abstractions

We are not looking for flexibility: tight coupling with the database is not an issue as we are always going to be using FirebirdSQL. We do not mock the database because we write raw queries and mistakes must be caught by the database. This means that we are not going to be using a repository pattern.

We want:

- a low level layer that contains the insert/update/delete SQL statements.
- a higher level layer that orchestrates the lower level operations.

TODO: should route handlers call either, or should it only be allowed to call conduit functions? I am used to MVC, which makes me think it would be best if routes should only invoke conduit functions.

### Translations

Translation tables define presentation content exposed by the `/store/` API.

Presentation content (eg. title, description...) in each table is in the store's default locale. Translation tables work as overrides. Whenever a client requests a specific `locale_id`, if any override exists it will be utilized.

Example: 
1. Client requests products from the `/store/` endpoints, the request contains a locale_id parameter.
2. Peony always retrieves product rows with their default title, subtitle and description from the product table.
3. Peony retrieves the translation rows from the product_translations table.
4. Peony checks if a translation for the requested locale_id was retrieved, if was: its values override the default values.
5. Peony returns the product objects with the overridden values.

This is the typical approach, but it is not perfect: changing default locale requires manual intervention that may be tedious. However, how often is the default locale changed?

### Classification

#### Products

##### category

A `category` allows to categorize `product`. A `product` can have many `category`. 

A `category` may have 0 or 1 parent `category`. This allows to build hierarchical structures.

##### product_type

A `product_type` is a categorization of `product`. A `product` can be of one `product_type`. For example: `physical`, `digital`, `service`. 

A `product_type` is used to control the tax rates for all `product` that share it. For example: a shop may need to apply different taxes to all `product` of `product_type` with value `service`.

##### product_tag

A `product_tag` is a categorization of `product` used for filtering and search. A product may have 0 or more tags.

#### Content Management System

##### Blog

A `blog` is a collection of posts. A store may have 0 or more blogs.

##### topic

A `topic` groups posts that have content related to the same subject. A post may have 0 or more `topic`.

### product

#### product_option, product_option_value and variant

Each `product` must have at least one `variant`. Each product variant must have at least one `product_option`. Each `product_option` must have at least one `product_option_value`.

### metadata

Some resources contain a `metadata` field. The admin frontend can give any data to peony using this 
field, and the data will be stored in the database. This field will be available on `/store/` endpoints, 
allowing customization when presenting data.

Note: currently this field is stored as a string in the database, without any validation or processing. 
Eventually, (when Firebird will support it) this field will be handled as JSON. For a smooth transition 
when such change happens it is best to only assign valid JSON value (an object, array, string, number, 
boolean or null).

### Countries, regions, currencies and prices

peony uses a multi‑currency architecture: typically, there is one base price for each supported currency, and this base price can be overridden by a `price_list` according to its conditions.

A `region` is a group of one or more `country`.

One `country` can only be in one `region`. One `region` can only have one `currency`. Therefore one `country` can only have one `currency`. 

By default, a `store` has one `region`, this region determines the default `currency`. 

There can be many `region` with the same `currency`.

A `variant` may have a `money_amount` that is related to a `region`.

Whenever a `variant` is requested, the request may contain a `region_id` parameter.

If it does: the returned `money_amount` will be the ones related to the `region` of the matching `region_id`, and the prices in the `prices` object will be in the `currency` of this `region`.

If the request does not contain a `region_id` parameter, the returned `money_amount` will be related to the default `region`, and the prices of the `prices` object  will be in the default `currency`.

WIP: a sub-division of a country is a `Zone`. These are used to handle taxes for locations that require special handling. How to define a zone? zip codes do not exist in all countries. Municipalities is too broad, for example: in Italy, Livigno is in the municipality of Sondrio, Livigno is more expensive to ship to, but the rest of Sondrio isn't. Should we concern ourselves with this or should we let the provider handle it?

### Prices

Each `variant` must have at least 1 `money_amount` per `region`. This is the *base price*.

A `variant` may have one more price if the optional `is_original` flag is set. The `money_amount` marked with `is_original` is the *original price*. The original price is used from frontends to display a price before any adjustment or sale.

One or more additional prices are set using `price_list`.

Note: whenever a new `region` is created, all existing `variant` will have no base price for the new `region`.

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

A `price_list` allows to assign prices and taxes to `variant` that modify or override their 
regional price and tax settings.

`price_list` are used to set volume pricing: prices only valid when a specific number of variants is 
placed in a cart. TODO may also be a cart_rule

`price_list` are used to configure sales-channel pricing: set prices that override the base prices on 
specific sales-channels.

A typical use of `price_list` is to create *catalogs* for B2B customers.

### cart_rule (WIP)

`cart_rule` are used to create behaviors for carts, such behaviors are discounts and gift products. 
`cart_rule` may be automatically applied or applied using a discount code.

A discount may be a percentage, a fixed amount or applied on shipping. A gift product is a product, 
with price of 0, added to the cart when conditions are met: when a total threshold is passed, or when 
a certain number of products or variants are added to the cart (buy X get Y).

Other `cart_rule` conditions: they may only be applied on some products, variants, require minimum amount of one item in the cart, have a per-customer usage limit, have a time-window, or reserved only to some channel and/or customers.

### `product`, `variant`, `inventory_item` and `inventory_level`

A `product` represents a good or service offered by the `store`

A `variant` represents a version of a `product` that has one or more `option`. A `variant` 
is available to the `/store/` endpoints.

A `inventory_item` represents a the physical attributes of a `variant`. These attributes are 
used for inventory tracking and fulfillment. The `manage_inventory` field specifies whether the inventory 
of this item is tracked. A `inventory_item` is not available to the `/store/` endpoints.

A `inventory_level` is the amount of `inventory_item` in one `stock_location`.
- `stocked_quantity` is the amount of `inventory_item` located at the `stock_location`.
- `reserved_quantity` is the amount of `inventory_item` located at the `stock_location` that is not 
  available to be ordered. This must be subtracted from `stocked_quantity` to determine the amount of 
  `inventory_item` that can be ordered.

Note: filtering products by availability should be handled by the frontend (eg. [Redict Sorted Sets](https://redict.io/docs/data-types/sorted-sets/)).

### Inventory management

By default, peony manages the inventory of each `variant`.
- A `variant` is always considered *purchasable* if peony does not manage its inventory.
- A `variant` is considered *purchasable* if `stocked_quantity` is more than its `reserved_quantity`.

A `reservation_item` is one `inventory_item` that is part of a `reserved_quantity`. This is used when 
  an order has been created but has not been fulfilled yet.

Each `variant` has exactly one `inventory_item`.

### Content Management System (WIP)

##### Post

A `post` is content that belongs to one `blog`.

#### Page

A `page` is long-term static content that rarely changes.

## Schema

