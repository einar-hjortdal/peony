CREATE TABLE migration (
  id BINARY(16) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  name VARCHAR(191) NOT NULL,
  CONSTRAINT "06a5c8bb-cdf2-19ec-2800-3c09f6d55391" PRIMARY KEY (id)
);

CREATE TABLE image (
  id BINARY(16) NOT NULL,
  url BLOB SUB_TYPE TEXT NOT NULL,
  alt VARCHAR(191),
  CONSTRAINT "06a5c8bb-cdf2-1cca-e400-199287cc645a" PRIMARY KEY (id)
);

CREATE TABLE password_details (
  id BINARY(16) NOT NULL,
  function_name VARCHAR(63) NOT NULL,
  parameters BLOB SUB_TYPE TEXT NOT NULL,
  hash BINARY(32) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  CONSTRAINT "06a5c8bb-cdf3-1042-3400-d13796fdfa53" PRIMARY KEY (id)
);

CREATE UNIQUE INDEX "06a5c8bb-cdf3-114b-2400-f04519909fa0" ON password_details (hash);

CREATE TABLE peony_user (
  id BINARY(16) NOT NULL,
  handle VARCHAR(63) NOT NULL,
  email VARCHAR(254), -- IETF RFC 3696 Errata 1690
  password_hash BLOB SUB_TYPE BINARY NOT NULL,
  password_salt BLOB SUB_TYPE BINARY NOT NULL,
  password_details_id BINARY(16) NOT NULL,
  role VARCHAR(11) DEFAULT 'member' NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  deleted_at TIMESTAMP,
  first_name VARCHAR(63),
  last_name VARCHAR(63),
  image_id BINARY(16),
  metadata BLOB SUB_TYPE TEXT,
  CONSTRAINT "06a5c8bb-cdf3-1959-c400-e378e6f0bc5a" PRIMARY KEY (id),
  CONSTRAINT "06a5c8bb-cdf3-19c9-6000-5acef04c3792" FOREIGN KEY (password_details_id) REFERENCES password_details (id),
  CONSTRAINT "06a5c8bb-cdf3-1a39-7000-a0dd6c7e2506" CHECK (
    role IN (
      'admin', 'member', 'developer', 'author', 'contributor'
    )
  ),
  CONSTRAINT "06a5c8bb-cdf3-1ba6-9000-e28579a483de" FOREIGN KEY (image_id) REFERENCES image (id) ON DELETE SET NULL
);

CREATE UNIQUE INDEX "06a5c8bb-cdf3-1cb6-2800-c3bbf7bff4e1" ON peony_user (email) WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX "06a5c8bb-cdf3-1d23-3400-aad984ff9e1f" ON peony_user (handle) WHERE deleted_at IS NULL;

CREATE TABLE currency (
  code CHAR(3) NOT NULL, -- ISO 4217
  decimal_digits INTEGER,
  CONSTRAINT "06a5c8bb-cdf3-1f1c-e000-fa17fa851d93" PRIMARY KEY (code)
);

CREATE TABLE product_tag (
  id BINARY(16) NOT NULL,
  name VARCHAR(63) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  deleted_at TIMESTAMP,
  metadata BLOB SUB_TYPE TEXT,
  CONSTRAINT "06a5c8bb-cdf4-1317-d400-21e8e469d2d7" PRIMARY KEY (id)
);

CREATE TABLE product_type (
  id BINARY(16) NOT NULL,
  name VARCHAR(63) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  deleted_at TIMESTAMP,
  metadata BLOB SUB_TYPE TEXT,
  CONSTRAINT "06a5c8bb-cdf4-16d4-7c00-f47f03051093" PRIMARY KEY (id)
);

CREATE TABLE price_list (
  id BINARY(16) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  deleted_at TIMESTAMP,
  name VARCHAR(63) NOT NULL,
  description VARCHAR(191),
  type VARCHAR(8) DEFAULT 'sale' NOT NULL,
  status VARCHAR(6) DEFAULT 'draft' NOT NULL,
  includes_tax BOOLEAN DEFAULT false NOT NULL,
  starts_at TIMESTAMP,
  ends_at TIMESTAMP,
  CONSTRAINT "06a5c8bb-cdf4-1cb7-b800-ab09c244bd70" PRIMARY KEY (id),
  CONSTRAINT "06a5c8bb-cdf4-1d3f-0c00-2c4194d03cc6" CHECK (type IN ('sale', 'override')),
  CONSTRAINT "06a5c8bb-cdf4-1da4-7c00-b1953c196dcd" CHECK (status IN ('active', 'draft'))
);

CREATE TABLE tax_rate (
  id BINARY(16) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  deleted_at TIMESTAMP,
  rate REAL NOT NULL,
  code VARCHAR(63),
  name VARCHAR(63) NOT NULL,
  type VARCHAR(12) DEFAULT 'additive' NOT NULL,
  CONSTRAINT "06a5c8bb-cdf5-1228-f000-14f1e5fab1c9" PRIMARY KEY (id),
  CONSTRAINT "06a5c8bb-cdf5-12ab-7c00-e261425daac5" CHECK (
    type IN (
      'additive', 'substitutive', 'compounding'
    )
  )
);

