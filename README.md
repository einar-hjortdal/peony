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
                               ┌────────────┐                                                                                    
                               │            │         ┌────────────────┐                                                         
                               │            │         │                │                                                         
                               │            ◄─────────┼     Blobly     │                                                         
                               │            │         │                │                                                         
                               │            │         └────────▲───────┘        ┌──────────────────────┐        ┌────────┐       
                               │            │                  │                │        peony         │        │        │       
                               │            │                  │                │                      ├────────► Redict ├──────┐
     ┌───────────────────┐     │            │     ┌────────────┼──────────┐     │                      │        │        │      │
     │                   │     │            │     │                       │     │                      │        └────────┘      │
     │ Admin browser app ◄─────►            ◄─────► Admin frontend server ◄─────►       /admin/        │                        │
     │                   │     │            │     │                       │     │                      │                        │
     └───────────────────┘     │            │     └───────────────────────┘     │                      │                        │
                               │ freenginx  │                                   │                      │                        │
                               │            │                                   │                      │                        │
                               │            │                                   │                      │                        │
     ┌───────────────────┐     │            │     ┌───────────────────────┐     │                      │                        │
     │                   │     │            │     │                       │     │                      │                        │
     │ Store browser app ◄─────►            ◄─────► Store frontend server ◄─────►       /store/        │   ┌────────────────┐   │
     │                   │     │            │     │                       │     │                      │   │                │   │
     └───────────────────┘     │            │     └───────────────────────┘     │                      ├───►    Firebird    ◄───┘
                               │            │                                   │                      │   │                │    
                               │            │                                   │                      │   └────────────────┘    
                               │            │                                   └──────────────────────┘                         
                               │            │                                                                                    
                               │            │                                                                                    
                               └────────────┘                                                                                    
```

peony is meant to work behind a web server set up as reverse proxy.

peony uses a cloud architecture. It can run on several backend servers sharing a connection to the database 
servers. BLOBs are uploaded from the Admin frontend (such as images and documents) are stored on a central 
BLOB server.

The Store API routes are all prefixed with `/store/`, while the Admin API routes are all prefixed with 
`/admin/`.

### Environment variables

If a `.env` file exists, peony will read it and use the variables provided in the file. Please look 
at the provided `.env.template` file for more information.
