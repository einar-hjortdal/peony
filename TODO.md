# TODO

## Basics

- [x] Read and validate settings <!-- Always panic on startup, never during runtime -->
- [x] Write a database-friendly uuid library <!-- https://github.com/einar-hjortdal/lexical_uuid -->
- [x] Write a FirebirdSQL connector <!-- https://github.com/einar-hjortdal/redict -->
- [x] Write a Redict library <!-- https://github.com/einar-hjortdal/redict -->
- [x] Write a BLOB storage service <!-- https://github.com/einar-hjortdal/blobly -->
- [x] Write a sessions management library <!-- https://github.com/einar-hjortdal/sessions -->
- [x] Seed new database with a schema, constants and defaults
- [x] Always return json
- [x] Error handling

## Features

### Implemented

- [x] Inventory items
- [x] Metadata
- [x] Multi-channel
- [x] Multi-currency
- [x] Multi-language
- [x] Prices
- [x] Product categories
- [x] Product variants
- [x] Products
- [x] Uploads

### Currently being implemented


### Soon to be implemented

- [ ] Multi-region
- [ ] Multi-warehouse
- [ ] Taxes
- [ ] Cache

### To be implement

- [ ] Reservations
- [ ] Price rules
- [ ] Price lists
- [ ] Unit pricing
- [ ] Discounts
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

### Modules:

- [x] Make peony a module
- [x] BlobProvider interface
- [ ] EmailProvider interface
- [ ] PaymentProvider interface
- [ ] TaxProvider interface
- [ ] FulfillmentProvider interface

## Changes

- [ ] handle default-locale translations as fields of their entity (join + coalesce queries)
- [ ] get_product_variants_availability should handle sales_channel_ids_bin as optional. I think
- [ ] Change `metadata` fields from `BLOB SUB_TYPE TEXT` to `JSON` [(once Firebird supports it)](https://github.com/FirebirdSQL/firebird/issues/5431)

## Internals

- [x] Keep response structs separate from internal structs
- [x] Return data as the root property of json payload
- [x] Return count, offset and fetch values with lists
- [ ] Firebird connection management
- [ ] Transaction attempts
- [ ] Soft-delete where needed, and only where needed
- [ ] Reduce boilerplating
- [ ] Engineer a way to allow sorting products by price
- [ ] Engineer a way to allow filtering by availability
- [ ] Remove `parse_` functions from methods
- [ ] Merge hygienise functions with extraction functions for object_query_string objects
- [ ] Graceful shutdown

## Considerations

- Consider setting a default region id on store.
- Consider creating higher order functions to wrap conduit functions to provide tx.
- Query builder to keep select columns together with their referenced table aliases.
- Need an alternative strategy on merge statements when source rows > 250

## Documentation

- [ ] Endpoints
- [ ] Parameters
- [ ] Query strings
