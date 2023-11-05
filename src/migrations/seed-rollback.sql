ALTER TABLE "discount_condition"
DROP FOREIGN KEY "FK_f9e56004-dfb7-4899-88a1-1b94d93acea3";

ALTER TABLE "discount"
DROP FOREIGN KEY "FK_06355ddc-2b83-4234-81e8-ebae8b81ceae";

ALTER TABLE "discount"
DROP FOREIGN KEY "FK_ea2a0723-0b78-4836-8896-96b65821ce37";

ALTER TABLE "region"
DROP FOREIGN KEY "FK_845dc700-49b5-4fff-82cc-23c3b9f9fd0f";

ALTER TABLE "region"
DROP FOREIGN KEY "FK_f6a1cddc-f0ca-40a6-8f82-eff7cda3ccd4";

ALTER TABLE "gift_card"
DROP FOREIGN KEY "FK_371fce46-cade-4c75-9889-e472ae1fbe0a";

ALTER TABLE "gift_card"
DROP FOREIGN KEY "FK_98185545-63d3-44dc-9f64-d51f4ead7b8d";

ALTER TABLE "claim_image"
DROP FOREIGN KEY "FK_1d7c51c6-e1a5-41a8-b86f-428f404c8986";

ALTER TABLE "claim_item"
DROP FOREIGN KEY "FK_ab1dfb3e-2537-45ef-860f-6ba0c81762a9";

ALTER TABLE "claim_item"
DROP FOREIGN KEY "FK_b5ee787a-99c6-4809-a005-31f08f248fb1";

ALTER TABLE "claim_item"
DROP FOREIGN KEY "FK_dd78c81f-4270-477b-bac6-714e041097ff";

ALTER TABLE "fulfillment_item"
DROP FOREIGN KEY "FK_7040d36a-4793-42e9-82df-68ad05b609e0";

ALTER TABLE "fulfillment_item"
DROP FOREIGN KEY "FK_9675f7af-948c-4654-b620-923d3ff88d4d";

ALTER TABLE "payment"
DROP FOREIGN KEY "FK_20cc85f7-a809-42ce-9ea3-f201a3f924d9";

ALTER TABLE "payment"
DROP FOREIGN KEY "FK_5462983d-5fc4-4a88-b7f9-7e9af6eabd98";

ALTER TABLE "payment"
DROP FOREIGN KEY "FK_8cd1bba0-fbab-4244-bd5c-6d7a9742cf3b";

ALTER TABLE "payment"
DROP FOREIGN KEY "FK_b7d8ce02-e052-41fe-b4d8-fca1c0e54ef9";

ALTER TABLE "return_reason"
DROP FOREIGN KEY "FK_94ebd379-6568-4e92-b0df-dec5da1cb28b";

ALTER TABLE "return_item"
DROP FOREIGN KEY "FK_a1ad998a-446d-45f8-95b5-9530ac3b0f2f";

ALTER TABLE "return_item"
DROP FOREIGN KEY "FK_b04fc611-0d2f-47fc-8ee0-266193891ca5";

ALTER TABLE "return_item"
DROP FOREIGN KEY "FK_fd1d5ff4-fa3c-4b03-a655-9f275ca4f36c";

ALTER TABLE "shipping_method_tax_line"
DROP FOREIGN KEY "FK_0a86bdc1-af47-4a27-8be8-936642d40bbc";

ALTER TABLE "shipping_option_requirement"
DROP FOREIGN KEY "FK_b57b7abc-bba9-42f6-ad40-79325dc6914b";

ALTER TABLE "shipping_option"
DROP FOREIGN KEY "FK_4477fb34-e6d2-488f-951c-e1c8e6f0008d";

ALTER TABLE "shipping_option"
DROP FOREIGN KEY "FK_45e60420-892b-44a6-902c-5a813dd1a002";

ALTER TABLE "shipping_option"
DROP FOREIGN KEY "FK_c41d2698-6723-4f28-9cef-006aba4219f4";

ALTER TABLE "shipping_method"
DROP FOREIGN KEY "FK_0855aa44-e993-43d8-aa5d-bcae5049543b";

ALTER TABLE "shipping_method"
DROP FOREIGN KEY "FK_4d613d1c-a17e-4839-8a8c-028e3926cc2f";

ALTER TABLE "shipping_method"
DROP FOREIGN KEY "FK_5c86dd3f-5bb6-4c39-9b43-3c719230343d";

ALTER TABLE "shipping_method"
DROP FOREIGN KEY "FK_9436a46d-0b26-4430-a08c-90fead8c538c";

ALTER TABLE "shipping_method"
DROP FOREIGN KEY "FK_af4b9339-5a1a-47b7-88b5-fffdae5d9642";

