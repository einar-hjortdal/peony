# Notes

## Design

- 

## Schema

- `tax_rate` models a many-to-many relation using `region_tax_rate`, `product_tax_rate` and `product_type_tax_rate`,
  but in reality we want a one-to-many relation: one `region` to many `tax_rate`, one `product` to many 
  `tax_rate` and one `product_type` to many `tax_rate`. To appropriately model a one-to-many relation 
  there are 2 options:
    1. polymorphic single table

    ```sql
    CREATE TABLE tax_rate (
      id         BINARY(16) NOT NULL PRIMARY KEY,
      scope      VARCHAR()  NOT NULL CHECK(scope IN ('region','product','product_type')),
      scope_id   BINARY(16)   NOT NULL,
      rate       REAL         NOT NULL,
      code       VARCHAR(63),
      name       VARCHAR(63)  NOT NULL,
      type       VARCHAR(12)  NOT NULL CHECK(type IN ('additive','substitutive','compounding')),
      created_at TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
      deleted_at TIMESTAMP
    );
    ```
  
      This solution cannot enforce foreign key checks, queries must include `WHERE domain = 'region'`.

  2. one table per domain

    ```sql
    CREATE TABLE region_tax_rate (
      id         BINARY(16) NOT NULL PRIMARY KEY,
      region_id  BINARY(16) NOT NULL REFERENCES region(id),
      rate       REAL       NOT NULL,
      code       VARCHAR(63),
      name       VARCHAR(63) NOT NULL,
      type       VARCHAR(12) NOT NULL CHECK(type IN ('additive','substitutive','compounding')),
      created_at TIMESTAMP  NOT NULL DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP  NOT NULL DEFAULT CURRENT_TIMESTAMP,
      deleted_at TIMESTAMP
    );

      CREATE TABLE product_tax_rate (
      id         BINARY(16) NOT NULL PRIMARY KEY,
      region_id  BINARY(16) NOT NULL REFERENCES product(id),
      rate       REAL       NOT NULL,
      code       VARCHAR(63),
      name       VARCHAR(63) NOT NULL,
      type       VARCHAR(12) NOT NULL CHECK(type IN ('additive','substitutive','compounding')),
      created_at TIMESTAMP  NOT NULL DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP  NOT NULL DEFAULT CURRENT_TIMESTAMP,
      deleted_at TIMESTAMP
    );

      CREATE TABLE product_type_tax_rate (
      id         BINARY(16) NOT NULL PRIMARY KEY,
      region_id  BINARY(16) NOT NULL REFERENCES product_type(id),
      rate       REAL       NOT NULL,
      code       VARCHAR(63),
      name       VARCHAR(63) NOT NULL,
      type       VARCHAR(12) NOT NULL CHECK(type IN ('additive','substitutive','compounding')),
      created_at TIMESTAMP  NOT NULL DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP  NOT NULL DEFAULT CURRENT_TIMESTAMP,
      deleted_at TIMESTAMP
    );
    ```
    
      This solution is more difficult to maintain because we have 3 almost identical tables.

  The current schema can enforce foreign key checks and is easier to maintain. The application must 
  ensure the relation is truly one-to-many and not many-to-many.
