CREATE TABLE currency (
  id BINARY(16),
  code CHAR(3), -- ISO 4217
  includes_tax BOOLEAN DEFAULT false NOT NULL,
  CONSTRAINT "06810e2b-d497-1b8d-0c00-05f3aef13f90" PRIMARY KEY (id),
  CONSTRAINT "06810e2b-d497-1bf0-5800-8856d5d0028b" UNIQUE (code)
);

CREATE TABLE image (
  id BINARY(16),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  deleted_at TIMESTAMP,
  url BLOB SUB_TYPE TEXT NOT NULL,
  CONSTRAINT "06810e2b-d498-132f-9c00-56abae358d4a" PRIMARY KEY (id)
);

CREATE TABLE product_collection (
  id BINARY(16),  
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  deleted_at TIMESTAMP,
  handle VARCHAR(63) NOT NULL,
  CONSTRAINT "06810e2b-d498-167f-4800-579fc213e01c" PRIMARY KEY (id)
);

CREATE UNIQUE INDEX "06810e2b-d498-1781-4800-31e96f3420ed" ON product_collection (handle) WHERE deleted_at IS NULL;

CREATE TABLE product_tag (
  id BINARY(16),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  deleted_at TIMESTAMP,
  CONSTRAINT "06810e2b-d498-19cb-5400-3ea67daf93dc" PRIMARY KEY (id)
);

CREATE TABLE product_type (
  id BINARY(16),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  deleted_at TIMESTAMP,
  CONSTRAINT "06810e2b-d498-1ca4-4800-27645d378a33" PRIMARY KEY (id),
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
  CONSTRAINT "06810e2b-d499-1282-4c00-e985ca6ef1f7" PRIMARY KEY (id),
  CONSTRAINT "06810e2b-d499-130c-3800-72c22c8d8ed2" CHECK (type IN ('sale', 'override')),
  CONSTRAINT "06810e2b-d499-1372-7800-71bb670af8ba" CHECK (status IN ('active', 'draft'))
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
  CONSTRAINT "06810e2b-d499-18f9-fc00-bf805bd3426f" PRIMARY KEY (id),
  CONSTRAINT "06810e2b-d499-1951-a000-f400ab7c3bd4" FOREIGN KEY (currency_code) REFERENCES currency (code),
  CONSTRAINT "06810e2b-d499-19a8-a400-0a4612517a41" FOREIGN KEY (price_list_id) REFERENCES price_list (id) ON DELETE CASCADE,
  CONSTRAINT "06810e2b-d499-1a01-8c00-2b858b2872be" FOREIGN KEY (variant_id) REFERENCES product_variant (id) ON DELETE CASCADE,
  CONSTRAINT "06810e2b-d499-1a62-5c00-e9b0c10e9f79" FOREIGN KEY (region_id) REFERENCES region (id)
);

CREATE INDEX "06810e2b-d499-1b90-6400-39343fe6f117" ON money_amount (currency_code);
CREATE INDEX "06810e2b-d49a-1306-8800-7d2f788ec5cd" ON money_amount (variant_id);
CREATE INDEX "06810e2b-d49a-139d-f800-8c5f502069da" ON money_amount (region_id);

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
  CONSTRAINT "06810e2b-d49a-1c4f-d800-49a33a1de20d" PRIMARY KEY (id),
  CONSTRAINT "06810e2b-d49a-1ca7-b000-3a9c5d447332" FOREIGN KEY (currency_code) REFERENCES currency (code)
);

CREATE INDEX "06810e2b-d49a-1daa-e000-bd506c329e81" ON region (currency_code);

CREATE TABLE country (
  id BINARY(16),
  code CHAR(2), -- ISO 3166-1 alpha 2
  region_id BINARY(16),
  CONSTRAINT "06810e2b-d49a-1fa2-ac00-4dd3a9584ec6" PRIMARY KEY (id),
  CONSTRAINT "06810e2b-d49b-1003-9400-06293f96c286" UNIQUE (code),
  CONSTRAINT "06810e2b-d49b-1059-c400-eb4c07ba4150" FOREIGN KEY (region_id) REFERENCES region (id)
);

