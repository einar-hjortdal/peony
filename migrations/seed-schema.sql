CREATE TABLE migration (
  id BINARY(16) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  name VARCHAR(191) NOT NULL,
  CONSTRAINT "06828532-0de2-15f4-6c00-263bdaf3d865" PRIMARY KEY (id)
);

CREATE TABLE image (
  id BINARY(16) NOT NULL,
  url BLOB SUB_TYPE TEXT NOT NULL,
  alt VARCHAR(191),
  CONSTRAINT "0681493b-ad7e-1eed-6400-452ff1dfa613" PRIMARY KEY (id)
);

CREATE TABLE app_user (
  id BINARY(16) NOT NULL,
  handle VARCHAR(63) NOT NULL,
  email VARCHAR(254), -- IETF RFC 3696 Errata 1690
  password_hash BINARY(64) NOT NULL,
  password_salt BINARY(32) NOT NULL,
  role VARCHAR(11) DEFAULT 'member' NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  deleted_at TIMESTAMP,
  first_name VARCHAR(63),
  last_name VARCHAR(63),
  image_id BINARY(16),
  metadata BLOB SUB_TYPE TEXT,
  CONSTRAINT "0681493b-ad7e-15e0-f000-68e91e4d68b9" PRIMARY KEY (id),
  CONSTRAINT "0681493b-ad7e-163b-a800-88be23fc406a" CHECK ( role IN (
    'admin', 'member', 'developer', 'author', 'contributor')
  ),
  CONSTRAINT "0686cd40-3323-15dc-7000-c90d894e0798" FOREIGN KEY (image_id) REFERENCES image (id) ON DELETE SET NULL
);

CREATE UNIQUE INDEX "0681493b-ad7e-17e0-d000-774707c2de94" ON app_user (email) WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX "0681493b-ad7e-1834-9000-63304927463c" ON app_user (handle) WHERE deleted_at IS NULL;

CREATE TABLE currency (
  code CHAR(3) NOT NULL, -- ISO 4217
  decimal_digits INTEGER,
  CONSTRAINT "0681493b-ad7e-1a2b-8c00-0137fed805b7" PRIMARY KEY (code)
);

CREATE TABLE product_tag (
  id BINARY(16) NOT NULL,
  name VARCHAR(63) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  deleted_at TIMESTAMP,
  metadata BLOB SUB_TYPE TEXT,
  CONSTRAINT "0681493b-ad7f-1495-c400-531833208d23" PRIMARY KEY (id)
);

