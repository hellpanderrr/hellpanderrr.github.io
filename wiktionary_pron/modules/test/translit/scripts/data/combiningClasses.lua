-- This cannot be loaded directly with mw.loadData, as its parent table has a metatable. However, using mw.loadData on this module will work instead. It is separated out of the main data module to ensure that it is only loaded when needed, as it uses ~2MB of the 50MB memory allocation.

return require("ustring/normalization-data").combclass