# peony

A content management system and shoping cart API.

## Goals

peony is a headless ecommerce software designed to satisfy publishers, merchants and service providers.

peony aims to be multi-language, multi-channel, multi-currency, multi-warehouse, and support physical, 
virtual products and services.

## Get started

Clone the [starter](https://github.com/einar-hjortdal/peony-starter) and customize it to fit your needs.

## Architecture

This graph represents how peony works on a single-server deployment. This setup may scale horizontally 
by deploying each box on its own independent server.

```
                                                                      ┌──────────────────────┐                      
                                                                      │        peony         │    ┌────────────────┐
                                                                      │                      │    │                │
                     ┌───────────────────┐                            │                      ┼────►    providers   │
                     │                   │                            │                      │    │                │
                     │ Admin browser app ◄────────────────────────────►       /admin/        │    └────────────────┘
                     │                   │                            │                      │                      
                     └─────────▲─────────┘                            │                      │     ┌────────────┐   
                               │                                      │                      │     │            │   
                               │                                      │                      ┼─────►   Redict   │   
┌───────────────────┐   ┌──────┼──────┐   ┌───────────────────────┐   │                      │     │            │   
│                   │   │             │   │                       │   │                      │     └────────────┘   
│ Store browser app ◄───►  freenginx  ◄───► Store frontend server ◄───┼                      │                      
│                   │   │             │   │                       │   │       /store/        │    ┌────────────────┐
└───────────────────┘   └─────────────┘   └───────────────────────┘   │                      │    │                │
                                                                      │                      ┼────►    Firebird    │
                                                                      │                      │    │                │
                                                                      │                      │    └────────────────┘
                                                                      └──────────────────────┘                      
```

peony uses a cloud architecture. It can run on several backend servers sharing a connection to the database 
servers.

- BLOBs (such as images and files) are uploaded from the admin frontend to peony which passes the data 
  through to a service of your choice: build your own integration by satisfying the `BlobProvider` interface.

The Store API routes are all prefixed with `/store/`, while the Admin API routes are all prefixed with 
`/admin/`.

### Environment variables

If a `.env` file exists, peony will read it and use the variables provided in the file. Please look 
at the provided `.env.template` file for more information.
