SET
  FOREIGN_KEY_CHECKS = 0;

CREATE TABLE
  "currency" (
    "id" binary(16) PRIMARY KEY,
    "code" char(3), -- ISO 4217
    "includes_tax" bit(1) NOT NULL DEFAULT 0x00,
    CONSTRAINT "UQ_1f8d3cd0-8a21-4d04-ab2c-cd9ccf11e34d" UNIQUE ("code")
  );

CREATE TABLE
  "fulfillment_provider" (
    "id" binary(16) PRIMARY KEY,
    "is_installed" bit(1) NOT NULL DEFAULT 0x01
  );

CREATE TABLE
  "payment_provider" (
    "id" binary(16) PRIMARY KEY,
    "is_installed" bit(1) NOT NULL DEFAULT 0x01
  );

CREATE TABLE
  "tax_provider" (
    "id" binary(16) PRIMARY KEY,
    "is_installed" bit(1) NOT NULL DEFAULT 0x01
  );

CREATE TABLE
  "image" (
    "id" binary(16) PRIMARY KEY,
    "created_at" datetime NOT NULL DEFAULT NOW(),
    "updated_at" datetime NOT NULL DEFAULT NOW(),
    "deleted_at" datetime,
    "url" text NOT NULL,
    "metadata" json
  );

CREATE TABLE
  "product_collection" (
    "id" binary(16) PRIMARY KEY,
    "created_at" datetime NOT NULL DEFAULT NOW(),
    "updated_at" datetime NOT NULL DEFAULT NOW(),
    "deleted_at" datetime,
    "title" varchar(63) NOT NULL,
    "handle" varchar(63) NOT NULL,
    "metadata" json
  );

CREATE UNIQUE INDEX "IX_fefcdc88-22e7-46f8-a2a8-b6cae400a19c" ON "product_collection" (
  "handle",
  (
    CASE
      WHEN "deleted_at" IS NULL THEN 0x01
      ELSE NULL
    END
  )
);

CREATE TABLE
  "product_tag" (
    "id" binary(16) PRIMARY KEY,
    "created_at" datetime NOT NULL DEFAULT NOW(),
    "updated_at" datetime NOT NULL DEFAULT NOW(),
    "deleted_at" datetime,
    "name" varchar(63) NOT NULL,
    "metadata" json
  );

CREATE TABLE
  "product_type" (
    "id" binary(16) PRIMARY KEY,
    "created_at" datetime NOT NULL DEFAULT NOW(),
    "updated_at" datetime NOT NULL DEFAULT NOW(),
    "deleted_at" datetime,
    "name" varchar(63) NOT NULL,
    "metadata" json
  );

CREATE TABLE
  "discount_rule" (
    "id" binary(16) PRIMARY KEY,
    "created_at" datetime NOT NULL DEFAULT NOW(),
    "updated_at" datetime NOT NULL DEFAULT NOW(),
    "deleted_at" datetime,
    "description" varchar(191),
    "type" varchar(13) NOT NULL,
    "value" integer NOT NULL,
    "allocation" varchar(5),
    "metadata" json,
    CONSTRAINT "CK_f4ce890e-919e-483b-a4ce-7248b6fa3a0f" CHECK (
      "type" IN ('fixed', 'percentage', 'free_shipping')
    ),
    CONSTRAINT "CK_0d369ab6-78a3-4e3e-9b36-2e5d29de29f9" CHECK ("allocation" IN ('total', 'item'))
  );

CREATE TABLE
  "claim_tag" (
    "id" binary(16) PRIMARY KEY,
    "created_at" datetime NOT NULL DEFAULT NOW(),
    "updated_at" datetime NOT NULL DEFAULT NOW(),
    "deleted_at" datetime,
    "value" varchar(63) NOT NULL,
    "metadata" json
  );

CREATE INDEX "IX_26e945a0-27da-416f-80d0-e90694b52456" ON "claim_tag" ("value");

CREATE TABLE
  "shipping_profile" (
    "id" binary(16) PRIMARY KEY,
    "created_at" datetime NOT NULL DEFAULT NOW(),
    "updated_at" datetime NOT NULL DEFAULT NOW(),
    "deleted_at" datetime,
    "name" varchar(63) NOT NULL,
    "type" varchar(9) NOT NULL,
    "metadata" json,
    CONSTRAINT "CK_69be4bbf-2429-4533-b45f-98db60164945" CHECK ("type" IN ('default', 'gift_card', 'custom'))
  );

CREATE TABLE
  "sales_channel" (
    "id" binary(16) PRIMARY KEY,
    "created_at" datetime NOT NULL DEFAULT NOW(),
    "updated_at" datetime NOT NULL DEFAULT NOW(),
    "deleted_at" datetime,
    "name" varchar(63) NOT NULL,
    "description" varchar(191),
    "is_disabled" bit(1) NOT NULL DEFAULT 0x00
  );

CREATE TABLE
  "customer_group" (
    "id" binary(16) PRIMARY KEY,
    "created_at" datetime NOT NULL DEFAULT NOW(),
    "updated_at" datetime NOT NULL DEFAULT NOW(),
    "deleted_at" datetime,
    "name" varchar(63) NOT NULL,
    "metadata" json
  );

CREATE UNIQUE INDEX "IX_3ba0c313-3f2c-4baf-9be6-fc40cdf03728" ON "customer_group" (
  "name",
  (
    CASE
      WHEN "deleted_at" IS NULL THEN 0x01
      ELSE NULL
    END
  )
);

CREATE TABLE
  "price_list" (
    "id" binary(16) PRIMARY KEY,
    "created_at" datetime NOT NULL DEFAULT NOW(),
    "updated_at" datetime NOT NULL DEFAULT NOW(),
    "deleted_at" datetime,
    "name" varchar(63) NOT NULL,
    "description" varchar(191) NOT NULL,
    "type" varchar(8) NOT NULL DEFAULT 'sale',
    "status" varchar(6) NOT NULL DEFAULT 'draft',
    "includes_tax" bit(1) NOT NULL DEFAULT 0x00,
    "starts_at" datetime,
    "ends_at" datetime,
    CONSTRAINT "CK_b8b55e80-6efb-443c-8912-54c6b75b10d6" CHECK ("type" IN ('sale', 'override')),
    CONSTRAINT "CK_a9a1f933-2556-4dd6-b649-ce839e7cdf69" CHECK ("status" IN ('active', 'draft'))
  );

CREATE TABLE
  "analytics_config" (
    "id" binary(16) PRIMARY KEY,
    "created_at" datetime NOT NULL DEFAULT NOW(),
    "updated_at" datetime NOT NULL DEFAULT NOW(),
    "deleted_at" datetime,
    "user_id" binary(16) NOT NULL,
    "opt_out" bit(1) NOT NULL DEFAULT 0x00,
    "anonymize" bit(1) NOT NULL DEFAULT 0x00
  );

CREATE UNIQUE INDEX "IX_e9bffba4-afe5-45c7-b611-5830a9e0312c" ON "analytics_config" (
  "user_id",
  (
    CASE
      WHEN "deleted_at" IS NULL THEN 0x01
      ELSE NULL
    END
  )
);

CREATE TABLE
  "user" (
    "id" binary(16) PRIMARY KEY,
    "handle" varchar(63) NOT NULL,
    "email" varchar(254), -- IETF RFC 3696 Errata 1690
    "password_hash" varchar(60) NOT NULL, -- bcrypt
    "role" varchar(11) NOT NULL DEFAULT 'member',
    "created_at" datetime NOT NULL DEFAULT NOW(),
    "updated_at" datetime NOT NULL DEFAULT NOW(),
    "deleted_at" datetime,
    "first_name" varchar(63),
    "last_name" varchar(63),
    "metadata" json,
    CONSTRAINT "CK_43c31a10-fdf9-49af-a076-e75d1c57b65b" CHECK (
      "role" IN (
        'admin',
        'member',
        'developer',
        'author',
        'contributor'
      )
    )
  );

CREATE UNIQUE INDEX "IX_0cc79f5d-6612-4e15-a994-6dcb798dd413" ON "user" (
  "email",
  (
    CASE
      WHEN "deleted_at" IS NULL THEN 0x01
      ELSE NULL
    END
  )
);

CREATE UNIQUE INDEX "IX_4118174d-b6bc-49b5-8097-c16ca1742c8f" ON "user" (
  "handle",
  (
    CASE
      WHEN "deleted_at" IS NULL THEN 0x01
      ELSE NULL
    END
  )
);

CREATE TABLE
  "idempotency_key" (
    "id" binary(16) PRIMARY KEY,
    "idempotency_key" varchar(41) NOT NULL, -- IDEM_ + Lexical_UUID TODO
    "created_at" datetime NOT NULL DEFAULT NOW(),
    "locked_at" datetime,
    "request_method" varchar(63),
    "request_params" json,
    "request_path" text,
    "response_code" integer,
    "response_body" json,
    "recovery_point" varchar(63) NOT NULL DEFAULT 'started',
    CONSTRAINT "UQ_213677e0-0836-408f-88bb-f1361039d9df" UNIQUE ("idempotency_key")
  );

CREATE TABLE
  "invite" (
    "id" binary(16) PRIMARY KEY,
    "created_at" datetime NOT NULL DEFAULT NOW(),
    "updated_at" datetime NOT NULL DEFAULT NOW(),
    "deleted_at" datetime,
    "user_email" varchar(254) NOT NULL,
    "role" varchar(9) DEFAULT('member'),
    "accepted" bit(1) NOT NULL DEFAULT 0x00,
    "token" text NOT NULL,
    "expires_at" datetime NOT NULL DEFAULT NOW(),
    "metadata" json,
    CONSTRAINT "CK_f9456252-2b93-41ab-ab66-04c2f5f477a2" CHECK (
      "role" IN (
        'admin',
        'member',
        'developer',
        'author',
        'contributor'
      )
    )
  );

CREATE UNIQUE INDEX "IX_150935c7-5717-4d69-aeb7-a638a0dd79d5" ON "invite" (
  "user_email",
  (
    CASE
      WHEN "deleted_at" IS NULL THEN 0x01
      ELSE NULL
    END
  )
);

CREATE TABLE
  "notification_provider" (
    "id" binary(16) PRIMARY KEY,
    "is_installed" bit(1) NOT NULL DEFAULT 0x01
  );

CREATE TABLE
  "publishable_api_key" (
    "id" binary(16) PRIMARY KEY,
    "publishable_api_key" varchar(63),
    "created_at" datetime NOT NULL DEFAULT NOW(),
    "updated_at" datetime NOT NULL DEFAULT NOW(),
    "created_by" binary(16),
    "revoked_by" binary(16),
    "revoked_at" datetime,
    "title" varchar(63) NOT NULL
  );

CREATE TABLE
  "publishable_api_key_sales_channel" (
    "sales_channel_id" binary(16) NOT NULL,
    "publishable_api_key_id" binary(16) NOT NULL,
    PRIMARY KEY ("sales_channel_id", "publishable_api_key_id")
  );

-- Tables with foreign keys
CREATE TABLE
  "discount_condition" (
    "id" binary(16) PRIMARY KEY,
    "created_at" datetime NOT NULL DEFAULT NOW(),
    "updated_at" datetime NOT NULL DEFAULT NOW(),
    "deleted_at" datetime,
    "type" varchar(19) NOT NULL,
    "operator" varchar(6) NOT NULL,
    "discount_rule_id" binary(16) NOT NULL,
    "metadata" json,
    CONSTRAINT "CK_b9b2a119-a9ac-4cb8-a69c-c4adaac00203" CHECK (
      "type" IN (
        'products',
        'product_types',
        'product_collections',
        'product_tags',
        'customer_groups'
      )
    ),
    CONSTRAINT "CK_29a432a2-3a69-4aec-b0b9-4b22afaf1293" CHECK ("operator" IN ('in', 'not_in')),
    CONSTRAINT "UQ_c25d73d2-5808-4a0e-822d-3c28f3e95a31" UNIQUE ("type", "operator", "discount_rule_id"),
    CONSTRAINT "FK_f9e56004-dfb7-4899-88a1-1b94d93acea3" FOREIGN KEY ("discount_rule_id") REFERENCES "discount_rule" ("id")
  );

CREATE INDEX "IX_b73b5b70-1800-4596-81d3-90b5f233d3e4" ON "discount_condition" ("discount_rule_id");

CREATE TABLE
  "discount" (
    "id" binary(16) PRIMARY KEY,
    "created_at" datetime NOT NULL DEFAULT NOW(),
    "updated_at" datetime NOT NULL DEFAULT NOW(),
    "deleted_at" datetime,
    "code" varchar(63) NOT NULL,
    "is_dynamic" bit(1) NOT NULL,
    "rule_id" binary(16),
    "is_disabled" bit(1) NOT NULL,
    "parent_discount_id" binary(16),
    "starts_at" datetime NOT NULL DEFAULT NOW(),
    "ends_at" datetime,
    "valid_duration" text,
    "usage_limit" integer,
    "usage_count" integer NOT NULL DEFAULT 0,
    "metadata" json,
    CONSTRAINT "FK_ea2a0723-0b78-4836-8896-96b65821ce37" FOREIGN KEY ("rule_id") REFERENCES "discount_rule" ("id"),
    CONSTRAINT "FK_06355ddc-2b83-4234-81e8-ebae8b81ceae" FOREIGN KEY ("parent_discount_id") REFERENCES "discount" ("id")
  );

CREATE UNIQUE INDEX "IX_69098fec-7650-4e24-a23f-72f8dd09a418" ON "discount" (
  "code",
  (
    CASE
      WHEN "deleted_at" IS NULL THEN 0x01
      ELSE NULL
    END
  )
);

CREATE INDEX "IX_2f7de7f4-824e-4f13-a498-8c3c786d80a2" ON "discount" ("rule_id");

CREATE TABLE
  "gift_card" (
    "id" binary(16) PRIMARY KEY,
    "created_at" datetime NOT NULL DEFAULT NOW(),
    "updated_at" datetime NOT NULL DEFAULT NOW(),
    "deleted_at" datetime,
    "code" varchar(63) NOT NULL,
    "value" integer NOT NULL,
    "balance" integer NOT NULL,
    "region_id" binary(16) NOT NULL,
    "order_id" binary(16),
    "is_disabled" bit(1) NOT NULL DEFAULT 0x00,
    "ends_at" datetime,
    "tax_rate" real,
    "metadata" json,
    CONSTRAINT "UQ_942ef4f0-6a37-46bb-be68-596215b9a64b" UNIQUE ("code"),
    CONSTRAINT "FK_371fce46-cade-4c75-9889-e472ae1fbe0a" FOREIGN KEY ("region_id") REFERENCES "region" ("id"),
    CONSTRAINT "FK_98185545-63d3-44dc-9f64-d51f4ead7b8d" FOREIGN KEY ("order_id") REFERENCES "order" ("id")
  );

CREATE INDEX "IX_438285de-033f-4635-8b23-c86e7819a5e9" ON "gift_card" ("region_id");

CREATE INDEX "IX_3c581f6b-8edb-4810-8780-28ba497cfc93" ON "gift_card" ("order_id");

CREATE TABLE
  "claim_image" (
    "id" binary(16) PRIMARY KEY,
    "created_at" datetime NOT NULL DEFAULT NOW(),
    "updated_at" datetime NOT NULL DEFAULT NOW(),
    "deleted_at" datetime,
    "claim_item_id" binary(16) NOT NULL,
    "url" text NOT NULL,
    "metadata" json,
    CONSTRAINT "FK_1d7c51c6-e1a5-41a8-b86f-428f404c8986" FOREIGN KEY ("claim_item_id") REFERENCES "claim_item" ("id")
  );

CREATE INDEX "IX_73449e6a-2d73-4348-8d70-224b164eeb46" ON "claim_image" ("claim_item_id");

CREATE TABLE
  "claim_item" (
    "id" binary(16) PRIMARY KEY,
    "created_at" datetime NOT NULL DEFAULT NOW(),
    "updated_at" datetime NOT NULL DEFAULT NOW(),
    "deleted_at" datetime,
    "claim_order_id" binary(16) NOT NULL,
    "item_id" binary(16) NOT NULL,
    "variant_id" binary(16) NOT NULL,
    "reason" varchar(18) NOT NULL,
    "note" text,
    "quantity" integer NOT NULL,
    "metadata" json,
    CONSTRAINT "CK_839125b5-7b4c-493b-b1af-2c2c876e700f" CHECK (
      "reason" IN (
        'missing_item',
        'wrong_item',
        'production_failure',
        'other'
      )
    ),
    CONSTRAINT "FK_b5ee787a-99c6-4809-a005-31f08f248fb1" FOREIGN KEY ("claim_order_id") REFERENCES "claim_order" ("id"),
    CONSTRAINT "FK_ab1dfb3e-2537-45ef-860f-6ba0c81762a9" FOREIGN KEY ("item_id") REFERENCES "line_item" ("id"),
    CONSTRAINT "FK_dd78c81f-4270-477b-bac6-714e041097ff" FOREIGN KEY ("variant_id") REFERENCES "product_variant" ("id")
  );

