CREATE TABLE currency (
  id BINARY(16),
  code CHAR(3), -- ISO 4217
  includes_tax BOOLEAN DEFAULT false NOT NULL,
  CONSTRAINT 06810d74-ce91-1f14-8000-d3ea466daa98 PRIMARY KEY (id)
  CONSTRAINT 06810d74-ce91-1f6e-8000-6462f31a00a7 UNIQUE (code)
);

CREATE TABLE image (
  id BINARY(16),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  deleted_at TIMESTAMP,
  url BLOB SUB_TYPE TEXT NOT NULL,
  CONSTRAINT 06810d74-ce92-131d-4800-98d2c20b2e51 PRIMARY KEY (id)
);

CREATE TABLE product_collection (
  id BINARY(16),  
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  deleted_at TIMESTAMP,
  title VARCHAR(63) NOT NULL,
  handle VARCHAR(63) NOT NULL,
  CONSTRAINT 06810d74-ce92-1aec-3400-ec39d822ef39 PRIMARY KEY (id)
);

CREATE UNIQUE INDEX 06810d74-ce92-1bda-5000-a1495dc92bce ON product_collection WHERE deleted_at IS NULL;

CREATE TABLE product_tag (
  id BINARY(16),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  deleted_at TIMESTAMP,
  CONSTRAINT 06810d74-ce92-1e3d-8400-cb0e3826430d PRIMARY KEY (id),
  name VARCHAR(63) NOT NULL
);

CREATE TABLE product_type (
  id BINARY(16),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  deleted_at TIMESTAMP,
  CONSTRAINT 06810d74-ce93-111b-e000-821f7a50aec9 PRIMARY KEY (id),
  name VARCHAR(63) NOT NULL
);

CREATE TABLE price_list (
  id BINARY(16),
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
  CONSTRAINT 06810d74-ce93-163d-8800-a027d2245afb PRIMARY KEY (id),
  CONSTRAINT 06810d74-ce93-1691-8c00-2af23537f914 CHECK (type IN ('sale', 'override')),
  CONSTRAINT 06810d74-ce93-1784-3800-2276e26a8d9f CHECK (status IN ('active', 'draft'))
);

CREATE TABLE money_amount (
  id BINARY(16),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  deleted_at TIMESTAMP,
  currency_code CHAR(3) NOT NULL,
  amount INTEGER NOT NULL,
  min_quantity INTEGER,
  max_quantity INTEGER,
  price_list_id BINARY(16),
  variant_id BINARY(16),
  region_id BINARY(16),
  CONSTRAINT 06810d74-ce93-1cc7-6800-6c3d12dfcebf PRIMARY KEY (id),
  CONSTRAINT 06810d74-ce93-1d19-5400-0954a802110f FOREIGN KEY (currency_code) REFERENCES currency (code),
  CONSTRAINT 06810d74-ce93-1d6c-7c00-f376c3d8b9fb FOREIGN KEY (price_list_id) REFERENCES price_list (id) ON DELETE CASCADE,
  CONSTRAINT 06810d74-ce93-1dc5-2c00-71e17cdc565a FOREIGN KEY (variant_id) REFERENCES product_variant (id) ON DELETE CASCADE,
  CONSTRAINT 06810d74-ce93-1e19-ac00-671dff597e36 FOREIGN KEY (region_id) REFERENCES region (id)
);

CREATE INDEX 06810d74-ce93-1f21-9c00-3e08c1fa94fb ON money_amount (currency_code);
CREATE INDEX 06810d74-ce93-1f95-8c00-d41d039c3427 ON money_amount (variant_id);
CREATE INDEX 06810d74-ce94-1003-c400-c143fa0dfa47 ON money_amount (region_id);

