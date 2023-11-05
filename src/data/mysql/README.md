# MySQL

This module contains functions to create MySQL connections and execute statements. 

## Models

Files prefixed with `model_` contain representations of entities handled by peony, methods and functions 
for CRUD operations on them. Models are V structs, they represent one or more tables in the database 
and their properties are named after the columns in the tables they represent. 

The name of functions that act on models are prefixed by the model name.

Models access the database using the connection pool in `app.db`, while the setup process uses independent 
connections.