# TODO

## Basics

- [x] Write a database-friendly uuid library <!-- https://github.com/einar-hjortdal/lexical_uuid -->
- [x] Write a FirebirdSQL connector <!-- https://github.com/einar-hjortdal/firebird -->
- [x] Write a Redict library <!-- https://github.com/einar-hjortdal/redict -->
- [x] Write a BLOB storage service <!-- https://github.com/einar-hjortdal/blobly -->
- [x] Write a sessions management library <!-- https://github.com/einar-hjortdal/sessions -->

## Features

### Implemented

- [x] Inventory items
- [x] Metadata
- [x] Multi-channel
- [x] Multi-currency
- [x] Multi-language
- [x] Multi-region
- [x] Prices
- [x] Product categories
- [x] Product variants
- [x] Products
- [x] Uploads

### Currently being implemented

- [ ] Taxes
- [ ] SEO

### Soon to be implemented

- [ ] Multi-warehouse
- [ ] Cache

### To be implement

- [ ] Reservations
- [ ] Price rules
- [ ] Price lists
- [ ] Unit pricing
- [ ] Product tags
- [ ] Product types
- [ ] Product collections
- [ ] Product bundles
- [ ] Posts
- [ ] Post tags
- [ ] Customer
- [ ] Cart
- [ ] Orders
- [ ] Payments
- [ ] User permissions
- [ ] Variant images
- [ ] API keys

### Low-priority

- [ ] Sub-divisions of country

### Not planned

- Multi-currency regions
- Marketplace

## Interfaces

- [x] BlobProvider
- [ ] EmailProvider
- [ ] PaymentProvider
- [ ] TaxProvider
- [ ] FulfillmentProvider

## Changes

- [ ] get_product_variants_availability should handle sales_channel_ids_bin as optional. I think
- [ ] Change `metadata` fields from `BLOB SUB_TYPE TEXT` to `JSON` [(once Firebird supports it)](https://github.com/FirebirdSQL/firebird/issues/5431)
- [ ] Allow variants creation on product creation.
  - [ ] Allow InventoryItem properties on variant creation.
  - [ ] Enforce at least one price per variant per region.
  - [ ] Request validation.
- [ ] Separate sales from price_list

## Internals

- [x] Keep response structs separate from internal structs
- [x] Return data as the root property of json payload
- [x] Return count, offset and fetch values with lists
- [ ] Soft-delete where needed, and only where needed
- [ ] Reduce boilerplating
- [ ] Engineer a way to allow sorting products by price
- [ ] Engineer a way to allow filtering by availability
- [ ] Remove `parse_` functions from methods
- [ ] Merge hygienise functions with extraction functions for object_query_string objects
- [ ] Request objects should have no mutable fields
- [ ] Graceful shutdown, or [wait for upstream patch](https://github.com/vlang/v/issues/25655)

## Upstream

- [ ] Firebird connection pooling
- [ ] Firebird connection management
- [ ] Firebird transaction attempts

## Considerations

- Creating higher order functions to wrap conduit functions to provide tx.
- Query builder to keep select columns together with their referenced table aliases.
- Use an ID struct with string and []u8. I decided early on to not do this but I forgot why.

## Documentation

- [ ] Endpoints
- [ ] Parameters
- [ ] Query strings
