# Roadmap

### v3.6.0

Allows customers to submit orders that can be manually approved by the admin.

- customer
- cart
- orders

### v3.5.0

CMS to manage pages and posts with multilanguage and multichannel support.

### v3.4.0

Adds features.

- Discounts

### v3.3.0

Allows the admin to login and create products.

- Multilanguage
- Multicurrency
- Multiregion
- Multichannel
- Multiwarehouse

#### Features description

A product:
  - must have a handle. This handle is used to find the product from a given url.
  - may have one origin country.
  - may have one or more image.
  - may have a price. This price may be in one or more currency (TODO).
  - may have one or more *option*. An option defines properties that may vary between different variants 
  of a product (eg. color, length...). Each option has a value. option can be translated.
  - may have one or more *variant*. Each variant may have a price, described by the price_list, which 
  overrides its base price. A variant specifies a unique combination of product option values.
  - may have one or more product_tag. product_tag can be translated.
  - may have one or more product_type. product_type can be translated.
  - may be part of one or more product_collection. product_collection can be translated.
  - may have one title. This title may be have translations.
  - may have one subtitle. This subtitle may be have translations.
  - may have one description. This description may be have translations.
  - may have an origin country.
  - may have height.
  - may have width.
  - may have depth.
  - may have weight.
  <!-- - may have a material_composition. A material_composition describes which materials are found in the 
  product and their percentage. These materials may have translations (typically required in the EU 
  for textile products). TODO maybe not: only applies to textiles? does not need to be a column of product -->


A money_amount represent a price amount, for example, a product variant's price or a price in a price 
list. Each money_amount either has a currency or region associated with it to indicate the pricing in 
a given currency or, for fully region-based pricing, the given price in a specific region. If region-based 
pricing is used, the amount will be in the currency defined for the region.

