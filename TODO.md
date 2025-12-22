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
- [x] SEO
- [x] Uploads

### Currently being implemented

- [ ] Multi-warehouse

### Soon to be implemented

- [ ] Taxes
- [ ] Cache

### To be implement

- [ ] Reservations
- [ ] Cart rules
- [ ] Price lists
- [ ] Unit pricing
- [ ] Product tags
- [ ] Product types
- [ ] Product collections
- [ ] Product bundles
- [ ] Posts
- [ ] Topics
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
- [x] Enforce at least one price per variant per region on variant creation and updates
  - [x] Request validation
  - [x] Enforce on variant created during product creation
- [ ] Separate sales from price_list
- [ ] Remove all `product_` prefixes from database, structs and function names
- [x] Get configuration from `Config` struct instead of env

## Internals

- [ ] Add tests
- [ ] Add debug level logs everywhere
- [x] Separate response structs from internal structs
- [ ] Separate model parameter objects from Request objects
  - [ ] Make Request objects public
  - [x] Remove `parse_` functions from methods
- [ ] Rename query string structs to include `Query` in their name
- [x] Return data as the root property of json payload
- [x] Return count, offset and fetch values with lists
- [ ] Soft-delete only where needed
- [ ] Reduce boilerplating
- [ ] Engineer a way to allow sorting products by price
- [ ] Engineer a way to allow filtering by availability
- [ ] Do not fetch default seo translations with a join, just format response with locale_id

## Upstream

- [ ] [Veb graceful shutdown](https://github.com/vlang/v/issues/25655)
- [ ] Firebird connection pooling
- [ ] Firebird connection management
- [ ] Firebird transaction attempts

## Considerations

- Creating higher order functions to wrap conduit functions to provide tx.
- Query builder to keep select columns together with their referenced table aliases.
- Use an ID struct with string and []u8. I decided early on to not do this but I forgot why.
- Put Request and Response structs in independent package

## Documentation

- [ ] Endpoints
- [ ] Parameters
- [ ] Query strings