CREATE INDEX "IX_a42b5977-1bc0-4186-823f-58bbc04f25c7" ON "claim_item" ("claim_order_id");

CREATE INDEX "IX_3cdf8f86-6013-482e-8bb8-9dc594d38f1c" ON "claim_item" ("item_id");

CREATE INDEX "IX_d80e74e0-3b45-4223-908c-d8129d460c00" ON "claim_item" ("variant_id");

CREATE TABLE
  "fulfillment_item" (
    "fulfillment_id" binary(16) NOT NULL,
    "item_id" binary(16) NOT NULL,
    "quantity" integer NOT NULL,
    CONSTRAINT "FK_9675f7af-948c-4654-b620-923d3ff88d4d" FOREIGN KEY ("fulfillment_id") REFERENCES "fulfillment" ("id"),
    CONSTRAINT "FK_7040d36a-4793-42e9-82df-68ad05b609e0" FOREIGN KEY ("item_id") REFERENCES "line_item" ("id"),
    PRIMARY KEY ("fulfillment_id", "item_id")
  );

CREATE TABLE
  "payment" (
    "id" binary(16) PRIMARY KEY,
    "created_at" datetime NOT NULL DEFAULT NOW(),
    "updated_at" datetime NOT NULL DEFAULT NOW(),
    "swap_id" binary(16),
    "cart_id" binary(16),
    "order_id" binary(16),
    "amount" integer NOT NULL,
    "currency_code" char(3) NOT NULL,
    "amount_refunded" integer NOT NULL DEFAULT 0,
    "provider_id" binary(16) NOT NULL,
    "data" json NOT NULL,
    "captured_at" datetime,
    "canceled_at" datetime,
    "metadata" json,
    "idempotency_key" varchar(63), -- TODO check
    CONSTRAINT "UQ_e3299315-be40-4a57-ba17-a11d916517ba" UNIQUE ("swap_id"),
    CONSTRAINT "FK_b7d8ce02-e052-41fe-b4d8-fca1c0e54ef9" FOREIGN KEY ("swap_id") REFERENCES "swap" ("id"),
    CONSTRAINT "FK_8cd1bba0-fbab-4244-bd5c-6d7a9742cf3b" FOREIGN KEY ("cart_id") REFERENCES "cart" ("id"),
    CONSTRAINT "FK_5462983d-5fc4-4a88-b7f9-7e9af6eabd98" FOREIGN KEY ("order_id") REFERENCES "order" ("id"),
    CONSTRAINT "FK_20cc85f7-a809-42ce-9ea3-f201a3f924d9" FOREIGN KEY ("currency_code") REFERENCES "currency" ("code")
  );

CREATE INDEX "IX_4115aef2-f23d-441b-bcf5-2e49a8c2f3d0" ON "payment" ("swap_id");

CREATE INDEX "IX_2967508f-309d-4a98-ab60-71a404e5070f" ON "payment" ("cart_id");

CREATE INDEX "IX_2b56db5a-4d49-4555-b166-fdad11e7b58a" ON "payment" ("order_id");

CREATE INDEX "IX_82b36bb9-5c19-4a5f-b1c6-f4a6d1e7b660" ON "payment" ("currency_code");

CREATE INDEX "IX_9fead48e-b4b8-4571-a3b4-ef022e9630e1" ON "payment" ("provider_id");

CREATE UNIQUE INDEX "IX_c1863e4b-848a-4d04-a9e0-08bb12b5ab33" ON "payment" (
  "cart_id",
  (
    CASE
      WHEN "canceled_at" IS NULL THEN 0x01
      ELSE NULL
    END
  )
);

CREATE INDEX "IX_b749eff0-384b-4a5c-94bd-c3a7a7cdbb8e" ON "payment" (
  "cart_id",
  (
    CASE
      WHEN "canceled_at" IS NOT NULL THEN 0x01
      ELSE NULL
    END
  )
);

CREATE TABLE
  "return_reason" (
    "id" binary(16) PRIMARY KEY,
    "created_at" datetime NOT NULL DEFAULT NOW(),
    "updated_at" datetime NOT NULL DEFAULT NOW(),
    "deleted_at" datetime,
    "value" varchar(63) NOT NULL,
    "label" text NOT NULL,
    "description" text,
    "parent_return_reason_id" binary(16),
    "metadata" json,
    CONSTRAINT "UQ_d8663769-5442-4395-87ab-3d29d7e394eb" UNIQUE ("value"),
    CONSTRAINT "FK_94ebd379-6568-4e92-b0df-dec5da1cb28b" FOREIGN KEY ("parent_return_reason_id") REFERENCES "return_reason" ("id")
  );

CREATE TABLE
  "return_item" (
    "return_id" binary(16) NOT NULL,
    "item_id" binary(16) NOT NULL,
    "quantity" integer NOT NULL,
    "is_requested" bit(1) NOT NULL DEFAULT 0x01,
    "requested_quantity" integer,
    "received_quantity" integer,
    "reason_id" binary(16),
    "note" text,
    "metadata" json,
    CONSTRAINT "FK_a1ad998a-446d-45f8-95b5-9530ac3b0f2f" FOREIGN KEY ("return_id") REFERENCES "return" ("id"),
    CONSTRAINT "FK_fd1d5ff4-fa3c-4b03-a655-9f275ca4f36c" FOREIGN KEY ("item_id") REFERENCES "line_item" ("id"),
    CONSTRAINT "FK_b04fc611-0d2f-47fc-8ee0-266193891ca5" FOREIGN KEY ("reason_id") REFERENCES "return_reason" ("id"),
    PRIMARY KEY ("return_id", "item_id")
  );

CREATE TABLE
  "shipping_method_tax_line" (
    "id" binary(16) PRIMARY KEY,
    "created_at" datetime NOT NULL DEFAULT NOW(),
    "updated_at" datetime NOT NULL DEFAULT NOW(),
    "rate" real NOT NULL,
    "name" varchar(63) NOT NULL,
    "code" varchar(63),
    "metadata" json,
    "shipping_method_id" binary(16) NOT NULL,
    CONSTRAINT "UQ_014c98f0-4c9e-4f33-be5d-9bac3c7d1e02" UNIQUE ("shipping_method_id", "code"),
    CONSTRAINT "FK_0a86bdc1-af47-4a27-8be8-936642d40bbc" FOREIGN KEY ("shipping_method_id") REFERENCES "shipping_method" ("id")
  );

CREATE INDEX "IX_6bf563eb-807c-4c4b-875b-bdc6689889c1" ON "shipping_method_tax_line" ("shipping_method_id");

CREATE TABLE
  "shipping_option_requirement" (
    "id" binary(16) PRIMARY KEY,
    "shipping_option_id" binary(16) NOT NULL,
    "type" varchar(12) NOT NULL,
    "amount" integer NOT NULL,
    "deleted_at" datetime,
    CONSTRAINT "CK_2c26dba5-908e-40a9-be5d-e971a31e2498" CHECK ("type" IN ('min_subtotal', 'max_subtotal')),
    CONSTRAINT "FK_b57b7abc-bba9-42f6-ad40-79325dc6914b" FOREIGN KEY ("shipping_option_id") REFERENCES "shipping_option" ("id")
  );

CREATE INDEX "IX_5b3d5fe9-39dc-4a2b-8147-c08d6ec63f29" ON "shipping_option_requirement" ("shipping_option_id");

CREATE TABLE
  "shipping_option" (
    "id" binary(16) PRIMARY KEY,
    "created_at" datetime NOT NULL DEFAULT NOW(),
    "updated_at" datetime NOT NULL DEFAULT NOW(),
    "deleted_at" datetime,
    "name" varchar(63) NOT NULL,
    "region_id" binary(16) NOT NULL,
    "profile_id" binary(16) NOT NULL,
    "provider_id" binary(16) NOT NULL,
    "price_type" varchar(10) NOT NULL,
    "amount" integer,
    "includes_tax" bit(1) NOT NULL DEFAULT 0x00,
    "is_return" bit(1) NOT NULL DEFAULT 0x00,
    "admin_only" bit(1) NOT NULL DEFAULT 0x00,
    "data" json NOT NULL,
    "metadata" json,
    CONSTRAINT "CK_c1fee6b4-5628-4229-8e7d-cd6fefbeaed9" CHECK ("price_type" IN ('flat_rate', 'calculated')),
    CONSTRAINT "CK_99a4a281-07b9-4f6a-afe7-c6e3b184819a" CHECK ("amount" >= 0),
    CONSTRAINT "FK_4477fb34-e6d2-488f-951c-e1c8e6f0008d" FOREIGN KEY ("region_id") REFERENCES "region" ("id"),
    CONSTRAINT "FK_45e60420-892b-44a6-902c-5a813dd1a002" FOREIGN KEY ("profile_id") REFERENCES "shipping_profile" ("id"),
    CONSTRAINT "FK_c41d2698-6723-4f28-9cef-006aba4219f4" FOREIGN KEY ("provider_id") REFERENCES "fulfillment_provider" ("id")
  );

CREATE INDEX "IX_517fd3dc-a0cc-45c0-b614-b707aaa3db16" ON "shipping_option" ("region_id");

CREATE INDEX "IX_f67a1d47-6cca-440f-8161-7de5fb293eb2" ON "shipping_option" ("profile_id");

CREATE INDEX "IX_d10b1194-c2ba-4080-a10f-9bdd558a1ae8" ON "shipping_option" ("provider_id");

CREATE TABLE
  "shipping_method" (
    "id" binary(16) PRIMARY KEY,
    "shipping_option_id" binary(16) NOT NULL,
    "order_id" binary(16),
    "claim_order_id" binary(16),
    "cart_id" binary(16),
    "swap_id" binary(16),
    "return_id" binary(16),
    "price" integer NOT NULL,
    "includes_tax" bit(1) NOT NULL DEFAULT 0x00,
    "data" json NOT NULL,
    CONSTRAINT "UQ_9fa5c3db-1608-4568-90ea-0e1a3bd74fd8" UNIQUE ("return_id"),
    CONSTRAINT "CK_bb210f88-eb85-4028-8916-74f2aa569aed" CHECK ("price" >= 0),
    CONSTRAINT "CK_eb01b03b-1a9a-438e-8396-2deed8cb4813" CHECK (
      "claim_order_id" IS NOT NULL
      OR "order_id" IS NOT NULL
      OR "cart_id" IS NOT NULL
      OR "swap_id" IS NOT NULL
      OR "return_id" IS NOT NULL
    ),
    CONSTRAINT "FK_5c86dd3f-5bb6-4c39-9b43-3c719230343d" FOREIGN KEY ("order_id") REFERENCES "order" ("id"),
    CONSTRAINT "FK_ff1777fc-4bfc-4662-aae6-cb6aeab51aeb" FOREIGN KEY ("claim_order_id") REFERENCES "claim_order" ("id"),
    CONSTRAINT "FK_9436a46d-0b26-4430-a08c-90fead8c538c" FOREIGN KEY ("cart_id") REFERENCES "cart" ("id"),
    CONSTRAINT "FK_4d613d1c-a17e-4839-8a8c-028e3926cc2f" FOREIGN KEY ("swap_id") REFERENCES "swap" ("id"),
    CONSTRAINT "FK_0855aa44-e993-43d8-aa5d-bcae5049543b" FOREIGN KEY ("return_id") REFERENCES "return" ("id"),
    CONSTRAINT "FK_af4b9339-5a1a-47b7-88b5-fffdae5d9642" FOREIGN KEY ("shipping_option_id") REFERENCES "shipping_option" ("id")
  );

CREATE INDEX "IX_085379b6-bbb4-40d5-96bc-9e4e2bcad024" ON "shipping_method" ("shipping_option_id");

CREATE INDEX "IX_ade04845-49b0-4d64-b1b2-dcfa8a50128d" ON "shipping_method" ("order_id");

CREATE INDEX "IX_a3b059eb-7b62-4262-b074-15231b710bb5" ON "shipping_method" ("claim_order_id");

CREATE INDEX "IX_26127713-f0e3-4fa0-88aa-49a5fd091a77" ON "shipping_method" ("cart_id");

CREATE INDEX "IX_4e0eecf8-c4dd-4fee-ad8b-53b47c6b5ff1" ON "shipping_method" ("swap_id");

CREATE INDEX "IX_ebf1a8fe-7cf6-4cc0-8a1b-8b858e8b2c00" ON "shipping_method" ("return_id");

CREATE TABLE
  "return" (
    "id" binary(16) PRIMARY KEY,
    "created_at" datetime NOT NULL DEFAULT NOW(),
    "updated_at" datetime NOT NULL DEFAULT NOW(),
    "status" varchar(15) NOT NULL DEFAULT 'requested',
    "swap_id" binary(16),
    "claim_order_id" binary(16),
    "order_id" binary(16),
    "location_id" binary(16),
    "shipping_data" json,
    "refund_amount" integer NOT NULL,
    "received_at" datetime,
    "no_notification" bit(1),
    "metadata" json,
    "idempotency_key" varchar(63), -- TODO check
    CONSTRAINT "CK_cba3b14a-eedc-4d36-8661-12e049b9b222" CHECK (
      "status" IN (
        'requested',
        'received',
        'requires_action',
        'canceled'
      )
    ),
    CONSTRAINT "UQ_2cb5352f-8d55-4fed-9d3b-3f60e74bfb07" UNIQUE ("swap_id"),
    CONSTRAINT "UQ_b61a9a32-5865-4d76-983d-66d7dc46f9d3" UNIQUE ("claim_order_id"),
    CONSTRAINT "FK_21d24c83-3ead-4f7e-a90b-a40918e2014d" FOREIGN KEY ("swap_id") REFERENCES "swap" ("id"),
    CONSTRAINT "FK_c7368386-78fa-46b1-a49d-7e75283c25c4" FOREIGN KEY ("claim_order_id") REFERENCES "claim_order" ("id"),
    CONSTRAINT "FK_76de831c-e3ae-41ff-a2b4-a390b9c2d5c8" FOREIGN KEY ("order_id") REFERENCES "order" ("id")
  );

CREATE INDEX "IX_c2d5de99-6e84-440e-a419-73a0cfc81b31" ON "return" ("swap_id");

CREATE INDEX "IX_d96fcb29-6c0a-4ec4-8a1b-2496f36c6b8f" ON "return" ("claim_order_id");

CREATE INDEX "IX_cb4f6d79-2d46-4ad6-8d9b-05e9beb5db01" ON "return" ("order_id");

CREATE INDEX "IX_70cea267-1a88-408b-98f1-a8452ab0b201" ON "return" ("location_id");

CREATE TABLE
  "swap" (
    "id" binary(16) PRIMARY KEY,
    "created_at" datetime NOT NULL DEFAULT NOW(),
    "updated_at" datetime NOT NULL DEFAULT NOW(),
    "deleted_at" datetime,
    "fulfillment_status" varchar(17) NOT NULL,
    "payment_status" varchar(19) NOT NULL,
    "order_id" binary(16) NOT NULL,
    "difference_due" integer,
    "shipping_address_id" binary(16),
    "cart_id" binary(16),
    "confirmed_at" datetime,
    "canceled_at" datetime,
    "no_notification" bit(1),
    "allow_backorder" bit(1) NOT NULL DEFAULT 0x00,
    "idempotency_key" varchar(63), -- TODO check
    "metadata" json,
    CONSTRAINT "CK_fa7bd1f3-84ac-4c8b-a970-8924d60c0cd4" CHECK (
      "fulfillment_status" IN (
        'not_fulfilled',
        'fulfilled',
        'shipped',
        'partially_shipped',
        'canceled',
        'requires_action'
      )
    ),
    CONSTRAINT "CK_2cfabafb-3fcb-41be-b95b-c7ce26245be7" CHECK (
      "payment_status" IN (
        'not_paid',
        'awaiting',
        'captured',
        'confirmed',
        'canceled',
        'difference_refunded',
        'partially_refunded',
        'refunded',
        'requires_action'
      )
    ),
    CONSTRAINT "UQ_1a567a54-90b1-4d17-8443-6ce76b414468" UNIQUE ("cart_id"),
    CONSTRAINT "FK_ee0af6b0-acd7-408f-8b96-eb1dd055b74d" FOREIGN KEY ("order_id") REFERENCES "order" ("id"),
    CONSTRAINT "FK_d5b7c411-39fa-4df5-b56d-a67955a8b659" FOREIGN KEY ("shipping_address_id") REFERENCES "address" ("id"),
    CONSTRAINT "FK_968ec785-e603-4ffb-a570-1a35d54fa25e" FOREIGN KEY ("cart_id") REFERENCES "cart" ("id")
  );