CREATE TABLE product_type (
  id BINARY(16) NOT NULL,
  name VARCHAR(63) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  deleted_at TIMESTAMP,
  metadata BLOB SUB_TYPE TEXT,
  CONSTRAINT "0681493b-ad7f-17e9-bc00-194e2c0426e8" PRIMARY KEY (id)
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
  CONSTRAINT "0681493b-ad7f-1c9b-6800-2fb702056fd7" PRIMARY KEY (id),
  CONSTRAINT "0681493b-ad7f-1ce9-6000-dcd762d94261" CHECK (type IN ('sale', 'override')),
  CONSTRAINT "0681493b-ad7f-1d3f-7c00-3cd53eb56cd7" CHECK (status IN ('active', 'draft'))
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
  CONSTRAINT "0681493b-ad84-100d-bc00-4f51f22e5a5a" PRIMARY KEY (id),
  CONSTRAINT "0686cd40-331d-13a4-2c00-4de2e11c5727" CHECK ( type IN (
    'additive', 'substitutive', 'compounding')
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
  CONSTRAINT "0681493b-ad81-10a7-d400-0d56ed1ab15f" PRIMARY KEY (id),
  CONSTRAINT "0681493b-ad81-10f8-4400-6255d70d2b5e" FOREIGN KEY (currency_code) REFERENCES currency (code)
);

CREATE INDEX "0681493b-ad81-11dd-0400-431cb8290aa0" ON region (currency_code);

CREATE TABLE region_tax_rate (
  region_id BINARY(16) NOT NULL,
  rate_id BINARY(16) NOT NULL,
  CONSTRAINT "06828532-0de7-1429-c800-a3171778c855" PRIMARY KEY (region_id, rate_id),
  CONSTRAINT "06828532-0de7-178a-5000-ed338e5504c2" FOREIGN KEY (region_id) REFERENCES region (id) ON DELETE CASCADE,
  CONSTRAINT "06828532-0de7-17db-0c00-d8402bcebe5a" FOREIGN KEY (rate_id) REFERENCES tax_rate (id) ON DELETE CASCADE
);

CREATE INDEX "0681493b-ad84-1513-fc00-1e18e707389e" ON region_tax_rate (rate_id);

CREATE TABLE money_amount (
  id BINARY(16) NOT NULL,
  amount INTEGER NOT NULL,
  region_id BINARY(16) NOT NULL,
  is_original BOOLEAN DEFAULT false NOT NULL,
  min_quantity INTEGER,
  max_quantity INTEGER,
  price_list_id BINARY(16),
  CONSTRAINT "0681493b-ad80-1816-4c00-b3057a12449b" PRIMARY KEY (id),
  CONSTRAINT "0681493b-ad80-1965-9c00-560c42556079" FOREIGN KEY (region_id) REFERENCES region (id) ON DELETE CASCADE,
  CONSTRAINT "0681493b-ad80-18c0-f800-29cd93ab1246" FOREIGN KEY (price_list_id) REFERENCES price_list (id) ON DELETE CASCADE
);

CREATE INDEX "0681493b-ad80-1c69-7800-8a18dd634104" ON money_amount (region_id);

CREATE TABLE country (
  code CHAR(2) NOT NULL, -- ISO 3166-1 alpha 2
  region_id BINARY(16),
  CONSTRAINT "0681493b-ad81-13a7-bc00-fa24e898f195" PRIMARY KEY (code),
  CONSTRAINT "0681493b-ad81-1441-8400-7eb549b4041e" FOREIGN KEY (region_id) REFERENCES region (id)
);

CREATE INDEX "0681493b-ad81-151d-7400-ec056f0a59c9" ON country (region_id);

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
  CONSTRAINT "0681493b-ad81-1b60-4400-c6c74051e5fb" PRIMARY KEY (id),
  CONSTRAINT "0681493b-ad81-1baf-9800-2b10d817dc21" CHECK (status IN ('draft', 'proposed', 'published', 'rejected')),
  CONSTRAINT "0686cd40-3325-10bb-3c00-d37e22aa5104" FOREIGN KEY (thumbnail_id) REFERENCES image (id),
  CONSTRAINT "0681493b-ad81-1c9b-6000-de3e24ed7e4a" FOREIGN KEY (type_id) REFERENCES product_type (id)
);

CREATE UNIQUE INDEX "0681493b-ad81-1d84-d400-02dd9406cda2" ON product (handle) WHERE deleted_at IS NULL;

CREATE TABLE product_variant (
  id BINARY(16) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  deleted_at TIMESTAMP,
  product_id BINARY(16) NOT NULL,
  title VARCHAR(63),
  barcode VARCHAR(63),
  ean VARCHAR(13),
  upc VARCHAR(12),
  variant_rank INTEGER DEFAULT 0 NOT NULL,
  metadata BLOB SUB_TYPE TEXT,
  CONSTRAINT "0681493b-ad82-1567-9800-ff9f17937647" PRIMARY KEY (id),
  CONSTRAINT "0681493b-ad82-15b3-1c00-30ccc78e0b8e" FOREIGN KEY (product_id) REFERENCES product (id) ON DELETE CASCADE
);

