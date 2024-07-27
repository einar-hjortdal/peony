# Contributing

Please follow these standards

## Git workflow

1. Fork the project and clone your fork to your development environment
2. Add the original repository as an additional git remote called "upstream"
3. Create a new branch
  - The branch called production is the branch that goes live
  - The branch called master is the branch used for development
  - Feature (feat_) branches are branched off and then merged into master once features are bug-free
  - Release (rele_) branches are branched off master and then merged into production
  - Bug fix (bugf_) branches are branched off production and then merged into both production, release 
  and master

4. Write your code, test it and make sure it works
5. Commit your changes
6. Pull the latest code from upstream into your branch 

  Make sure your changes do not conflict with the original repository.

7. Push changes to the remote "origin" (your repository)
8. Create a pull request
  - If the pull request addresses an issue, tag the related issue

## Code standards

- Comment code when needed, use self-explanatory symbol names.

### V

- Prefer factory functions over static methods.
- The model should validate data before acting on the database.
- The controller can prepare the data before giving it to the model by adding values.
- Do not use the `@[required]` attribute in struct definitions, always manually check values to return 
  adequate error messages.
- For consistency reasons, use `arrays.concat` over `<<` to concatenate items to an array.

#### Patterns

Each request-response cycle follows the route-controller-model pattern.

1. A request reaches a *route*
2. The route invokes the correct *controller* for the request
3. Controllers may invoke a *model* to act on the data-layer
4. Models return the result of data-layer operation to the controller
5. The controller gives the result to the route
6. The route formats the data and serves the response as JSON

Note: in vweb, routes and controllers are defined together. The key takeaway is that a route/controller 
  should never perform data-layer operations directly, but only invoke model functions or methods.

### Firebird

- Only use *prepared statements* to pass V values to the MySQL server. An acceptable exception to this 
  rule is when executing SQL scripts before the app starts.
- Only use pooled connections to query the database unless an independent connection is required. One 
  such case is when database connections are needed before starting vweb with `vweb.run_at`.

- Uppercase for keywords, data types. Lowercase all other identifiers.
- Use `REAL` and `DOUBLE PRECISION` for floating point types.
- Use `CHAR` for strings with expected exact lengths.
- Use `VARCHAR` for strings with expected maximum lengths, for strings with default values, and for 
  strings that are in an `INDEX` or `UNIQUE` constraint.
- Use `TEXT` for unknown-length strings.