CREATE TABLE region (
  id BINARY(16) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  deleted_at TIMESTAMP,
  name VARCHAR(63) NOT NULL,
  currency_code CHAR(3) NOT NULL,
  includes_tax BOOLEAN DEFAULT false NOT NULL,
  gift_cards_taxable BOOLEAN DEFAULT true NOT NULL,
  automatic_taxes BOOLEAN DEFAULT true NOT NULL,
  CONSTRAINT "06a5c8bb-cdf5-1880-5400-ce648f02f674" PRIMARY KEY (id),
  CONSTRAINT "06a5c8bb-cdf5-18e7-dc00-189627b53bc5" FOREIGN KEY (currency_code) REFERENCES currency (code)
);

CREATE INDEX "06a5c8bb-cdf5-19f8-e000-6d0ffe4ee315" ON region (currency_code);

CREATE TABLE region_tax_rate (
  region_id BINARY(16) NOT NULL,
  rate_id BINARY(16) NOT NULL,
  CONSTRAINT "06a5c8bb-cdf5-1bea-8800-6b0b38665f38" PRIMARY KEY (region_id, rate_id),
  CONSTRAINT "06a5c8bb-cdf5-1c68-0400-a224c93a8b18" FOREIGN KEY (region_id) REFERENCES region (id) ON DELETE CASCADE,
  CONSTRAINT "06a5c8bb-cdf5-1cd9-5400-24c665b212cb" FOREIGN KEY (rate_id) REFERENCES tax_rate (id) ON DELETE CASCADE
);

CREATE INDEX "06a5c8bb-cdf5-1de7-a800-b9e81c489338" ON region_tax_rate (rate_id);

CREATE TABLE money_amount (
  id BINARY(16) NOT NULL,
  amount INTEGER NOT NULL,
  region_id BINARY(16) NOT NULL,
  is_original BOOLEAN DEFAULT false NOT NULL,
  min_quantity INTEGER,
  max_quantity INTEGER,
  price_list_id BINARY(16),
  CONSTRAINT "06a5c8bb-cdf6-1196-f000-6490f5b7e755" PRIMARY KEY (id),
  CONSTRAINT "06a5c8bb-cdf6-121a-4c00-c65a35da802d" FOREIGN KEY (region_id) REFERENCES region (id) ON DELETE CASCADE,
  CONSTRAINT "06a5c8bb-cdf6-127c-6c00-419000b838b0" FOREIGN KEY (price_list_id) REFERENCES price_list (id) ON DELETE CASCADE
);

CREATE INDEX "06a5c8bb-cdf6-13c1-5c00-bfbdad6fbd94" ON money_amount (region_id);

CREATE TABLE country (
  code CHAR(2) NOT NULL, -- ISO 3166-1 alpha 2
  region_id BINARY(16),
  CONSTRAINT "06a5c8bb-cdf6-159b-9800-5a3748e29f83" PRIMARY KEY (code),
  CONSTRAINT "06a5c8bb-cdf6-1600-7800-5f1ff3876c0b" FOREIGN KEY (region_id) REFERENCES region (id)
);

CREATE INDEX "06a5c8bb-cdf6-16ff-d800-c5461ff32249" ON country (region_id);

CREATE TABLE product (
  id BINARY(16) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  deleted_at TIMESTAMP,
  handle VARCHAR(63) NOT NULL,
  title VARCHAR(63) NOT NULL,
  subtitle VARCHAR(191),
  description BLOB SUB_TYPE TEXT,
  is_giftcard BOOLEAN DEFAULT false NOT NULL,
  status VARCHAR(9) DEFAULT 'draft' NOT NULL,
  thumbnail_id BINARY(16),
  type_id BINARY(16),
  discountable BOOLEAN DEFAULT true NOT NULL,
  metadata BLOB SUB_TYPE TEXT,
  CONSTRAINT "06a5c8bb-cdf6-1d36-2800-09c1e8d10e0d" PRIMARY KEY (id),
  CONSTRAINT "06a5c8bb-cdf6-1d99-d400-e30864330c3f" CHECK (status IN ('draft', 'proposed', 'published', 'rejected')),
  CONSTRAINT "06a5c8bb-cdf6-1e07-ac00-f85cda233d20" FOREIGN KEY (thumbnail_id) REFERENCES image (id),
  CONSTRAINT "06a5c8bb-cdf6-1e86-3c00-2574d3c74821" FOREIGN KEY (type_id) REFERENCES product_type (id)
);

CREATE UNIQUE INDEX "06a5c8bb-cdf7-1037-4800-89dbc03a924b" ON product (handle) WHERE deleted_at IS NULL;

CREATE TABLE variant (
  id BINARY(16) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  deleted_at TIMESTAMP,
  product_id BINARY(16) NOT NULL,
  image_id BINARY(16),
  title VARCHAR(63),
  barcode VARCHAR(63),
  ean VARCHAR(13),
  upc VARCHAR(12),
  variant_rank INTEGER DEFAULT 0 NOT NULL,
  metadata BLOB SUB_TYPE TEXT,
  CONSTRAINT "06a5c8bb-cdf7-1862-7800-6d75890bdbe1" PRIMARY KEY (id),
  CONSTRAINT "06a5c8bb-cdf7-18e8-e400-d79d39dc37ee" FOREIGN KEY (product_id) REFERENCES product (id) ON DELETE CASCADE,
  CONSTRAINT "06a5c8bb-cdf7-1953-f800-db202c999765" FOREIGN KEY (image_id) REFERENCES image (id) ON DELETE SET NULL
);

