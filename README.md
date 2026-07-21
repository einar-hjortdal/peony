# peony

Commerce

## Goals

peony is a headless ecommerce software designed to satisfy publishers, merchants and service providers.

peony aims to be multi-language, multi-channel, multi-currency, multi-warehouse, and support physical, virtual products and services, B2C and B2B.

## Get started

Clone the [starter](https://github.com/einar-hjortdal/peony-starter) and customize it to fit your needs.

## Architecture

This graph represents how peony works on a single-server deployment. This setup may scale horizontally by deploying each box on its own independent server.

```
 ┌────────────────┐                       ┌───────────────┐                
 │                │                       │     peony     │                
 │ Admin frontend ◄────────┐              │               │  ┌────────┐    
 │                │    ┌───▼──────────┐   │  ┌─────────┐  │  │        │    
 └────────────────┘    │              │   │  │         │  ◄──► Redict │    
                       │  freeNGINX   ◄───►  │   API   │  │  │        │    
 ┌────────────────┐    │              │   │  │         │  │  └────────┘    
 │                │    └───▲────▲─────┘   │  └─────────┘  │  ┌──────────┐  
 │ Store frontend ◄────────┘    │         │               │  │          │  
 │                │             │         │  ┌──────────┐ ◄──► Firebird │  
 └────────────────┘       ┌─────▼─────┐   │  │          │ │  │          │  
                          │           │   │  │  worker  │ │  └──────────┘  
                          │ providers ◄───►  │          │ │                
                          │           │   │  └──────────┘ │                
                          └───────────┘   └───────────────┘                
```

peony is a commerce backend. It consists of an API and a worker. The API and worker portions may be combined (for example, in a single-server deployment) or separated (for example, in a horizontally scaled system).

Data is persisted on a [Firebird](https://firebirdsql.org/) database, and [Redict](https://redict.io/) is used for cache, job queues and events. Other core components (called providers) are swappable: implement the provider interface to replace a provider.

[freeNGINX](https://freenginx.org/en/) is used as a TLS termination proxy to secure communication with API consumers, including the admin and store frontends, as well as providers that communicate with peony using webhooks.

### Environment variables

If a `.env` file exists, peony will read it and use the variables provided in the file. Please look 
at the provided `.env.template` file for more information.
