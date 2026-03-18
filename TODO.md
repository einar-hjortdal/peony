# TODO

## Basics

- [x] Write a database-friendly uuid library <!-- https://github.com/einar-hjortdal/lexical_uuid -->
- [x] Write a string to slug conversion library <!-- https://github.com/einar-hjortdal/slugify -->
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
- [ ] Product bundles
- [ ] Blog
- [ ] Post
- [ ] Page
- [ ] Topics
- [ ] Customer
- [ ] Cart
- [ ] Orders
- [ ] Payments
- [ ] User permissions
- [ ] API keys
- [ ] Taxes

### Low-priority

- [ ] Sub-divisions of country
- [ ] Comment

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

- [ ] Separate sales from price_list.
- [ ] Limit returned list items to 250 in all requests.
- [ ] Return created resources on creation.
- [ ] Return updated resources on update.
- [x] Add product variant endpoints.
- [ ] Add product option endpoints.
- [ ] Add product option value endpoints.
- [ ] Add product images endpoints.
- [x] Move cors handling to starter.
- [x] Return and accept translations as a map rather than an array.
- [x] Return and accept variant prices as a map rather than an array.

## Internals

- [x] Add tests
- [ ] Add debug level logs where opportune
- [x] Separate response structs from internal structs
- [ ] Separate model parameter objects from Request objects
  - [x] Make Request objects public
  - [x] Remove `parse_` functions from methods
- [x] Rename query string structs to include `Query` in their name
- [x] Return data as the root property of json payload
- [x] Return count, offset and fetch values with lists
- [ ] Soft-delete only where needed
- [x] Remove all unnecessary `product_` prefixes from database, structs and function names.
- [ ] Attach function name to each error. Nested hygienise functions may return same error messages right now, making it difficult to identify which struct is malformed.
- [ ] Change `metadata` fields from `BLOB SUB_TYPE TEXT` to `JSON` [(once Firebird supports it)](https://github.com/FirebirdSQL/firebird/issues/5431).

## Upstream

- [ ] [Veb graceful shutdown](https://github.com/vlang/v/issues/25655)
- [ ] [Firebird connection pooling with connection management and transaction attempts](https://github.com/einar-hjortdal/firebird/tree/feat_client)

## Considerations

- Create higher order to provide tx by wraping blocks that need tx.
  - Problem: impossible to modify variables outside of closures without using unsafe blocks.
- Use an ID struct with string and []u8. I decided early on to not do this but I forgot why.
- Refactor, abstract, reduce boilerplating, separate concerns, but only after minimal viable product works.

## Documentation

- [ ] Endpoints
- [ ] Parameters
- [ ] Query strings