CREATE TABLE product_variant (
  id BINARY(16),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  deleted_at TIMESTAMP,
  title VARCHAR(63) NOT NULL,
  product_id BINARY(16) NOT NULL,
  sku VARCHAR(63),
  barcode VARCHAR(63),
  ean VARCHAR(13),
  upc VARCHAR(12),
  variant_rank INTEGER DEFAULT 0,
  inventory_quantity INTEGER NOT NULL,
  allow_backorder BOOLEAN DEFAULT false NOT NULL,
  manage_inventory BOOLEAN DEFAULT true NOT NULL,
  hs_code VARCHAR(63),
  origin_country CHAR(2),
  mid_code VARCHAR(63),
  weight INTEGER,
  length INTEGER,
  height INTEGER,
  width INTEGER,
  CONSTRAINT 06810d74-ce94-1c68-e800-dc1268609836 PRIMARY KEY (id),
  CONSTRAINT 06810d74-ce94-1ccb-8800-c397c8b396b9 FOREIGN KEY (product_id) REFERENCES product (id),
  CONSTRAINT 06810d74-ce94-1d80-6c00-b5943daa730a FOREIGN KEY (origin_country) REFERENCES country (code)
);

CREATE INDEX 06810d74-ce94-1e98-1000-3ffcd218360e ON product_variant (product_id);
CREATE UNIQUE INDEX 06810d74-ce94-1ef5-e800-72f770c6002a product_variant (sku) WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX 06810d74-ce94-1f4b-1000-c9ce74188301 product_variant (barcode) WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX 06810d74-ce94-1fa3-ac00-c8a60dc391da product_variant (ean) WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX 06810d74-ce95-1002-5400-42fbbee35a66 product_variant (upc) WHERE deleted_at IS NULL;

CREATE TABLE product_option (
  id BINARY(16),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  deleted_at TIMESTAMP,
  product_id BINARY(16) NOT NULL,
  title VARCHAR(63) NOT NULL,
  CONSTRAINT 06810d74-ce95-12dc-fc00-5f8a996b1b26 PRIMARY KEY (id),
  CONSTRAINT 06810d74-ce95-1338-9400-91094de0a14d FOREIGN KEY (product_id) REFERENCES product (id)
);

CREATE TABLE product_option_value (
  id BINARY(16),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  deleted_at TIMESTAMP,
  name VARCHAR(63) NOT NULL,
  option_id BINARY(16) NOT NULL,
  variant_id BINARY(16) NOT NULL,
  CONSTRAINT 06810d74-ce95-16d8-f400-f22933e7f0a6 PRIMARY KEY (id),
  CONSTRAINT 06810d74-ce95-172a-9400-e08b1c0725f2 FOREIGN KEY (option_id) REFERENCES product_option (id),
  CONSTRAINT 06810d74-ce95-1783-3c00-97fb5c59e2a0 FOREIGN KEY (variant_id) REFERENCES product_variant (id) ON DELETE CASCADE
);

CREATE INDEX 06810d74-ce95-187b-3000-f9dbfbad4f0c ON product_option_value (option_id);
CREATE INDEX 06810d74-ce95-18d1-d800-cf9d882e76a8 ON product_option_value (variant_id);

CREATE TABLE product_category (
  id BINARY(16),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  deleted_at TIMESTAMP,
  name VARCHAR(63) NOT NULL,
  handle VARCHAR(63) NOT NULL,
  is_active BOOLEAN NOT NULL,
  is_internal BOOLEAN NOT NULL,
  parent_category_id BINARY(16) NOT NULL,
  CONSTRAINT 06810d74-ce95-1cab-0c00-7c8ccefc849e PRIMARY KEY (id),
  CONSTRAINT 06810d74-ce95-1e74-d000-5096e2090e4c FOREIGN KEY (parent_category_id) REFERENCES product_category (id)
);

CREATE UNIQUE INDEX 06810d74-ce95-1feb-1000-d8a172ff7061 product_category (handle) WHERE deleted_at IS NULL;

