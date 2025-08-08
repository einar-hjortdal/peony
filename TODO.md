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

### 3.3.0

- [x] Products
- [x] Variants
- [x] Prices
- [x] Multilanguage
- [x] Multicurrency
- [x] Uploads

### Currently being implemented

- [ ] Multiregion
- [ ] Taxes

### Next

- [ ] Multichannel
- [ ] Multiwarehouse
- [ ] Multistore
- [ ] Inventory management
- [ ] Price rules
- [ ] Price lists
- [ ] Unit pricing
- [ ] Discounts
- [ ] Product tags
- [ ] Product types
- [ ] Product collections
- [ ] Product categories
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
- [ ] User-defined data
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

## Internals

- [x] Keep response structs separate from internal structs
- [x] Return data as the root property of json payload
- [x] Return count, offset and fetch values with lists
- [ ] Return time.Time.format_rfc3339() instead of time.Time
- [ ] Transaction attempts
- [ ] Soft-delete

## Considerations

- Currently select queries must respect the order of the variables in `parse_` functions, instead consider 
  rewriting `parse_` functions to check and match column names. This introduces string normalization 
  and comparison but prevents order-related errors when select queries are modified. Otherwise parse 
  locally so the order is obvious, or use function parameters instead of an array of values.
- Consider setting a default region id on store.
- Consider modularizing price calculation.
- User-defined data may be a simple json or a system like the one implemented by shopify or vendure: 
  the user defines data and its types and a database migration happens. The first option leaves everything 
  in the hands of the frontend, the second option may allow custom filters in query strings when requesting 
  data from peony. However, the second option is also significantly more complex to implement and maintain.

## Documentation

- [ ] Endpoints
- [ ] Parameters
- [ ] Query strings
