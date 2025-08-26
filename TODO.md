# TODO

## Basics

- [x] Read and validate settings~~ <!-- Always panic on startup, never during runtime -->
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

- [x] Products
- [x] Variants
- [x] Prices
- [x] Multi-language
- [x] Multi-currency
- [x] Uploads
- [x] Metadata
- [x] Product categories

### Currently being implemented

- [ ] Inventory management

### Soon to be implemented

- [ ] Multi-region
- [ ] Taxes

### To be implement

- [ ] Multi-channel
- [ ] Multi-warehouse
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
- [ ] Pages
- [ ] Tags
- [ ] Customer
- [ ] Cart
- [ ] Orders
- [ ] Payments
- [ ] User permissions
- [ ] Variant images
- [ ] API keys
- [ ] Cache

### Modules:

- [x] Make peony a module
- [x] BlobProvider interface
- [ ] EmailProvider interface
- [ ] PaymentProvider interface
- [ ] TaxProvider interface
- [ ] FulfillmentProvider interface

## Changes

- [ ] Better error handling
- [ ] Change `metadata` fields from `BLOB SUB_TYPE TEXT` to `JSON` [(once Firebird supports it)](https://github.com/FirebirdSQL/firebird/issues/5431)

## Internals

- [x] Keep response structs separate from internal structs
- [x] Return data as the root property of json payload
- [x] Return count, offset and fetch values with lists
- [ ] Return time.Time.format_rfc3339() instead of time.Time
- [ ] Transaction attempts
- [ ] Soft-delete where needed, and only where needed

## Considerations

- Currently select queries must respect the order of the variables in `parse_` functions, instead consider 
  rewriting `parse_` functions to check and match column names. This introduces string normalization 
  and comparison but prevents order-related errors when select queries are modified. Otherwise parse 
  locally so the order is obvious, or use function parameters instead of an array of values.
- Consider setting a default region id on store.
- Consider modularizing price calculation.
- Consider creating higher order functions to wrap conduit functions to provide tx.
- Consider independent query for count.

## Documentation

- [ ] Endpoints
- [ ] Parameters
- [ ] Query strings