ALTER TABLE "shipping_method"
DROP FOREIGN KEY "FK_ff1777fc-4bfc-4662-aae6-cb6aeab51aeb";

ALTER TABLE "return"
DROP FOREIGN KEY "FK_21d24c83-3ead-4f7e-a90b-a40918e2014d";

ALTER TABLE "return"
DROP FOREIGN KEY "FK_76de831c-e3ae-41ff-a2b4-a390b9c2d5c8";

ALTER TABLE "return"
DROP FOREIGN KEY "FK_c7368386-78fa-46b1-a49d-7e75283c25c4";

ALTER TABLE "swap"
DROP FOREIGN KEY "FK_968ec785-e603-4ffb-a570-1a35d54fa25e";

ALTER TABLE "swap"
DROP FOREIGN KEY "FK_d5b7c411-39fa-4df5-b56d-a67955a8b659";

ALTER TABLE "swap"
DROP FOREIGN KEY "FK_ee0af6b0-acd7-408f-8b96-eb1dd055b74d";

ALTER TABLE "tracking_link"
DROP FOREIGN KEY "FK_5e425b93-2695-4734-9967-103ee316bc9d";

ALTER TABLE "fulfillment"
DROP FOREIGN KEY "FK_ceca7b5f-338a-40e7-983e-1bee528d9439";

ALTER TABLE "fulfillment"
DROP FOREIGN KEY "FK_d07568d5-e3f3-4d5d-8bfd-2a49dd6ae98a";

ALTER TABLE "fulfillment"
DROP FOREIGN KEY "FK_e1e48ded-22b5-4684-b593-05c4dabaf292";

ALTER TABLE "fulfillment"
DROP FOREIGN KEY "FK_f3ac6a1f-2e07-4fda-9a3a-2be045967339";

ALTER TABLE "claim_order"
DROP FOREIGN KEY "FK_333374b0-fdc0-4b0b-acba-da358f41d96a";

ALTER TABLE "claim_order"
DROP FOREIGN KEY "FK_3e765f10-5a8c-4b62-bf3e-e23d1e3da5fd";

ALTER TABLE "line_item_adjustment"
DROP FOREIGN KEY "FK_267dd4c2-2709-4a5a-9990-fa56acf6fa53";

ALTER TABLE "line_item_adjustment"
DROP FOREIGN KEY "FK_676cd26a-2845-407d-9497-df9be8333261";

ALTER TABLE "line_item_tax_line"
DROP FOREIGN KEY "FK_d33dd8b7-73a2-4c6b-811b-3273697d0fb6";

ALTER TABLE "order_edit"
DROP FOREIGN KEY "FK_6c36a356-5527-4950-9cf2-c6f17e2de653";

ALTER TABLE "order_edit"
DROP FOREIGN KEY "FK_e0ef3720-9dd2-424c-a7ca-874e40e7f55f";

ALTER TABLE "line_item"
DROP FOREIGN KEY "FK_0861d9ac-4f83-4995-8a5d-92e14bd7d525";

ALTER TABLE "line_item"
DROP FOREIGN KEY "FK_08fa3dc5-1979-46ed-a142-87808d55c9c9";

ALTER TABLE "line_item"
DROP FOREIGN KEY "FK_58581511-1998-40d4-8c49-df34f9b12a7b";

ALTER TABLE "line_item"
DROP FOREIGN KEY "FK_987ea516-1e81-4059-b91d-6b501c528e64";

ALTER TABLE "line_item"
DROP FOREIGN KEY "FK_b4290892-a328-4f73-8e01-e9b02b7cbc9b";

ALTER TABLE "line_item"
DROP FOREIGN KEY "FK_e30f2751-4b97-4995-9d70-86bee5ba52e6";

ALTER TABLE "payment_session"
DROP FOREIGN KEY "FK_f759e96d-c88d-4508-82c2-1e60edfbcc9a";

ALTER TABLE "sales_channel_location"
DROP FOREIGN KEY "FK_4f53a26a-d611-497c-9610-33a20688f696";

ALTER TABLE "cart"
DROP FOREIGN KEY "FK_0b697e62-fb88-42e3-a3ef-5ede0cbaaca5";

ALTER TABLE "cart"
DROP FOREIGN KEY "FK_10161e0d-5989-4e1d-9b33-ce8c02c11e3d";

ALTER TABLE "cart"
DROP FOREIGN KEY "FK_ac247cbe-8364-4364-9e04-bdc623e9b3e4";

ALTER TABLE "cart"
DROP FOREIGN KEY "FK_cbec31e1-8037-4058-bbac-c78b2b540bb8";

ALTER TABLE "cart"
DROP FOREIGN KEY "FK_d12f5f15-84d8-416f-953a-84dc8b09e4d4";