CREATE INDEX "0681493b-ad82-16da-7000-61fe4483229d" ON product_variant (product_id);
CREATE UNIQUE INDEX "0681493b-ad82-1799-4800-7aba05e57f99" ON product_variant (barcode) WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX "0681493b-ad82-1802-d000-454acce626f6" ON product_variant (ean) WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX "0681493b-ad82-186b-2800-015e1c02ca35" ON product_variant (upc) WHERE deleted_at IS NULL;

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
  CONSTRAINT "06828532-0de1-11a7-a000-6f71f973f8bf" PRIMARY KEY (id),
  CONSTRAINT "06828532-0de0-1e7a-6000-78a1d15c4ff1" FOREIGN KEY (variant_id) REFERENCES product_variant (id) ON DELETE CASCADE,
  CONSTRAINT "0681493b-ad82-15ff-8400-59a26da86c3d" FOREIGN KEY (origin_country) REFERENCES country (code)
);

CREATE UNIQUE INDEX "06828532-0de0-1d21-f800-7309e0f7c125" ON inventory_item (variant_id);
CREATE UNIQUE INDEX "0681493b-ad82-1729-cc00-081f57f16e27" ON inventory_item (sku) WHERE deleted_at IS NULL;

CREATE TABLE product_variant_money_amount (
  variant_id BINARY(16) NOT NULL,
  money_amount_id BINARY(16) NOT NULL,
  CONSTRAINT "06828532-0dde-11b1-bc00-ed787ddb3a8a" PRIMARY KEY (variant_id, money_amount_id),
  CONSTRAINT "0681493b-ad80-1918-6c00-b3e1e39d7298" FOREIGN KEY (variant_id) REFERENCES product_variant (id) ON DELETE CASCADE,
  CONSTRAINT "06828532-0de2-16cc-0c00-cf4ad2b29958" FOREIGN KEY (money_amount_id) REFERENCES money_amount (id) ON DELETE CASCADE
);

CREATE UNIQUE INDEX "06828532-0dde-1256-9c00-c34b44f8e9c4" ON product_variant_money_amount (money_amount_id);

CREATE TABLE product_option (
  id BINARY(16) NOT NULL,
  product_id BINARY(16) NOT NULL,
  title VARCHAR(63) NOT NULL,
  CONSTRAINT "0681493b-ad82-1d8f-b800-748d549c42a0" PRIMARY KEY (id),
  CONSTRAINT "0681493b-ad82-1ddc-3c00-22ac1e0ada28" FOREIGN KEY (product_id) REFERENCES product (id) ON DELETE CASCADE
);

CREATE INDEX "0686cd40-3324-1029-9c00-b6e2d46d32b1" ON product_option (product_id);

CREATE TABLE product_option_value (
  id BINARY(16) NOT NULL,
  name VARCHAR(63) NOT NULL,
  option_id BINARY(16) NOT NULL,
  CONSTRAINT "0681493b-ad83-1117-7000-26b3a822eacc" PRIMARY KEY (id),
  CONSTRAINT "0681493b-ad83-1167-7400-d94a180e5015" FOREIGN KEY (option_id) REFERENCES product_option (id) ON DELETE CASCADE
);

CREATE INDEX "0681493b-ad83-1296-6c00-1cc6ce4f275a" ON product_option_value (option_id);

CREATE TABLE product_option_value_product_variant (
  option_value_id BINARY(16) NOT NULL,
  variant_id BINARY(16) NOT NULL,
  CONSTRAINT "0686cd40-3323-1b78-a800-0cc5d4486b6f" PRIMARY KEY (option_value_id, variant_id),
  CONSTRAINT "0686cd40-3323-17d3-6000-fc3b4739d2f9" FOREIGN KEY (option_value_id) REFERENCES product_option_value (id) ON DELETE CASCADE,
  CONSTRAINT "0686cd40-3323-1f6e-9800-afb257a57fd7" FOREIGN KEY (variant_id) REFERENCES product_variant (id) ON DELETE CASCADE
);