CREATE INDEX "06a5c8bb-cdf7-1a6e-a800-ae491c13dbee" ON variant (product_id);
CREATE UNIQUE INDEX "06a5c8bb-cdf7-1adb-7000-4fb74de02ca9" ON variant (barcode) WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX "06a5c8bb-cdf7-1b4b-e800-d7b11d79f1ca" ON variant (ean) WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX "06a5c8bb-cdf7-1bb5-e400-b66c9bbb4248" ON variant (upc) WHERE deleted_at IS NULL;

CREATE TABLE inventory_item (
  id BINARY(16) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  deleted_at TIMESTAMP,
  variant_id BINARY(16) NOT NULL,
  sku VARCHAR(63),
  origin_country CHAR(2),
  hs_code VARCHAR(63),
  mid_code VARCHAR(15),
  material VARCHAR(191),
  weight INTEGER,
  length INTEGER,
  height INTEGER,
  width INTEGER,
  requires_shipping BOOLEAN DEFAULT true NOT NULL,
  manage_inventory BOOLEAN DEFAULT true NOT NULL,
  allow_backorder BOOLEAN DEFAULT false NOT NULL,
  CONSTRAINT "06a5c8bb-cdf8-14cb-8c00-c95443f10ec1" PRIMARY KEY (id),
  CONSTRAINT "06a5c8bb-cdf8-1532-e400-53a2e5cf6178" FOREIGN KEY (variant_id) REFERENCES variant (id) ON DELETE CASCADE,
  CONSTRAINT "06a5c8bb-cdf8-15a2-b800-66f511073d50" FOREIGN KEY (origin_country) REFERENCES country (code)
);

CREATE UNIQUE INDEX "06a5c8bb-cdf8-16de-6c00-b08287ebf6da" ON inventory_item (variant_id);
CREATE UNIQUE INDEX "06a5c8bb-cdf8-175c-a000-e27fdac0b0bf" ON inventory_item (sku) WHERE deleted_at IS NULL;

CREATE TABLE variant_money_amount (
  variant_id BINARY(16) NOT NULL,
  money_amount_id BINARY(16) NOT NULL,
  CONSTRAINT "06a5c8bb-cdf8-1917-1800-3bc445bc8bc9" PRIMARY KEY (variant_id, money_amount_id),
  CONSTRAINT "06a5c8bb-cdf8-1986-b400-9e969750817a" FOREIGN KEY (variant_id) REFERENCES variant (id) ON DELETE CASCADE,
  CONSTRAINT "06a5c8bb-cdf8-1a10-6400-57a7aeb36358" FOREIGN KEY (money_amount_id) REFERENCES money_amount (id) ON DELETE CASCADE
);

CREATE UNIQUE INDEX "06a5c8bb-cdf8-1b32-2400-6144d713ff34" ON variant_money_amount (money_amount_id);

CREATE TABLE product_option (
  id BINARY(16) NOT NULL,
  product_id BINARY(16) NOT NULL,
  option_rank INTEGER DEFAULT 0 NOT NULL,
  title VARCHAR(63) NOT NULL,
  CONSTRAINT "06a5c8bb-cdf8-1deb-1800-8e004c59cd2c" PRIMARY KEY (id),
  CONSTRAINT "06a5c8bb-cdf8-1e56-f400-f91da1c1d5d5" FOREIGN KEY (product_id) REFERENCES product (id) ON DELETE CASCADE
);

CREATE INDEX "06a5c8bb-cdf8-1f75-1000-935b8d2894a2" ON product_option (product_id);

CREATE TABLE product_option_value (
  id BINARY(16) NOT NULL,
  option_id BINARY(16) NOT NULL,
  value_rank INTEGER DEFAULT 0 NOT NULL,
  name VARCHAR(63) NOT NULL,
  CONSTRAINT "06a5c8bb-cdf9-1c5f-3800-2f867af46016" PRIMARY KEY (id),
  CONSTRAINT "06a5c8bb-cdf9-1cc4-6000-4f4c08147aff" FOREIGN KEY (option_id) REFERENCES product_option (id) ON DELETE CASCADE
);

CREATE INDEX "06a5c8bb-cdf9-1ddd-a800-14151d9c7c18" ON product_option_value (option_id);

CREATE TABLE product_option_value_variant (
  option_value_id BINARY(16) NOT NULL,
  variant_id BINARY(16) NOT NULL,
  CONSTRAINT "06a5c8bb-cdf9-1f8e-d800-9d94af6d38e6" PRIMARY KEY (option_value_id, variant_id),
  CONSTRAINT "06a5c8bb-cdf9-1ff8-d800-ce860abb7492" FOREIGN KEY (option_value_id) REFERENCES product_option_value (id) ON DELETE CASCADE,
  CONSTRAINT "06a5c8bb-cdfa-1063-ec00-63d01d495b0a" FOREIGN KEY (variant_id) REFERENCES variant (id) ON DELETE CASCADE
);

CREATE INDEX "06a5c8bb-cdfa-1171-4000-11d41523b66b" ON product_option_value_variant (variant_id);