ALTER TABLE "cart"
DROP FOREIGN KEY "FK_f7ab6e53-f428-43da-b7e7-44a2f8b5f441";

ALTER TABLE "draft_order"
DROP FOREIGN KEY "FK_3751fb17-be3d-4f59-b936-94d4ea749f86";

ALTER TABLE "draft_order"
DROP FOREIGN KEY "FK_b776c589-cc95-4f19-9a39-1278e133787e";

ALTER TABLE "gift_card_transaction"
DROP FOREIGN KEY "FK_43fbe911-7e8e-4e35-a31b-b662bf769bd3";

ALTER TABLE "gift_card_transaction"
DROP FOREIGN KEY "FK_e9a27cb5-788f-447d-a340-002d961a586a";

ALTER TABLE "refund"
DROP FOREIGN KEY "FK_d14a2769-46ea-4cc1-8ef5-97a9ce660386";

ALTER TABLE "refund"
DROP FOREIGN KEY "FK_ff8796e6-ad13-4d5c-a738-94f5fade4d02";

ALTER TABLE "order"
DROP FOREIGN KEY "FK_42daab6b-b219-4435-ba91-5e760e20bf20";

ALTER TABLE "order"
DROP FOREIGN KEY "FK_4b348c33-98d5-4d78-b19c-24740949d5b9";

ALTER TABLE "order"
DROP FOREIGN KEY "FK_62765b4f-fbd2-48fa-9d4f-0d5b319ee8e8";

ALTER TABLE "order"
DROP FOREIGN KEY "FK_7ce838f2-0359-44ee-8bb2-d7c7280da6cc";

ALTER TABLE "order"
DROP FOREIGN KEY "FK_7e2621dd-8229-4f17-8217-055bcd7d68f7";

ALTER TABLE "order"
DROP FOREIGN KEY "FK_819b416f-2031-4322-8189-14b9b8380624";

ALTER TABLE "order"
DROP FOREIGN KEY "FK_94d0f526-c95c-4d32-84b1-e4de89cf93ce";

ALTER TABLE "order"
DROP FOREIGN KEY "FK_bf5d9d30-8bd4-40a4-9d7b-99992736741e";

ALTER TABLE "customer"
DROP FOREIGN KEY "FK_78d07c58-22be-4fab-b6f8-a93bf04930bd";

ALTER TABLE "money_amount"
DROP FOREIGN KEY "FK_13cfcaf8-6400-4bfe-aa90-8a8e83b17890";

ALTER TABLE "money_amount"
DROP FOREIGN KEY "FK_34c4e0e6-92ec-424f-ab42-cea667b57476";

ALTER TABLE "money_amount"
DROP FOREIGN KEY "FK_e5d8706c-64c9-41c3-8930-898e5d1f855d";

ALTER TABLE "money_amount"
DROP FOREIGN KEY "FK_f421fb35-cb3c-422e-82f4-ca1f818682af";

ALTER TABLE "product_variant_inventory_item"
DROP FOREIGN KEY "FK_bf0a3b04-1fc5-4f54-bc87-3d6117560252";

ALTER TABLE "product_option_value"
DROP FOREIGN KEY "FK_07ca72fb-ab3a-48fc-9b3a-72294cc3c858";

ALTER TABLE "product_option_value"
DROP FOREIGN KEY "FK_5ad935e8-5206-47bb-8cd7-12f2e3c664e0";

ALTER TABLE "product_option"
DROP FOREIGN KEY "FK_ce6a3d79-22b3-432d-b0d7-069c82c895ca";

ALTER TABLE "product_category"
DROP FOREIGN KEY "FK_02e51bdc-23bc-46e4-966f-fba89fa44259";

ALTER TABLE "tax_rate"
DROP FOREIGN KEY "FK_f708e5c3-4871-40b2-8dc3-046db20961fd";

ALTER TABLE "product"
DROP FOREIGN KEY "FK_5ce072b3-dc9b-4c9f-8035-127a79d4c1f2";

ALTER TABLE "product"
DROP FOREIGN KEY "FK_79768901-a193-4ee9-8a90-9404cd91348e";

ALTER TABLE "product"
DROP FOREIGN KEY "FK_946002f1-2e0d-488b-a2cf-181378ff6c83";

ALTER TABLE "product"
DROP FOREIGN KEY "FK_f9256204-73e1-4079-90ed-ce7a32b3254a";

ALTER TABLE "product_variant"
DROP FOREIGN KEY "FK_df519082-742f-406d-940b-7e3a2612424b";

ALTER TABLE "product_variant"
DROP FOREIGN KEY "FK_e07a4177-ee4d-4247-ab13-db942db5770b";

