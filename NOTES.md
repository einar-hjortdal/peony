# Notes

## Design

### Countries, regions, currencies and prices

One country can only be in one region. One region can only have one currency. Therefore one country 
can only have one currency. By default, a store has no regions.

A product_variant can be given many money_amount. If a region is created, a product_variant can have 
a money_amount that is related to a region. In this case, if the customer is from this region, the regional 
money_amount is prioritized: the customer will get the regional money_amount in its currency.

### Inventory management

By default, peony manages the inventory of each `product_variant`. A `product_variant` is always considered 
*in stock* if peony does not manage its inventory.

An `inventory_item` is a `product_variant` for which the inventory is managed by peony.
- `requires_shipping` indicates whether the item must be shipped.

An `inventory_level` represents the `inventory_item` in one `stock_location`.
- `stocked_quantity` is the amount of `inventory_item` located at the `stock_location`.
- `reserved_quantity` is the amount of `inventory_item` located at the `stock_location` that is not 
  available to be ordered. This must be subtracted from `stocked_quantity` to determine the amount of 
  `inventory_item` that can be ordered.

A `product_variant` is considered *in stock* whenever there exist `inventory_item` associated with the 
`product_variant` and the calculated available amount of `inventory_item` is more than 0.

A `reservation_item` is one `inventory_item` that is part of a `reserved_quantity`. This is used when 
  an order has been created but has not been fulfilled yet.

## Schema

