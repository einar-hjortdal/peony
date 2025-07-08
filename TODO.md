# TODO

## Basics

- [x] Read and validate settings~~ <!-- Always panic right away on startup, never on runtime -->
- [x] Write a database-friendly uuid library <!-- https://github.com/einar-hjortdal/lexical_uuid -->
- [x] Write a sessions management library <!-- https://github.com/einar-hjortdal/sessions -->
- [x] Write a FirebirdSQL connector <!-- https://github.com/einar-hjortdal/redict -->
- [x] Write a Redict library <!-- https://github.com/einar-hjortdal/redict -->
- [x] Write a BLOB storage service <!-- https://github.com/einar-hjortdal/blobly -->
- [x] Seed new database with a schema, constants and defaults
- [ ] Always return json
- [ ] Iron out error handling

## Features

### 3.3.0

- [ ] Products
- [ ] Variants
- [ ] Images
- [ ] Prices
- [ ] Multilanguage
- [ ] Multicurrency

### Next

- [ ] Redict cache
- [ ] Multiregion
- [ ] Multichannel
- [ ] Multiwarehouse
- [ ] Multistore
- [ ] Taxes
- [ ] Caching
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
- [ ] API keys management
- [ ] Unit pricing
- [ ] Price rules

## Refactor

- [x] Keep response struct separate from internal structs
- [ ] Return count, offset and fetch values with lists
- [ ] Return time.Time.format_rfc3339() instead of time.Time
- [ ] Namespace functions that orchestrate database operations to separate them from functions that 
        actually perform database operations

## Considerations

- Currently select queries must respect the order of the variables in `parse_` functions, instead consider 
  rewriting `parse_` functions to check and match column names. This introduces string normalization 
  and comparison but prevents order-related errors when select queries are modified.
