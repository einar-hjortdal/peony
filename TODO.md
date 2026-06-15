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

- [x] API keys
- [x] Cache
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

- [ ] Product types
- [ ] Unit pricing

### To be implement

- [ ] Reservations
- [ ] Cart rules
- [ ] Price lists
- [ ] Product tags
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
- [ ] Taxes

### Low-priority

- [ ] OAuth
- [ ] Sub-divisions of country
- [ ] Comment

### Not planned

- Multi-currency regions
- Marketplace

## Provider interfaces

- [x] BlobProvider
- [ ] EmailProvider
- [ ] PaymentProvider
- [ ] FulfillmentProvider

### Provider implementations

#### Blob

- [x] Blobly

#### Payment

- [ ] Manual

#### Fulfillment

- [ ] Manual

## Changes

- [ ] Separate sales from price_list.
- [ ] Limit returned list items to 250 in all requests.
- [ ] Return created resources on creation.
- [ ] Return updated resources on update.
- [x] Add variant endpoints.
- [ ] Add product option endpoints.
- [ ] Add product option value endpoints.
- [ ] Add product image endpoints.
- [x] Move cors handling to starter.
- [x] Return and accept translations as a map rather than an array.
- [x] Return and accept variant prices as a map rather than an array.
- [ ] Database setup and migrations should be separate from startup.

## Internals

- [x] Add tests
- [ ] Add log messages (error, warn, info, debug)
- [x] Separate response structs from internal structs
- [x] Separate model parameter objects from Request objects
  - [x] Make Request objects public
  - [x] Remove `parse_` functions from methods
- [x] Rename query string structs to include `Query` in their name
- [x] Return data as the root property of json payload
- [x] Return count, offset and fetch values with lists
- [x] Soft-delete only where needed
- [x] Remove all unnecessary `product_` prefixes from database, structs and function names
- [ ] Attach function name to each error
- [ ] Transaction management
- [ ] Worker mode
- [x] Routes should not call models, only conduit.
- [x] Refactor record fields to use option types instead of firebird.NullT

## Upstream

- [Veb graceful shutdown](https://github.com/vlang/v/issues/25655)
- [Firebird currently does not support JSON data type](https://github.com/FirebirdSQL/firebird/issues/5431). Change `metadata` fields from `BLOB SUB_TYPE TEXT` to `JSON` when possible.

## Considerations



## Documentation

- [ ] Endpoints
- [ ] Parameters
- [ ] Query strings