CREATE INDEX "IX_398fc109-efce-43c9-8f89-19f3f71f7254" ON "swap" ("order_id");

CREATE TABLE
  "tracking_link" (
    "id" binary(16) PRIMARY KEY,
    "created_at" datetime NOT NULL DEFAULT NOW(),
    "updated_at" datetime NOT NULL DEFAULT NOW(),
    "deleted_at" datetime,
    "url" text,
    "tracking_number" text NOT NULL,
    "fulfillment_id" binary(16) NOT NULL,
    "idempotency_key" varchar(63), -- TODO check
    "metadata" json,
    CONSTRAINT "FK_5e425b93-2695-4734-9967-103ee316bc9d" FOREIGN KEY ("fulfillment_id") REFERENCES "fulfillment" ("id")
  );

CREATE TABLE
  "fulfillment" (
    "id" binary(16) PRIMARY KEY,
    "created_at" datetime NOT NULL DEFAULT NOW(),
    "updated_at" datetime NOT NULL DEFAULT NOW(),
    "claim_order_id" binary(16),
    "swap_id" binary(16),
    "order_id" binary(16),
    "no_notification" bit(1),
    "provider_id" binary(16) NOT NULL,
    "location_id" binary(16),
    "tracking_numbers" json NOT NULL DEFAULT('[]'),
    "data" json NOT NULL,
    "shipped_at" datetime,
    "canceled_at" datetime,
    "metadata" json,
    "idempotency_key" varchar(63), -- TODO check
    CONSTRAINT "FK_e1e48ded-22b5-4684-b593-05c4dabaf292" FOREIGN KEY ("claim_order_id") REFERENCES "claim_order" ("id"),
    CONSTRAINT "FK_d07568d5-e3f3-4d5d-8bfd-2a49dd6ae98a" FOREIGN KEY ("swap_id") REFERENCES "swap" ("id"),
    CONSTRAINT "FK_f3ac6a1f-2e07-4fda-9a3a-2be045967339" FOREIGN KEY ("order_id") REFERENCES "order" ("id"),
    CONSTRAINT "FK_ceca7b5f-338a-40e7-983e-1bee528d9439" FOREIGN KEY ("provider_id") REFERENCES "fulfillment_provider" ("id")
  );

CREATE INDEX "IX_5ee4277a-b348-4abd-8c6a-a5036ae18716" ON "fulfillment" ("claim_order_id");

CREATE INDEX "IX_28af535a-0801-4133-920e-3748d8a9606d" ON "fulfillment" ("swap_id");

CREATE INDEX "IX_e7c00a6e-15bd-4070-961b-2e08cbf0ae1d" ON "fulfillment" ("order_id");

CREATE INDEX "IX_97ff20b0-8ce1-48ab-a646-cf180faf68f1" ON "fulfillment" ("provider_id");

CREATE TABLE
  "claim_order" (
    "id" binary(16) PRIMARY KEY,
    "created_at" datetime NOT NULL DEFAULT NOW(),
    "updated_at" datetime NOT NULL DEFAULT NOW(),
    "deleted_at" datetime,
    "payment_status" varchar(12) NOT NULL DEFAULT 'na',
    "fulfillment_status" varchar(19) NOT NULL DEFAULT 'not_fulfilled',
    "type" varchar(7) NOT NULL,
    "order_id" binary(16) NOT NULL,
    "shipping_address_id" binary(16),
    "refund_amount" binary(16),
    "canceled_at" datetime,
    "no_notification" bit(1),
    "metadata" json,
    "idempotency_key" varchar(63), -- TODO check
    CONSTRAINT "CK_3e69beb1-996d-468a-9c6b-24a52ea8a276" CHECK ("type" IN ('refund', 'replace')),
    CONSTRAINT "CK_126572da-de8c-4a43-8203-c9d4a6f3fd68" CHECK (
      "fulfillment_status" IN (
        'not_fulfilled',
        'partially_fulfilled',
        'fulfilled',
        'partially_shipped',
        'shipped',
        'partially_returned',
        'returned',
        'canceled',
        'requires_action'
      )
    ),
    CONSTRAINT "CK_94c993fb-cb7b-4697-8c56-2836d3dc9713" CHECK (
      "payment_status" IN ('na', 'not_refunded', 'refunded')
    ),
    CONSTRAINT "FK_3e765f10-5a8c-4b62-bf3e-e23d1e3da5fd" FOREIGN KEY ("order_id") REFERENCES "order" ("id"),
    CONSTRAINT "FK_333374b0-fdc0-4b0b-acba-da358f41d96a" FOREIGN KEY ("shipping_address_id") REFERENCES "address" ("id")
  );

CREATE INDEX "IX_0d30cde5-36e1-4045-99e5-4f641b2783c7" ON "claim_order" ("order_id");

CREATE INDEX "IX_c73e0675-c22a-4b90-8f66-66a5bd61dd46" ON "claim_order" ("shipping_address_id");

CREATE TABLE
  "line_item_adjustment" (
    "id" binary(16) PRIMARY KEY,
    "item_id" binary(16) NOT NULL,
    "description" varchar(191) NOT NULL,
    "discount_id" binary(16),
    "amount" integer NOT NULL,
    "metadata" json,
    CONSTRAINT "FK_267dd4c2-2709-4a5a-9990-fa56acf6fa53" FOREIGN KEY ("item_id") REFERENCES "line_item" ("id") ON DELETE CASCADE,
    CONSTRAINT "FK_676cd26a-2845-407d-9497-df9be8333261" FOREIGN KEY ("discount_id") REFERENCES "discount" ("id")
  );

CREATE INDEX "IX_a19c4ab6-b919-461c-9508-2b4f16fe3899" ON "line_item_adjustment" ("item_id");

CREATE INDEX "IX_80c3059b-601d-43a4-83ef-41eec09cb20a" ON "line_item_adjustment" ("discount_id");

CREATE UNIQUE INDEX "IX_89fab08f-587d-4677-8321-ba7206a988e5" ON "line_item_adjustment" (
  "discount_id",
  "item_id",
  (
    CASE
      WHEN "discount_id" IS NOT NULL THEN 0x01
      ELSE NULL
    END
  )
);

CREATE TABLE
  "line_item_tax_line" (
    "id" binary(16) PRIMARY KEY,
    "created_at" datetime NOT NULL DEFAULT NOW(),
    "updated_at" datetime NOT NULL DEFAULT NOW(),
    "rate" real NOT NULL,
    "name" varchar(63) NOT NULL,
    "code" varchar(63),
    "metadata" json,
    "item_id" binary(16) NOT NULL,
    CONSTRAINT "UQ_94442712-d302-44bc-a3f1-e80919648570" UNIQUE ("item_id", "code"),
    CONSTRAINT "FK_d33dd8b7-73a2-4c6b-811b-3273697d0fb6" FOREIGN KEY ("item_id") REFERENCES "line_item" ("id")
  );

CREATE INDEX "IX_c1b7fb5e-838b-456b-a636-03e209e6c563" ON "line_item_tax_line" ("item_id");

CREATE TABLE
  "order_edit" (
    "id" binary(16) PRIMARY KEY,
    "created_at" datetime NOT NULL DEFAULT NOW(),
    "updated_at" datetime NOT NULL DEFAULT NOW(),
    "order_id" binary(16) NOT NULL,
    "internal_note" text,
    "created_by" binary(16) NOT NULL,
    "requested_by" binary(16),
    "requested_at" datetime,
    "confirmed_by" binary(16),
    "confirmed_at" datetime,
    "declined_by" binary(16),
    "declined_reason" text,
    "declined_at" datetime,
    "canceled_by" binary(16),
    "canceled_at" datetime,
    "payment_collection_id" binary(16),
    CONSTRAINT "UQ_24bcc997-b6e6-4f94-8f54-87e39033743d" UNIQUE ("payment_collection_id"),
    CONSTRAINT "FK_e0ef3720-9dd2-424c-a7ca-874e40e7f55f" FOREIGN KEY ("order_id") REFERENCES "order" ("id"),
    CONSTRAINT "FK_6c36a356-5527-4950-9cf2-c6f17e2de653" FOREIGN KEY ("payment_collection_id") REFERENCES "payment_collection" ("id")
  );

CREATE INDEX "IX_7b6aa75a-e1f3-45f2-9866-1e6ee3664d7d" ON "order_edit" ("order_id");

CREATE INDEX "IX_5f156063-ab8f-4f95-bac7-9f75c6892c0f" ON "order_edit" ("payment_collection_id");

CREATE TABLE
  "line_item" (
    "id" binary(16) PRIMARY KEY,
    "created_at" datetime NOT NULL DEFAULT NOW(),
    "updated_at" datetime NOT NULL DEFAULT NOW(),
    "cart_id" binary(16),
    "order_id" binary(16),
    "swap_id" binary(16),
    "claim_order_id" binary(16),
    "original_item_id" binary(16),
    "order_edit_id" binary(16),
    "title" varchar(63) NOT NULL,
    "description" varchar(191),
    "thumbnail" text,
    "is_return" bit(1) NOT NULL DEFAULT 0x00,
    "is_giftcard" bit(1) NOT NULL DEFAULT 0x00,
    "should_merge" bit(1) NOT NULL DEFAULT 0x01,
    "allow_discounts" bit(1) NOT NULL DEFAULT 0x01,
    "includes_tax" bit(1) NOT NULL DEFAULT 0x00,
    "has_shipping" bit(1),
    "unit_price" integer NOT NULL,
    "variant_id" binary(16),
    "quantity" integer NOT NULL,
    "fulfilled_quantity" integer,
    "returned_quantity" integer,
    "shipped_quantity" integer,
    "metadata" json,
    CONSTRAINT "CK_5a163a6d-4d54-4166-8bb3-9090abaf4a24" CHECK ("quantity" > 0),
    CONSTRAINT "CK_2d5a1721-31ea-493a-8e00-93513904e615" CHECK ("returned_quantity" <= "quantity"),
    CONSTRAINT "CK_893a7829-ace0-46ba-ac00-f91e22d75543" CHECK ("shipped_quantity" <= "fulfilled_quantity"),
    CONSTRAINT "CK_9d297251-4a2f-42a5-b7dc-14f0fb08061f" CHECK ("fulfilled_quantity" <= "quantity"),
    CONSTRAINT "FK_08fa3dc5-1979-46ed-a142-87808d55c9c9" FOREIGN KEY ("cart_id") REFERENCES "cart" ("id"),
    CONSTRAINT "FK_58581511-1998-40d4-8c49-df34f9b12a7b" FOREIGN KEY ("order_id") REFERENCES "order" ("id"),
    CONSTRAINT "FK_e30f2751-4b97-4995-9d70-86bee5ba52e6" FOREIGN KEY ("swap_id") REFERENCES "swap" ("id"),
    CONSTRAINT "FK_b4290892-a328-4f73-8e01-e9b02b7cbc9b" FOREIGN KEY ("claim_order_id") REFERENCES "claim_order" ("id"),
    CONSTRAINT "FK_0861d9ac-4f83-4995-8a5d-92e14bd7d525" FOREIGN KEY ("order_edit_id") REFERENCES "order_edit" ("id"),
    CONSTRAINT "FK_987ea516-1e81-4059-b91d-6b501c528e64" FOREIGN KEY ("variant_id") REFERENCES "product_variant" ("id")
  );

CREATE INDEX "IX_a3dc0167-c7d7-4d63-8beb-cc29a1f43847" ON "line_item" ("cart_id");

CREATE INDEX "IX_2767d092-6bfc-4ab8-a25f-007fb1617774" ON "line_item" ("order_id");

CREATE INDEX "IX_ef0e1ae9-c519-4e9c-a978-1de970a2f33b" ON "line_item" ("swap_id");

CREATE INDEX "IX_34d8a258-5094-4a36-8fed-2c185ecb2f4a" ON "line_item" ("claim_order_id");

CREATE INDEX "IX_924556fc-352b-4c22-ba23-b547bba6dde9" ON "line_item" ("variant_id");

CREATE UNIQUE INDEX "IX_60e608dc-43d8-4da5-81a2-d51a367d0c00" ON "line_item" (
  "order_edit_id",
  "original_item_id",
  (
    CASE
      WHEN "original_item_id" IS NOT NULL
      AND "order_edit_id" IS NOT NULL THEN 0x01
      ELSE NULL
    END
  )
);

CREATE TABLE
  "payment_session" (
    "id" binary(16) PRIMARY KEY,
    "created_at" datetime NOT NULL DEFAULT NOW(),
    "updated_at" datetime NOT NULL DEFAULT NOW(),
    "cart_id" binary(16),
    "provider_id" binary(16) NOT NULL,
    "is_selected" bit(1),
    "is_initiated" bit(1) NOT NULL DEFAULT 0x00,
    "status" varchar(13) NOT NULL,
    "data" json NOT NULL,
    "idempotency_key" varchar(63), -- TODO check
    "amount" integer,
    "payment_authorized_at" datetime,
    CONSTRAINT "CK_0cc2fb94-1fc2-4a6e-91c6-39e7af108756" CHECK (
      "status" IN (
        'authorized',
        'pending',
        'requires_more',
        'error',
        'canceled'
      )
    ),
    CONSTRAINT "UQ_69fa2b29-4c64-47e5-bb35-aee69ed99bf7" UNIQUE ("cart_id", "is_selected"),
    CONSTRAINT "FK_f759e96d-c88d-4508-82c2-1e60edfbcc9a" FOREIGN KEY ("cart_id") REFERENCES "cart" ("id")
  );

CREATE INDEX "IX_6f664584-05c1-42cc-806c-2b25022b9e53" ON "payment_session" ("cart_id");

CREATE INDEX "IX_d2de7cc7-e7de-48d1-9589-9da327c0e9d4" ON "payment_session" ("provider_id");

CREATE UNIQUE INDEX "IX_ebedd9fa-487a-45a8-bf5f-0eb27234cfdc" ON "payment_session" (
  "cart_id",
  "provider_id",
  (
    CASE
      WHEN "cart_id" IS NOT NULL THEN 0x01
      ELSE NULL
    END
  )
);

CREATE TABLE
  "sales_channel_location" (
    "id" binary(16) PRIMARY KEY,
    "created_at" datetime NOT NULL DEFAULT NOW(),
    "updated_at" datetime NOT NULL DEFAULT NOW(),
    "deleted_at" datetime,
    "sales_channel_id" binary(16) NOT NULL,
    "location_id" binary(16) NOT NULL,
    CONSTRAINT "FK_4f53a26a-d611-497c-9610-33a20688f696" FOREIGN KEY ("sales_channel_id") REFERENCES "sales_channel" ("id")
  );

CREATE INDEX "IX_f6c38406-84d8-441d-b712-2e6273bbe970" ON "sales_channel_location" ("sales_channel_id");

CREATE INDEX "IX_3bf3b981-efc7-451a-b147-371957e63bb5" ON "sales_channel_location" ("location_id");

CREATE TABLE
  "cart" (
    "id" binary(16) PRIMARY KEY,
    "created_at" datetime NOT NULL DEFAULT NOW(),
    "updated_at" datetime NOT NULL DEFAULT NOW(),
    "deleted_at" datetime,
    "email" varchar(254),
    "billing_address_id" binary(16),
    "shipping_address_id" binary(16),
    "region_id" binary(16) NOT NULL,
    "customer_id" binary(16),
    "payment_id" binary(16),
    "type" varchar(12) NOT NULL DEFAULT 'default',
    "completed_at" datetime,
    "payment_authorized_at" datetime,
    "idempotency_key" varchar(63), -- TODO check
    "context" json,
    "metadata" json,
    "sales_channel_id" binary(16),
    CONSTRAINT "CK_58de3361-8564-463d-a8db-13957f73dec3" CHECK (
      "type" IN (
        'default',
        'swap',
        'draft_order',
        'payment_link',
        'claim'
      )
    ),
    CONSTRAINT "UQ_c0c83d9a-82e0-4994-9554-86fe1ea356f0" UNIQUE ("payment_id"),
    CONSTRAINT "FK_10161e0d-5989-4e1d-9b33-ce8c02c11e3d" FOREIGN KEY ("billing_address_id") REFERENCES "address" ("id"),
    CONSTRAINT "FK_0b697e62-fb88-42e3-a3ef-5ede0cbaaca5" FOREIGN KEY ("shipping_address_id") REFERENCES "address" ("id"),
    CONSTRAINT "FK_d12f5f15-84d8-416f-953a-84dc8b09e4d4" FOREIGN KEY ("region_id") REFERENCES "region" ("id"),
    CONSTRAINT "FK_ac247cbe-8364-4364-9e04-bdc623e9b3e4" FOREIGN KEY ("customer_id") REFERENCES "customer" ("id"),
    CONSTRAINT "FK_cbec31e1-8037-4058-bbac-c78b2b540bb8" FOREIGN KEY ("payment_id") REFERENCES "payment" ("id"),
    CONSTRAINT "FK_f7ab6e53-f428-43da-b7e7-44a2f8b5f441" FOREIGN KEY ("sales_channel_id") REFERENCES "sales_channel" ("id")
  );