CREATE INDEX "0686cd40-3323-1fcc-2400-0cc6d0092801" ON product_option_value_product_variant (variant_id);

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
  category_rank INTEGER DEFAULT 0 NOT NULL,
  metadata BLOB SUB_TYPE TEXT,
  CONSTRAINT "0681493b-ad83-1b65-8400-8c8e5989be1d" PRIMARY KEY (id),
  CONSTRAINT "0681493b-ad83-1bbc-c400-6c3ba906dfa8" FOREIGN KEY (parent_category_id) REFERENCES category (id)
);

CREATE UNIQUE INDEX "0681493b-ad83-1ca3-9800-9478574f1e92" ON category (handle) WHERE deleted_at IS NULL;

CREATE TABLE product_collection (
  id BINARY(16) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  deleted_at TIMESTAMP,
  name VARCHAR(63) NOT NULL,
  description BLOB SUB_TYPE TEXT,
  handle VARCHAR(63) NOT NULL,
  is_active BOOLEAN DEFAULT true NOT NULL,
  is_internal BOOLEAN DEFAULT false NOT NULL,
  metadata BLOB SUB_TYPE TEXT,
  CONSTRAINT "0681493b-ad7f-1197-4400-3f49d8a69649" PRIMARY KEY (id)
);

CREATE UNIQUE INDEX "0681493b-ad7f-1288-2400-e97020611535" ON product_collection (handle) WHERE deleted_at IS NULL;


CREATE TABLE product_tax_rate (
  product_id BINARY(16) NOT NULL,
  rate_id BINARY(16) NOT NULL,
  CONSTRAINT "0686cd40-331f-13cf-2000-c352fc68f281" PRIMARY KEY (product_id, rate_id),
  CONSTRAINT "0681493b-ad84-1338-7000-be1a7b106bed" FOREIGN KEY (product_id) REFERENCES product (id) ON DELETE CASCADE,
  CONSTRAINT "0681493b-ad84-138c-bc00-6f75ac2ed431" FOREIGN KEY (rate_id) REFERENCES tax_rate (id) ON DELETE CASCADE
);

CREATE INDEX "0681493b-ad84-14c3-f400-0ba45b29e4d3" ON product_tax_rate (rate_id);

CREATE TABLE product_type_tax_rate (
  product_type_id BINARY(16) NOT NULL,
  rate_id BINARY(16) NOT NULL,
  CONSTRAINT "0686cd40-331f-142a-f400-f93e67fb58ed" PRIMARY KEY (product_type_id, rate_id),
  CONSTRAINT "0681493b-ad84-1791-8800-c3519280ba87" FOREIGN KEY (product_type_id) REFERENCES product_type (id) ON DELETE CASCADE,
  CONSTRAINT "0681493b-ad84-17e4-8c00-9a9d08ccafc9" FOREIGN KEY (rate_id) REFERENCES tax_rate (id) ON DELETE CASCADE
);

CREATE INDEX "0681493b-ad84-1922-2000-80d2d3e5ac26" ON product_type_tax_rate (rate_id);

CREATE TABLE locale (
  id BINARY(16) NOT NULL,
  code VARCHAR(63) NOT NULL,
  CONSTRAINT "0681493b-ad84-1afe-8400-e4f8990e0744" PRIMARY KEY (id),
  CONSTRAINT "0681493b-ad84-1b4d-ac00-955f9befd9c9" UNIQUE (code)
);

CREATE TABLE stock_location_address (
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
  CONSTRAINT "068284bc-d749-1f4e-9000-b6c6e237bd23" PRIMARY KEY (id),
  CONSTRAINT "068284bc-d749-1fa8-4800-72394cfabf1f" FOREIGN KEY (country_code) REFERENCES country (code)
);

CREATE INDEX "068284bc-d74a-113a-cc00-7a45c21dc847" ON stock_location_address (country_code);

CREATE TABLE stock_location (
  id BINARY(16) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  deleted_at TIMESTAMP,
  name VARCHAR(63) NOT NULL,
  address_id BINARY(16),
  CONSTRAINT "068284bc-d74a-1190-a400-30b8104851fe" PRIMARY KEY (id)
);