CREATE TABLE category (
  id BINARY(16) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  deleted_at TIMESTAMP,
  name VARCHAR(63) NOT NULL,
  description BLOB SUB_TYPE TEXT,
  handle VARCHAR(63) NOT NULL,
  is_active BOOLEAN DEFAULT true NOT NULL,
  is_internal BOOLEAN DEFAULT false NOT NULL,
  parent_category_id BINARY(16),
  metadata BLOB SUB_TYPE TEXT,
  CONSTRAINT "06a5c8bb-cdfa-165d-a800-81bbdeb1ea27" PRIMARY KEY (id),
  CONSTRAINT "06a5c8bb-cdfa-16c0-a400-ac11bf007993" FOREIGN KEY (parent_category_id) REFERENCES category (id)
);

CREATE UNIQUE INDEX "06a5c8bb-cdfa-17cf-9800-a4728897f1bb" ON category (handle) WHERE deleted_at IS NULL;

CREATE TABLE product_tax_rate (
  product_id BINARY(16) NOT NULL,
  rate_id BINARY(16) NOT NULL,
  CONSTRAINT "06a5c8bb-cdfa-1997-5000-ede955b848c1" PRIMARY KEY (product_id, rate_id),
  CONSTRAINT "06a5c8bb-cdfa-1a41-0c00-9e86ab31976c" FOREIGN KEY (product_id) REFERENCES product (id) ON DELETE CASCADE,
  CONSTRAINT "06a5c8bb-cdfa-1aaf-5c00-a54607d8e318" FOREIGN KEY (rate_id) REFERENCES tax_rate (id) ON DELETE CASCADE
);

CREATE INDEX "06a5c8bb-cdfa-1bba-e800-609ed16e11f6" ON product_tax_rate (rate_id);

CREATE TABLE product_type_tax_rate (
  product_type_id BINARY(16) NOT NULL,
  rate_id BINARY(16) NOT NULL,
  CONSTRAINT "06a5c8bb-cdfa-1d7d-2c00-f228a2d93d6f" PRIMARY KEY (product_type_id, rate_id),
  CONSTRAINT "06a5c8bb-cdfa-1ed4-3c00-27871b557efc" FOREIGN KEY (product_type_id) REFERENCES product_type (id) ON DELETE CASCADE,
  CONSTRAINT "06a5c8bb-cdfa-1f45-a400-a964e615f39f" FOREIGN KEY (rate_id) REFERENCES tax_rate (id) ON DELETE CASCADE
);

CREATE INDEX "06a5c8bb-cdfb-10df-1400-0f5bdf6e0a3d" ON product_type_tax_rate (rate_id);

CREATE TABLE locale (
  id BINARY(16) NOT NULL,
  code VARCHAR(63) NOT NULL,
  CONSTRAINT "06a5c8bb-cdfb-129f-f400-38bde9985c05" PRIMARY KEY (id),
  CONSTRAINT "06a5c8bb-cdfb-1310-8800-deabc8fc62b6" UNIQUE (code)
);

CREATE TABLE address (
  id BINARY(16) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  deleted_at TIMESTAMP,
  address_1 VARCHAR(191) NOT NULL,
  address_2 VARCHAR(191),
  company VARCHAR(63),
  city VARCHAR(63),
  country_code CHAR(2) NOT NULL,
  phone VARCHAR(63),
  province VARCHAR(63),
  postal_code VARCHAR(63),
  status VARCHAR(8) DEFAULT 'active' NOT NULL,
  CONSTRAINT "06a5c8bb-cdfb-18e8-fc00-9070de6cdb1a" PRIMARY KEY (id),
  CONSTRAINT "06a5c8bb-cdfb-1945-b800-bf2a0698893a" FOREIGN KEY (country_code) REFERENCES country (code),
  CONSTRAINT "06a5c8bb-cdfb-19ae-3000-7e013298a54e" CHECK (status IN ('active', 'frozen', 'replaced'))
);

CREATE INDEX "06a5c8bb-cdfb-1ab1-b800-66a38bb47ec9" ON address (country_code);

CREATE TABLE customer (
  id BINARY(16) NOT NULL,
  email VARCHAR(254), -- IETF RFC 3696 Errata 1690
  password_hash BLOB SUB_TYPE BINARY,
  password_salt BLOB SUB_TYPE BINARY,
  password_details_id BINARY(16),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  deleted_at TIMESTAMP,
  first_name VARCHAR(63),
  last_name VARCHAR(63),
  phone VARCHAR(63), -- E.164
  is_registered BOOLEAN DEFAULT false NOT NULL,
  metadata BLOB SUB_TYPE TEXT,
  CONSTRAINT "06a5c8bb-cdfc-1039-6000-7ed6859313df" PRIMARY KEY (id),
  CONSTRAINT "REPLACE_WITH_LUUID" FOREIGN KEY (password_details_id) REFERENCES password_details (id)
);

CREATE UNIQUE INDEX "06a5c8bb-cdfc-1152-3800-4ceda38110fb" ON customer (email);

CREATE TABLE customer_address (
  customer_id BINARY(16) NOT NULL,
  address_id BINARY(16) NOT NULL,
  is_default BOOLEAN DEFAULT false NOT NULL,
  CONSTRAINT "06a5c8bb-cdfc-137e-f000-970db82d4e81" PRIMARY KEY (customer_id, address_id),
  CONSTRAINT "06a5c8bb-cdfc-13e0-8c00-3ac82104ae5f" FOREIGN KEY (customer_id) REFERENCES customer (id) ON DELETE CASCADE,
  CONSTRAINT "06a5c8bb-cdfc-1447-c400-d0a224c46fad" FOREIGN KEY (address_id) REFERENCES address (id) ON DELETE CASCADE
);