CREATE TABLE product (
  id BINARY(16),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  deleted_at TIMESTAMP,
  handle VARCHAR(63) NOT NULL,
  is_giftcard BOOLEAN DEFAULT false NOT NULL,
  status VARCHAR(9) DEFAULT 'draft' NOT NULL,
  thumbnail BLOB SUB_TYPE TEXT,
  weight INTEGER,
  length INTEGER,
  height INTEGER,
  width INTEGER,
  hs_code varchar(63),
  origin_country char(2),
  mid_code text,
  collection_id BINARY(16),
  type_id BINARY(16),
  discountable BOOLEAN DEFAULT true NOT NULL,
  CONSTRAINT 06810d74-ce96-16e3-6000-b8b5e8af2b85 PRIMARY KEY (id),
  CONSTRAINT 06810d74-ce96-1733-7800-b8a41f098e5c CHECK (status IN ('draft', 'proposed', 'published', 'rejected')),
  CONSTRAINT 06810d74-ce96-178c-b000-071484f76155 FOREIGN KEY (origin_country) REFERENCES country (code),
  CONSTRAINT 06810d74-ce96-17e4-5000-88218d9c04a6 FOREIGN KEY (collection_id) REFERENCES product_collection (id),
  CONSTRAINT 06810d74-ce96-183f-b800-d78fd7a22231 FOREIGN KEY (type_id) REFERENCES product_type (id)
);

CREATE INDEX 06810d74-ce96-1931-a000-9927db4fa5ce ON product (profile_id);
CREATE UNIQUE INDEX 06810d74-ce96-1981-d000-d2e274545680 product (handle) WHERE deleted_at IS NULL;

CREATE TABLE country (
  id BINARY(16),
  code CHAR(2), -- ISO 3166-1 alpha 2
  region_id BINARY(16),
  CONSTRAINT 06810d74-ce96-1c64-bc00-1a61bebe977b PRIMARY KEY (id),
  CONSTRAINT 06810d74-ce96-1cb9-c800-c76fd5aae568 UNIQUE (code),
  CONSTRAINT 06810d74-ce96-1d13-ac00-fc356a1c6806 FOREIGN KEY (region_id) REFERENCES region (id)
);

CREATE INDEX 06810d74-ce96-1ec6-fc00-de2a465b3678 ON country (region_id);

CREATE TABLE region (
  id BINARY(16),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  deleted_at TIMESTAMP,
  name VARCHAR(63) NOT NULL,
  currency_code CHAR(3) NOT NULL,
  tax_rate REAL NOT NULL,
  tax_code VARCHAR(63),
  includes_tax BOOLEAN DEFAULT false NOT NULL,
  gift_cards_taxable BOOLEAN DEFAULT true NOT NULL,
  automatic_taxes BOOLEAN DEFAULT true NOT NULL,
  CONSTRAINT 06810d74-ce97-13af-e400-025eb0f57dc4 PRIMARY KEY (id),
  CONSTRAINT 06810d74-ce97-1425-a000-dc6946799be1 FOREIGN KEY (currency_code) REFERENCES currency (code),
  CONSTRAINT 06810d74-ce97-147e-0000-3ee6678fb3aa FOREIGN KEY (tax_provider_id) REFERENCES tax_provider (id)
  );

CREATE INDEX 06810d74-ce97-1589-5800-674119ecf74e ON region (currency_code);

CREATE TABLE tax_rate (
  id BINARY(16),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  deleted_at TIMESTAMP,
  rate REAL,
  code VARCHAR(63),
  name VARCHAR(63) NOT NULL,
  region_id BINARY(16) NOT NULL,
  CONSTRAINT 06810d74-ce97-1922-2400-5f43d1e66d99 PRIMARY KEY (id),
  CONSTRAINT 06810d74-ce97-1977-b000-f048fa424c2e FOREIGN KEY (region_id) REFERENCES region (id)
);

CREATE TABLE product_tax_rate (
  product_id BINARY(16) NOT NULL,
  rate_id BINARY(16) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  deleted_at TIMESTAMP,
  CONSTRAINT 06810d74-ce98-1121-c000-248e9d07f0e0 FOREIGN KEY (product_id) REFERENCES product (id) ON DELETE CASCADE,
  CONSTRAINT 06810d74-ce98-117d-ec00-84ad2a988589 FOREIGN KEY (rate_id) REFERENCES tax_rate (id) ON DELETE CASCADE,
  PRIMARY KEY (product_id, rate_id)
);