CREATE INDEX "06810e2b-d49b-1159-3800-1f4a7adb163a" ON country (region_id);

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
  mid_code BLOB SUB_TYPE TEXT,
  collection_id BINARY(16),
  type_id BINARY(16),
  discountable BOOLEAN DEFAULT true NOT NULL,
  CONSTRAINT "06810e2b-d49b-182b-3800-34fcbe44332b" PRIMARY KEY (id),
  CONSTRAINT "06810e2b-d49b-1881-9000-1caa0a69bad9" CHECK (status IN ('draft', 'proposed', 'published', 'rejected')),
  CONSTRAINT "06810e2b-d49b-18dd-e000-6eca508e0689" FOREIGN KEY (origin_country) REFERENCES country (code),
  CONSTRAINT "06810e2b-d49b-193b-f400-6ac1542d6753" FOREIGN KEY (collection_id) REFERENCES product_collection (id),
  CONSTRAINT "06810e2b-d49b-1994-2400-a6da6eb1503b" FOREIGN KEY (type_id) REFERENCES product_type (id)
);

CREATE UNIQUE INDEX "06810e2b-d49b-1cdd-e400-3d6f64491062" ON product (handle) WHERE deleted_at IS NULL;

CREATE TABLE product_variant (
  id BINARY(16),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  deleted_at TIMESTAMP,
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
  CONSTRAINT "06810e2b-d49c-1546-8c00-31ae5e135c94" PRIMARY KEY (id),
  CONSTRAINT "06810e2b-d49c-15a1-2000-afa0631986bd" FOREIGN KEY (product_id) REFERENCES product (id),
  CONSTRAINT "06810e2b-d49c-15f9-6000-e3705993e198" FOREIGN KEY (origin_country) REFERENCES country (code)
);

CREATE INDEX "06810e2b-d49c-16f1-4c00-6ed9b1de9fbb" ON product_variant (product_id);
CREATE UNIQUE INDEX "06810e2b-d49c-174d-a400-539db5f7af60" ON product_variant (sku) WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX "06810e2b-d49c-17ab-4c00-8088095c486c" ON product_variant (barcode) WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX "06810e2b-d49c-1800-6400-9a4e5144a407" ON product_variant (ean) WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX "06810e2b-d49c-185d-f800-26b831dc42df" ON product_variant (upc) WHERE deleted_at IS NULL;

CREATE TABLE product_option (
  id BINARY(16),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  deleted_at TIMESTAMP,
  product_id BINARY(16) NOT NULL,
  CONSTRAINT "06810e2b-d49c-1c96-b000-21d2bbccc15f" PRIMARY KEY (id),
  CONSTRAINT "06810e2b-d49c-1d09-1400-a6521ed9ae50" FOREIGN KEY (product_id) REFERENCES product (id)
);

CREATE TABLE product_option_value (
  id BINARY(16),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  deleted_at TIMESTAMP,
  option_id BINARY(16) NOT NULL,
  variant_id BINARY(16) NOT NULL,
  CONSTRAINT "06810e2b-d49d-10dc-6400-3a4194c4ee73" PRIMARY KEY (id),
  CONSTRAINT "06810e2b-d49d-1134-f800-c1c0acc5adfd" FOREIGN KEY (option_id) REFERENCES product_option (id),
  CONSTRAINT "06810e2b-d49d-118e-0800-59771f23da28" FOREIGN KEY (variant_id) REFERENCES product_variant (id) ON DELETE CASCADE
);

CREATE INDEX "06810e2b-d49d-133a-c400-d1347139df4a" ON product_option_value (option_id);
CREATE INDEX "06810e2b-d49d-138f-2400-4f7d78290f8f" ON product_option_value (variant_id);

CREATE TABLE product_category (
  id BINARY(16),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  deleted_at TIMESTAMP,
  handle VARCHAR(63) NOT NULL,
  is_active BOOLEAN NOT NULL,
  is_internal BOOLEAN NOT NULL,
  parent_category_id BINARY(16) NOT NULL,
  CONSTRAINT "06810e2b-d49d-17b0-f800-2476d60ed641" PRIMARY KEY (id),
  CONSTRAINT "06810e2b-d49d-1805-c000-6c7381e93544" FOREIGN KEY (parent_category_id) REFERENCES product_category (id)
);

CREATE UNIQUE INDEX "06810e2b-d49d-18fd-9400-db64e3e26ec2" ON product_category (handle) WHERE deleted_at IS NULL;

CREATE TABLE tax_rate (
  id BINARY(16),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  deleted_at TIMESTAMP,
  rate REAL,
  code VARCHAR(63),
  name VARCHAR(63) NOT NULL,
  region_id BINARY(16) NOT NULL,
  CONSTRAINT "06810e2b-d49e-112b-c400-bab83635784b" PRIMARY KEY (id),
  CONSTRAINT "06810e2b-d49e-1181-e800-4eaaab7d8619" FOREIGN KEY (region_id) REFERENCES region (id)
);