CREATE TABLE stock_location (
  id BINARY(16) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  deleted_at TIMESTAMP,
  name VARCHAR(63) NOT NULL,
  address_id BINARY(16),
  CONSTRAINT "06a5c8bb-cdfc-17c9-7000-8d5eb2c0da73" PRIMARY KEY (id),
  CONSTRAINT "06a5c8bb-cdfc-182e-9000-6ac0347854f8" FOREIGN KEY (address_id) REFERENCES address (id)
);

CREATE INDEX "06a5c8bb-cdfc-1943-d000-288ab9bcbd32" ON stock_location (address_id) WHERE deleted_at IS NOT NULL;

CREATE TABLE inventory_level (
  inventory_item_id BINARY(16) NOT NULL,
  stock_location_id BINARY(16) NOT NULL,
  stocked_quantity INTEGER DEFAULT 0 NOT NULL,
  CONSTRAINT "06a5c8bb-cdfc-1b7c-0c00-75d7ef7bce43" PRIMARY KEY (inventory_item_id, stock_location_id),
  CONSTRAINT "06a5c8bb-cdfc-1bde-dc00-e0c52293b6db" FOREIGN KEY (inventory_item_id) REFERENCES inventory_item (id) ON DELETE CASCADE,
  CONSTRAINT "06a5c8bb-cdfc-1c48-6400-fe2240bc6d0e" FOREIGN KEY (stock_location_id) REFERENCES stock_location (id) ON DELETE CASCADE
);

CREATE INDEX "06a5c8bb-cdfc-1d8a-3000-57ea6ef90c7b" ON inventory_level (stock_location_id);

CREATE TABLE sales_channel (
  id BINARY(16) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  deleted_at TIMESTAMP,
  name VARCHAR(63) NOT NULL,
  description VARCHAR(191),
  is_disabled BOOLEAN DEFAULT false NOT NULL,
  CONSTRAINT "06a5c8bb-cdfd-10f9-7400-42f4ed7659ce" PRIMARY KEY (id)
);

CREATE TABLE sales_channel_stock_location (
  sales_channel_id BINARY(16) NOT NULL,
  stock_location_id BINARY(16) NOT NULL,
  CONSTRAINT "06a5c8bb-cdfd-1316-f000-ef0e1f0c0c00" PRIMARY KEY (sales_channel_id, stock_location_id),
  CONSTRAINT "06a5c8bb-cdfd-137d-6400-1836e9b07e52" FOREIGN KEY (sales_channel_id) REFERENCES sales_channel (id) ON DELETE CASCADE,
  CONSTRAINT "06a5c8bb-cdfd-13ef-4c00-a08dc8124d07" FOREIGN KEY (stock_location_id) REFERENCES stock_location (id) ON DELETE CASCADE
);

CREATE INDEX "06a5c8bb-cdfd-1501-9000-799d5907ea66" ON sales_channel_stock_location (stock_location_id);

CREATE TABLE item_availability (
  item_id BINARY(16) NOT NULL,
  sales_channel_id BINARY(16) NOT NULL,
  amount INTEGER DEFAULT 0 NOT NULL,
  CONSTRAINT "06a5c8bb-cdfd-1709-6400-9835a7778454" PRIMARY KEY (item_id, sales_channel_id),
  CONSTRAINT "06a5c8bb-cdfd-17c1-0c00-c041b5ac90af" FOREIGN KEY (item_id) REFERENCES inventory_item (id) ON DELETE CASCADE,
  CONSTRAINT "06a5c8bb-cdfd-1879-6000-65b5a7970d43" FOREIGN KEY (sales_channel_id) REFERENCES sales_channel (id) ON DELETE CASCADE
);

CREATE TABLE item_reservation (
  id BINARY(16) NOT NULL,
  item_id BINARY(16) NOT NULL,
  sales_channel_id BINARY(16) NOT NULL,
  stock_location_id BINARY(16) NOT NULL,
  amount INTEGER NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  expires_at TIMESTAMP NOT NULL,
  -- checkout_id BINARY(16) NOT NULL,
  CONSTRAINT "06a5c8bb-cdfd-1c92-8400-258531893207" PRIMARY KEY (id),
  CONSTRAINT "06a5c8bb-cdfd-1cf9-3000-4fba19686760" FOREIGN KEY (item_id) REFERENCES inventory_item (id) ON DELETE CASCADE,
  CONSTRAINT "06a5c8bb-cdfd-1d68-5400-30871f76ab1f" FOREIGN KEY (sales_channel_id) REFERENCES sales_channel (id) ON DELETE CASCADE,
  CONSTRAINT "06a5c8bb-cdfd-1ddf-9400-7062b372259d" FOREIGN KEY (stock_location_id) REFERENCES stock_location (id) ON DELETE CASCADE,
  CONSTRAINT "06a5c8bb-cdfd-1e4e-b000-1f27703a4af7" CHECK (amount > 0)
);

CREATE INDEX "06a5c8bb-cdfd-1f4e-f400-6300976db61a" ON item_reservation (expires_at);
-- CREATE INDEX "06a5c8bb-cdfd-1fc5-6c00-decd35177de2" ON item_reservation (checkout_id);
CREATE INDEX "06a5c8bb-cdfe-102c-f800-77320ce1c0f4" ON item_reservation (item_id, stock_location_id);