ALTER TABLE "country"
DROP FOREIGN KEY "FK_113800f7-a578-456b-a3e1-ef020a28e40c";

ALTER TABLE "address"
DROP FOREIGN KEY "FK_ae763a01-3045-425b-8377-9b14078ee19b";

ALTER TABLE "address"
DROP FOREIGN KEY "FK_e0cf5f4d-f5c8-42ca-9d64-044599264224";

ALTER TABLE "custom_shipping_option"
DROP FOREIGN KEY "FK_26ede49d-2f6f-45ad-bb6c-bbe50f17d5ad";

ALTER TABLE "custom_shipping_option"
DROP FOREIGN KEY "FK_d0dd6188-a967-4aee-91da-752bc2df9377";

ALTER TABLE "discount_condition_customer_group"
DROP FOREIGN KEY "FK_1f3649f4-d40e-4189-9de8-67c5d8d4024f";

ALTER TABLE "discount_condition_customer_group"
DROP FOREIGN KEY "FK_339759b8-d315-48de-8ede-bd5d5daf857b";

ALTER TABLE "discount_condition_product"
DROP FOREIGN KEY "FK_1389fab2-ad2c-4ca5-b2e5-07da3f256578";

ALTER TABLE "discount_condition_product"
DROP FOREIGN KEY "FK_4e2ae138-4f63-4525-80ca-ec981d2225b2";

ALTER TABLE "discount_condition_product_collection"
DROP FOREIGN KEY "FK_63e6b5dc-8415-411a-89c3-7130d5b586cc";

ALTER TABLE "discount_condition_product_collection"
DROP FOREIGN KEY "FK_94efcb11-ab64-41f7-9c5b-9768b64e72fa";

ALTER TABLE "discount_condition_product_tag"
DROP FOREIGN KEY "FK_29ffed51-be01-498c-ab37-e55aaa89aa5a";

ALTER TABLE "discount_condition_product_tag"
DROP FOREIGN KEY "FK_5f239071-2d47-4b1f-b4ca-5c3613b03ffd";

ALTER TABLE "discount_condition_product_type"
DROP FOREIGN KEY "FK_ce352b6e-3094-4d90-8bf1-d65008d0985f";

ALTER TABLE "discount_condition_product_type"
DROP FOREIGN KEY "FK_ead57d77-8436-46aa-b1a1-cf7f6f376e4e";

ALTER TABLE "note"
DROP FOREIGN KEY "FK_866474ad-5bfa-40b0-b9a9-4de408d59973";

ALTER TABLE "notification"
DROP FOREIGN KEY "FK_131d9f39-2911-4f18-907f-f28fb97ea922";

ALTER TABLE "notification"
DROP FOREIGN KEY "FK_5379eec8-9174-4d6a-9ef9-345d2a957035";

ALTER TABLE "notification"
DROP FOREIGN KEY "FK_cd8afdbe-0fdd-43b3-b853-c26651dd90f8";

ALTER TABLE "order_item_change"
DROP FOREIGN KEY "FK_32a7b9ce-2e10-41c6-a6a8-ac65adf0a5c3";

ALTER TABLE "order_item_change"
DROP FOREIGN KEY "FK_66a2d1b8-b214-4711-9610-e2d57ebd1a5d";

ALTER TABLE "order_item_change"
DROP FOREIGN KEY "FK_7063536d-7b16-437c-8cee-271e4ba40d84";

ALTER TABLE "payment_collection"
DROP FOREIGN KEY "FK_3df43deb-6bf3-4d4d-8dae-a6b9e61c731a";

ALTER TABLE "payment_collection"
DROP FOREIGN KEY "FK_db50b1af-758b-4e29-9b60-24886d4416f8";

ALTER TABLE "product_tax_rate"
DROP FOREIGN KEY "FK_92d8f9c3-1969-421b-9209-190ead5d9134";

ALTER TABLE "product_tax_rate"
DROP FOREIGN KEY "FK_f3e8b4b1-fc14-4522-a317-accc39fa1899";

ALTER TABLE "product_type_tax_rate"
DROP FOREIGN KEY "FK_1c20c96c-6306-447c-8e9e-cfe5122b22d5";

ALTER TABLE "product_type_tax_rate"
DROP FOREIGN KEY "FK_2f6c6775-c38a-46c7-a005-2c17a887018a";

ALTER TABLE "shipping_tax_rate"
DROP FOREIGN KEY "FK_44f01a85-36b2-40de-8374-0d80cc8d541a";

ALTER TABLE "shipping_tax_rate"
DROP FOREIGN KEY "FK_e2683132-fdd8-44b0-908e-f6c4f829ac8e";

