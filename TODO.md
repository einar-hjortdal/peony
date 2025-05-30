# TODO

- [x] Read settings from environment and validate~~ <!-- Always panic right away on startup, never on runtime -->
- [x] Write a firebird connector <!-- https://github.com/einar-hjortdal/redict -->
- [x] Write a Redict library <!-- https://github.com/einar-hjortdal/redict -->
- [x] Write a BLOB storage service <!-- https://github.com/einar-hjortdal/blobly -->
- [ ] Seed new database with a schema, constants and defaults
- [ ] Iron out error handling

## Refactor

- include `id_bin` in structs, use `@[json: '-']`.