CREATE TABLE api_key (
  id BINARY(16) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  deleted_at TIMESTAMP,
  name VARCHAR(63) NOT NULL,
  sales_channel_id BINARY(16) NOT NULL,
  CONSTRAINT "06a5c8bb-cdfe-134d-4000-05fed2736950" PRIMARY KEY (id),
  CONSTRAINT "06a5c8bb-cdfe-13b6-6c00-eb457f78fb17" FOREIGN KEY (sales_channel_id) REFERENCES sales_channel (id) ON DELETE CASCADE
);

CREATE TABLE store (
  id BINARY(16) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  name VARCHAR(63) NOT NULL,
  default_locale_id BINARY(16) NOT NULL,
  default_region_id BINARY(16) NOT NULL,
  default_stock_location_id BINARY(16) NOT NULL,
  default_sales_channel_id BINARY(16) NOT NULL,
  CONSTRAINT "06a5c8bb-cdfe-17de-6800-2bd571910e85" PRIMARY KEY (id),
  CONSTRAINT "06a5c8bb-cdfe-184b-9800-8bd25f4a4615" UNIQUE (default_sales_channel_id),
  CONSTRAINT "06a5c8bb-cdfe-18b5-1800-b85471eafbd4" FOREIGN KEY (default_locale_id) REFERENCES locale (id),
  CONSTRAINT "06a5c8bb-cdfe-1926-b800-c996d42bbf26" FOREIGN KEY (default_region_id) REFERENCES region (id),
  CONSTRAINT "06a5c8bb-cdfe-1997-d000-633f0c02179c" FOREIGN KEY (default_sales_channel_id) REFERENCES sales_channel (id)
);

CREATE TABLE category_product (
  category_id BINARY(16) NOT NULL,
  product_id BINARY(16) NOT NULL,
  CONSTRAINT "06a5c8bb-cdfe-1db4-4000-b2fb648cbdf6" PRIMARY KEY (category_id, product_id),
  CONSTRAINT "06a5c8bb-cdfe-1e1d-9000-929ad16f4e8f" FOREIGN KEY (category_id) REFERENCES category (id) ON DELETE CASCADE,
  CONSTRAINT "06a5c8bb-cdfe-1e82-c400-e3c66673aa8f" FOREIGN KEY (product_id) REFERENCES product (id) ON DELETE CASCADE
);

CREATE INDEX "06a5c8bb-cdfe-1f9a-8400-53d7b8f7f69b" ON category_product (product_id);


CREATE TABLE product_image (
  product_id BINARY(16) NOT NULL,
  image_id BINARY(16) NOT NULL,
  image_rank INTEGER DEFAULT 0 NOT NULL,
  CONSTRAINT "06a5c8bb-cdff-1208-9800-44ba139485a7" PRIMARY KEY (product_id, image_id),
  CONSTRAINT "06a5c8bb-cdff-1278-4000-40b71a510b72" FOREIGN KEY (product_id) REFERENCES product (id) ON DELETE CASCADE,
  CONSTRAINT "06a5c8bb-cdff-12da-4000-c25e7af9b33c" FOREIGN KEY (image_id) REFERENCES image (id) ON DELETE CASCADE
);

CREATE INDEX "06a5c8bb-cdff-13e3-5800-b923fd00ddfd" ON product_image (image_id);

CREATE TABLE product_tag_product (
  product_id BINARY(16) NOT NULL,
  product_tag_id BINARY(16) NOT NULL,
  CONSTRAINT "06a5c8bb-cdff-159f-7400-494b01ae6c22" PRIMARY KEY (product_id, product_tag_id),
  CONSTRAINT "06a5c8bb-cdff-1604-4400-3b83fd9ca054" FOREIGN KEY (product_id) REFERENCES product (id) ON DELETE CASCADE,
  CONSTRAINT "06a5c8bb-cdff-166d-9c00-7233a44a2e5e" FOREIGN KEY (product_tag_id) REFERENCES product_tag (id) ON DELETE CASCADE
);

CREATE INDEX "06a5c8bb-cdff-1787-0000-55e83ac2e092" ON product_tag_product (product_tag_id);

CREATE TABLE product_sales_channel (
  product_id BINARY(16) NOT NULL,
  sales_channel_id BINARY(16) NOT NULL,
  CONSTRAINT "06a5c8bb-cdff-194a-ac00-cbf247bfd2f0" PRIMARY KEY (product_id, sales_channel_id),
  CONSTRAINT "06a5c8bb-cdff-19ad-4c00-0c5d63d4ca25" FOREIGN KEY (product_id) REFERENCES product (id) ON DELETE CASCADE,
  CONSTRAINT "06a5c8bb-cdff-1a10-3000-5d0da904108b" FOREIGN KEY (sales_channel_id) REFERENCES sales_channel (id) ON DELETE CASCADE
);

CREATE INDEX "06a5c8bb-cdff-1b29-3000-a949773b2de5" ON product_sales_channel (sales_channel_id);

CREATE TABLE store_locales (
  store_id BINARY(16) NOT NULL,
  locale_id BINARY(16) NOT NULL,
  CONSTRAINT "06a5c8bb-cdff-1ce7-f400-1b28953ae57c" PRIMARY KEY (store_id, locale_id),
  CONSTRAINT "06a5c8bb-cdff-1d48-f000-6fb2f5a92bd1" FOREIGN KEY (store_id) REFERENCES store (id) ON DELETE CASCADE,
  CONSTRAINT "06a5c8bb-cdff-1dad-b800-3a8281fa2c9c" FOREIGN KEY (locale_id) REFERENCES locale (id)
);