ALTER TABLE "discount_regions"
DROP FOREIGN KEY "FK_a26d5e59-7ce8-4c26-af6c-3532d1254fec";

ALTER TABLE "discount_regions"
DROP FOREIGN KEY "FK_e844ccc0-1c80-4944-9a3e-f21d5573a96e";

ALTER TABLE "claim_item_tags"
DROP FOREIGN KEY "FK_acfd9846-5204-4195-a9ac-1a600ed402a8";

ALTER TABLE "claim_item_tags"
DROP FOREIGN KEY "FK_fa97b7a9-fbc4-46f1-9a68-cf704b0909cf";

ALTER TABLE "cart_discounts"
DROP FOREIGN KEY "FK_0ab67f83-0d00-4c61-ad30-ba2592cd6086";

ALTER TABLE "cart_discounts"
DROP FOREIGN KEY "FK_30651805-7dd2-4fea-abce-b2af36668986";

ALTER TABLE "cart_gift_cards"
DROP FOREIGN KEY "FK_408290bd-45e5-493c-9fc6-3a21df704c1d";

ALTER TABLE "cart_gift_cards"
DROP FOREIGN KEY "FK_d61226f9-15a3-4e02-b7b1-799c1e3dde5d";

ALTER TABLE "order_discounts"
DROP FOREIGN KEY "FK_4d909d52-af62-4133-88cf-cdf4bf1f0078";

ALTER TABLE "order_discounts"
DROP FOREIGN KEY "FK_bc355f5f-5004-4a3e-9808-3ca9df7957b4";

ALTER TABLE "order_gift_cards"
DROP FOREIGN KEY "FK_b348c27e-f8e1-4ba8-a87b-95f4674b85e1";

ALTER TABLE "order_gift_cards"
DROP FOREIGN KEY "FK_f5efe556-9f6f-40e5-be86-5139230509f5";

ALTER TABLE "customer_group_customers"
DROP FOREIGN KEY "FK_a3fa916f-b006-492a-8beb-c317c651d359";

ALTER TABLE "customer_group_customers"
DROP FOREIGN KEY "FK_e9c36886-9462-47d1-b7f0-1b5a41f1b749";

ALTER TABLE "price_list_customer_groups"
DROP FOREIGN KEY "FK_89816574-f11d-4cbd-b0c1-d003076d6383";

ALTER TABLE "price_list_customer_groups"
DROP FOREIGN KEY "FK_94f77420-96b2-4ddc-92e1-310e4cbb3788";

ALTER TABLE "product_category_product"
DROP FOREIGN KEY "FK_aa942891-58d0-4eb6-884b-a6346201ca9e";

ALTER TABLE "product_category_product"
DROP FOREIGN KEY "FK_f0e71e2b-e1c4-43ce-a3d9-f8b83e0e0952";

ALTER TABLE "product_images"
DROP FOREIGN KEY "FK_4d161f58-9f2a-41e5-af92-5ce4267ea7e1";

ALTER TABLE "product_images"
DROP FOREIGN KEY "FK_59eb4776-60bc-4da2-a068-cb537c5ecb39";

ALTER TABLE "product_tags"
DROP FOREIGN KEY "FK_a0ed5b28-0e55-418c-851c-7d2bd183b485";

ALTER TABLE "product_tags"
DROP FOREIGN KEY "FK_d491d367-45bb-4c1c-8401-42acc2659d7a";

ALTER TABLE "product_sales_channel"
DROP FOREIGN KEY "FK_9d43c7c1-5ab9-417f-8172-e61cb3c92c67";

ALTER TABLE "product_sales_channel"
DROP FOREIGN KEY "FK_a2bf212c-f33c-45d1-9fcd-a9edf37bc39d";

ALTER TABLE "region_payment_providers"
DROP FOREIGN KEY "FK_29427082-3a6c-4e49-98fe-4d97ef8f8751";

ALTER TABLE "region_payment_providers"
DROP FOREIGN KEY "FK_93ddc225-9960-414e-a347-6a6ea27483c2";

ALTER TABLE "region_fulfillment_providers"
DROP FOREIGN KEY "FK_e928e068-35f6-44f9-9a52-f6197f699f35";

ALTER TABLE "region_fulfillment_providers"
DROP FOREIGN KEY "FK_f098b94c-dd9a-4eaa-bdaf-5b6654beeea2";

ALTER TABLE "payment_collection_sessions"
DROP FOREIGN KEY "FK_bf583aeb-974b-42e5-97fd-5225c146e37b";

ALTER TABLE "payment_collection_sessions"
DROP FOREIGN KEY "FK_c766a0c3-6092-42d8-bc6f-8ba6b3c17a3b";