CREATE INDEX 06810d74-ce98-12cf-6400-f86e55783d5d ON product_tax_rate (rate_id);
CREATE INDEX 06810d74-ce98-1324-5400-84d86033aca6 ON product_tax_rate (product_id);

CREATE TABLE product_type_tax_rate (
  product_type_id BINARY(16) NOT NULL,
  rate_id BINARY(16) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  deleted_at TIMESTAMP,
  CONSTRAINT 06810d74-ce98-15e4-7000-860b0a9fa3d4 FOREIGN KEY (product_type_id) REFERENCES product_type (id) ON DELETE CASCADE,
  CONSTRAINT 06810d74-ce98-1643-b000-6c3c7c21137d FOREIGN KEY (rate_id) REFERENCES tax_rate (id) ON DELETE CASCADE,
  PRIMARY KEY (product_type_id, rate_id)
);

CREATE INDEX 06810d74-ce98-1796-5400-957b88beaf94 ON product_type_tax_rate (rate_id);
CREATE INDEX 06810d74-ce98-17f0-8800-9e5fe68466f8 ON product_type_tax_rate (product_type_id);

CREATE TABLE store (
  id BINARY(16),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  name VARCHAR(63) DEFAULT 'peony store' NOT NULL,
  default_locale_code VARCHAR(63) NOT NULL DEFAULT 'en',
  default_currency_code CHAR(3) NOT NULL DEFAULT 'EUR',
  default_stock_location_id BINARY(16),
  default_sales_channel_id BINARY(16),
  CONSTRAINT 06810d74-ce98-1bbd-f800-cfdc0d46c5a9 PRIMARY KEY (id),
  CONSTRAINT 06810d74-ce98-1c1d-2400-d11ab2a5fa33 UNIQUE (default_sales_channel_id),
  CONSTRAINT 06810d74-ce98-1c7d-0800-cc0a892cbfaa FOREIGN KEY (default_locale_code) REFERENCES locale (code),
  CONSTRAINT 06810d74-ce98-1cd5-1000-4a67e8462599 FOREIGN KEY (default_currency_code) REFERENCES currency (code),
  CONSTRAINT 06810d74-ce98-1d36-f400-a45aca9fea63 FOREIGN KEY (default_sales_channel_id) REFERENCES sales_channel (id)
);