CREATE INDEX "IX_9d29983e-5631-44cb-9088-053fa90b6210" ON "cart" ("billing_address_id");

CREATE INDEX "IX_fd0121db-e4b7-4208-8dde-0ff849da02d4" ON "cart" ("shipping_address_id");

CREATE INDEX "IX_9f19dc50-2112-4b4b-8434-9308b525d8fd" ON "cart" ("region_id");

CREATE INDEX "IX_cae6b7a0-875f-4d2c-968f-93d5ec31bf6b" ON "cart" ("customer_id");

CREATE INDEX "IX_86fcc564-1f46-4856-b2df-2f2fdd65188b" ON "cart" ("payment_id");

CREATE TABLE
  "draft_order" (
    "id" binary(16) PRIMARY KEY,
    "created_at" datetime NOT NULL DEFAULT NOW(),
    "updated_at" datetime NOT NULL DEFAULT NOW(),
    "status" varchar(9) NOT NULL DEFAULT 'open',
    "display_id" binary(16) NOT NULL,
    "cart_id" binary(16),
    "order_id" binary(16),
    "canceled_at" datetime,
    "completed_at" datetime,
    "no_notification_order" bit(1),
    "metadata" json,
    "idempotency_key" varchar(63), -- TODO check
    CONSTRAINT "CK_afad4027-baf6-46bb-8839-c2ae50ca7888" CHECK ("status" IN ('open', 'completed')),
    CONSTRAINT "UQ_01c7feb7-45f2-4ff6-89a1-1e94da3b17fe" UNIQUE ("cart_id"),
    CONSTRAINT "UQ_34d69a25-e455-44f2-a059-0f70f0e972d7" UNIQUE ("order_id"),
    CONSTRAINT "FK_b776c589-cc95-4f19-9a39-1278e133787e" FOREIGN KEY ("cart_id") REFERENCES "cart" ("id") ON DELETE CASCADE,
    CONSTRAINT "FK_3751fb17-be3d-4f59-b936-94d4ea749f86" FOREIGN KEY ("order_id") REFERENCES "order" ("id")
  );

CREATE INDEX "IX_28c40dba-d463-4937-b339-efebb6921b53" ON "draft_order" ("display_id");

CREATE INDEX "IX_17f2d722-444a-4ad1-be7d-db13c94750de" ON "draft_order" ("cart_id");

CREATE INDEX "IX_06f8acbd-cbc0-426e-9e85-f92f364fb047" ON "draft_order" ("order_id");

CREATE TABLE
  "gift_card_transaction" (
    "id" binary(16) PRIMARY KEY,
    "gift_card_id" binary(16) NOT NULL,
    "order_id" binary(16) NOT NULL,
    "amount" integer NOT NULL,
    "created_at" datetime NOT NULL DEFAULT NOW(),
    "is_taxable" bit(1),
    "tax_rate" real,
    CONSTRAINT "UQ_1d7e0f6a-5c9e-4180-945a-d61568a9e71e" UNIQUE ("gift_card_id", "order_id"),
    CONSTRAINT "FK_43fbe911-7e8e-4e35-a31b-b662bf769bd3" FOREIGN KEY ("gift_card_id") REFERENCES "gift_card" ("id"),
    CONSTRAINT "FK_e9a27cb5-788f-447d-a340-002d961a586a" FOREIGN KEY ("order_id") REFERENCES "order" ("id")
  );

CREATE INDEX "IX_8ab8ee60-3d64-49ee-a7ab-7e75bf2b4da8" ON "gift_card_transaction" ("order_id");

CREATE TABLE
  "refund" (
    "id" binary(16) PRIMARY KEY,
    "created_at" datetime NOT NULL DEFAULT NOW(),
    "updated_at" datetime NOT NULL DEFAULT NOW(),
    "order_id" binary(16),
    "payment_id" binary(16),
    "amount" integer NOT NULL,
    "note" varchar(191),
    "reason" VARCHAR(8) NOT NULL,
    "metadata" json,
    "idempotency_key" varchar(63), -- TODO check
    CONSTRAINT "CK_bae8e8ad-bf38-496c-94ca-4ada2062f273" CHECK (
      "reason" IN ('discount', 'return', 'swap', 'claim', 'other')
    ),
    CONSTRAINT "UQ_5d857a38-8aee-4057-836e-aeb9d47a50ce" UNIQUE ("payment_id"),
    CONSTRAINT "FK_d14a2769-46ea-4cc1-8ef5-97a9ce660386" FOREIGN KEY ("order_id") REFERENCES "order" ("id"),
    CONSTRAINT "FK_ff8796e6-ad13-4d5c-a738-94f5fade4d02" FOREIGN KEY ("payment_id") REFERENCES "payment" ("id")
  );

CREATE INDEX "IX_9d1b858b-88ac-4e7f-9840-a6f89ec2e70b" ON "refund" ("order_id");

CREATE INDEX "IX_caeeb080-806e-41a2-b1e3-4fb824429b8c" ON "refund" ("payment_id");

CREATE TABLE
  "order" (
    "id" binary(16) PRIMARY KEY,
    "created_at" datetime NOT NULL DEFAULT NOW(),
    "updated_at" datetime NOT NULL DEFAULT NOW(),
    "status" varchar(15) NOT NULL DEFAULT('pending'),
    "fulfillment_status" varchar(19) NOT NULL DEFAULT('not_fulfilled'),
    "payment_status" varchar(18) NOT NULL DEFAULT('not_paid'),
    "display_id" binary(16) NOT NULL,
    "cart_id" binary(16),
    "customer_id" binary(16) NOT NULL,
    "email" varchar(254) NOT NULL,
    "billing_address_id" binary(16),
    "shipping_address_id" binary(16),
    "region_id" binary(16) NOT NULL,
    "currency_code" char(3) NOT NULL,
    "tax_rate" real,
    "draft_order_id" binary(16),
    "canceled_at" datetime,
    "metadata" json,
    "no_notification" bit(1),
    "idempotency_key" varchar(63),
    "external_id" text,
    "sales_channel_id" binary(16),
    CONSTRAINT "CK_8a53780e-67a7-4d5c-9906-6242c656bc90" CHECK (
      "status" IN (
        'pending',
        'completed',
        'archived',
        'canceled',
        'requires_action'
      )
    ),
    CONSTRAINT "CK_6eab1ae4-f0be-48ef-8cd2-97bab42eb690" CHECK (
      "fulfillment_status" IN (
        'not_fulfilled',
        'partially_fulfilled',
        'fulfilled',
        'partially_shipped',
        'shipped',
        'partially_returned',
        'returned',
        'canceled',
        'requires_action'
      )
    ),
    CONSTRAINT "CK_bafede52-160b-4bec-a31c-cfc42dc75126" CHECK (
      "payment_status" IN (
        'not_paid',
        'awaiting',
        'captured',
        'partially_refunded',
        'refunded',
        'canceled',
        'requires_action'
      )
    ),
    CONSTRAINT "UQ_d6639c08-c80d-4690-bd51-a717ad28318e" UNIQUE ("cart_id"),
    CONSTRAINT "UQ_9bcd1f8d-7c07-4765-bbc8-0515a467fdc9" UNIQUE ("draft_order_id"),
    CONSTRAINT "FK_bf5d9d30-8bd4-40a4-9d7b-99992736741e" FOREIGN KEY ("cart_id") REFERENCES "cart" ("id"),
    CONSTRAINT "FK_819b416f-2031-4322-8189-14b9b8380624" FOREIGN KEY ("customer_id") REFERENCES "customer" ("id"),
    CONSTRAINT "FK_94d0f526-c95c-4d32-84b1-e4de89cf93ce" FOREIGN KEY ("billing_address_id") REFERENCES "address" ("id"),
    CONSTRAINT "FK_42daab6b-b219-4435-ba91-5e760e20bf20" FOREIGN KEY ("shipping_address_id") REFERENCES "address" ("id"),
    CONSTRAINT "FK_4b348c33-98d5-4d78-b19c-24740949d5b9" FOREIGN KEY ("region_id") REFERENCES "region" ("id"),
    CONSTRAINT "FK_7ce838f2-0359-44ee-8bb2-d7c7280da6cc" FOREIGN KEY ("currency_code") REFERENCES "currency" ("code"),
    CONSTRAINT "FK_62765b4f-fbd2-48fa-9d4f-0d5b319ee8e8" FOREIGN KEY ("draft_order_id") REFERENCES "draft_order" ("id"),
    CONSTRAINT "FK_7e2621dd-8229-4f17-8217-055bcd7d68f7" FOREIGN KEY ("sales_channel_id") REFERENCES "sales_channel" ("id")
  );

CREATE INDEX "IX_161eade6-58cf-45a4-9af9-8d805bc5fdf1" ON "order" ("display_id");

CREATE INDEX "IX_1c6a71f5-2b5e-4aaa-8071-b70d80222551" ON "order" ("cart_id");

CREATE INDEX "IX_be9550b3-6455-4649-bea7-eda8d621555e" ON "order" ("customer_id");

CREATE INDEX "IX_20d544d8-3a4a-44b9-8482-b6755898bc3c" ON "order" ("billing_address_id");

CREATE INDEX "IX_3323ff72-79b3-44ea-9e57-61888fb8ce09" ON "order" ("shipping_address_id");

CREATE INDEX "IX_c2dacf60-e7ea-48b6-b7c9-a15db84924b5" ON "order" ("region_id");

CREATE INDEX "IX_546a2378-5219-4b89-8ae1-96e2ceb9394d" ON "order" ("currency_code");

CREATE TABLE
  "customer" (
    "id" binary(16) PRIMARY KEY,
    "created_at" datetime NOT NULL DEFAULT NOW(),
    "updated_at" datetime NOT NULL DEFAULT NOW(),
    "deleted_at" datetime,
    "email" varchar(254) NOT NULL,
    "first_name" varchar(63),
    "last_name" varchar(63),
    "billing_address_id" binary(16),
    "password_hash" varchar(60),
    "phone" varchar(63),
    "has_account" bit(1) NOT NULL DEFAULT 0x00,
    "metadata" json,
    CONSTRAINT "UQ_1e94e4c0-5144-4b1c-965f-7e09e3aa2671" UNIQUE ("email", "has_account"),
    CONSTRAINT "UQ_193db8f6-e71d-4c85-aa58-3bf9a91145c5" UNIQUE ("billing_address_id"),
    CONSTRAINT "FK_78d07c58-22be-4fab-b6f8-a93bf04930bd" FOREIGN KEY ("billing_address_id") REFERENCES "address" ("id")
  );

CREATE INDEX "IX_a7ecbb0c-ae33-4935-b3e7-a3b62846040b" ON "customer" ("email");

CREATE INDEX "IX_4d221497-21bc-4c4b-9eb7-37b0e8c7f65b" ON "customer" ("billing_address_id");

CREATE TABLE
  "money_amount" (
    "id" binary(16) PRIMARY KEY,
    "created_at" datetime NOT NULL DEFAULT NOW(),
    "updated_at" datetime NOT NULL DEFAULT NOW(),
    "deleted_at" datetime,
    "currency_code" char(3) NOT NULL,
    "amount" integer NOT NULL,
    "min_quantity" integer,
    "max_quantity" integer,
    "price_list_id" binary(16),
    "variant_id" binary(16),
    "region_id" binary(16),
    CONSTRAINT "FK_e5d8706c-64c9-41c3-8930-898e5d1f855d" FOREIGN KEY ("currency_code") REFERENCES "currency" ("code"),
    CONSTRAINT "FK_34c4e0e6-92ec-424f-ab42-cea667b57476" FOREIGN KEY ("price_list_id") REFERENCES "price_list" ("id") ON DELETE CASCADE,
    CONSTRAINT "FK_f421fb35-cb3c-422e-82f4-ca1f818682af" FOREIGN KEY ("variant_id") REFERENCES "product_variant" ("id") ON DELETE CASCADE,
    CONSTRAINT "FK_13cfcaf8-6400-4bfe-aa90-8a8e83b17890" FOREIGN KEY ("region_id") REFERENCES "region" ("id")
  );

CREATE INDEX "IX_f22a1764-92e1-4277-9b2a-e755962087f9" ON "money_amount" ("currency_code");

CREATE INDEX "IX_bb8995da-82d6-4916-9e7d-80d0546fd71a" ON "money_amount" ("variant_id");

CREATE INDEX "IX_4db9c040-f56a-45d8-84ed-5bf8481f366c" ON "money_amount" ("region_id");

CREATE TABLE
  "product_variant_inventory_item" (
    "id" binary(16) PRIMARY KEY,
    "created_at" datetime NOT NULL DEFAULT NOW(),
    "updated_at" datetime NOT NULL DEFAULT NOW(),
    "deleted_at" datetime,
    "inventory_item_id" binary(16) NOT NULL,
    "variant_id" binary(16) NOT NULL,
    "required_quantity" integer NOT NULL DEFAULT 1,
    CONSTRAINT "FK_bf0a3b04-1fc5-4f54-bc87-3d6117560252" FOREIGN KEY ("variant_id") REFERENCES "product_variant" ("id")
  );

CREATE INDEX "IX_0b3aaa73-79f9-4640-a884-c19f69199a91" ON "product_variant_inventory_item" ("inventory_item_id");

CREATE INDEX "IX_0d9deabd-ea47-4b37-912f-3af3b773269b" ON "product_variant_inventory_item" ("variant_id");

CREATE TABLE
  "product_variant" (
    "id" binary(16) PRIMARY KEY,
    "created_at" datetime NOT NULL DEFAULT NOW(),
    "updated_at" datetime NOT NULL DEFAULT NOW(),
    "deleted_at" datetime,
    "title" varchar(63) NOT NULL,
    "product_id" binary(16) NOT NULL,
    "sku" varchar(63),
    "barcode" varchar(63),
    "ean" varchar(13),
    "upc" varchar(12),
    "variant_rank" integer DEFAULT 0,
    "inventory_quantity" integer NOT NULL,
    "allow_backorder" bit(1) NOT NULL DEFAULT 0x00,
    "manage_inventory" bit(1) NOT NULL DEFAULT 0x01,
    "hs_code" varchar(63),
    "origin_country" char(2),
    "mid_code" varchar(63),
    "material" text,
    "weight" integer,
    "length" integer,
    "height" integer,
    "width" integer,
    "metadata" json,
    CONSTRAINT "FK_df519082-742f-406d-940b-7e3a2612424b" FOREIGN KEY ("product_id") REFERENCES "product" ("id"),
    CONSTRAINT "FK_e07a4177-ee4d-4247-ab13-db942db5770b" FOREIGN KEY ("origin_country") REFERENCES "country" ("code")
  );

CREATE INDEX "IX_7442d170-27eb-476f-bd12-ef9ef4beb96b" ON "product_variant" ("product_id");

CREATE UNIQUE INDEX "IX_68d80bed-be2e-44b8-9a7c-a0dc13e2ca7d" ON "product_variant" (
  "sku",
  (
    CASE
      WHEN "deleted_at" IS NULL THEN 0x01
      ELSE NULL
    END
  )
);

CREATE UNIQUE INDEX "IX_db2783e9-89e4-448d-8eef-4d7a2f178f97" ON "product_variant" (
  "barcode",
  (
    CASE
      WHEN "deleted_at" IS NULL THEN 0x01
      ELSE NULL
    END
  )
);

CREATE UNIQUE INDEX "IX_dba4f7ec-1061-4e82-82fd-479d851d75ac" ON "product_variant" (
  "ean",
  (
    CASE
      WHEN "deleted_at" IS NULL THEN 0x01
      ELSE NULL
    END
  )
);