ALTER TABLE "payment_collection_payments"
DROP FOREIGN KEY "FK_1a41fd97-34c9-42e7-8424-7c231e4f3aa7";

ALTER TABLE "payment_collection_payments"
DROP FOREIGN KEY "FK_af442c9b-e960-42cc-b6ba-8357a9f987ef";

ALTER TABLE "store"
DROP FOREIGN KEY "FK_262e04ae-bb99-4d07-9dad-6e1abd7d509f";

ALTER TABLE "store"
DROP FOREIGN KEY "FK_6f1245fe-5009-4689-9c97-216aad8ff2b8";

ALTER TABLE "store"
DROP FOREIGN KEY "FK_7acee9c3-c88c-45e3-a7d0-43b033045622";

ALTER TABLE "store_currencies"
DROP FOREIGN KEY "FK_c481d385-91cb-425d-85bd-64709c01d9ee";

ALTER TABLE "store_currencies"
DROP FOREIGN KEY "FK_d0e7c53a-a068-4cee-a4d7-6e1c4aa8e8b8";

ALTER TABLE "stock_location_address"
DROP FOREIGN KEY "FK_00927868-35d5-40db-a679-5b8b3a5d164c";

ALTER TABLE "post"
DROP FOREIGN KEY "FK_00f42943-9b91-4b43-b059-a1b44e61fc3e";

ALTER TABLE "post"
DROP FOREIGN KEY "FK_11fb1f04-7b95-43f5-b317-efedaa8a8628";

ALTER TABLE "post"
DROP FOREIGN KEY "FK_bd32e96e-a974-4754-8cfa-e3a719618b54";

ALTER TABLE "post"
DROP FOREIGN KEY "FK_f9c4dca2-a8da-4508-a9e7-c9bfb489a244";

ALTER TABLE "post_authors"
DROP FOREIGN KEY "FK_2de075c9-b223-4f52-a6aa-b83ee7dba0c5";

ALTER TABLE "post_authors"
DROP FOREIGN KEY "FK_e8c24891-3138-4bd7-baaa-b4d4463193fb";

ALTER TABLE "post_revision"
DROP FOREIGN KEY "FK_3a58d08b-1168-4b1b-b8fd-14c3c63c1ab9";

ALTER TABLE "post_revision"
DROP FOREIGN KEY "FK_70a8aca6-9a1d-4f2d-8b1c-46c2a9060590";

ALTER TABLE "post_revision"
DROP FOREIGN KEY "FK_871d1e48-b5d3-47fe-aa82-388e29105e1b";

ALTER TABLE "post_products"
DROP FOREIGN KEY "FK_485e7aaf-b8c5-4c63-9381-c57ec375d326";

ALTER TABLE "post_products"
DROP FOREIGN KEY "FK_85797cf2-eee7-4ca3-98ee-240cbf74bace";

ALTER TABLE "post_images"
DROP FOREIGN KEY "FK_83a68f23-9fae-41be-b789-5425dc741ae8";

ALTER TABLE "post_images"
DROP FOREIGN KEY "FK_9a53963d-694d-4375-b90f-bb3d3a84582d";

ALTER TABLE "tag"
DROP FOREIGN KEY "FK_046712e2-098e-447f-ad59-1293e2da23d8";

ALTER TABLE "tag"
DROP FOREIGN KEY "FK_52e2391e-53db-4018-b5b1-7d78884d8574";

ALTER TABLE "tag"
DROP FOREIGN KEY "FK_61bb3b8e-4025-44df-a596-3a4bfae72cc3";

ALTER TABLE "tag"
DROP FOREIGN KEY "FK_cce9e5fa-98b7-42a2-a07f-099b21d30125";

ALTER TABLE "tag_images"
DROP FOREIGN KEY "FK_3074f0b2-8f21-4512-a0af-14c659eb7826";

ALTER TABLE "tag_images"
DROP FOREIGN KEY "FK_79915a8e-f10e-41d2-8da3-4ce6bccca0dc";

ALTER TABLE "post_tags"
DROP FOREIGN KEY "FK_0287e4c3-f9f2-4438-b272-912f5898ed37";

ALTER TABLE "post_tags"
DROP FOREIGN KEY "FK_1ee032e9-c628-481b-a972-05393c6943df";

ALTER TABLE "comment"
DROP FOREIGN KEY "FK_275d7ba2-6b7c-414a-91cb-9e7a35cf783b";

ALTER TABLE "comment"
DROP FOREIGN KEY "FK_85cc0dd7-fd4a-41af-9054-59fdbfb2256f";

ALTER TABLE "comment"
DROP FOREIGN KEY "FK_9dfc0597-8ca1-48e6-abdb-8b6a168a3259";

