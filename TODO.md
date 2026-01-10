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
- [ ] Taxes

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

- [ ] Change `metadata` fields from `BLOB SUB_TYPE TEXT` to `JSON` [(once Firebird supports it)](https://github.com/FirebirdSQL/firebird/issues/5431).
- [ ] Separate sales from price_list.
- [ ] Remove all unnecessary `product_` prefixes from database, structs and function names.
- [ ] Limit returned list items in all requests.
- [ ] Remove store_currencies table, instead get used currencies by selecting region. Remove currency_codes from StoreUpdateRequest.

## Internals

- [ ] Add tests
- [ ] Add debug level logs where opportune
- [x] Separate response structs from internal structs
- [ ] Separate model parameter objects from Request objects
  - [ ] Make Request objects public
  - [x] Remove `parse_` functions from methods
- [ ] Rename query string structs to include `Query` in their name
- [x] Return data as the root property of json payload
- [x] Return count, offset and fetch values with lists
- [ ] Soft-delete only where needed
- [ ] Reduce boilerplating
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
- While price‑sorting and availability‑filtering belong in the frontend, a naive fallback using complex Firebird queries can still work acceptably for stores with very few variants.

## Documentation

- [ ] Endpoints
- [ ] Parameters
- [ ] Query strings