CREATE UNIQUE INDEX "IX_be0701ee-6fe1-4baa-8621-29c8c493ca65" ON "product_variant" (
  "upc",
  (
    CASE
      WHEN "deleted_at" IS NULL THEN 0x01
      ELSE NULL
    END
  )
);

CREATE TABLE
  "product_option_value" (
    "id" binary(16) PRIMARY KEY,
    "created_at" datetime NOT NULL DEFAULT NOW(),
    "updated_at" datetime NOT NULL DEFAULT NOW(),
    "deleted_at" datetime,
    "name" varchar(63) NOT NULL,
    "option_id" binary(16) NOT NULL,
    "variant_id" binary(16) NOT NULL,
    "metadata" json,
    CONSTRAINT "FK_5ad935e8-5206-47bb-8cd7-12f2e3c664e0" FOREIGN KEY ("option_id") REFERENCES "product_option" ("id"),
    CONSTRAINT "FK_07ca72fb-ab3a-48fc-9b3a-72294cc3c858" FOREIGN KEY ("variant_id") REFERENCES "product_variant" ("id") ON DELETE CASCADE
  );

CREATE INDEX "IX_ff95676a-80f5-45f0-9a54-b52b70310564" ON "product_option_value" ("option_id");

CREATE INDEX "IX_11cde975-5cc1-4f71-9745-a86f715bf18d" ON "product_option_value" ("variant_id");

CREATE TABLE
  "product_option" (
    "id" binary(16) PRIMARY KEY,
    "created_at" datetime NOT NULL DEFAULT NOW(),
    "updated_at" datetime NOT NULL DEFAULT NOW(),
    "deleted_at" datetime,
    "title" varchar(63) NOT NULL,
    "product_id" binary(16) NOT NULL,
    "metadata" json,
    CONSTRAINT "FK_ce6a3d79-22b3-432d-b0d7-069c82c895ca" FOREIGN KEY ("product_id") REFERENCES "product" ("id")
  );

CREATE TABLE
  "product_category" (
    "id" binary(16) PRIMARY KEY,
    "created_at" datetime NOT NULL DEFAULT NOW(),
    "updated_at" datetime NOT NULL DEFAULT NOW(),
    "deleted_at" datetime,
    "name" varchar(63) NOT NULL,
    "handle" varchar(63) NOT NULL,
    "is_active" bit(1) NOT NULL,
    "is_internal" bit(1) NOT NULL,
    "parent_category_id" binary(16) NOT NULL,
    CONSTRAINT "FK_02e51bdc-23bc-46e4-966f-fba89fa44259" FOREIGN KEY ("parent_category_id") REFERENCES "product_category" ("id")
  );

CREATE UNIQUE INDEX "IX_82637fe3-5fb4-4259-8f11-b02725aafd5b" ON "product_category" (
  "handle",
  (
    CASE
      WHEN "deleted_at" IS NULL THEN 0x01
      ELSE NULL
    END
  )
);

CREATE TABLE
  "product" (
    "id" binary(16) PRIMARY KEY,
    "created_at" datetime NOT NULL DEFAULT NOW(),
    "updated_at" datetime NOT NULL DEFAULT NOW(),
    "deleted_at" datetime,
    "title" varchar(63) NOT NULL,
    "subtitle" varchar(191),
    "description" text,
    "handle" varchar(63) NOT NULL,
    "is_giftcard" bit(1) NOT NULL DEFAULT 0x00,
    "status" varchar(9) NOT NULL DEFAULT 'draft',
    "thumbnail" text,
    "profile_id" binary(16) NOT NULL,
    "weight" integer,
    "length" integer,
    "height" integer,
    "width" integer,
    "hs_code" varchar(63),
    "origin_country" char(2),
    "mid_code" text,
    "material" text,
    "collection_id" binary(16),
    "type_id" binary(16),
    "discountable" bit(1) NOT NULL DEFAULT 0x01,
    "external_id" text,
    "metadata" json,
    CONSTRAINT "CK_9779636b-f2da-4b9b-82db-fb986720f166" CHECK (
      "status" IN ('draft', 'proposed', 'published', 'rejected')
    ),
    CONSTRAINT "FK_5ce072b3-dc9b-4c9f-8035-127a79d4c1f2" FOREIGN KEY ("profile_id") REFERENCES "shipping_profile" ("id"),
    CONSTRAINT "FK_946002f1-2e0d-488b-a2cf-181378ff6c83" FOREIGN KEY ("origin_country") REFERENCES "country" ("code"),
    CONSTRAINT "FK_79768901-a193-4ee9-8a90-9404cd91348e" FOREIGN KEY ("collection_id") REFERENCES "product_collection" ("id"),
    CONSTRAINT "FK_f9256204-73e1-4079-90ed-ce7a32b3254a" FOREIGN KEY ("type_id") REFERENCES "product_type" ("id")
  );

CREATE UNIQUE INDEX "IX_3ea72bd9-fa5e-43fe-b106-3d32d4b3f982" ON "product" (
  "handle",
  (
    CASE
      WHEN "deleted_at" IS NULL THEN 0x01
      ELSE NULL
    END
  )
);

CREATE INDEX "IX_97e19e2b-0c5c-4d8d-b20c-4f8d8e08b837" ON "product" ("profile_id");

CREATE TABLE
  "tax_rate" (
    "id" binary(16) PRIMARY KEY,
    "created_at" datetime NOT NULL DEFAULT NOW(),
    "updated_at" datetime NOT NULL DEFAULT NOW(),
    "rate" real,
    "code" varchar(63),
    "name" varchar(63) NOT NULL,
    "region_id" binary(16) NOT NULL,
    "metadata" json,
    CONSTRAINT "FK_f708e5c3-4871-40b2-8dc3-046db20961fd" FOREIGN KEY ("region_id") REFERENCES "region" ("id")
  );

CREATE TABLE
  "region" (
    "id" binary(16) PRIMARY KEY,
    "created_at" datetime NOT NULL DEFAULT NOW(),
    "updated_at" datetime NOT NULL DEFAULT NOW(),
    "deleted_at" datetime,
    "name" varchar(63) NOT NULL,
    "currency_code" char(3) NOT NULL,
    "tax_rate" real NOT NULL,
    "tax_code" varchar(63),
    "includes_tax" bit(1) NOT NULL DEFAULT 0x00,
    "gift_cards_taxable" bit(1) NOT NULL DEFAULT 0x01,
    "automatic_taxes" bit(1) NOT NULL DEFAULT 0x01,
    "tax_provider_id" binary(16),
    "metadata" json,
    CONSTRAINT "FK_f6a1cddc-f0ca-40a6-8f82-eff7cda3ccd4" FOREIGN KEY ("currency_code") REFERENCES "currency" ("code"),
    CONSTRAINT "FK_845dc700-49b5-4fff-82cc-23c3b9f9fd0f" FOREIGN KEY ("tax_provider_id") REFERENCES "tax_provider" ("id")
  );

CREATE INDEX "IX_66914c30-4289-49b5-a90d-d0438c7c127c" ON "region" ("currency_code");

CREATE TABLE
  "country" (
    "id" binary(16) PRIMARY KEY,
    "code" char(2), -- ISO 3166-1 alpha 2
    "region_id" binary(16),
    CONSTRAINT "UQ_a5bca56a-4502-483f-8d9c-df8df15b6a3f" UNIQUE ("code"),
    CONSTRAINT "FK_113800f7-a578-456b-a3e1-ef020a28e40c" FOREIGN KEY ("region_id") REFERENCES "region" ("id")
  );

CREATE INDEX "IX_5a89974a-cccd-4a81-b03d-814907bf478d" ON "country" ("region_id");

CREATE TABLE
  "address" (
    "id" binary(16) PRIMARY KEY,
    "created_at" datetime NOT NULL DEFAULT NOW(),
    "updated_at" datetime NOT NULL DEFAULT NOW(),
    "deleted_at" datetime,
    "customer_id" binary(16) NOT NULL,
    "company" varchar(63),
    "first_name" varchar(63) NOT NULL,
    "last_name" varchar(63) NOT NULL,
    "address_1" varchar(191) NOT NULL,
    "address_2" varchar(191),
    "city" varchar(63) NOT NULL,
    "country_code" char(2) NOT NULL,
    "province" varchar(63) NOT NULL,
    "postal_code" varchar(63) NOT NULL,
    "phone" varchar(63) NOT NULL,
    "metadata" json,
    CONSTRAINT "FK_ae763a01-3045-425b-8377-9b14078ee19b" FOREIGN KEY ("customer_id") REFERENCES "customer" ("id"),
    CONSTRAINT "FK_e0cf5f4d-f5c8-42ca-9d64-044599264224" FOREIGN KEY ("country_code") REFERENCES "country" ("code")
  );

CREATE INDEX "IX_e2bb5613-01e7-4374-9b9e-d542b9647023" ON "address" ("customer_id");

CREATE TABLE
  "custom_shipping_option" (
    "id" binary(16) PRIMARY KEY,
    "created_at" datetime NOT NULL DEFAULT NOW(),
    "updated_at" datetime NOT NULL DEFAULT NOW(),
    "deleted_at" datetime,
    "price" integer NOT NULL,
    "shipping_option_id" binary(16) NOT NULL,
    "cart_id" binary(16),
    "metadata" json,
    CONSTRAINT "UQ_f04f8536-3fd2-4fc2-9365-08560a3102ba" UNIQUE ("shipping_option_id", "cart_id"),
    CONSTRAINT "FK_d0dd6188-a967-4aee-91da-752bc2df9377" FOREIGN KEY ("shipping_option_id") REFERENCES "shipping_option" ("id"),
    CONSTRAINT "FK_26ede49d-2f6f-45ad-bb6c-bbe50f17d5ad" FOREIGN KEY ("cart_id") REFERENCES "cart" ("id")
  );

CREATE INDEX "IX_c86fd5e0-fa2e-4771-b117-e1f6d0238e96" ON "custom_shipping_option" ("shipping_option_id");

CREATE INDEX "IX_e651fab8-d5e3-483b-af84-5a217a9c5400" ON "custom_shipping_option" ("cart_id");

CREATE TABLE
  "discount_condition_customer_group" (
    "customer_group_id" binary(16) NOT NULL,
    "condition_id" binary(16) NOT NULL,
    "created_at" datetime NOT NULL DEFAULT NOW(),
    "updated_at" datetime NOT NULL DEFAULT NOW(),
    "metadata" json,
    CONSTRAINT "FK_339759b8-d315-48de-8ede-bd5d5daf857b" FOREIGN KEY ("customer_group_id") REFERENCES "customer_group" ("id") ON DELETE CASCADE,
    CONSTRAINT "FK_1f3649f4-d40e-4189-9de8-67c5d8d4024f" FOREIGN KEY ("condition_id") REFERENCES "discount_condition" ("id") ON DELETE CASCADE,
    PRIMARY KEY ("customer_group_id", "condition_id")
  );

CREATE INDEX "IX_50958e0f-d989-4362-8f10-d7e7d2fb66c0" ON "discount_condition_customer_group" ("condition_id");

CREATE INDEX "IX_c013bb69-b9d4-4181-8e6f-aea650bcd0f0" ON "discount_condition_customer_group" ("customer_group_id");

CREATE TABLE
  "discount_condition_product" (
    "product_id" binary(16) NOT NULL,
    "condition_id" binary(16) NOT NULL,
    "created_at" datetime NOT NULL DEFAULT NOW(),
    "updated_at" datetime NOT NULL DEFAULT NOW(),
    "metadata" json,
    CONSTRAINT "FK_4e2ae138-4f63-4525-80ca-ec981d2225b2" FOREIGN KEY ("product_id") REFERENCES "product" ("id") ON DELETE CASCADE,
    CONSTRAINT "FK_1389fab2-ad2c-4ca5-b2e5-07da3f256578" FOREIGN KEY ("condition_id") REFERENCES "discount_condition" ("id") ON DELETE CASCADE,
    PRIMARY KEY ("product_id", "condition_id")
  );

CREATE INDEX "IX_ad831148-4858-47d2-bc64-c60693fe12d3" ON "discount_condition_product" ("condition_id");

CREATE INDEX "IX_9df90805-bf0d-4a86-b06f-cb41cde27959" ON "discount_condition_product" ("product_id");

CREATE TABLE
  "discount_condition_product_collection" (
    "product_collection_id" binary(16) NOT NULL,
    "condition_id" binary(16) NOT NULL,
    "created_at" datetime NOT NULL DEFAULT NOW(),
    "updated_at" datetime NOT NULL DEFAULT NOW(),
    "metadata" json,
    CONSTRAINT "FK_94efcb11-ab64-41f7-9c5b-9768b64e72fa" FOREIGN KEY ("product_collection_id") REFERENCES "product_collection" ("id") ON DELETE CASCADE,
    CONSTRAINT "FK_63e6b5dc-8415-411a-89c3-7130d5b586cc" FOREIGN KEY ("condition_id") REFERENCES "discount_condition" ("id") ON DELETE CASCADE,
    PRIMARY KEY ("product_collection_id", "condition_id")
  );

CREATE INDEX "IX_b24198f8-1e4d-427f-b0eb-11f33ec00fcf" ON "discount_condition_product_collection" ("condition_id");

CREATE INDEX "IX_6b18cea2-e620-409d-8c75-6a7d0d8973b9" ON "discount_condition_product_collection" ("product_collection_id");

CREATE TABLE
  "discount_condition_product_tag" (
    "product_tag_id" binary(16) NOT NULL,
    "condition_id" binary(16) NOT NULL,
    "created_at" datetime NOT NULL DEFAULT NOW(),
    "updated_at" datetime NOT NULL DEFAULT NOW(),
    "metadata" json,
    CONSTRAINT "FK_29ffed51-be01-498c-ab37-e55aaa89aa5a" FOREIGN KEY ("product_tag_id") REFERENCES "product_tag" ("id") ON DELETE CASCADE,
    CONSTRAINT "FK_5f239071-2d47-4b1f-b4ca-5c3613b03ffd" FOREIGN KEY ("condition_id") REFERENCES "discount_condition" ("id") ON DELETE CASCADE,
    PRIMARY KEY ("product_tag_id", "condition_id")
  );

CREATE INDEX "IX_7b660f63-5cc4-419f-87db-080cc7d45461" ON "discount_condition_product_tag" ("condition_id");

CREATE INDEX "IX_1d9362f9-a35b-4912-86e1-02b685aee79d" ON "discount_condition_product_tag" ("product_tag_id");

CREATE TABLE
  "discount_condition_product_type" (
    "product_type_id" binary(16) NOT NULL,
    "condition_id" binary(16) NOT NULL,
    "created_at" datetime NOT NULL DEFAULT NOW(),
    "updated_at" datetime NOT NULL DEFAULT NOW(),
    "metadata" json,
    CONSTRAINT "FK_ead57d77-8436-46aa-b1a1-cf7f6f376e4e" FOREIGN KEY ("product_type_id") REFERENCES "product_type" ("id") ON DELETE CASCADE,
    CONSTRAINT "FK_ce352b6e-3094-4d90-8bf1-d65008d0985f" FOREIGN KEY ("condition_id") REFERENCES "discount_condition" ("id") ON DELETE CASCADE,
    PRIMARY KEY ("product_type_id", "condition_id")
  );

CREATE INDEX "IX_18d668bd-b2ed-487c-adf4-049fc25c2708" ON "discount_condition_product_type" ("condition_id");

CREATE INDEX "IX_e2ca954b-ca58-4352-9dec-ccd41b4c9a7c" ON "discount_condition_product_type" ("product_type_id");

CREATE TABLE
  "note" (
    "id" binary(16) PRIMARY KEY,
    "created_at" datetime NOT NULL DEFAULT NOW(),
    "updated_at" datetime NOT NULL DEFAULT NOW(),
    "deleted_at" datetime,
    "value" varchar(191) NOT NULL,
    "resource_type" varchar(63) NOT NULL,
    "resource_id" binary(16) NOT NULL,
    "author_id" binary(16),
    "metadata" json,
    CONSTRAINT "FK_866474ad-5bfa-40b0-b9a9-4de408d59973" FOREIGN KEY ("author_id") REFERENCES "user" ("id")
  );

CREATE INDEX "IX_38806136-dc23-4b8d-b878-6ed08a3cad93" ON "note" ("resource_type");

CREATE INDEX "IX_501f5c5b-3a51-4eb6-aeb9-919bb95920ae" ON "note" ("resource_id");