CREATE TABLE seo (
  id BINARY(16) NOT NULL,
  product_id BINARY(16),
  category_id BINARY(16),
  title VARCHAR(63),
  description VARCHAR(191),
  CONSTRAINT "06a5c8bb-ce00-10bc-8000-2ddf720270c3" PRIMARY KEY (id),
  CONSTRAINT "06a5c8bb-ce00-1120-d000-6f6110fdeaa2" FOREIGN KEY (product_id) REFERENCES product (id) ON DELETE CASCADE,
  CONSTRAINT "06a5c8bb-ce00-1187-b400-2f18e6d3bf1d" FOREIGN KEY (category_id) REFERENCES category (id) ON DELETE CASCADE
);

CREATE UNIQUE INDEX "06a5c8bb-ce00-12a1-f800-9eaf7b601d14" ON seo (product_id) WHERE product_id IS NOT NULL;
CREATE UNIQUE INDEX "06a5c8bb-ce00-130e-c000-48ebee484951" ON seo (category_id) WHERE category_id IS NOT NULL;

CREATE TABLE password_reset_token (
  id BINARY(16) NOT NULL,
  user_id BINARY(16),
  customer_id BINARY(16),
  hash BINARY(32) NOT NULL,
  expires_at TIMESTAMP NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  deleted_at TIMESTAMP,
  CONSTRAINT "REPLACE_WITH_LUUID" PRIMARY KEY (id),
  CONSTRAINT "REPLACE_WITH_LUUID" FOREIGN KEY (user_id) REFERENCES peony_user (id) ON DELETE CASCADE,
  CONSTRAINT "REPLACE_WITH_LUUID" FOREIGN KEY (customer_id) REFERENCES customer (id) ON DELETE CASCADE,
);

CREATE UNIQUE INDEX "REPLACE_WITH_LUUID" ON password_reset_token (user_id) WHERE deleted_at IS NOT NULL;
CREATE UNIQUE INDEX "REPLACE_WITH_LUUID" ON password_reset_token (customer_id) WHERE deleted_at IS NOT NULL;

CREATE TABLE notification_provider (
  id BINARY(16) NOT NULL,
  name VARCHAR(63) NOT NULL,
  is_installed BOOLEAN DEFAULT true NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  CONSTRAINT "REPLACE_WITH_LUUID" PRIMARY KEY (id)
);

CREATE UNIQUE INDEX "REPLACE_WITH_LUUID" ON notification_provider (name);

CREATE TABLE notification_channel (
  id BINARY(16) NOT NULL,
  name VARCHAR(63) NOT NULL,
  provider_id BINARY(16),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  CONSTRAINT "REPLACE_WITH_LUUID" PRIMARY KEY (id),
  CONSTRAINT "REPLACE_WITH_LUUID" FOREIGN KEY (provider_id) REFERENCES provider (id) ON DELETE CASCADE
);

CREATE UNIQUE INDEX "REPLACE_WITH_LUUID" ON notification_channel (name);

CREATE TABLE notification (
  id BINARY(16) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  deleted_at TIMESTAMP,
  provider_id BINARY(16) NOT NULL,
  channel_id BINARY(16) NOT NULL,
  "to" BLOB SUB_TYPE TEXT NOT NULL,
  "from" BLOB SUB_TYPE TEXT,
  template BLOB SUB_TYPE TEXT, -- external
  payload BLOB SUB_TYPE TEXT,
  source_event VARCHAR(16),
  -- password_reset_token_id BINARY(16),
  -- order_id BINARY(16),
  -- shipment_id BINARY(16),
  user_id BINARY(16), -- recipient
  customer_id BINARY(16), -- recipient
  status VARCHAR(7) DEFAULT 'pending' NOT NULL,
  CONSTRAINT "REPLACE_WITH_LUUID" PRIMARY KEY (id),
  CONSTRAINT "REPLACE_WITH_LUUID" CHECK (
    source_event IN (
      'password_reset',
      'customer_created', 'customer_updated', 'customer_deleted',
    )
  ),
  CONSTRAINT "REPLACE_WITH_LUUID" CHECK (status IN ('pending', 'success', 'failure')),
  CONSTRAINT "REPLACE_WITH_LUUID" FOREIGN KEY (provider_id) REFERENCES notification_provider (id) ON DELETE CASCADE,
  CONSTRAINT "REPLACE_WITH_LUUID" FOREIGN KEY (channel_id) REFERENCES notification_channel (id) ON DELETE CASCADE,
  CONSTRAINT "REPLACE_WITH_LUUID" FOREIGN KEY (user_id) REFERENCES peony_user (id) ON DELETE CASCADE,
  CONSTRAINT "REPLACE_WITH_LUUID" FOREIGN KEY (customer_id) REFERENCES customer (id) ON DELETE CASCADE
);

CREATE TABLE image_translations (
  image_id BINARY(16) NOT NULL,
  locale_id BINARY(16) NOT NULL,
  alt VARCHAR(191) NOT NULL,
  CONSTRAINT "06a5c8bb-ce00-1523-9400-a315feb889b2" PRIMARY KEY (image_id, locale_id),
  CONSTRAINT "06a5c8bb-ce00-1586-0800-c48ba01936ec" FOREIGN KEY (image_id) REFERENCES image (id) ON DELETE CASCADE,
  CONSTRAINT "06a5c8bb-ce00-15ef-1400-4bb8e99cb137" FOREIGN KEY (locale_id) REFERENCES locale (id)
);

