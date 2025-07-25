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
- [x] Iron out error handling

## Features

### 3.3.0

- [x] Products
- [x] Variants
- [x] Prices
- [x] Multilanguage
- [x] Multicurrency
- [x] Uploads

### Next

- [ ] Inventory management
- [ ] Multiregion
- [ ] Multichannel
- [ ] Multiwarehouse
- [ ] Multistore
- [ ] Taxes
- [ ] Price rules
- [ ] Price lists
- [ ] Unit pricing
- [ ] Discounts
- [ ] Product tags
- [ ] Product types
- [ ] Product collections
- [ ] Product categories
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
- [ ] User-defined data

### Modules:

- [x] Make peony a module
- [x] BlobProvider interface
- [ ] EmailProvider interface
- [ ] PaymentProvider interface
- [ ] FulfillmentProvider interface

## Changes


## Internals

- [x] Keep response structs separate from internal structs
- [ ] Return data as the root property of json payload
- [x] Return count, offset and fetch values with lists
- [ ] Return time.Time.format_rfc3339() instead of time.Time
- [ ] Redict cache
- [ ] Transaction attempts
- [ ] Soft-delete

## Considerations

- Currently select queries must respect the order of the variables in `parse_` functions, instead consider 
  rewriting `parse_` functions to check and match column names. This introduces string normalization 
  and comparison but prevents order-related errors when select queries are modified. Otherwise parse 
  locally so the order is obvious, or use function parameters instead of an array of values.

## Documentation

- [ ] Endpoints
- [ ] Parameters
- [ ] Query strings
