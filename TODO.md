# TODO

- [x] Read settings from environment and validate~~ <!-- Always panic right away on startup, never on runtime -->
- [x] Write a firebird connector <!-- https://github.com/einar-hjortdal/redict -->
- [x] Write a Redict library <!-- https://github.com/einar-hjortdal/redict -->
- [x] Write a BLOB storage service <!-- https://github.com/einar-hjortdal/blobly -->
- [x] Seed new database with a schema, constants and defaults
- [ ] Always return json
- [ ] Iron out error handling
- [ ] Cache and invalidation

## Refactor

- [x] Keep response struct separate from internal structs
- [ ] Return count, offset and fetch values with lists
- [ ] Return time.Time.format_rfc3339() instead of time.Time

## Considerations

- Currently select queries must respect the order of the variables in `parse_` functions, instead consider 
  rewriting `parse_` functions to check and match column names. This introduces string normalization 
  and comparison but prevents order-related errors when select queries are modified.