CREATE TABLE product_tag_translations (
  product_tag_id BINARY(16) NOT NULL,
  locale_id BINARY(16) NOT NULL,
  name VARCHAR(63) NOT NULL,
  CONSTRAINT "06a5c8bb-ce00-186b-8800-1813936d8ad3" PRIMARY KEY (product_tag_id, locale_id),
  CONSTRAINT "06a5c8bb-ce00-18d5-0000-1331e1b0cb86" FOREIGN KEY (locale_id) REFERENCES locale (id),
  CONSTRAINT "06a5c8bb-ce00-1937-8800-ab5b8bd9cb9a" FOREIGN KEY (product_tag_id) REFERENCES product_tag (id) ON DELETE CASCADE
);

CREATE TABLE product_type_translations (
  product_type_id BINARY(16) NOT NULL,
  locale_id BINARY(16) NOT NULL,
  name VARCHAR(63) NOT NULL,
  CONSTRAINT "06a5c8bb-ce00-1b9b-bc00-7e90af0c3b6a" PRIMARY KEY (product_type_id, locale_id),
  CONSTRAINT "06a5c8bb-ce00-1c02-8c00-5112aa9b78a7" FOREIGN KEY (locale_id) REFERENCES locale (id),
  CONSTRAINT "06a5c8bb-ce00-1c64-8400-6e5d4f714999" FOREIGN KEY (product_type_id) REFERENCES product_type (id) ON DELETE CASCADE
);

CREATE TABLE product_option_value_translations (
  product_option_value_id BINARY(16) NOT NULL,
  locale_id BINARY(16) NOT NULL,
  name VARCHAR(63) NOT NULL,
  CONSTRAINT "06a5c8bb-ce00-1ec5-cc00-a4901ba0a9ce" PRIMARY KEY (product_option_value_id, locale_id),
  CONSTRAINT "06a5c8bb-ce00-1f30-2000-298a5fd53847" FOREIGN KEY (locale_id) REFERENCES locale (id),
  CONSTRAINT "06a5c8bb-ce00-1f93-0400-48cf3aaadafe" FOREIGN KEY (product_option_value_id) REFERENCES product_option_value (id) ON DELETE CASCADE
);

CREATE TABLE product_option_translations (
  product_option_id BINARY(16) NOT NULL,
  locale_id BINARY(16) NOT NULL,
  title VARCHAR(63) NOT NULL,
  CONSTRAINT "06a5c8bb-ce01-11f6-3800-403e5e3a7992" PRIMARY KEY (product_option_id, locale_id),
  CONSTRAINT "06a5c8bb-ce01-1261-c400-b9fe80e1b28d" FOREIGN KEY (product_option_id) REFERENCES product_option (id) ON DELETE CASCADE,
  CONSTRAINT "06a5c8bb-ce01-12c4-0000-ed381eda0bcb" FOREIGN KEY (locale_id) REFERENCES locale (id)
);

CREATE TABLE category_translations (
  category_id BINARY(16) NOT NULL,
  locale_id BINARY(16) NOT NULL,
  name VARCHAR(63),
  description BLOB SUB_TYPE TEXT,
  CONSTRAINT "06a5c8bb-ce01-15ce-ec00-b40ae6118b90" PRIMARY KEY (category_id, locale_id),
  CONSTRAINT "06a5c8bb-ce01-1639-1800-172aae384e12" FOREIGN KEY (category_id) REFERENCES category (id) ON DELETE CASCADE,
  CONSTRAINT "06a5c8bb-ce01-16a6-f000-5d1f518f91d7" FOREIGN KEY (locale_id) REFERENCES locale (id)
);

CREATE TABLE product_translations (
  product_id BINARY(16) NOT NULL,
  locale_id BINARY(16) NOT NULL,
  title VARCHAR(63),
  subtitle VARCHAR(191),
  description BLOB SUB_TYPE TEXT,
  CONSTRAINT "06a5c8bb-ce01-19c5-5800-6cd6e6b8f744" PRIMARY KEY (product_id, locale_id),
  CONSTRAINT "06a5c8bb-ce01-1a2f-c800-b43aad30a3f0" FOREIGN KEY (product_id) REFERENCES product (id) ON DELETE CASCADE,
  CONSTRAINT "06a5c8bb-ce01-1a9f-b800-0e7cdf0b96c4" FOREIGN KEY (locale_id) REFERENCES locale (id)
);

CREATE TABLE seo_translations (
  seo_id BINARY(16) NOT NULL,
  locale_id BINARY(16) NOT NULL,
  title VARCHAR(63),
  description VARCHAR(191),
  CONSTRAINT "06a5c8bb-ce01-1d6f-5c00-e59a8271502a" PRIMARY KEY (seo_id, locale_id),
  CONSTRAINT "06a5c8bb-ce01-1dd2-b000-27de495019e2" FOREIGN KEY (seo_id) REFERENCES seo (id) ON DELETE CASCADE,
  CONSTRAINT "06a5c8bb-ce01-1e30-dc00-ef7dd80ca811" FOREIGN KEY (locale_id) REFERENCES locale (id)
);