CREATE TABLE product_tax_rate (
  product_id BINARY(16) NOT NULL,
  rate_id BINARY(16) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  deleted_at TIMESTAMP,
  CONSTRAINT "06810e2b-d49e-1482-cc00-924b74c48837" FOREIGN KEY (product_id) REFERENCES product (id) ON DELETE CASCADE,
  CONSTRAINT "06810e2b-d49e-14da-1800-1bf1fb4fa97a" FOREIGN KEY (rate_id) REFERENCES tax_rate (id) ON DELETE CASCADE,
  PRIMARY KEY (product_id, rate_id)
);

CREATE INDEX "06810e2b-d49e-162d-1c00-1ed12d83854a" ON product_tax_rate (rate_id);
CREATE INDEX "06810e2b-d49e-1680-6400-09ae43621985" ON product_tax_rate (product_id);

CREATE TABLE product_type_tax_rate (
  product_type_id BINARY(16) NOT NULL,
  rate_id BINARY(16) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  deleted_at TIMESTAMP,
  CONSTRAINT "06810e2b-d49e-192d-b000-f4a826524bb5" FOREIGN KEY (product_type_id) REFERENCES product_type (id) ON DELETE CASCADE,
  CONSTRAINT "06810e2b-d49e-199a-7000-d6584d9e20fe" FOREIGN KEY (rate_id) REFERENCES tax_rate (id) ON DELETE CASCADE,
  PRIMARY KEY (product_type_id, rate_id)
);

CREATE INDEX "06810e2b-d49e-1ae5-bc00-71397ff4410e" ON product_type_tax_rate (rate_id);
CREATE INDEX "06810e2b-d49e-1b40-2800-c17071bffe54" ON product_type_tax_rate (product_type_id);

CREATE TABLE locale (
  id BINARY(16),
  code VARCHAR(63),
  CONSTRAINT "06810e2b-d49e-1cd8-a000-e2bb7d6b9c35" PRIMARY KEY (id),
  CONSTRAINT "06810e2b-d49e-1d34-2c00-8d9745208a77" UNIQUE (code)
);

CREATE TABLE sales_channel (
  id BINARY(16),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  deleted_at TIMESTAMP,
  name VARCHAR(63) NOT NULL,
  description VARCHAR(191),
  is_disabled BOOLEAN DEFAULT false NOT NULL,
  CONSTRAINT "06810e2b-d49f-10ab-cc00-7f5fcb6c5853" PRIMARY KEY (id)
);

CREATE TABLE store (
  id BINARY(16),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  name VARCHAR(63) DEFAULT 'peony store' NOT NULL,
  default_locale_code VARCHAR(63) DEFAULT 'en' NOT NULL,
  default_currency_code CHAR(3) DEFAULT 'EUR' NOT NULL,
  default_stock_location_id BINARY(16),
  default_sales_channel_id BINARY(16),
  CONSTRAINT "06810e2b-d49f-14b3-0000-59ea9fa6813a" PRIMARY KEY (id),
  CONSTRAINT "06810e2b-d49f-1509-dc00-dfa818cc1c2e" UNIQUE (default_sales_channel_id),
  CONSTRAINT "06810e2b-d49f-1560-b400-c5bf9ada0657" FOREIGN KEY (default_locale_code) REFERENCES locale (code),
  CONSTRAINT "06810e2b-d49f-15b7-1400-56e1294c3574" FOREIGN KEY (default_currency_code) REFERENCES currency (code),
  CONSTRAINT "06810e2b-d49f-160b-8000-a2317268da7d" FOREIGN KEY (default_sales_channel_id) REFERENCES sales_channel (id)
);

