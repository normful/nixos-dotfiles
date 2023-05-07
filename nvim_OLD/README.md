To migrate old plugin lua files:

- Remove all `require("utils")` and just access `utils` directly because it's already in scope
- Rename all `configure()` functions to be a unique function name and immediately call it after declaring the function
