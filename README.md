# peony

<a href="https://github.com/mkenney/software-guides/blob/master/STABILITY-BADGES.md#alpha"><img src="https://img.shields.io/badge/stability-alpha-f4d03f.svg" alt="Alpha"></a>

A content management system and shoping cart API for simple ecommerce needs. It is developed and used 
for [Coachonko's blog](https://coachonko.com). 

## Objectives

This project aims to satisfy the needs of humble businesses: with support for multi-language, multi-currency, 
multi-channel, multiple stock locations, physical and virtual products.

## Architecture

This graph represents how peony works on a single-server deployment. This setup can be scale horizontally 
by deploying each box on multiple servers.

```
┌────────────┐                           ┌──────────────────────┐        ┌───────┐
│            │                           │        peony         │        │       │
│            │                           │                      ├────────► KeyDB ├───────┐
│            │     ┌────────────────┐    │                      │        │       │       │
│            │     │                │    │                      │        └───────┘       │
│            ◄─────► Admin frontend ◄────►       /admin/        │                        │
│            │     │                │    │                      │   ┌────────────────┐   │
│            │     └────────────────┘    │                      │   │                │   │
│            │                           │                      ├───► Percona Server ◄───┘
│            ◄───────────────────────────►                      │   │                │
│            │                           │                      │   └────────────────┘
│  lighttpd  │  ┌─────────────────────┐  │                      │
│            │  │                     │  │                      │   ┌────────────────┐
│            ◄──► Storefront frontend ◄──►     /storefront/     │   │                │
│            │  │                     │  │                      ├───►     Garage     ├───┐
│            │  └─────────────────────┘  │                      │   │                │   │
│            │                           │                      │   └────────────────┘   │
│            │                           │                      │                        │
│            │                           └──────────────────────┘                        │
│            │                                                                           │
│            ◄───────────────────────────────────────────────────────────────────────────┘
└────────────┘
```

peony is meant to work behind a web server set up as reverse proxy. It is recommended to use lighttpd.

peony uses a cloud architecture. It can run on several backend servers sharing a connection to the KeyDB 
server and Percona Server. Static files uploaded from the Admin frontend (such as images and documents) 
are stored on Garage. KeyDB works as cache, job queue and session storage, and Percona Server stores 
data.

While I use these technologies deployed as containers on my VPS, this application can be used with any 
managed MySQL server, Redis server and S3-compatible object storage.

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