CREATE TABLE product_category_product (
  product_category_id BINARY(16) NOT NULL,
  product_id BINARY(16) NOT NULL,
  CONSTRAINT 06810d74-ce98-1f46-2000-572e34961b7a FOREIGN KEY (product_category_id) REFERENCES product_category (id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT 06810d74-ce98-1ff6-b400-d3245d9b2db2 FOREIGN KEY (product_id) REFERENCES product (id) ON DELETE CASCADE ON UPDATE CASCADE,
  PRIMARY KEY (product_category_id, product_id)
);

CREATE INDEX 06810d74-ce99-1157-c000-2088fabf844a ON product_category_product (product_category_id);
CREATE INDEX 06810d74-ce99-11ad-c800-0a80eb8f3a71 ON product_category_product (product_id);

CREATE TABLE product_images (
  product_id BINARY(16) NOT NULL,
  image_id BINARY(16) NOT NULL,
  CONSTRAINT 06810d74-ce99-1356-a400-746625c02b1f FOREIGN KEY (product_id) REFERENCES product (id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT 06810d74-ce99-13af-ac00-2dc122409227 FOREIGN KEY (image_id) REFERENCES image (id) ON DELETE CASCADE ON UPDATE CASCADE,
  PRIMARY KEY (product_id, image_id)
);

CREATE INDEX 06810d74-ce99-14ea-5800-193e4494fe0d ON product_images (product_id);
CREATE INDEX 06810d74-ce99-153f-cc00-9fe09de6e698 ON product_images (image_id);

CREATE TABLE product_tags (
  product_id BINARY(16) NOT NULL,
  product_tag_id BINARY(16) NOT NULL,
  CONSTRAINT 06810d74-ce99-16e0-8800-3b877502ac29 FOREIGN KEY (product_id) REFERENCES product (id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT 06810d74-ce99-1735-1000-ef7e3cdea996 FOREIGN KEY (product_tag_id) REFERENCES product_tag (id) ON DELETE CASCADE ON UPDATE CASCADE,
  PRIMARY KEY (product_id, product_tag_id)
);

CREATE INDEX 06810d74-ce99-1891-5000-d1b34728794e ON product_tags (product_id);
CREATE INDEX 06810d74-ce99-18de-4800-009a2a5c7d30 ON product_tags (product_tag_id);

CREATE TABLE product_sales_channel (
  product_id BINARY(16) NOT NULL,
  sales_channel_id BINARY(16) NOT NULL,
  CONSTRAINT 06810d74-ce99-1b23-c800-0fda13cebea9 FOREIGN KEY (product_id) REFERENCES product (id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT 06810d74-ce99-1b7b-1000-dec45054b36e FOREIGN KEY (sales_channel_id) REFERENCES sales_channel (id) ON DELETE CASCADE ON UPDATE CASCADE,
  PRIMARY KEY (product_id, sales_channel_id)
);

CREATE INDEX 06810d74-ce99-1cc5-1000-f5955ecc363d ON product_sales_channel (product_id);
CREATE INDEX 06810d74-ce99-1d23-f000-346c592f0854 ON product_sales_channel (sales_channel_id);

CREATE TABLE store_currencies (
  store_id BINARY(16) NOT NULL,
  currency_code CHAR(3) NOT NULL,
  CONSTRAINT 06810d74-ce99-1eba-9c00-8e5accfb9a0b FOREIGN KEY (store_id) REFERENCES store (id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT 06810d74-ce99-1f18-1800-aa18dda77e83 FOREIGN KEY (currency_code) REFERENCES currency (code) ON DELETE CASCADE ON UPDATE CASCADE,
  PRIMARY KEY (store_id, currency_code)
);

CREATE INDEX 06810d74-ce9a-105d-6800-dd2d63f3294c ON store_currencies (store_id);
CREATE INDEX 06810d74-ce9a-10b6-c800-174911ea0b7e ON store_currencies (currency_code);

CREATE TABLE locale (
  id BINARY(16),
  code VARCHAR(63),
  CONSTRAINT 06810d74-ce9a-1241-f000-0052d3e668d7 PRIMARY KEY (id),
  CONSTRAINT 06810d74-ce9a-1298-1400-69e85890b08b UNIQUE (code)
);

CREATE TABLE store_locales (
  store_id BINARY(16) NOT NULL,
  locale_code VARCHAR(63) NOT NULL,
  PRIMARY KEY (store_id, locale_code),
  CONSTRAINT 06810d74-ce9a-14df-9c00-803740ab57ca FOREIGN KEY (store_id) REFERENCES store (id) ON DELETE CASCADE,
  CONSTRAINT 06810d74-ce9a-1534-c000-9f53d40b28a2 FOREIGN KEY (locale_code) REFERENCES locale (code)
);

CREATE TABLE product_tag_translations (
  product_tag_id BINARY(16) NOT NULL,
  locale_code VARCHAR(63) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  deleted_at TIMESTAMP,
  name VARCHAR(63) NOT NULL,
  CONSTRAINT 06810d74-ce9a-185d-0400-14ab49c19d11 FOREIGN KEY (locale_code) REFERENCES locale (code),
  CONSTRAINT 06810d74-ce9a-18b3-fc00-50b0b0538206 FOREIGN KEY (product_tag_id) REFERENCES product_tag (id) ON DELETE CASCADE,
  PRIMARY KEY (product_tag_id, locale_code)
);

CREATE TABLE product_type_translations (
  product_type_id BINARY(16),
  locale_code VARCHAR(63) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  deleted_at TIMESTAMP,
  name VARCHAR(63),
  CONSTRAINT 06810d74-ce9a-1c3c-5800-d08d3a623411 FOREIGN KEY (locale_code) REFERENCES locale (code),
  CONSTRAINT 06810d74-ce9a-1c8e-2c00-46580f793768 FOREIGN KEY (product_type_id) REFERENCES product_type (id) ON DELETE CASCADE,
  PRIMARY KEY (product_type_id, locale_code)
);

CREATE TABLE product_variant_translations (
  product_variant_id BINARY(16),
  locale_code VARCHAR(63) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  deleted_at TIMESTAMP,
  title VARCHAR(63),
  CONSTRAINT 06810d74-ce9b-123d-2400-562986b360b9 FOREIGN KEY (locale_code) REFERENCES locale (code),
  CONSTRAINT 06810d74-ce9b-1292-9800-466cffac81d5 FOREIGN KEY (product_variant_id) REFERENCES product_variant (id) ON DELETE CASCADE,
  PRIMARY KEY (product_variant_id, locale_code)
);

CREATE TABLE product_option_value_translations (
  product_option_value_id BINARY(16),
  locale_code VARCHAR(63) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  deleted_at TIMESTAMP,
  name VARCHAR(63),
  CONSTRAINT 06810d74-ce9b-1630-4400-cb2bc4c9277b FOREIGN KEY (locale_code) REFERENCES locale (code),
  CONSTRAINT 06810d74-ce9b-16be-b800-f16bfb807d8c FOREIGN KEY (product_option_value_id) REFERENCES product_option_value (id) ON DELETE CASCADE,
  PRIMARY KEY (product_option_value_id, locale_code)
);

CREATE TABLE product_option_translations (
  product_option_id BINARY(16),
  locale_code VARCHAR(63) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  deleted_at TIMESTAMP,
  title VARCHAR(63),
  CONSTRAINT 06810d74-ce9b-1a92-e400-ee7d522d47f0 FOREIGN KEY (product_option_id) REFERENCES product_option (id) ON DELETE CASCADE,
  CONSTRAINT 06810d74-ce9b-1af0-5400-8f84e5db3663 FOREIGN KEY (locale_code) REFERENCES locale (code),
  PRIMARY KEY (product_option_id, locale_code)
);

CREATE TABLE product_category_translations (
  product_category_id BINARY(16),
  locale_code VARCHAR(63) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  deleted_at TIMESTAMP,
  name VARCHAR(63),
  handle VARCHAR(63),
  CONSTRAINT 06810d74-ce9b-1f42-1400-3d827de0fd96 FOREIGN KEY (product_category_id) REFERENCES product_category (id) ON DELETE CASCADE,
  CONSTRAINT 06810d74-ce9b-1f93-7000-e489bde6433e FOREIGN KEY (locale_code) REFERENCES locale (code),
  PRIMARY KEY (product_category_id, locale_code)
);

CREATE TABLE product_translations (
  product_id BINARY(16),
  locale_code VARCHAR(63) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  deleted_at TIMESTAMP,
  title VARCHAR(63),
  subtitle VARCHAR(191),
  description BLOB SUB_TYPE TEXT,
  handle VARCHAR(63),
  CONSTRAINT 06810d74-ce9c-149d-0000-4c1be8b2f660 FOREIGN KEY (product_id) REFERENCES product (id) ON DELETE CASCADE,
  CONSTRAINT 06810d74-ce9c-14f5-4400-08a0bed1ba1c FOREIGN KEY (locale_code) REFERENCES locale (code),
  PRIMARY KEY (product_id, locale_code)
);

CREATE TABLE product_collection_translations (
  product_collection_id BINARY(16),
  locale_code VARCHAR(63) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  deleted_at TIMESTAMP,
  title VARCHAR(63) NOT NULL,
  handle VARCHAR(63),
  CONSTRAINT 06810d74-ce9c-1911-0800-12cd96b45c51 FOREIGN KEY (product_collection_id) REFERENCES product_collection (id) ON DELETE CASCADE,
  CONSTRAINT 06810d74-ce9c-1967-7000-bbcf5f4b97c5 FOREIGN KEY (locale_code) REFERENCES locale (code),
  PRIMARY KEY (product_collection_id, locale_code)
);
