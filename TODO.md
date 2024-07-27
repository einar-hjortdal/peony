# TODO

## Rewrite:

- Change BLOB storage: use a [central file server](https://github.com/Coachonko/vistas).
- Change database: use [Firebird](https://www.firebirdsql.org/).
- Change cache: use [Redict](https://redict.io/).
- Change mail handling: use [SensorPro](https://sensorpro.eu/).

## Roadmap

### v3.1.0

This release allows the admin to login, create posts and store them in Firebird.

- Read settings from .env
  - ~~Validate settings~~ <!-- Always panic right away on startup, never on runtime -->
- Firebird
  - Write a firebird connector
  - ~~Seeding new database~~
    - ~~Schema~~
    - ~~Data~~ <!-- countries, currencies, locale, default store, default user -->
- Redict
  - ~~Write a redis library~~ <!-- https://github.com/Coachonko/redis -->
  - ~~Cache~~ <!-- https://github.com/Coachonko/cache -->
  - Sessions
- BLOBs
  - ~~Write a BLOB storage service~~ <!-- https://github.com/Coachonko/vistas -->
- Users
  - Sessions
- Admin frontend <!-- https://github.com/Coachonko/peony_admin -->
- Storefront frontend <!-- https://github.com/Coachonko/coachonko_storefront -->

### v3.2.0

Needed enhancements on basic functionality.

- Query parameters
- User permissions:
  - admin: all
  - member:
  - developer:
  - author: can write and publish posts
  - contributor: can write posts but not publish
- New features for posts:
  - ~~Tags~~ <!-- Tags have no hierarchy, categories are a subset of tags and have hierarchy -->
  - ~~Authors~~
- Search

### v3.3.0

This release allows the store to have more than one language. The store can have a default language 
set, content will be in this language by default. More languages can be enabled for the store, then, 
translations for posts, product names, subtitles, descriptions and handles can be stored in any of the 
enabled languages. Even images, if necessary, can have language-specific alternatives.

- multi-language

### v3.4.0

This release allows scaling horizontally, by running many instances of peony on different server, thanks 
to Redict working as both job queue and event bus. Additionally, events can now be scheduled: posts 
can be scheduled to become public at a specific date and time.

- Redis:
  - Job queue
  - Event bus

### v3.5.0

This release allows users to register, login and manage their account. It is possible to request a password 
reset, an email is sent to the user email containing a link to change their password.

- Customers: registration, authentication, authorization
  - GDPR compliance: automated anonymization of customer data
- SMTP client: user and customer password reset <!-- email are generated with vweb templates -->

### v3.6.0

This release focuses on polishing peony as a publishing platform. The blogging functionality should 
be considered mature and stable. Future releases will focus on ecommerce capabilities to allow monetization 
for content publishers and to make peony appealing as a versatile and comprehensive ecommerce system.
<!-- 
Add lower-priority content-publishing features:
restore deleted posts, tags, users
post revisions

Code optimizations:
multiple prepared statements within one transaction
-->

### v3.7.0

This release implements shopping cart capabilities. Customers can add products to their cart and check 
out. Transactional emails are sent to customers. Countries are grouped into regions, these are used 
to enable payment and shipping options, as well as managing prices and taxes. 

Shopping cart capabilities are not limited to products but extend to subscriptions with different tiers: 
publishers can offer exclusive content to members, and clubs can manage memberships through peony. This 
system can be applied to many different use cases.

- Memberships and tiers
- Products
- Payments, subscriptions with tiers <!-- TODO consider Stripe, PayPal, Mollie   -->
- Shipping <!-- SkyNet -->
- Transactional emails <!-- using the previously-implemented SMTP client -->

### v3.8.0

Reserved

### v3.9.0

This release allows the store to have more than one currency. One or more countries can be part of one 
region, each region can be served with one currency. Products and their variants can have prices set 
with each currency.

- multi-currency

### v3.10.0

This release allows to create and manage different sales channels. Each channel can have its own posts 
and products, each product can have different prices and availability on each channel. Each order is 
associated with the sales channel it came from.

- multi-channel

### v3.11.0

- Giftcards
- Discounts

## v3.12.0

This release simplifies the way peony is customized: by implementing a plugin system, peony becomes 
modular and highly customizable. This allows the peony community to develop solutions to expand peony's 
capabilities without having to modify peony itself.

- Plugin system
  - Sessions
  - Fulfillment
  - Payment
  - Transactional email
- Official peony plugins <!-- Refactor -->
  - Sessions: Redict sessions with JWT token
  - Fullfillment provider: SkyNet Worldwide Express
  - Payment provider: <!-- TBD -->
  - Transactional email: Sensorpro

## Future projects and enhancements

- Save last 10 versions of every post: add endpoints to allow users to view and revert to previous versions.
- Digital products should be able to be stored on Garage.
- Webmentions
- Official peony plugins
  - Sessions: Redict sessions with session ID Cookie
  - Transactional email: Cleverreach
  - Email marketing: Cleverreach