CREATE TABLE
  "notification" (
    "id" binary(16) PRIMARY KEY,
    "created_at" datetime NOT NULL DEFAULT NOW(),
    "updated_at" datetime NOT NULL DEFAULT NOW(),
    "event_name" varchar(63),
    "resource_type" varchar(63) NOT NULL,
    "resource_id" binary(16) NOT NULL,
    "customer_id" binary(16),
    "to" varchar(254) NOT NULL,
    "data" json NOT NULL,
    "parent_id" binary(16),
    "provider_id" binary(16),
    CONSTRAINT "FK_5379eec8-9174-4d6a-9ef9-345d2a957035" FOREIGN KEY ("customer_id") REFERENCES "customer" ("id"),
    CONSTRAINT "FK_131d9f39-2911-4f18-907f-f28fb97ea922" FOREIGN KEY ("parent_id") REFERENCES "notification" ("id"),
    CONSTRAINT "FK_cd8afdbe-0fdd-43b3-b853-c26651dd90f8" FOREIGN KEY ("provider_id") REFERENCES "notification_provider" ("id")
  );

CREATE INDEX "IX_72a0f7aa-f24b-4c41-849b-50b8359d5637" ON "notification" ("resource_type");

CREATE INDEX "IX_ff021761-4162-455a-b747-adf3c40cb95f" ON "notification" ("resource_id");

CREATE INDEX "IX_6ea16404-c565-4e02-b233-c9a59335fb00" ON "notification" ("customer_id");

CREATE TABLE
  "order_item_change" (
    "id" binary(16) PRIMARY KEY,
    "created_at" datetime NOT NULL DEFAULT NOW(),
    "updated_at" datetime NOT NULL DEFAULT NOW(),
    "deleted_at" datetime,
    "type" varchar(11) NOT NULL,
    "order_edit_id" binary(16) NOT NULL,
    "original_line_item_id" binary(16),
    "line_item_id" binary(16),
    CONSTRAINT "CK_21c3a57c-0596-4be0-95db-96ff09469343" CHECK (
      "type" IN ('item_add', 'item_remove', 'item_update')
    ),
    CONSTRAINT "UQ_9604e1a4-c677-436b-96ec-650957674cad" UNIQUE ("order_edit_id", "line_item_id"),
    CONSTRAINT "UQ_e4e5489e-2893-4f09-86bd-0161e705f66b" UNIQUE ("order_edit_id", "original_line_item_id"),
    CONSTRAINT "UQ_11957938-8a11-4745-9363-7ff86a9825d9" UNIQUE ("line_item_id"),
    CONSTRAINT "FK_66a2d1b8-b214-4711-9610-e2d57ebd1a5d" FOREIGN KEY ("order_edit_id") REFERENCES "order_edit" ("id"),
    CONSTRAINT "FK_7063536d-7b16-437c-8cee-271e4ba40d84" FOREIGN KEY ("original_line_item_id") REFERENCES "line_item" ("id"),
    CONSTRAINT "FK_32a7b9ce-2e10-41c6-a6a8-ac65adf0a5c3" FOREIGN KEY ("line_item_id") REFERENCES "line_item" ("id")
  );

CREATE TABLE
  "payment_collection" (
    "id" binary(16) PRIMARY KEY,
    "created_at" datetime NOT NULL DEFAULT NOW(),
    "updated_at" datetime NOT NULL DEFAULT NOW(),
    "deleted_at" datetime,
    "type" varchar(10) NOT NULL,
    "status" varchar(20) NOT NULL,
    "description" varchar(191),
    "amount" integer NOT NULL,
    "authorized_amount" integer,
    "region_id" binary(16) NOT NULL,
    "currency_code" char(3) NOT NULL,
    "metadata" json NOT NULL,
    "created_by" binary(16) NOT NULL,
    CONSTRAINT "CK_3321c347-922e-4f33-9018-7ffd5f75de01" CHECK ("type" IN ('order_edit')),
    CONSTRAINT "CK_1f94cb0b-9649-47e8-a141-01a7f43867db" CHECK (
      "status" IN (
        'not_paid',
        'awaiting',
        'authorized',
        'partially_authorized',
        'canceled'
      )
    ),
    CONSTRAINT "FK_db50b1af-758b-4e29-9b60-24886d4416f8" FOREIGN KEY ("region_id") REFERENCES "region" ("id"),
    CONSTRAINT "FK_3df43deb-6bf3-4d4d-8dae-a6b9e61c731a" FOREIGN KEY ("currency_code") REFERENCES "currency" ("code")
  );

CREATE INDEX "IX_927795ee-b501-42f9-b24f-0735df8d6c35" ON "payment_collection" ("region_id");

CREATE INDEX "IX_fb393f01-06cb-4f73-bf3f-2a702b3e8de6" ON "payment_collection" ("currency_code");

CREATE TABLE
  "product_tax_rate" (
    "product_id" binary(16) NOT NULL,
    "rate_id" binary(16) NOT NULL,
    "created_at" datetime NOT NULL DEFAULT NOW(),
    "updated_at" datetime NOT NULL DEFAULT NOW(),
    "metadata" json,
    CONSTRAINT "FK_f3e8b4b1-fc14-4522-a317-accc39fa1899" FOREIGN KEY ("product_id") REFERENCES "product" ("id") ON DELETE CASCADE,
    CONSTRAINT "FK_92d8f9c3-1969-421b-9209-190ead5d9134" FOREIGN KEY ("rate_id") REFERENCES "tax_rate" ("id") ON DELETE CASCADE,
    PRIMARY KEY ("product_id", "rate_id")
  );

CREATE INDEX "IX_fc7c3ba9-58d0-459a-8954-c9c7c2b0d23c" ON "product_tax_rate" ("rate_id");

CREATE INDEX "IX_3d4f263d-d12d-420a-bbd0-082ee4c85cb7" ON "product_tax_rate" ("product_id");

CREATE TABLE
  "product_type_tax_rate" (
    "product_type_id" binary(16) NOT NULL,
    "rate_id" binary(16) NOT NULL,
    "created_at" datetime NOT NULL DEFAULT NOW(),
    "updated_at" datetime NOT NULL DEFAULT NOW(),
    "metadata" json,
    CONSTRAINT "FK_2f6c6775-c38a-46c7-a005-2c17a887018a" FOREIGN KEY ("product_type_id") REFERENCES "product_type" ("id") ON DELETE CASCADE,
    CONSTRAINT "FK_1c20c96c-6306-447c-8e9e-cfe5122b22d5" FOREIGN KEY ("rate_id") REFERENCES "tax_rate" ("id") ON DELETE CASCADE,
    PRIMARY KEY ("product_type_id", "rate_id")
  );

CREATE INDEX "IX_55cc3114-da37-43f2-b56d-949e2bcdab84" ON "product_type_tax_rate" ("rate_id");

CREATE INDEX "IX_90e6026a-f14b-4a64-a992-a840c07110a6" ON "product_type_tax_rate" ("product_type_id");

CREATE TABLE
  "shipping_tax_rate" (
    "shipping_option_id" binary(16) NOT NULL,
    "rate_id" binary(16) NOT NULL,
    "created_at" datetime NOT NULL DEFAULT NOW(),
    "updated_at" datetime NOT NULL DEFAULT NOW(),
    "metadata" json,
    CONSTRAINT "FK_44f01a85-36b2-40de-8374-0d80cc8d541a" FOREIGN KEY ("shipping_option_id") REFERENCES "shipping_option" ("id") ON DELETE CASCADE,
    CONSTRAINT "FK_e2683132-fdd8-44b0-908e-f6c4f829ac8e" FOREIGN KEY ("rate_id") REFERENCES "tax_rate" ("id") ON DELETE CASCADE,
    PRIMARY KEY ("shipping_option_id", "rate_id")
  );

CREATE INDEX "IX_9883ef4a-560a-4caa-b730-290b2359c7a5" ON "shipping_tax_rate" ("rate_id");

CREATE INDEX "IX_c008091a-a7a7-4504-ab32-b37d3b4fbafc" ON "shipping_tax_rate" ("shipping_option_id");

CREATE TABLE
  "store" (
    "id" binary(16) PRIMARY KEY,
    "created_at" datetime NOT NULL DEFAULT NOW(),
    "updated_at" datetime NOT NULL DEFAULT NOW(),
    "name" varchar(63) NOT NULL DEFAULT 'peony store',
    "default_locale_code" varchar(63) NOT NULL DEFAULT 'en',
    "default_currency_code" char(3) NOT NULL DEFAULT 'EUR',
    "swap_link_template" text,
    "payment_link_template" text,
    "invite_link_template" text,
    "default_stock_location_id" binary(16),
    "default_sales_channel_id" binary(16),
    "metadata" json,
    CONSTRAINT "UQ_b92c79c4-802a-4002-8e80-a0d52456fc25" UNIQUE ("default_sales_channel_id"),
    CONSTRAINT "FK_262e04ae-bb99-4d07-9dad-6e1abd7d509f" FOREIGN KEY ("default_locale_code") REFERENCES "locale" ("code"),
    CONSTRAINT "FK_6f1245fe-5009-4689-9c97-216aad8ff2b8" FOREIGN KEY ("default_currency_code") REFERENCES "currency" ("code"),
    CONSTRAINT "FK_7acee9c3-c88c-45e3-a7d0-43b033045622" FOREIGN KEY ("default_sales_channel_id") REFERENCES "sales_channel" ("id")
  );

CREATE TABLE
  "discount_regions" (
    "discount_id" binary(16) NOT NULL,
    "region_id" binary(16) NOT NULL,
    CONSTRAINT "FK_e844ccc0-1c80-4944-9a3e-f21d5573a96e" FOREIGN KEY ("discount_id") REFERENCES "discount" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "FK_a26d5e59-7ce8-4c26-af6c-3532d1254fec" FOREIGN KEY ("region_id") REFERENCES "region" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    PRIMARY KEY ("discount_id", "region_id")
  );

CREATE INDEX "IX_40cf1394-5532-4ad2-92b8-c5787fe03e11" ON "discount_regions" ("discount_id");

CREATE INDEX "IX_c0bad06c-e39a-47fa-b7a5-f4e0799d4e96" ON "discount_regions" ("region_id");

CREATE TABLE
  "claim_item_tags" (
    "item_id" binary(16) NOT NULL,
    "tag_id" binary(16) NOT NULL,
    CONSTRAINT "FK_acfd9846-5204-4195-a9ac-1a600ed402a8" FOREIGN KEY ("item_id") REFERENCES "claim_item" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "FK_fa97b7a9-fbc4-46f1-9a68-cf704b0909cf" FOREIGN KEY ("tag_id") REFERENCES "claim_tag" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    PRIMARY KEY ("item_id", "tag_id")
  );

CREATE INDEX "IX_d99994d7-126f-4974-80a0-d6fad52dc48d" ON "claim_item_tags" ("item_id");

CREATE INDEX "IX_4c293f42-7112-4c25-874e-33bc786fefd1" ON "claim_item_tags" ("tag_id");

CREATE TABLE
  "cart_discounts" (
    "cart_id" binary(16) NOT NULL,
    "discount_id" binary(16) NOT NULL,
    CONSTRAINT "FK_30651805-7dd2-4fea-abce-b2af36668986" FOREIGN KEY ("cart_id") REFERENCES "cart" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "FK_0ab67f83-0d00-4c61-ad30-ba2592cd6086" FOREIGN KEY ("discount_id") REFERENCES "discount" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    PRIMARY KEY ("cart_id", "discount_id")
  );

CREATE INDEX "IX_35571320-166c-4511-b6df-9324f5b8de18" ON "cart_discounts" ("cart_id");

CREATE INDEX "IX_67b46ced-dd22-4df3-a68e-daa87c6eb67c" ON "cart_discounts" ("discount_id");

CREATE TABLE
  "cart_gift_cards" (
    "cart_id" binary(16) NOT NULL,
    "gift_card_id" binary(16) NOT NULL,
    CONSTRAINT "FK_408290bd-45e5-493c-9fc6-3a21df704c1d" FOREIGN KEY ("cart_id") REFERENCES "cart" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "FK_d61226f9-15a3-4e02-b7b1-799c1e3dde5d" FOREIGN KEY ("gift_card_id") REFERENCES "gift_card" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    PRIMARY KEY ("cart_id", "gift_card_id")
  );

CREATE INDEX "IX_ece2526f-80c9-4385-ab1f-fc71524c747c" ON "cart_gift_cards" ("cart_id");

CREATE INDEX "IX_e9eab01d-fba0-4123-a690-1dbab0bba4e0" ON "cart_gift_cards" ("gift_card_id");

CREATE TABLE
  "order_discounts" (
    "order_id" binary(16) NOT NULL,
    "discount_id" binary(16) NOT NULL,
    CONSTRAINT "FK_4d909d52-af62-4133-88cf-cdf4bf1f0078" FOREIGN KEY ("order_id") REFERENCES "order" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "FK_bc355f5f-5004-4a3e-9808-3ca9df7957b4" FOREIGN KEY ("discount_id") REFERENCES "discount" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    PRIMARY KEY ("order_id", "discount_id")
  );

CREATE INDEX "IX_04651987-3f67-49f6-a64a-fbbc58e5cfa6" ON "order_discounts" ("order_id");

CREATE INDEX "IX_97c956f7-78c9-434a-b4fe-0cb757ac99ec" ON "order_discounts" ("discount_id");

CREATE TABLE
  "order_gift_cards" (
    "order_id" binary(16) NOT NULL,
    "gift_card_id" binary(16) NOT NULL,
    CONSTRAINT "FK_b348c27e-f8e1-4ba8-a87b-95f4674b85e1" FOREIGN KEY ("order_id") REFERENCES "order" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "FK_f5efe556-9f6f-40e5-be86-5139230509f5" FOREIGN KEY ("gift_card_id") REFERENCES "gift_card" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    PRIMARY KEY ("order_id", "gift_card_id")
  );

CREATE INDEX "IX_7f12caaa-dfc5-4d56-8052-e75cbcaaf370" ON "order_gift_cards" ("order_id");

CREATE INDEX "IX_1d076f9c-0b3c-4d8c-b058-b71475f86c39" ON "order_gift_cards" ("gift_card_id");

CREATE TABLE
  "customer_group_customers" (
    "customer_id" binary(16) NOT NULL,
    "customer_group_id" binary(16) NOT NULL,
    CONSTRAINT "FK_a3fa916f-b006-492a-8beb-c317c651d359" FOREIGN KEY ("customer_id") REFERENCES "customer" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "FK_e9c36886-9462-47d1-b7f0-1b5a41f1b749" FOREIGN KEY ("customer_group_id") REFERENCES "customer_group" ("id") ON DELETE CASCADE,
    PRIMARY KEY ("customer_id", "customer_group_id")
  );

CREATE INDEX "IX_2e2de930-87f0-4883-a077-ea8e081ecce0" ON "customer_group_customers" ("customer_id");

CREATE INDEX "IX_a3f56738-60d1-4590-b47f-b2b756925a03" ON "customer_group_customers" ("customer_group_id");

CREATE TABLE
  "price_list_customer_groups" (
    "price_list_id" binary(16) NOT NULL,
    "customer_group_id" binary(16) NOT NULL,
    CONSTRAINT "FK_94f77420-96b2-4ddc-92e1-310e4cbb3788" FOREIGN KEY ("price_list_id") REFERENCES "price_list" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "FK_89816574-f11d-4cbd-b0c1-d003076d6383" FOREIGN KEY ("customer_group_id") REFERENCES "customer_group" ("id") ON DELETE CASCADE,
    PRIMARY KEY ("price_list_id", "customer_group_id")
  );

CREATE INDEX "IX_fda3eac4-7d25-427e-9657-2feb7bea59e1" ON "price_list_customer_groups" ("price_list_id");

CREATE INDEX "IX_6d5d50c6-e680-463b-9779-e8b55a52aedc" ON "price_list_customer_groups" ("customer_group_id");

CREATE TABLE
  "product_category_product" (
    "product_category_id" binary(16) NOT NULL,
    "product_id" binary(16) NOT NULL,
    CONSTRAINT "FK_aa942891-58d0-4eb6-884b-a6346201ca9e" FOREIGN KEY ("product_category_id") REFERENCES "product_category" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "FK_f0e71e2b-e1c4-43ce-a3d9-f8b83e0e0952" FOREIGN KEY ("product_id") REFERENCES "product" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    PRIMARY KEY ("product_category_id", "product_id")
  );

CREATE INDEX "IX_21e32b85-06ef-4041-9b17-57c13eeb9d39" ON "product_category_product" ("product_category_id");

