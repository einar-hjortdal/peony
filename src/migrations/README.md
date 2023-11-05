# Migrations

peony does not use any ORM, the database lifecycle is managed independently of the application lifecycle. 
Migrations are scripts that have the following characteristics:
- A database backup is prepared before changes are applied.
- Database changes are always run in the same predetermined order.
- Changes should be in a single transaction.
- The script can be run multiple times but changes are only applied once.

The `seed.sql` file contains the queries used to seed an empty database for a new peony store. the file 
`seed-rollback.sql` can be used to quickly rollback the setup performed by `seed.sql`, useful for development.

The `seed-currency-codes` file contains ISO 4217:2015 currency codes.

## Notes

- *Accretion is non-breaking*: adding new tables, columns, ...
- *Deletion is breaking*: only remove tables, columns, ... when no other part of the system is using it.
- *Updates are dangerous*: when updating a column name, table name, … treat it as multiple steps in 
which the new desired element is added, every other part of the system is changed to use the new element, 
and then the old element is removed.

- Names for constraints and indexes are generated with the following technique: 
  1. The first 2 letters of the name match one of
    - `UQ` for `UNIQUE`
    - `IX` for `INDEX`
    - `FK` for `FOREIGN KEY`
    - `CK` for `CHECK`
  2. An underscore to separate the first 2 letters from the following characters
  3. The UUID generated with a minimal V program 
    ```v
    import rand
    
    println(rand.uuid_v4())
    ```
