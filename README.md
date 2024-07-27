# peony

A content management system and shoping cart API.

## Goals

peony aims to provide the tools to publish content, market and monetize it. These tools should also 
be able to satisfy merchants and service providers.

peony aims to support multi-language, multi-channel, multi-currency, multi-stock locations, physical, 
virtual products and services.

## Architecture

This graph represents how peony works on a single-server deployment. This setup may scale horizontally 
by deploying each box on its own independent server.

```
┌────────────┐                           ┌──────────────────────┐        ┌────────┐
│            │                           │        peony         │        │        │
│            │                           │                      ├────────► Redict ├──────┐
│            │     ┌────────────────┐    │                      │        │        │      │
│            │     │                │    │                      │        └────────┘      │
│            ◄─────► Admin frontend ◄────►       /admin/        │                        │
│            │     │                │    │                      │   ┌────────────────┐   │
│            │     └────────────────┘    │                      │   │                │   │
│            │                           │                      ├───►    Firebird    ◄───┘
│            ◄───────────────────────────►                      │   │                │
│            │                           │                      │   └────────────────┘
│ freenginx  │  ┌─────────────────────┐  │                      │
│            │  │                     │  │                      │   ┌────────────────┐
│            ◄──► Storefront frontend ◄──►     /storefront/     │   │                │
│            │  │                     │  │                      ├───►     Vistas     ├───┐
│            │  └─────────────────────┘  │                      │   │                │   │
│            │                           │                      │   └────────────────┘   │
│            │                           │                      │                        │
│            │                           └──────────────────────┘                        │
│            │                                                                           │
│            ◄───────────────────────────────────────────────────────────────────────────┘
└────────────┘
```

peony is meant to work behind a web server set up as reverse proxy.

peony uses a cloud architecture. It can run on several backend servers sharing a connection to the database 
servers. BLOBs are uploaded from the Admin frontend (such as images and documents) are stored on a central 
BLOB server.

The Storefront API routes are all prefixed with `/storefront`, while the Admin API routes are all prefixed 
with `/admin`.

<!--
### Directory structure
.
├── CONTRIBUTING.md
├── docs
├── LICENSE.md
├── README.md
├── src
│   ├── config
│   ├── data
│   │   ├── mysql
│   │   ├── redis
│   │   └── s3
│   ├── middlewares
│   ├── migrations
│   └── utils
├── container-compose.yml
├── Containerfile
├── .env
├── .env.template
└── v.mod

- `docs` contains documentation for development and deployment.
- `src` contains the entry point of the program `main.v`, and vweb routes in files prefixed with `route_`.
- `config` contains environment variables-related functions.
- `controllers` contains the handler functions for the routes.
- `data` contains everything related to MySQL, Redis and S3.
- `migrations` contain the MySQL scripts that change the database schema.
- `utils` contains useful and reusable functions.
 -->

## Development and deployment

Instructions for development of peony can be found [here](docs/development/), comprehensive instructions 
for a single-server deployment are provided [here](docs/deployment/).

### Important

- It is required to add `ANSI` to the default `sql-mode` of the MySQL server.

### Defaults

The default admin account has *username* `default_admin@peony.com` and *password* `peony_password`. 
These are logged to console when running peony for the first time, it is recommended to change both 
email and password of the default admin account.

### Environment variables

If a `.env` file exists, peony will read it and use the variables provided in the file. Please look 
at the provided `.env.template` file for more information.
