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
- [ ] Images
- [x] Prices
- [x] Multilanguage
- [x] Multicurrency

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

- Make peony a module
- Create public interfaces and make modules

## Internals

- [x] Keep response structs separate from internal structs
- [ ] Return data as the root property of json payload
- [x] Return count, offset and fetch values with lists
- [ ] Return time.Time.format_rfc3339() instead of time.Time
- [ ] Redict cache
- [ ] Transaction attempts

## Considerations

- Currently select queries must respect the order of the variables in `parse_` functions, instead consider 
  rewriting `parse_` functions to check and match column names. This introduces string normalization 
  and comparison but prevents order-related errors when select queries are modified.

## Documentation

- [ ] Endpoints
- [ ] Parameters
- [ ] Query strings