CREATE INDEX "IX_dab874f7-cd00-4272-a8ec-b922b4271df6" ON "product_category_product" ("product_id");

CREATE TABLE
  "product_images" (
    "product_id" binary(16) NOT NULL,
    "image_id" binary(16) NOT NULL,
    CONSTRAINT "FK_4d161f58-9f2a-41e5-af92-5ce4267ea7e1" FOREIGN KEY ("product_id") REFERENCES "product" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "FK_59eb4776-60bc-4da2-a068-cb537c5ecb39" FOREIGN KEY ("image_id") REFERENCES "image" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    PRIMARY KEY ("product_id", "image_id")
  );

CREATE INDEX "IX_871e94b3-12d8-4096-9e3e-9a30b93d46a3" ON "product_images" ("product_id");

CREATE INDEX "IX_11f092ff-4a41-49b0-9e08-6687c9b8c255" ON "product_images" ("image_id");

CREATE TABLE
  "product_tags" (
    "product_id" binary(16) NOT NULL,
    "product_tag_id" binary(16) NOT NULL,
    CONSTRAINT "FK_a0ed5b28-0e55-418c-851c-7d2bd183b485" FOREIGN KEY ("product_id") REFERENCES "product" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "FK_d491d367-45bb-4c1c-8401-42acc2659d7a" FOREIGN KEY ("product_tag_id") REFERENCES "product_tag" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    PRIMARY KEY ("product_id", "product_tag_id")
  );

CREATE INDEX "IX_b0542424-d3f9-438e-996a-6c31c5f839f9" ON "product_tags" ("product_id");

CREATE INDEX "IX_2f80b8be-d1b3-4467-a9d5-819dc1f1f012" ON "product_tags" ("product_tag_id");

CREATE TABLE
  "product_sales_channel" (
    "product_id" binary(16) NOT NULL,
    "sales_channel_id" binary(16) NOT NULL,
    CONSTRAINT "FK_9d43c7c1-5ab9-417f-8172-e61cb3c92c67" FOREIGN KEY ("product_id") REFERENCES "product" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "FK_a2bf212c-f33c-45d1-9fcd-a9edf37bc39d" FOREIGN KEY ("sales_channel_id") REFERENCES "sales_channel" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    PRIMARY KEY ("product_id", "sales_channel_id")
  );

CREATE INDEX "IX_ced3d066-3597-4d1f-8d9e-6e158b24b3f8" ON "product_sales_channel" ("product_id");

CREATE INDEX "IX_4e261f60-b261-4a5a-93bf-45a4ccf40f81" ON "product_sales_channel" ("sales_channel_id");

CREATE TABLE
  "region_payment_providers" (
    "region_id" binary(16) NOT NULL,
    "provider_id" binary(16) NOT NULL,
    CONSTRAINT "FK_93ddc225-9960-414e-a347-6a6ea27483c2" FOREIGN KEY ("region_id") REFERENCES "region" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "FK_29427082-3a6c-4e49-98fe-4d97ef8f8751" FOREIGN KEY ("provider_id") REFERENCES "payment_provider" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    PRIMARY KEY ("region_id", "provider_id")
  );

CREATE INDEX "IX_206e1789-62e8-4d29-9a0d-4a1a466cf53c" ON "region_payment_providers" ("region_id");

CREATE INDEX "IX_3ba9807a-0be3-422e-96fa-1f98d21e98b3" ON "region_payment_providers" ("provider_id");

CREATE TABLE
  "region_fulfillment_providers" (
    "region_id" binary(16) NOT NULL,
    "provider_id" binary(16) NOT NULL,
    CONSTRAINT "FK_e928e068-35f6-44f9-9a52-f6197f699f35" FOREIGN KEY ("region_id") REFERENCES "region" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "FK_f098b94c-dd9a-4eaa-bdaf-5b6654beeea2" FOREIGN KEY ("provider_id") REFERENCES "fulfillment_provider" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    PRIMARY KEY ("region_id", "provider_id")
  );

CREATE INDEX "IX_dfeab0f2-cc7b-4c0d-82ef-826e314d1c58" ON "region_fulfillment_providers" ("region_id");

CREATE INDEX "IX_0782997a-e217-472d-bd00-1596c4bb7249" ON "region_fulfillment_providers" ("provider_id");

CREATE TABLE
  "payment_collection_sessions" (
    "payment_collection_id" binary(16) NOT NULL,
    "payment_session_id" binary(16) NOT NULL,
    CONSTRAINT "FK_bf583aeb-974b-42e5-97fd-5225c146e37b" FOREIGN KEY ("payment_collection_id") REFERENCES "payment_collection" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "FK_c766a0c3-6092-42d8-bc6f-8ba6b3c17a3b" FOREIGN KEY ("payment_session_id") REFERENCES "payment_session" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    PRIMARY KEY ("payment_collection_id", "payment_session_id")
  );

CREATE INDEX "IX_0a4632b2-fc1a-48e4-99e6-08e56b61cc01" ON "payment_collection_sessions" ("payment_collection_id");

CREATE INDEX "IX_bad185a6-d4b6-40da-903d-504f7243923f" ON "payment_collection_sessions" ("payment_session_id");

CREATE TABLE
  "payment_collection_payments" (
    "payment_collection_id" binary(16) NOT NULL,
    "payment_id" binary(16) NOT NULL,
    CONSTRAINT "FK_1a41fd97-34c9-42e7-8424-7c231e4f3aa7" FOREIGN KEY ("payment_collection_id") REFERENCES "payment_collection" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "FK_af442c9b-e960-42cc-b6ba-8357a9f987ef" FOREIGN KEY ("payment_id") REFERENCES "payment" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    PRIMARY KEY ("payment_collection_id", "payment_id")
  );

CREATE INDEX "IX_12161d73-9fff-42a1-b93d-ea424c72b2f9" ON "payment_collection_payments" ("payment_collection_id");

CREATE INDEX "IX_f644b12f-d1aa-4767-8ad5-3d99a62d18e9" ON "payment_collection_payments" ("payment_id");

CREATE TABLE
  "store_currencies" (
    "store_id" binary(16) NOT NULL,
    "currency_code" char(3) NOT NULL,
    CONSTRAINT "FK_d0e7c53a-a068-4cee-a4d7-6e1c4aa8e8b8" FOREIGN KEY ("store_id") REFERENCES "store" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "FK_c481d385-91cb-425d-85bd-64709c01d9ee" FOREIGN KEY ("currency_code") REFERENCES "currency" ("code") ON DELETE CASCADE ON UPDATE CASCADE,
    PRIMARY KEY ("store_id", "currency_code")
  );

CREATE INDEX "IX_2d365047-5ac9-4be8-85cd-6f51c25f51e1" ON "store_currencies" ("store_id");

CREATE INDEX "IX_322bd740-fb76-4de3-85bd-5eb514802394" ON "store_currencies" ("currency_code");

-- stock + inventory
CREATE TABLE
  "inventory_item" (
    "id" binary(16) PRIMARY KEY,
    "created_at" datetime NOT NULL DEFAULT NOW(),
    "updated_at" datetime NOT NULL DEFAULT NOW(),
    "deleted_at" datetime,
    "sku" varchar(63),
    "origin_country" char(2),
    "hs_code" varchar(63),
    "mid_code" varchar(63),
    "material" text,
    "weight" integer,
    "length" integer,
    "height" integer,
    "width" integer,
    "requires_shipping" bit(1) NOT NULL DEFAULT 0x01,
    "metadata" json
  );

CREATE UNIQUE INDEX "IX_39c0ddc9-e8d8-45e6-85f0-e965f89c1515" ON "inventory_item" (
  "sku",
  (
    CASE
      WHEN "deleted_at" IS NULL THEN 0x01
      ELSE NULL
    END
  )
);

CREATE TABLE
  "reservation_item" (
    "id" binary(16) PRIMARY KEY,
    "created_at" datetime NOT NULL DEFAULT NOW(),
    "updated_at" datetime NOT NULL DEFAULT NOW(),
    "deleted_at" datetime,
    "line_item_id" binary(16),
    "inventory_item_id" binary(16) NOT NULL,
    "location_id" binary(16) NOT NULL,
    "quantity" integer NOT NULL,
    "metadata" json
  );

CREATE INDEX "IX_0eba5be7-e771-4d7a-ae2e-f6bf84e853b3" ON "reservation_item" (
  "line_item_id",
  (
    CASE
      WHEN "deleted_at" IS NULL THEN 0x01
      ELSE NULL
    END
  )
);

CREATE INDEX "IX_b46e96b2-1381-44ed-9ce2-bddcde151786" ON "reservation_item" (
  "inventory_item_id",
  (
    CASE
      WHEN "deleted_at" IS NULL THEN 0x01
      ELSE NULL
    END
  )
);

CREATE INDEX "IX_6ffbf1d9-4d74-4d1d-ae62-2e9cc3abd2c7" ON "reservation_item" (
  "location_id",
  (
    CASE
      WHEN "deleted_at" IS NULL THEN 0x01
      ELSE NULL
    END
  )
);

CREATE TABLE
  "inventory_level" (
    "id" binary(16) PRIMARY KEY,
    "created_at" datetime NOT NULL DEFAULT NOW(),
    "updated_at" datetime NOT NULL DEFAULT NOW(),
    "deleted_at" datetime,
    "inventory_item_id" binary(16) NOT NULL,
    "location_id" binary(16) NOT NULL,
    "stocked_quantity" integer NOT NULL DEFAULT 0,
    "reserved_quantity" integer NOT NULL DEFAULT 0,
    "incoming_quantity" integer NOT NULL DEFAULT 0,
    "metadata" json,
    CONSTRAINT "UQ_5159c89b-f10c-4f6f-bbfe-459eedca55a7" UNIQUE ("inventory_item_id", "location_id")
  );

CREATE INDEX "IX_0f0d28b6-11d0-4144-98bc-82ce525f305b" ON "inventory_level" ("inventory_item_id");

CREATE INDEX "IX_12d13232-2523-4e3d-b505-fb2d66f3e08f" ON "inventory_level" ("location_id");

CREATE TABLE
  "stock_location_address" (
    "id" binary(16) PRIMARY KEY,
    "created_at" datetime NOT NULL DEFAULT NOW(),
    "updated_at" datetime NOT NULL DEFAULT NOW(),
    "deleted_at" datetime,
    "address_1" varchar(191) NOT NULL,
    "address_2" varchar(191),
    "company" varchar(63),
    "city" varchar(63),
    "country_code" char(2) NOT NULL,
    "phone" varchar(63),
    "province" varchar(63),
    "postal_code" varchar(63),
    "metadata" json,
    CONSTRAINT "FK_00927868-35d5-40db-a679-5b8b3a5d164c" FOREIGN KEY ("country_code") REFERENCES "country" ("code")
  );

CREATE INDEX "IX_a4c8e1bb-ca08-43c2-bd8b-079284e43eea" ON "stock_location_address" ("country_code");

CREATE TABLE
  "stock_location" (
    "id" binary(16) PRIMARY KEY,
    "created_at" datetime NOT NULL DEFAULT NOW(),
    "updated_at" datetime NOT NULL DEFAULT NOW(),
    "deleted_at" datetime,
    "name" varchar(63) NOT NULL,
    "address_id" binary(16),
    "metadata" json
  );

CREATE INDEX "IX_d6777fb7-5635-4292-9905-ee9899a1c8eb" ON "stock_location" (
  "address_id",
  (
    CASE
      WHEN "deleted_at" IS NOT NULL THEN 0x01
      ELSE NULL
    END
  )
);

-- CMS tables
CREATE TABLE
  "post" (
    "id" binary(16) PRIMARY KEY,
    "created_at" datetime NOT NULL DEFAULT NOW(),
    "created_by" binary(16) NOT NULL,
    "updated_at" datetime NOT NULL DEFAULT NOW(),
    "updated_by" binary(16) NOT NULL,
    "deleted_at" datetime,
    "deleted_by" binary(16),
    "status" varchar(9) NOT NULL DEFAULT 'draft',
    "type" varchar(4) NOT NULL DEFAULT 'post',
    "featured" bit(1) NOT NULL DEFAULT 0x00,
    "published_at" datetime,
    "published_by" binary(16),
    "visibility" varchar(63) DEFAULT 'public',
    "title" varchar(63),
    "subtitle" varchar(191),
    "content" text,
    "excerpt" text,
    "handle" varchar(63) NOT NULL,
    "metadata" json,
    CONSTRAINT "CK_2ebc6a93-2710-4db4-b8ac-ed50879cb93f" CHECK ("visibility" IN ('public', 'paid')),
    CONSTRAINT "CK_7933d5cc-50af-4393-9fcb-05c0f928d3d1" CHECK ("type" IN ('post', 'page')),
    CONSTRAINT "CK_099b1849-68b9-4e0e-a240-1cd670a48758" CHECK ("status" IN ('published', 'draft', 'scheduled')),
    CONSTRAINT "FK_00f42943-9b91-4b43-b059-a1b44e61fc3e" FOREIGN KEY ("created_by") REFERENCES "user" ("id"),
    CONSTRAINT "FK_f9c4dca2-a8da-4508-a9e7-c9bfb489a244" FOREIGN KEY ("updated_by") REFERENCES "user" ("id"),
    CONSTRAINT "FK_11fb1f04-7b95-43f5-b317-efedaa8a8628" FOREIGN KEY ("published_by") REFERENCES "user" ("id"),
    CONSTRAINT "FK_bd32e96e-a974-4754-8cfa-e3a719618b54" FOREIGN KEY ("deleted_by") REFERENCES "user" ("id")
  );

CREATE UNIQUE INDEX "IX_8c63458a-4198-42d3-9128-0bb089c10baf" ON "post" (
  "handle",
  (
    CASE
      WHEN "deleted_at" IS NULL THEN 0x01
      ELSE NULL
    END
  )
);

CREATE TABLE
  "post_authors" (
    "post_id" binary(16) NOT NULL,
    "author_id" binary(16) NOT NULL,
    CONSTRAINT "FK_2de075c9-b223-4f52-a6aa-b83ee7dba0c5" FOREIGN KEY ("post_id") REFERENCES "post" ("id"),
    CONSTRAINT "FK_e8c24891-3138-4bd7-baaa-b4d4463193fb" FOREIGN KEY ("author_id") REFERENCES "user" ("id"),
    PRIMARY KEY ("post_id", "author_id")
  );

CREATE TABLE
  "post_revision" (
    "id" binary(16) PRIMARY KEY,
    "post_id" binary(16) NOT NULL,
    "locale_code" char(63) NOT NULL,
    "created_at" datetime NOT NULL DEFAULT NOW(),
    "created_by" binary(16) NOT NULL,
    CONSTRAINT "FK_70a8aca6-9a1d-4f2d-8b1c-46c2a9060590" FOREIGN KEY ("post_id") REFERENCES "post" ("id"),
    CONSTRAINT "FK_871d1e48-b5d3-47fe-aa82-388e29105e1b" FOREIGN KEY ("locale_code") REFERENCES "locale" ("code"),
    CONSTRAINT "FK_3a58d08b-1168-4b1b-b8fd-14c3c63c1ab9" FOREIGN KEY ("created_by") REFERENCES "user" ("id")
  );

CREATE TABLE
  "post_products" (
    "post_id" binary(16) NOT NULL,
    "product_id" binary(16) NOT NULL,
    CONSTRAINT "FK_485e7aaf-b8c5-4c63-9381-c57ec375d326" FOREIGN KEY ("post_id") REFERENCES "post" ("id") ON DELETE CASCADE,
    CONSTRAINT "FK_85797cf2-eee7-4ca3-98ee-240cbf74bace" FOREIGN KEY ("product_id") REFERENCES "product" ("id") ON DELETE CASCADE,
    PRIMARY KEY ("post_id", "product_id")
  );

CREATE TABLE
  "post_images" (
    "post_id" binary(16) NOT NULL,
    "image_id" binary(16) NOT NULL,
    CONSTRAINT "FK_83a68f23-9fae-41be-b789-5425dc741ae8" FOREIGN KEY ("post_id") REFERENCES "post" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "FK_9a53963d-694d-4375-b90f-bb3d3a84582d" FOREIGN KEY ("image_id") REFERENCES "image" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    PRIMARY KEY ("post_id", "image_id")
  );