ALTER TABLE "comment"
DROP FOREIGN KEY "FK_e296e77b-3081-42e2-b2d6-afe008295acf";

ALTER TABLE "comment_likes"
DROP FOREIGN KEY "FK_832e17b6-605a-4f3f-8a97-cbda10e241f9";

ALTER TABLE "comment_likes"
DROP FOREIGN KEY "FK_c6db9280-9918-4917-9030-204235a2ad38";

ALTER TABLE "comment_likes"
DROP FOREIGN KEY "FK_f569347c-20e9-4dcc-a557-d20200c231e2";

ALTER TABLE "comment_reports"
DROP FOREIGN KEY "FK_337d31b7-ccf4-4f00-8676-2d803edc6d50";

ALTER TABLE "comment_reports"
DROP FOREIGN KEY "FK_7e78ddcf-6196-4c4d-9193-b0d1b1fc8684";

ALTER TABLE "store_locales"
DROP FOREIGN KEY "FK_71419f45-332d-4d99-bd42-277c21e460da";

ALTER TABLE "store_locales"
DROP FOREIGN KEY "FK_99647084-2972-4e43-95a7-29255e31b97c";

ALTER TABLE "image_translations"
DROP FOREIGN KEY "FK_767e87ec-45f6-4f39-a629-7e479cb30890";

ALTER TABLE "image_translations"
DROP FOREIGN KEY "FK_f024e671-4806-4d00-9dda-d708ce6b5a49";

ALTER TABLE "post_translations"
DROP FOREIGN KEY "FK_4567c4cf-481d-45b1-a362-7a77ec8be7b6";

ALTER TABLE "post_translations"
DROP FOREIGN KEY "FK_b955a51d-202b-409b-b6b0-dc0a7fe7709c";

ALTER TABLE "tag_translations"
DROP FOREIGN KEY "FK_8240b92b-f88c-4e9a-9415-322a3c2f1d83";

ALTER TABLE "tag_translations"
DROP FOREIGN KEY "FK_beb56cfe-9000-43dc-8974-72e6fde9888b";

ALTER TABLE "product_tag_translations"
DROP FOREIGN KEY "FK_2636a248-da56-4a8c-aff7-57e681d77fe1";

ALTER TABLE "product_tag_translations"
DROP FOREIGN KEY "FK_67902bea-2751-45ab-8357-109b92776fa5";

ALTER TABLE "product_type_translations"
DROP FOREIGN KEY "FK_01ec4e66-ff64-448f-912d-957b524f920a";

ALTER TABLE "product_type_translations"
DROP FOREIGN KEY "FK_8563711e-4eca-4aec-b322-6a1e2613173d";

ALTER TABLE "product_variant_translations"
DROP FOREIGN KEY "FK_06e33d36-14cb-41d0-878a-577987edc0e2";

ALTER TABLE "product_variant_translations"
DROP FOREIGN KEY "FK_af509b01-6943-4649-af32-d00a51bfb1fd";

ALTER TABLE "product_option_value_translations"
DROP FOREIGN KEY "FK_253a6c80-9b70-4ea0-98a2-5b5400f36068";

ALTER TABLE "product_option_value_translations"
DROP FOREIGN KEY "FK_967aabcd-a3ec-4293-93f5-1a63d0e2d693";

ALTER TABLE "shipping_option_translations"
DROP FOREIGN KEY "FK_243732b9-e872-45d3-bc5f-f8f1a01923ee";

ALTER TABLE "shipping_option_translations"
DROP FOREIGN KEY "FK_648f3186-b9a3-426b-b0ea-6937538936d0";

ALTER TABLE "product_option_translations"
DROP FOREIGN KEY "FK_158f588a-78ee-4611-b4b7-368e19c9770f";

ALTER TABLE "product_option_translations"
DROP FOREIGN KEY "FK_392a703f-3787-4a25-9d72-466b9247ae0f";

ALTER TABLE "product_category_translations"
DROP FOREIGN KEY "FK_1f9cbb52-6a79-4d4c-808d-e18b1a39759e";

ALTER TABLE "product_category_translations"
DROP FOREIGN KEY "FK_85dafe70-b72b-4dcb-afe5-c21d096bbdc3";

ALTER TABLE "product_translations"
DROP FOREIGN KEY "FK_97fc0ddd-56fc-4cfe-b52e-98594d68eacb";

ALTER TABLE "product_translations"
DROP FOREIGN KEY "FK_9cf92add-917f-47ba-bbee-377d91505cb9";

ALTER TABLE "product_collection_translations"
DROP FOREIGN KEY "FK_3e50e6c8-8577-4a17-9da8-015bac0c13eb";

ALTER TABLE "product_collection_translations"
DROP FOREIGN KEY "FK_454a42f7-8990-48a3-b941-e557f7bb956d";

