# Notes

## Design

### Countries, regions, currencies and prices

One country can only be in one region. One region can only have one currency. Therefore one country 
can only have one currency. By default, a store has no regions.

A product_variant can be given many money_amount. If a region is created, a product_variant can have 
a money_amount that is related to a region. In this case, if the customer is from this region, the regional 
money_amount is prioritized: the customer will get the regional money_amount in its currency.

## Schema

