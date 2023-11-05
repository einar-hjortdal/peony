# Main

## App struct

This module contains the `App` struct definition.

In vweb, routes are methods on the `App` struct. Because of this, they must be defined in the same module 
as the `App` struct.

## Routes, controllers and utilities in vweb

In vweb there exists a struct called `Controller`, peony does not consider this struct.

Routes have to task to map each request (with specific HTTP methods and URL patterns) to the appropriate 
handler function, the controller, that processes that request. Routes define the structure of the API 
and determine how different endpoints are accessed by the clients, 

Controllers validate the request and prepare the response for each request. Different controllers may 
need to perform in part the same operations, these operations are abstracted to utility functions that 
are reused by all these controllers. Both controllers and utility functions can invoke models to act 
on the database.

In vweb, routes are defined together with their controllers.

### Routes

Storefront routes are prefixed with `/storefront` and Admin routes are prefixed with `/admin`. Routes 
are defined in the respective directories (`src/routes/storefront` or `src/routes/admin`) and are enabled 
in `src/routes/routes_enabled.v`

<!--
/storefront/auth authorize customers to manage their sessions
/storefront/cart 
/storefront/customer handles customer profiles
/storefront/order
/storefront/orderEdit
/storefront/payment
/storefront/product
/storefront/productCategory
/storefront/productTag
/storefront/productType
/storefront/productVariant
/storefront/region
/storefront/return
/storefront/shippingOption

/storefront/post
/storefront/postCategory
/storefront/author
/storefront/postTag
/storefront/page

/admin/auth authorize admin users to change settings
/admin/claim
/admin/customer
/admin/customerGroup
/admin/discount
/admin/discountCondition
/admin/draftOrder
/admin/fullfillment
/admin/note
/admin/notification
/admin/order
/admin/orderEdit
/admin/payment
/admin/paymentCollection
/admin/product
/admin/productCategory
/admin/productTag
/admin/productType
/admin/productVariant
/admin/region
/admin/return
/admin/returnReason
/admin/shippingOption
/admin/shippingProfile
/admin/stockLocation
/admin/store
/admin/taxRate
/admin/upload
/admin/user

/admin/post
/admin/postCategory
/admin/author
/admin/postTag
/admin/page

 -->

<!-- 
TODO secure API:
Only frontends and services with allowed tokens should be allowed to perform requests to the api.
-->