DROP TABLE "address";

DROP TABLE "analytics_config";

DROP TABLE "cart";

DROP TABLE "cart_discounts";

DROP TABLE "cart_gift_cards";

DROP TABLE "claim_image";

DROP TABLE "claim_item";

DROP TABLE "claim_item_tags";

DROP TABLE "claim_order";

DROP TABLE "claim_tag";

DROP TABLE "comment";

DROP TABLE "comment_likes";

DROP TABLE "comment_reports";

DROP TABLE "country";

DROP TABLE "currency";

DROP TABLE "custom_shipping_option";

DROP TABLE "customer";

DROP TABLE "customer_group";

DROP TABLE "customer_group_customers";

DROP TABLE "discount";

DROP TABLE "discount_condition";

DROP TABLE "discount_condition_customer_group";

DROP TABLE "discount_condition_product";

DROP TABLE "discount_condition_product_collection";

DROP TABLE "discount_condition_product_tag";

DROP TABLE "discount_condition_product_type";

DROP TABLE "discount_regions";

DROP TABLE "discount_rule";

DROP TABLE "draft_order";

DROP TABLE "fulfillment";

DROP TABLE "fulfillment_item";

DROP TABLE "fulfillment_provider";

DROP TABLE "gift_card";

DROP TABLE "gift_card_transaction";

DROP TABLE "idempotency_key";

DROP TABLE "image";

DROP TABLE "image_translations";

DROP TABLE "inventory_item";

DROP TABLE "inventory_level";

DROP TABLE "invite";

DROP TABLE "line_item";

DROP TABLE "line_item_adjustment";

DROP TABLE "line_item_tax_line";

DROP TABLE "locale";

DROP TABLE "money_amount";

DROP TABLE "note";

DROP TABLE "notification";

DROP TABLE "notification_provider";

DROP TABLE "order";

DROP TABLE "order_discounts";

DROP TABLE "order_edit";

DROP TABLE "order_gift_cards";

DROP TABLE "order_item_change";

DROP TABLE "payment";

DROP TABLE "payment_collection";

DROP TABLE "payment_collection_payments";

DROP TABLE "payment_collection_sessions";

DROP TABLE "payment_provider";

DROP TABLE "payment_session";

DROP TABLE "post";

DROP TABLE "post_authors";

DROP TABLE "post_images";

DROP TABLE "post_products";

DROP TABLE "post_revision";

DROP TABLE "post_tags";

DROP TABLE "post_translations";

DROP TABLE "price_list";

DROP TABLE "price_list_customer_groups";

DROP TABLE "product";

DROP TABLE "product_category";

DROP TABLE "product_category_product";

DROP TABLE "product_category_translations";

DROP TABLE "product_collection";

DROP TABLE "product_collection_translations";

DROP TABLE "product_images";

DROP TABLE "product_option";

DROP TABLE "product_option_translations";

DROP TABLE "product_option_value";

DROP TABLE "product_option_value_translations";

DROP TABLE "product_sales_channel";

DROP TABLE "product_tag";

DROP TABLE "product_tag_translations";

DROP TABLE "product_tags";

DROP TABLE "product_tax_rate";

DROP TABLE "product_translations";

DROP TABLE "product_type";

DROP TABLE "product_type_tax_rate";

DROP TABLE "product_type_translations";

DROP TABLE "product_variant";

DROP TABLE "product_variant_inventory_item";

DROP TABLE "product_variant_translations";

DROP TABLE "publishable_api_key";

DROP TABLE "publishable_api_key_sales_channel";

DROP TABLE "refund";

DROP TABLE "region";

DROP TABLE "region_fulfillment_providers";

DROP TABLE "region_payment_providers";

DROP TABLE "reservation_item";

DROP TABLE "return";

DROP TABLE "return_item";

DROP TABLE "return_reason";

DROP TABLE "sales_channel";

DROP TABLE "sales_channel_location";

DROP TABLE "shipping_method";

DROP TABLE "shipping_method_tax_line";

DROP TABLE "shipping_option";

DROP TABLE "shipping_option_requirement";

DROP TABLE "shipping_option_translations";

DROP TABLE "shipping_profile";

DROP TABLE "shipping_tax_rate";

DROP TABLE "stock_location";

DROP TABLE "stock_location_address";

DROP TABLE "store";

DROP TABLE "store_currencies";

DROP TABLE "store_locales";

DROP TABLE "swap";

DROP TABLE "tag";

DROP TABLE "tag_images";

DROP TABLE "tag_translations";

DROP TABLE "tax_provider";

DROP TABLE "tax_rate";

DROP TABLE "tracking_link";

DROP TABLE "user";