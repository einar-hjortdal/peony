# Models

Each model is the representation of one or more tables in the database. A model can have functions and 
methods that fetch and manipulate data stored in the tables they represent. Data should not be retrieved 
nor changed without utilizing a model.

Models should validate data before trying to send it to the database: while the database should reject 
bad inserts, the model can give better feedback to the developers.

Note: care must be taken to not enter V zero-values in tables.