CREATE TABLE product_category_product (
  product_category_id BINARY(16) NOT NULL,
  product_id BINARY(16) NOT NULL,
  CONSTRAINT "06810e2b-d49f-1807-7c00-73ee32273bc9" FOREIGN KEY (product_category_id) REFERENCES product_category (id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "06810e2b-d49f-18ae-c400-9023a6666e98" FOREIGN KEY (product_id) REFERENCES product (id) ON DELETE CASCADE ON UPDATE CASCADE,
  PRIMARY KEY (product_category_id, product_id)
);

CREATE INDEX "06810e2b-d49f-1a05-cc00-3e30021a9258" ON product_category_product (product_category_id);
CREATE INDEX "06810e2b-d49f-1a62-d400-4b67944f0f37" ON product_category_product (product_id);

CREATE TABLE product_images (
  product_id BINARY(16) NOT NULL,
  image_id BINARY(16) NOT NULL,
  CONSTRAINT "06810e2b-d49f-1c21-1c00-a2640457a59d" FOREIGN KEY (product_id) REFERENCES product (id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "06810e2b-d49f-1c7a-5000-b182b609733c" FOREIGN KEY (image_id) REFERENCES image (id) ON DELETE CASCADE ON UPDATE CASCADE,
  PRIMARY KEY (product_id, image_id)
);

CREATE INDEX "06810e2b-d49f-1dcc-a000-63e50878fae4" ON product_images (product_id);
CREATE INDEX "06810e2b-d49f-1e24-7400-2c936e3875e0" ON product_images (image_id);

CREATE TABLE product_tags (
  product_id BINARY(16) NOT NULL,
  product_tag_id BINARY(16) NOT NULL,
  CONSTRAINT "06810e2b-d49f-1fc1-f000-d298da2a30ca" FOREIGN KEY (product_id) REFERENCES product (id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "06810e2b-d4a0-101f-6800-386d59154124" FOREIGN KEY (product_tag_id) REFERENCES product_tag (id) ON DELETE CASCADE ON UPDATE CASCADE,
  PRIMARY KEY (product_id, product_tag_id)
);

CREATE INDEX "06810e2b-d4a0-116b-a800-b93f5421fb7d" ON product_tags (product_id);
CREATE INDEX "06810e2b-d4a0-11cd-a800-2df1fd5a8611" ON product_tags (product_tag_id);

CREATE TABLE product_sales_channel (
  product_id BINARY(16) NOT NULL,
  sales_channel_id BINARY(16) NOT NULL,
  CONSTRAINT "06810e2b-d4a0-137a-6c00-855f7ce42cc2" FOREIGN KEY (product_id) REFERENCES product (id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "06810e2b-d4a0-13d3-8000-113ab06cb23c" FOREIGN KEY (sales_channel_id) REFERENCES sales_channel (id) ON DELETE CASCADE ON UPDATE CASCADE,
  PRIMARY KEY (product_id, sales_channel_id)
);

CREATE INDEX "06810e2b-d4a0-151e-4000-68d1dcb727e6" ON product_sales_channel (product_id);
CREATE INDEX "06810e2b-d4a0-1572-f800-b3bd82d6c836" ON product_sales_channel (sales_channel_id);

CREATE TABLE store_currencies (
  store_id BINARY(16) NOT NULL,
  currency_code CHAR(3) NOT NULL,
  CONSTRAINT "06810e2b-d4a0-170e-f400-d5a719cf7dda" FOREIGN KEY (store_id) REFERENCES store (id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "06810e2b-d4a0-176a-f800-aab21ae2bbfa" FOREIGN KEY (currency_code) REFERENCES currency (code) ON DELETE CASCADE ON UPDATE CASCADE,
  PRIMARY KEY (store_id, currency_code)
);

CREATE INDEX "06810e2b-d4a0-18ad-6800-56542bb9b180" ON store_currencies (store_id);
CREATE INDEX "06810e2b-d4a0-1904-6c00-62a647589d3c" ON store_currencies (currency_code);

CREATE TABLE store_locales (
  store_id BINARY(16) NOT NULL,
  locale_code VARCHAR(63) NOT NULL,
  PRIMARY KEY (store_id, locale_code),
  CONSTRAINT "06810e2b-d4a0-1afb-4c00-7e535b7f1af7" FOREIGN KEY (store_id) REFERENCES store (id) ON DELETE CASCADE,
  CONSTRAINT "06810e2b-d4a0-1b50-3000-da40cd75e9ff" FOREIGN KEY (locale_code) REFERENCES locale (code)
);

CREATE TABLE product_tag_translations (
  product_tag_id BINARY(16) NOT NULL,
  locale_code VARCHAR(63) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  deleted_at TIMESTAMP,
  name VARCHAR(63) NOT NULL,
  CONSTRAINT "06810e2b-d4a0-1f27-5800-2eeee685d5cc" FOREIGN KEY (locale_code) REFERENCES locale (code),
  CONSTRAINT "06810e2b-d4a0-1f7c-7400-e05fa144e9d9" FOREIGN KEY (product_tag_id) REFERENCES product_tag (id) ON DELETE CASCADE,
  PRIMARY KEY (product_tag_id, locale_code)
);

CREATE TABLE product_type_translations (
  product_type_id BINARY(16) NOT NULL,
  locale_code VARCHAR(63) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  deleted_at TIMESTAMP,
  name VARCHAR(63),
  CONSTRAINT "06810e2b-d4a1-146c-4000-0322c6f16e2c" FOREIGN KEY (locale_code) REFERENCES locale (code),
  CONSTRAINT "06810e2b-d4a1-14bf-ec00-7a76d2f637b9" FOREIGN KEY (product_type_id) REFERENCES product_type (id) ON DELETE CASCADE,
  PRIMARY KEY (product_type_id, locale_code)
);

CREATE TABLE product_variant_translations (
  product_variant_id BINARY(16) NOT NULL,
  locale_code VARCHAR(63) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  deleted_at TIMESTAMP,
  title VARCHAR(63),
  CONSTRAINT "06810e2b-d4a1-18c3-0800-99f7d3b5c1b9" FOREIGN KEY (locale_code) REFERENCES locale (code),
  CONSTRAINT "06810e2b-d4a1-194b-f800-b75fa5a286b5" FOREIGN KEY (product_variant_id) REFERENCES product_variant (id) ON DELETE CASCADE,
  PRIMARY KEY (product_variant_id, locale_code)
);

CREATE TABLE product_option_value_translations (
  product_option_value_id BINARY(16) NOT NULL,
  locale_code VARCHAR(63) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  deleted_at TIMESTAMP,
  name VARCHAR(63),
  CONSTRAINT "06810e2b-d4a1-1d63-3800-d2a1b60ea175" FOREIGN KEY (locale_code) REFERENCES locale (code),
  CONSTRAINT "06810e2b-d4a1-1dbb-2000-0e02e9be85e8" FOREIGN KEY (product_option_value_id) REFERENCES product_option_value (id) ON DELETE CASCADE,
  PRIMARY KEY (product_option_value_id, locale_code)
);

CREATE TABLE product_option_translations (
  product_option_id BINARY(16) NOT NULL,
  locale_code VARCHAR(63) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  deleted_at TIMESTAMP,
  title VARCHAR(63),
  CONSTRAINT "06810e2b-d4a2-15b7-8000-64680eb2f4f1" FOREIGN KEY (product_option_id) REFERENCES product_option (id) ON DELETE CASCADE,
  CONSTRAINT "06810e2b-d4a2-1615-6400-33b3085e48b0" FOREIGN KEY (locale_code) REFERENCES locale (code),
  PRIMARY KEY (product_option_id, locale_code)
);

CREATE TABLE product_category_translations (
  product_category_id BINARY(16) NOT NULL,
  locale_code VARCHAR(63) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  deleted_at TIMESTAMP,
  name VARCHAR(63),
  CONSTRAINT "06810e2b-d4a2-1a10-e400-9449adae8f8b" FOREIGN KEY (product_category_id) REFERENCES product_category (id) ON DELETE CASCADE,
  CONSTRAINT "06810e2b-d4a2-1a69-3800-09ad7710ab34" FOREIGN KEY (locale_code) REFERENCES locale (code),
  PRIMARY KEY (product_category_id, locale_code)
);

CREATE TABLE product_translations (
  product_id BINARY(16) NOT NULL,
  locale_code VARCHAR(63) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  deleted_at TIMESTAMP,
  title VARCHAR(63),
  subtitle VARCHAR(191),
  description BLOB SUB_TYPE TEXT,
  CONSTRAINT "06810e2b-d4a2-1f00-3800-27ab93a88179" FOREIGN KEY (product_id) REFERENCES product (id) ON DELETE CASCADE,
  CONSTRAINT "06810e2b-d4a2-1f58-c000-7c5702b7795a" FOREIGN KEY (locale_code) REFERENCES locale (code),
  PRIMARY KEY (product_id, locale_code)
);

CREATE TABLE product_collection_translations (
  product_collection_id BINARY(16) NOT NULL,
  locale_code VARCHAR(63) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  deleted_at TIMESTAMP,
  title VARCHAR(63) NOT NULL,
  CONSTRAINT "06810e2b-d4a3-1346-0800-376492a82411" FOREIGN KEY (product_collection_id) REFERENCES product_collection (id) ON DELETE CASCADE,
  CONSTRAINT "06810e2b-d4a3-13a4-6800-0775cd18724e" FOREIGN KEY (locale_code) REFERENCES locale (code),
  PRIMARY KEY (product_collection_id, locale_code)
);