CREATE TABLE
  "post_tag" (
    "id" binary(16) PRIMARY KEY,
    "parent_id" binary(16),
    "visibility" varchar(63) NOT NULL default 'public',
    "created_at" datetime NOT NULL DEFAULT NOW(),
    "created_by" binary(16) NOT NULL,
    "updated_at" datetime NOT NULL DEFAULT NOW(),
    "updated_by" binary(16) NOT NULL,
    "deleted_at" datetime,
    "deleted_by" binary(16),
    "title" varchar(63) NOT NULL,
    "subtitle" varchar(191),
    "content" text,
    "handle" varchar(63) NOT NULL,
    "excerpt" text,
    "metadata" json,
    CONSTRAINT "CK_db3214a3-4747-43ae-92dd-f7c4dfbcbe02" CHECK ("visibility" in ('public', 'paid')),
    CONSTRAINT "FK_cce9e5fa-98b7-42a2-a07f-099b21d30125" FOREIGN KEY ("parent_id") REFERENCES "post_tag" ("id"),
    CONSTRAINT "FK_61bb3b8e-4025-44df-a596-3a4bfae72cc3" FOREIGN KEY ("created_by") REFERENCES "user" ("id"),
    CONSTRAINT "FK_046712e2-098e-447f-ad59-1293e2da23d8" FOREIGN KEY ("updated_by") REFERENCES "user" ("id"),
    CONSTRAINT "FK_52e2391e-53db-4018-b5b1-7d78884d8574" FOREIGN KEY ("deleted_by") REFERENCES "user" ("id")
  );

CREATE UNIQUE INDEX "IX_a8712950-695a-4b27-b57d-86eb4f30d475" ON "post_tag" (
  "handle",
  (
    CASE
      WHEN "deleted_at" IS NULL THEN 0x01
      ELSE NULL
    END
  )
);

CREATE TABLE
  "post_tag_images" (
    "post_tag_id" binary(16) NOT NULL,
    "image_id" binary(16) NOT NULL,
    CONSTRAINT "FK_79915a8e-f10e-41d2-8da3-4ce6bccca0dc" FOREIGN KEY ("post_tag_id") REFERENCES "post_tag" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "FK_3074f0b2-8f21-4512-a0af-14c659eb7826" FOREIGN KEY ("image_id") REFERENCES "image" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    PRIMARY KEY ("post_tag_id", "image_id")
  );

CREATE TABLE
  "post_tags" (
    "post_id" binary(16) NOT NULL,
    "post_tag_id" binary(16) NOT NULL,
    CONSTRAINT "FK_0287e4c3-f9f2-4438-b272-912f5898ed37" FOREIGN KEY ("post_id") REFERENCES "post" ("id"),
    CONSTRAINT "FK_1ee032e9-c628-481b-a972-05393c6943df" FOREIGN KEY ("post_tag_id") REFERENCES "post_tag" ("id"),
    PRIMARY KEY ("post_id", "post_tag_id")
  );

CREATE TABLE
  "comment" (
    "id" binary(16) PRIMARY KEY,
    "post_id" binary(16) NOT NULL,
    "customer_id" binary(16),
    "user_id" binary(16),
    "parent_id" binary(16),
    "is_hidden" bit(1) DEFAULT 0x00,
    "content" text,
    "created_at" datetime NOT NULL DEFAULT NOW(),
    "updated_at" datetime NOT NULL DEFAULT NOW(),
    "deleted_at" datetime,
    CONSTRAINT "CK_75da4b67-0709-4ef7-841d-1f7ff9a8a57d" CHECK (
      "customer_id" IS NOT NULL
      OR "user_id" IS NOT NULL
    ),
    CONSTRAINT "FK_e296e77b-3081-42e2-b2d6-afe008295acf" FOREIGN KEY ("post_id") REFERENCES "posts" ("id") ON DELETE CASCADE,
    CONSTRAINT "FK_9dfc0597-8ca1-48e6-abdb-8b6a168a3259" FOREIGN KEY ("customer_id") REFERENCES "customer" ("id") ON DELETE CASCADE,
    CONSTRAINT "FK_275d7ba2-6b7c-414a-91cb-9e7a35cf783b" FOREIGN KEY ("user_id") REFERENCES "user" ("id") ON DELETE CASCADE,
    CONSTRAINT "FK_85cc0dd7-fd4a-41af-9054-59fdbfb2256f" FOREIGN KEY ("parent_id") REFERENCES "comment" ("id") ON DELETE CASCADE
  );

CREATE TABLE
  "comment_likes" (
    "id" binary(16) PRIMARY KEY,
    "comment_id" binary(16) NOT NULL,
    "customer_id" binary(16),
    "user_id" binary(16),
    "created_at" datetime NOT NULL,
    "updated_at" datetime NOT NULL,
    CONSTRAINT "CK_61928aa9-675f-4a3d-85c6-9d29766891b8" CHECK (
      "customer_id" IS NOT NULL
      OR "user_id" IS NOT NULL
    ),
    CONSTRAINT "FK_c6db9280-9918-4917-9030-204235a2ad38" FOREIGN KEY ("comment_id") REFERENCES "comments" ("id") ON DELETE CASCADE,
    CONSTRAINT "FK_832e17b6-605a-4f3f-8a97-cbda10e241f9" FOREIGN KEY ("customer_id") REFERENCES "customer" ("id") ON DELETE CASCADE,
    CONSTRAINT "FK_f569347c-20e9-4dcc-a557-d20200c231e2" FOREIGN KEY ("user_id") REFERENCES "user" ("id")
  );

CREATE TABLE
  "comment_reports" (
    "id" binary(16) PRIMARY KEY,
    "comment_id" binary(16) NOT NULL,
    "customer_id" binary(16),
    "created_at" datetime NOT NULL,
    "updated_at" datetime NOT NULL,
    CONSTRAINT "FK_337d31b7-ccf4-4f00-8676-2d803edc6d50" FOREIGN KEY ("comment_id") REFERENCES "comments" ("id") ON DELETE CASCADE,
    CONSTRAINT "FK_7e78ddcf-6196-4c4d-9193-b0d1b1fc8684" FOREIGN KEY ("customer_id") REFERENCES "customer" ("id") ON DELETE CASCADE
  );

-- Internationalization
CREATE TABLE
  "locale" (
    "id" binary(16) PRIMARY KEY,
    "code" varchar(63),
    CONSTRAINT "UQ_78336968-65c7-40a1-bfe1-1a87fdfa1c47" UNIQUE ("code")
  );

CREATE TABLE
  "store_locales" (
    "store_id" binary(16) NOT NULL,
    "locale_code" varchar(63) NOT NULL,
    PRIMARY KEY ("store_id", "locale_code"),
    CONSTRAINT "FK_71419f45-332d-4d99-bd42-277c21e460da" FOREIGN KEY ("store_id") REFERENCES "store" ("id") ON DELETE CASCADE,
    CONSTRAINT "FK_99647084-2972-4e43-95a7-29255e31b97c" FOREIGN KEY ("locale_code") REFERENCES "locale" ("code")
  );

CREATE TABLE
  "image_translations" (
    "image_id" binary(16),
    "locale_code" varchar(63),
    "created_at" datetime NOT NULL DEFAULT NOW(),
    "updated_at" datetime NOT NULL DEFAULT NOW(),
    "deleted_at" datetime,
    "url" text NOT NULL,
    PRIMARY KEY ("image_id", "locale_code"),
    CONSTRAINT "FK_767e87ec-45f6-4f39-a629-7e479cb30890" FOREIGN KEY ("image_id") REFERENCES "image" ("id") ON DELETE CASCADE,
    CONSTRAINT "FK_f024e671-4806-4d00-9dda-d708ce6b5a49" FOREIGN KEY ("locale_code") REFERENCES "locale" ("code")
  );

CREATE TABLE
  "post_translations" (
    "post_id" binary(16) NOT NULL,
    "locale_code" varchar(63) NOT NULL,
    "created_at" datetime NOT NULL DEFAULT NOW(),
    "updated_at" datetime NOT NULL DEFAULT NOW(),
    "deleted_at" datetime,
    "title" varchar(63),
    "subtitle" varchar(191),
    "content" text,
    "handle" varchar(63),
    "excerpt" text,
    CONSTRAINT "FK_4567c4cf-481d-45b1-a362-7a77ec8be7b6" FOREIGN KEY ("locale_code") REFERENCES "locale" ("code"),
    CONSTRAINT "FK_b955a51d-202b-409b-b6b0-dc0a7fe7709c" FOREIGN KEY ("post_id") REFERENCES "post" ("id") ON DELETE CASCADE,
    PRIMARY KEY ("post_id", "locale_code")
  );

CREATE TABLE
  "post_tag_translations" (
    "post_tag_id" binary(16) NOT NULL,
    "locale_code" varchar(63) NOT NULL,
    "created_at" datetime NOT NULL DEFAULT NOW(),
    "updated_at" datetime NOT NULL DEFAULT NOW(),
    "deleted_at" datetime,
    "name" varchar(63) NOT NULL,
    "handle" varchar(63) NOT NULL,
    "content" text,
    "excerpt" text,
    CONSTRAINT "FK_beb56cfe-9000-43dc-8974-72e6fde9888b" FOREIGN KEY ("locale_code") REFERENCES "locale" ("code"),
    CONSTRAINT "FK_8240b92b-f88c-4e9a-9415-322a3c2f1d83" FOREIGN KEY ("post_tag_id") REFERENCES "post_tag" ("id") ON DELETE CASCADE,
    PRIMARY KEY ("post_tag_id", "locale_code")
  );

CREATE TABLE
  "product_tag_translations" (
    "product_tag_id" binary(16) NOT NULL,
    "locale_code" varchar(63) NOT NULL,
    "created_at" datetime NOT NULL DEFAULT NOW(),
    "updated_at" datetime NOT NULL DEFAULT NOW(),
    "deleted_at" datetime,
    "name" varchar(63) NOT NULL,
    CONSTRAINT "FK_67902bea-2751-45ab-8357-109b92776fa5" FOREIGN KEY ("locale_code") REFERENCES "locale" ("code"),
    CONSTRAINT "FK_2636a248-da56-4a8c-aff7-57e681d77fe1" FOREIGN KEY ("product_tag_id") REFERENCES "product_tag" ("id") ON DELETE CASCADE,
    PRIMARY KEY ("product_tag_id", "locale_code")
  );

CREATE TABLE
  "product_type_translations" (
    "product_type_id" binary(16),
    "locale_code" varchar(63) NOT NULL,
    "created_at" datetime NOT NULL DEFAULT NOW(),
    "updated_at" datetime NOT NULL DEFAULT NOW(),
    "deleted_at" datetime,
    "name" varchar(63),
    CONSTRAINT "FK_01ec4e66-ff64-448f-912d-957b524f920a" FOREIGN KEY ("locale_code") REFERENCES "locale" ("code"),
    CONSTRAINT "FK_8563711e-4eca-4aec-b322-6a1e2613173d" FOREIGN KEY ("product_type_id") REFERENCES "product_type" ("id") ON DELETE CASCADE,
    PRIMARY KEY ("product_type_id", "locale_code")
  );

CREATE TABLE
  "product_variant_translations" (
    "product_variant_id" binary(16) NOT NULL,
    "locale_code" varchar(63) NOT NULL,
    "created_at" datetime NOT NULL DEFAULT NOW(),
    "updated_at" datetime NOT NULL DEFAULT NOW(),
    "deleted_at" datetime,
    "title" varchar(63),
    "material" varchar(63),
    CONSTRAINT "FK_06e33d36-14cb-41d0-878a-577987edc0e2" FOREIGN KEY ("locale_code") REFERENCES "locale" ("code"),
    CONSTRAINT "FK_af509b01-6943-4649-af32-d00a51bfb1fd" FOREIGN KEY ("product_variant_id") REFERENCES "product_variant" ("id") ON DELETE CASCADE,
    PRIMARY KEY ("product_variant_id", "locale_code")
  );

CREATE TABLE
  "product_option_value_translations" (
    "product_option_value_id" binary(16) NOT NULL,
    "locale_code" varchar(63) NOT NULL,
    "created_at" datetime NOT NULL DEFAULT NOW(),
    "updated_at" datetime NOT NULL DEFAULT NOW(),
    "deleted_at" datetime,
    "name" varchar(63),
    CONSTRAINT "FK_253a6c80-9b70-4ea0-98a2-5b5400f36068" FOREIGN KEY ("locale_code") REFERENCES "locale" ("code"),
    CONSTRAINT "FK_967aabcd-a3ec-4293-93f5-1a63d0e2d693" FOREIGN KEY ("product_option_value_id") REFERENCES "product_option_value" ("id") ON DELETE CASCADE,
    PRIMARY KEY ("product_option_value_id", "locale_code")
  );

CREATE TABLE
  "shipping_option_translations" (
    "shipping_option_id" binary(16) NOT NULL,
    "locale_code" varchar(63) NOT NULL,
    "name" varchar(63),
    CONSTRAINT "FK_648f3186-b9a3-426b-b0ea-6937538936d0" FOREIGN KEY ("locale_code") REFERENCES "locale" ("code"),
    CONSTRAINT "FK_243732b9-e872-45d3-bc5f-f8f1a01923ee" FOREIGN KEY ("shipping_option_id") REFERENCES "shipping_option" ("id") ON DELETE CASCADE,
    PRIMARY KEY ("shipping_option_id", "locale_code")
  );

CREATE TABLE
  "product_option_translations" (
    "product_option_id" binary(16) NOT NULL,
    "locale_code" varchar(63) NOT NULL,
    "created_at" datetime NOT NULL DEFAULT NOW(),
    "updated_at" datetime NOT NULL DEFAULT NOW(),
    "deleted_at" datetime,
    "title" varchar(63),
    CONSTRAINT "FK_158f588a-78ee-4611-b4b7-368e19c9770f" FOREIGN KEY ("product_option_id") REFERENCES "product_option" ("id") ON DELETE CASCADE,
    CONSTRAINT "FK_392a703f-3787-4a25-9d72-466b9247ae0f" FOREIGN KEY ("locale_code") REFERENCES "locale" ("code"),
    PRIMARY KEY ("product_option_id", "locale_code")
  );

CREATE TABLE
  "product_category_translations" (
    "product_category_id" binary(16) NOT NULL,
    "locale_code" varchar(63) NOT NULL,
    "created_at" datetime NOT NULL DEFAULT NOW(),
    "updated_at" datetime NOT NULL DEFAULT NOW(),
    "deleted_at" datetime,
    "name" varchar(63),
    "handle" varchar(63),
    CONSTRAINT "FK_85dafe70-b72b-4dcb-afe5-c21d096bbdc3" FOREIGN KEY ("product_category_id") REFERENCES "product_category" ("id") ON DELETE CASCADE,
    CONSTRAINT "FK_1f9cbb52-6a79-4d4c-808d-e18b1a39759e" FOREIGN KEY ("locale_code") REFERENCES "locale" ("code"),
    PRIMARY KEY ("product_category_id", "locale_code")
  );

CREATE TABLE
  "product_translations" (
    "product_id" binary(16) NOT NULL,
    "locale_code" varchar(63) NOT NULL,
    "created_at" datetime NOT NULL DEFAULT NOW(),
    "updated_at" datetime NOT NULL DEFAULT NOW(),
    "deleted_at" datetime,
    "title" varchar(63),
    "subtitle" varchar(191),
    "description" text,
    "handle" varchar(63),
    "material" text,
    CONSTRAINT "FK_97fc0ddd-56fc-4cfe-b52e-98594d68eacb" FOREIGN KEY ("product_id") REFERENCES "product" ("id") ON DELETE CASCADE,
    CONSTRAINT "FK_9cf92add-917f-47ba-bbee-377d91505cb9" FOREIGN KEY ("locale_code") REFERENCES "locale" ("code"),
    PRIMARY KEY ("product_id", "locale_code")
  );

CREATE TABLE
  "product_collection_translations" (
    "product_collection_id" binary(16) NOT NULL,
    "locale_code" varchar(63) NOT NULL,
    "created_at" datetime NOT NULL DEFAULT NOW(),
    "updated_at" datetime NOT NULL DEFAULT NOW(),
    "deleted_at" datetime,
    "title" varchar(63) NOT NULL,
    "handle" varchar(63),
    CONSTRAINT "FK_3e50e6c8-8577-4a17-9da8-015bac0c13eb" FOREIGN KEY ("product_collection_id") REFERENCES "product_collection" ("id") ON DELETE CASCADE,
    CONSTRAINT "FK_454a42f7-8990-48a3-b941-e557f7bb956d" FOREIGN KEY ("locale_code") REFERENCES "locale" ("code"),
    PRIMARY KEY ("product_collection_id", "locale_code")
  );

SET
  FOREIGN_KEY_CHECKS = 1;