CREATE INDEX "068284bc-d74a-1362-3800-bfa41b2fe4a8" ON stock_location (address_id) WHERE deleted_at IS NOT NULL;

CREATE TABLE inventory_level (
  inventory_item_id BINARY(16) NOT NULL,
  stock_location_id BINARY(16) NOT NULL,
  stocked_quantity INTEGER DEFAULT 0 NOT NULL,
  reserved_quantity INTEGER DEFAULT 0 NOT NULL,
  CONSTRAINT "06828532-0de1-11fb-5800-aecf67f0cc77" PRIMARY KEY (inventory_item_id, stock_location_id),
  CONSTRAINT "06828532-0de1-1ef1-e000-ed029783b4aa" FOREIGN KEY (inventory_item_id) REFERENCES inventory_item (id) ON DELETE CASCADE,
  CONSTRAINT "06828532-0de1-1f47-fc00-0bd5681967b9" FOREIGN KEY (stock_location_id) REFERENCES stock_location (id) ON DELETE CASCADE
);

CREATE INDEX "06828532-0de2-10cd-6400-0d702f5a6fea" ON inventory_level (stock_location_id);

CREATE TABLE sales_channel (
  id BINARY(16) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  deleted_at TIMESTAMP,
  name VARCHAR(63) NOT NULL,
  description VARCHAR(191),
  is_disabled BOOLEAN DEFAULT false NOT NULL,
  CONSTRAINT "0681493b-ad84-1ec7-0800-68d1ec89bf9e" PRIMARY KEY (id)
);

CREATE TABLE sales_channel_stock_location (
  sales_channel_id BINARY(16) NOT NULL,
  stock_location_id BINARY(16) NOT NULL,
  CONSTRAINT "068284bc-d74a-191b-3000-6dd35ee3e21b" PRIMARY KEY (sales_channel_id, stock_location_id),
  CONSTRAINT "068284bc-d74a-1a0b-c000-9f68490f9d3c" FOREIGN KEY (sales_channel_id) REFERENCES sales_channel (id) ON DELETE CASCADE,
  CONSTRAINT "068284bc-d74a-1f78-5400-6820c274c28e" FOREIGN KEY (stock_location_id) REFERENCES stock_location (id) ON DELETE CASCADE
);

CREATE INDEX "06828532-0ddc-1b6b-0c00-cb10f67da04b" ON sales_channel_stock_location (stock_location_id);

CREATE TABLE store (
  id BINARY(16) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  name VARCHAR(63) NOT NULL,
  default_locale_id BINARY(16) NOT NULL,
  default_region_id BINARY(16) NOT NULL,
  default_stock_location_id BINARY(16) NOT NULL,
  default_sales_channel_id BINARY(16) NOT NULL,
  CONSTRAINT "0681493b-ad85-127e-3400-14796fb97f61" PRIMARY KEY (id),
  CONSTRAINT "0681493b-ad85-12d1-5000-235e3c958344" UNIQUE (default_sales_channel_id),
  CONSTRAINT "0681493b-ad85-1328-8400-e0abfb402420" FOREIGN KEY (default_locale_id) REFERENCES locale (id),
  CONSTRAINT "0686cd40-3323-177c-3c00-44b89aa9d0d7" FOREIGN KEY (default_region_id) REFERENCES region (id),
  CONSTRAINT "0681493b-ad85-13d4-e400-43e4b8fcbb08" FOREIGN KEY (default_sales_channel_id) REFERENCES sales_channel (id)
);

CREATE TABLE category_product (
  category_id BINARY(16) NOT NULL,
  product_id BINARY(16) NOT NULL,
  CONSTRAINT "0686cd40-331d-1405-f800-942a66024ec4" PRIMARY KEY (category_id, product_id),
  CONSTRAINT "0681493b-ad85-15a0-dc00-0bb8f8fabbd1" FOREIGN KEY (category_id) REFERENCES category (id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "0681493b-ad85-1636-6400-30c6fe6460b4" FOREIGN KEY (product_id) REFERENCES product (id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX "0681493b-ad85-17b5-1c00-77a1a1ff2a8c" ON category_product (product_id);


CREATE TABLE product_collection_product (
  product_collection_id BINARY(16) NOT NULL,
  product_id BINARY(16) NOT NULL,
  CONSTRAINT "0686cd40-3322-1ed6-e800-43d173f8e3f6" PRIMARY KEY (product_collection_id, product_id),
  CONSTRAINT "0686cd40-3322-1f2f-7400-69727ceab86a" FOREIGN KEY (product_collection_id) REFERENCES product_collection (id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "0686cd40-3323-107f-5400-28c37c59c7a0" FOREIGN KEY (product_id) REFERENCES product (id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX "0686cd40-3323-10d8-9800-144ed53aad80" ON product_collection_product (product_id);

CREATE TABLE product_image (
  product_id BINARY(16) NOT NULL,
  image_id BINARY(16) NOT NULL,
  image_rank INTEGER DEFAULT 0 NOT NULL,
  CONSTRAINT "0686cd40-331d-15af-3000-d668c4ffbec1" PRIMARY KEY (product_id, image_id),
  CONSTRAINT "0681493b-ad85-1944-1c00-f370c73c0267" FOREIGN KEY (product_id) REFERENCES product (id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "0681493b-ad85-199a-3c00-5180bc814563" FOREIGN KEY (image_id) REFERENCES image (id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX "0681493b-ad85-1b2a-cc00-4a77334dc5b6" ON product_image (image_id);

CREATE TABLE variant_image (
  variant_id BINARY(16) NOT NULL,
  image_id BINARY(16) NOT NULL,
  CONSTRAINT "0686cd40-331d-160d-1c00-16d22c4d03c1" PRIMARY KEY (variant_id, image_id),
  CONSTRAINT "06828532-0de3-105a-d400-73d44583098a" FOREIGN KEY (variant_id) REFERENCES product_variant (id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "06828532-0de3-10ad-b400-c1a3196a0c89" FOREIGN KEY (image_id) REFERENCES image (id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX "06828532-0de2-1c0e-cc00-9efe4e4a7906" ON variant_image (image_id);

CREATE TABLE product_tag_product (
  product_id BINARY(16) NOT NULL,
  product_tag_id BINARY(16) NOT NULL,
  CONSTRAINT "0686cd40-331d-1819-dc00-0844f3b4ceea" PRIMARY KEY (product_id, product_tag_id),
  CONSTRAINT "0681493b-ad85-1cb4-3400-a63ff6ece1a3" FOREIGN KEY (product_id) REFERENCES product (id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "0681493b-ad85-1d02-6800-b72e379e3f4b" FOREIGN KEY (product_tag_id) REFERENCES product_tag (id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX "0681493b-ad85-1e7a-3400-a730f5052e86" ON product_tag_product (product_tag_id);

CREATE TABLE product_sales_channel (
  product_id BINARY(16) NOT NULL,
  sales_channel_id BINARY(16) NOT NULL,
  CONSTRAINT "0686cd40-331d-187d-6c00-6aa93eb10fcc" PRIMARY KEY (product_id, sales_channel_id),
  CONSTRAINT "0681493b-ad85-1ffa-6800-fa142d398ee3" FOREIGN KEY (product_id) REFERENCES product (id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "0681493b-ad86-104b-3c00-f5fa5af9b930" FOREIGN KEY (sales_channel_id) REFERENCES sales_channel (id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX "0681493b-ad86-11c8-9c00-2802dd52f5ce" ON product_sales_channel (sales_channel_id);

CREATE TABLE store_locales (
  store_id BINARY(16) NOT NULL,
  locale_id BINARY(16) NOT NULL,
  CONSTRAINT "0686cd40-331d-1e67-f800-48fe58951895" PRIMARY KEY (store_id, locale_id),
  CONSTRAINT "0681493b-ad86-1a25-4800-5fd5f3b6a3f6" FOREIGN KEY (store_id) REFERENCES store (id) ON DELETE CASCADE,
  CONSTRAINT "0681493b-ad86-1a76-bc00-e0ca8031b6d2" FOREIGN KEY (locale_id) REFERENCES locale (id)
);

CREATE TABLE seo (
  id BINARY(16) NOT NULL,
  product_id BINARY(16),
  category_id BINARY(16),
  collection_id BINARY(16),
  title VARCHAR(63),
  description VARCHAR(191),
  CONSTRAINT "0686cd40-3324-12ce-9800-9acfaa2f3ad3" PRIMARY KEY (id),
  CONSTRAINT "0686cd40-3324-1697-b000-967871bd9ca3" FOREIGN KEY (product_id) REFERENCES product (id) ON DELETE CASCADE,
  CONSTRAINT "0686cd40-3324-16f2-5000-33c19823782a" FOREIGN KEY (category_id) REFERENCES category (id) ON DELETE CASCADE,
  CONSTRAINT "0686cd40-3324-1841-0400-a4573406bc2f" FOREIGN KEY (collection_id) REFERENCES product_collection (id) ON DELETE CASCADE
);

CREATE UNIQUE INDEX "0686cd40-3324-1a4f-2000-d7ff7c962b9d" ON seo (product_id) WHERE product_id IS NOT NULL;
CREATE UNIQUE INDEX "0686cd40-3324-1aa6-a400-37d3a0d0f0b1" ON seo (category_id) WHERE category_id IS NOT NULL;
CREATE UNIQUE INDEX "0686cd40-3324-1bec-4400-94fab7cc5f1f" ON seo (collection_id) WHERE collection_id IS NOT NULL;

CREATE TABLE image_translations (
  image_id BINARY(16) NOT NULL,
  locale_id BINARY(16) NOT NULL,
  alt VARCHAR(191) NOT NULL,
  CONSTRAINT "0686cd40-3323-13d1-8800-7d2adc8ea415" PRIMARY KEY (image_id, locale_id),
  CONSTRAINT "0686cd40-3323-1431-e000-e409cd4362d5" FOREIGN KEY (image_id) REFERENCES image (id) ON DELETE CASCADE,
  CONSTRAINT "0686cd40-3323-1588-6000-3ba7b1076afb" FOREIGN KEY (locale_id) REFERENCES locale (id)
);

CREATE TABLE product_tag_translations (
  product_tag_id BINARY(16) NOT NULL,
  locale_id BINARY(16) NOT NULL,
  name VARCHAR(63) NOT NULL,
  CONSTRAINT "0686cd40-331d-1f72-a800-f135f9a18773" PRIMARY KEY (product_tag_id, locale_id),
  CONSTRAINT "0681493b-ad86-1e1d-4800-e5012b6bb650" FOREIGN KEY (locale_id) REFERENCES locale (id),
  CONSTRAINT "0681493b-ad86-1e82-8c00-c285061f83d0" FOREIGN KEY (product_tag_id) REFERENCES product_tag (id) ON DELETE CASCADE
);

CREATE TABLE product_type_translations (
  product_type_id BINARY(16) NOT NULL,
  locale_id BINARY(16) NOT NULL,
  name VARCHAR(63) NOT NULL,
  CONSTRAINT "0686cd40-331e-11b4-b000-5bb7a1fe718e" PRIMARY KEY (product_type_id, locale_id),
  CONSTRAINT "0681493b-ad87-120a-a800-56399e88f404" FOREIGN KEY (locale_id) REFERENCES locale (id),
  CONSTRAINT "0681493b-ad87-125c-c000-ecfcbc02751b" FOREIGN KEY (product_type_id) REFERENCES product_type (id) ON DELETE CASCADE
);

CREATE TABLE product_option_value_translations (
  product_option_value_id BINARY(16) NOT NULL,
  locale_id BINARY(16) NOT NULL,
  name VARCHAR(63) NOT NULL,
  CONSTRAINT "0686cd40-331e-155a-a800-dbb3da8b4c0c" PRIMARY KEY (product_option_value_id, locale_id),
  CONSTRAINT "0681493b-ad87-1e15-1800-d2de50642886" FOREIGN KEY (locale_id) REFERENCES locale (id),
  CONSTRAINT "0681493b-ad87-1e60-d800-84711ff8403b" FOREIGN KEY (product_option_value_id) REFERENCES product_option_value (id) ON DELETE CASCADE
);

CREATE TABLE product_option_translations (
  product_option_id BINARY(16) NOT NULL,
  locale_id BINARY(16) NOT NULL,
  title VARCHAR(63) NOT NULL,
  CONSTRAINT "0686cd40-331e-1ab3-f000-871d000081a1" PRIMARY KEY (product_option_id, locale_id),
  CONSTRAINT "0681493b-ad88-11a3-b800-2b712f3e3d31" FOREIGN KEY (product_option_id) REFERENCES product_option (id) ON DELETE CASCADE,
  CONSTRAINT "0681493b-ad88-11fd-6c00-e849d9a12128" FOREIGN KEY (locale_id) REFERENCES locale (id)
);

CREATE TABLE category_translations (
  category_id BINARY(16) NOT NULL,
  locale_id BINARY(16) NOT NULL,
  name VARCHAR(63),
  description BLOB SUB_TYPE TEXT,
  CONSTRAINT "0686cd40-331e-1b07-6000-010a1625e5c0" PRIMARY KEY (category_id, locale_id),
  CONSTRAINT "0681493b-ad88-154d-8c00-37a1528f2b37" FOREIGN KEY (category_id) REFERENCES category (id) ON DELETE CASCADE,
  CONSTRAINT "0681493b-ad88-159c-1000-e7761236ae70" FOREIGN KEY (locale_id) REFERENCES locale (id)
);

CREATE TABLE product_collection_translations (
  product_collection_id BINARY(16) NOT NULL,
  locale_id BINARY(16) NOT NULL,
  name VARCHAR(63),
  description BLOB SUB_TYPE TEXT,
  CONSTRAINT "0686cd40-331f-1376-4000-ba40352c1687" PRIMARY KEY (product_collection_id, locale_id),
  CONSTRAINT "0681493b-ad88-1d0b-9400-99972b894202" FOREIGN KEY (product_collection_id) REFERENCES product_collection (id) ON DELETE CASCADE,
  CONSTRAINT "0681493b-ad88-1d59-0800-759be0f51dae" FOREIGN KEY (locale_id) REFERENCES locale (id)
);

CREATE TABLE product_translations (
  product_id BINARY(16) NOT NULL,
  locale_id BINARY(16) NOT NULL,
  title VARCHAR(63),
  subtitle VARCHAR(191),
  description BLOB SUB_TYPE TEXT,
  CONSTRAINT "0686cd40-331e-1b64-1000-989986ca4207" PRIMARY KEY (product_id, locale_id),
  CONSTRAINT "0681493b-ad88-1976-f800-fa9ffcccbf8c" FOREIGN KEY (product_id) REFERENCES product (id) ON DELETE CASCADE,
  CONSTRAINT "0681493b-ad88-19ce-8800-37968a334b2f" FOREIGN KEY (locale_id) REFERENCES locale (id)
);

CREATE TABLE seo_translations (
  seo_id BINARY(16) NOT NULL,
  locale_id BINARY(16) NOT NULL,
  title VARCHAR(63),
  description VARCHAR(191),
  CONSTRAINT "0686cd40-3324-134a-0c00-37a1528f2b37" PRIMARY KEY (seo_id, locale_id),
  CONSTRAINT "0686cd40-3324-134a-0c00-120053a4688f" FOREIGN KEY (locale_id) REFERENCES locale (id)
);
