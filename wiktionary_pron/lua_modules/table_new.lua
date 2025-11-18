local export = {}

--[==[ intro:
This module provides functions for dealing with Lua tables. All of them, except for two helper functions, take a table
as their first argument.

Some functions are available as methods in the arrays created by [[Module:array]].

Functions by what they do:
* Create a new table:
** `shallowCopy`, `deepCopy`, `removeDuplicates`, `numKeys`, `compressSparseArray`, `keysToList`, `reverse`, `invert`, `listToSet`
* Create an array:
** `removeDuplicates`, `numKeys`, `compressSparseArray`, `keysToList`, `reverse`
* Return information about the table:
** `size`, `length`, `contains`, `keyFor`, `isArray`, `deepEquals`
* Treat the table as an array (that is, operate on the values in the array portion of the table: values indexed by
  consecutive integers starting at {1}):
** `removeDuplicates`, `length`, `contains`, `serialCommaJoin`, `reverseIpairs`, `reverse`, `invert`, `listToSet`, `isArray`
* Treat a table as a sparse array (that is, operate on values indexed by non-consecutive integers):
** `numKeys`, `maxIndex`, `compressSparseArray`, `sparseConcat`, `sparseIpairs`
* Generate an iterator:
** `sparseIpairs`, `sortedPairs`, `reverseIpairs`
* Other functions:
** `sparseConcat`, `serialCommaJoin`, `reverseConcat`

The original version was a copy of {{w|Module:TableTools}} on Wikipedia via [[c:Module:TableTools|Module:TableTools]] on
Commons, but in the course of time this module has been almost completely rewritten, with many new functions added. The
main legacy of this is the use of camelCase for function names rather than snake_case, as is normal in the English
Wiktionary.
]==]

local collation_module = "collation"
local debug_track_module = "debug/track"
local function_module = "fun"
local math_module = "math"

local table = table

local concat = table.concat
local deep_equals -- defined as export.deepEquals
local dump = mw.dumpObject
local format = string.format
local getmetatable = getmetatable
local insert = table.insert
local invert -- defined as export.invert
local ipairs = ipairs
local ipairs_default_iter = ipairs { export }
local keys_to_list -- defined as export.keysToList
local list_to_set -- defined as export.listToSet
local next = next
local num_keys -- defined as export.numKeys
local pairs = pairs
local pcall = pcall
local rawget = rawget
local require = require
local select = select
local setmetatable = setmetatable
local signed_index -- defined as export.signedIndex
local sort = table.sort
local sparse_ipairs -- defined as export.sparseIpairs
local table_len -- defined as export.length
local table_reverse -- defined as export.reverse
local type = type

--[==[
Loaders for functions in other modules, which overwrite themselves with the target function when called. This ensures modules are only loaded when needed, retains the speed/convenience of locally-declared pre-loaded functions, and has no overhead after the first call, since the target functions are called directly in any subsequent calls.]==]
local function debug_track(...)
    debug_track = require(debug_track_module)
    return debug_track(...)
end

local function is_callable(...)
    is_callable = require(function_module).is_callable
    return is_callable(...)
end

local function is_integer(...)
    is_integer = require(math_module).is_integer
    return is_integer(...)
end

local function is_positive_integer(...)
    is_positive_integer = require(math_module).is_positive_integer
    return is_positive_integer(...)
end

local function string_sort(...)
    string_sort = require(collation_module).string_sort
    return string_sort(...)
end

--[==[
Returns a clone of an object. If the object is a table, the value returned is a new table, but all subtables and functions are shared. Metamethods are respected unless the `raw` flag is set, but the returned table will have no metatable of its own.]==]
function export.shallowCopy(orig, raw)
    if type(orig) ~= "table" then
        return orig
    end
    local copy, iter, state, init = {}
    if raw then
        iter, state = next, orig
    else
        iter, state, init = pairs(orig)
    end
    for k, v in iter, state, init do
        copy[k] = v
    end
    return copy
end

do
    local tracked1, tracked2

    local function make_copy(orig, seen, mt_flag, keep_loaded_data)
        if type(orig) ~= "table" then
            return orig
        end
        local memoized = seen[orig]
        if memoized ~= nil then
            return memoized
        end
        local mt, iter, state, init = getmetatable(orig)
        -- `mt` could be a non-table if `__metatable` has been used, but discard it in such cases.
        if not (mt and type(mt) == "table") then
            mt, iter, state, init = nil, next, orig, nil
            -- Data loaded via `mw.loadData`, which sets the key "mw_loadData" to true in the metatable.
        elseif rawget(mt, "mw_loadData") == true then
            if keep_loaded_data then
                seen[orig] = orig
                return orig
                -- Track instances of such data being copied, which is very inefficient and usually unnecessary.
            elseif not tracked1 then
                debug_track("table/deepCopy/loaded data")
                tracked1 = true
            end
            -- Discard the metatable, and use the `__pairs` metamethod.
            mt, iter, state, init = nil, pairs(orig)
            -- Otherwise, keep `mt`.
        else
            -- Track copied metatables to find any instances where it's really necessary, as it would be preferable for the default to be `pairs` instead of `next` (i.e. using __pairs if present, returning a table with no metatable).
            if not tracked2 then
                debug_track("table/deepCopy/copied metatable")
                tracked2 = true
            end
            iter, state, init = next, orig, nil
        end
        local copy = {}
        seen[orig] = copy
        for k, v in iter, state, init do
            copy[make_copy(k, seen, mt_flag, keep_loaded_data)] = make_copy(v, seen, mt_flag, keep_loaded_data)
        end
        if mt == nil or mt_flag == "none" then
            return copy
        elseif mt_flag ~= "keep" then
            mt = make_copy(mt, seen, mt_flag, keep_loaded_data)
        end
        return setmetatable(copy, mt)
    end

    --[==[
    Recursive deep copy function. Preserves copied identities of subtables.
    A more powerful version of {mw.clone}, with customizable options.
    * By default, metatables are copied, except for data loaded via {mw.loadData} (see below). If `metatableFlag` is set to "none", the copy will not have any metatables at all. Conversely, if `metatableFlag` is set to "keep", then the cloned table (and all its members) will have the exact same metatable as their original version.
    * If `keepLoadedData` is true, then any data loaded via {mw.loadData} will not be copied, and the original will be used instead. This is useful in iterative contexts where it is necessary to copy data being destructively modified, because objects loaded via mw.loadData are immutable.
    * Notes:
    *# Protected metatables will not be copied (i.e. those hidden behind a __metatable metamethod), as they are not
       accessible by Lua's design. Instead, the output of the __metatable method will be used instead.
    *# When iterating over the table, the __pairs metamethod is ignored, since this can prevent the table from being properly cloned.
    *# Data loaded via mw.loadData is a special case in two ways: the metatable is stripped, because otherwise the cloned table throws errors when accessed; in addition, the __pairs metamethod is used, since otherwise the cloned table would be empty.]==]
    function export.deepCopy(orig, metatableFlag, keepLoadedData)
        return make_copy(orig, {}, metatableFlag, keepLoadedData)
    end
end

--[==[
Given an array and a signed index, returns the true table index. If the signed index is negative, the array will be counted from the end, where {-1} is the highest index in the array; otherwise, the returned index will be the same. To aid optimization, the first argument may be a number representing the array length instead of the array itself; this is useful when the array length is already known, as it avoids recalculating it each time this function is called.]==]
function export.signedIndex(t, k)
    if not is_integer(k) then
        error("index must be an integer")
    end
    return k < 0 and (type(t) == "table" and table_len(t) or t) + k + 1 or k
end
signed_index = export.signedIndex

--[==[
Returns the highest positive integer index of a table or array that possibly has holes in it, or otherwise 0 if no positive integer keys are found. Note that this differs from `table.maxn`, which returns the highest positive numerical index, even if it is not an integer.]==]
function export.maxIndex(t)
    local max = 0
    for k in pairs(t) do
        if is_positive_integer(k) and k > max then
            max = k
        end
    end
    return max
end

--[==[
Append any number of lists together and returns the result. Compare the Lisp expression {(append list1 list2 ...)}.]==]
function export.append(...)
    local args, list, n = { ... }, {}, 0
    for i = 1, select("#", ...) do
        local t, j = args[i], 0
        while true do
            j = j + 1
            local v = t[j]
            if v == nil then
                break
            end
            n = n + 1
            list[n] = v
        end
    end
    return list
end

--[==[
Extend an existing list by a new list, modifying the existing list in-place. Compare the Python expression
{list.extend(new_items)}.]==]
function export.extend(t, ...)
    if select("#", ...) < 2 then
        local i, new_items = 0, ...
        while true do
            i = i + 1
            local item = new_items[i]
            if item == nil then
                return t
            end
            insert(t, item)
        end
        return
    end
    local i, pos, new_items = 0, ...
    while true do
        i = i + 1
        local item = new_items[i]
        if item == nil then
            return t
        end
        insert(t, pos, item)
        pos = pos + 1
    end
end

--[==[
Given a list, returns a new list consisting of the items between the start index `i` and end index `j` (inclusive). `i` defaults to `1`, and `j` defaults to the length of the input list.]==]
function export.slice(t, i, j)
    local t_len = table_len(t)
    i = i and signed_index(t_len, i) or 1
    local list, offset = {}, i - 1
    for key = i, j and signed_index(t_len, j) or t_len do
        list[key - offset] = t[key]
    end
    return list
end

do
    local pos_nan, neg_nan
    --[==[
    Remove any duplicate values from a list, ignoring non-positive-integer keys. The earliest value is kept, and all subsequent duplicate values are removed, but otherwise the list order is unchanged.]==]
    function export.removeDuplicates(t)
        local list, seen, i, n = {}, {}, 0, 0
        while true do
            i = i + 1
            local v = t[i]
            if v == nil then
                return list
            end
            local memo_key
            if v == v then
                memo_key = v
                -- NaN
            elseif format("%f", v) == "nan" then
                if not pos_nan then
                    pos_nan = {}
                end
                memo_key = pos_nan
                -- -NaN
            else
                if not neg_nan then
                    neg_nan = {}
                end
                memo_key = neg_nan
            end
            if not seen[memo_key] then
                n = n + 1
                list[n], seen[memo_key] = v, true
            end
        end
    end
end

--[==[
Given a table, return an array containing all positive integer keys, sorted in numerical order.]==]
function export.numKeys(t)
    local nums, i = {}, 0
    for k in pairs(t) do
        if is_positive_integer(k) then
            i = i + 1
            nums[i] = k
        end
    end
    sort(nums)
    return nums
end
num_keys = export.numKeys

--[==[
Takes a list that may contain gaps (e.g. {1, 2, nil, 4}), and returns a new gapless list in the same order.]==]
function export.compressSparseArray(t)
    local list, keys, i = {}, num_keys(t), 0
    while true do
        i = i + 1
        local k = keys[i]
        if k == nil then
            return list
        end
        list[i] = t[k]
    end
end

--[==[
An iterator which works like `pairs`, but ignores any `__pairs` metamethod.]==]
function export.rawPairs(t)
    return next, t, nil
end

--[==[
An iterator which works like `ipairs`, but ignores any `__ipairs` metamethod.]==]
function export.rawIpairs(t)
    return ipairs_default_iter, t, 0
end

do
    local current
    --[==[
    An iterator which works like `pairs`, except that it also respects the `__index` metamethod. This works by iterating over the input table with `pairs`, followed by the table at its `__index` metamethod (if any). This is then repeated for that table's `__index` table and so on, with any repeated keys being skipped over, until there are no more tables, or a table repeats (so as to prevent an infinite loop). If `__index` is a function, however, then it is ignored, since there is no way to iterate over its return values.

    A `__pairs` metamethod will be respected for any given table instead of iterating over it directly, but these will be ignored if the `raw` flag is set.

    Note: this function can be used as a `__pairs` metamethod. In such cases, it does not call itself, since this would cause an infinite loop, so it treats the relevant table as having no `__pairs` metamethod. Other `__pairs` metamethods on subsequent tables will still be respected.]==]
    function export.indexPairs(t, raw)
        -- If there's no metatable, result is identical to `pairs`.
        -- To prevent infinite loops, act like `pairs` if `current` is set with `t`, which means this function is being used as a __pairs metamethod.
        if current and current[t] or getmetatable(t) == nil then
            return next, t, nil
        end

        -- `seen_k` memoizes keys, as they should never repeat; `seen_t` memoizes tables iterated over.
        local seen_k, seen_t, iter, state, k, v, success = {}, { [t] = true }

        return function()
            while true do
                if iter == nil then
                    -- If `raw` is set, use `next`.
                    if raw then
                        iter, state, k = next, t, nil
                        -- Otherwise, call `pairs`, setting `current` with `t` so that export.indexPairs knows to return `next` if it's being used as a metamethod, as this prevents infinite loops. `t` is then unset, so that `current` doesn't get polluted if the loop breaks early.
                    else
                        if not current then
                            current = {}
                        end
                        current[t] = true
                        -- Use `pcall`, so that `t` can always be unset from `current`.
                        success, iter, state, k = pcall(pairs, t)
                        current[t] = nil
                        -- If there was an error, raise it.
                        if not success then
                            error(iter)
                        end
                    end
                end
                while true do
                    -- It's possible for a `__pairs` metamethod to return additional values, but assume there aren't any, since this iterator specifically relates to table indexes.
                    k, v = iter(state, k)
                    if k == nil then
                        break
                        -- If a repeated key is found, skip and iterate again.
                    elseif not seen_k[k] then
                        seen_k[k] = true
                        return k, v
                    end
                end
                -- If there's an __index metamethod, iterate over it iff it's a table not already seen before.
                local mt = getmetatable(t)
                -- `mt` might not be a table if __metatable is used.
                if not mt or type(mt) ~= "table" then
                    return nil
                end
                seen_t[t] = true
                t = rawget(mt, "__index")
                if not t or type(t) ~= "table" then
                    return nil
                    -- Throw error if it's been seen before.
                elseif seen_t[t] then
                    error("loop in gettable")
                end
                iter = nil -- New `iter` will be generated on the next iteration of the while loop.
            end
        end
    end
end

do
    local function ipairs_func(t, i)
        i = i + 1
        local v = t[i]
        if v ~= nil then
            return i, v
        end
    end

    --[==[
    An iterator which works like `ipairs`, except that it also respects the `__index` metamethod. This works by looking up values in the table, iterating integers from key `1` until no value is found.]==]
    function export.indexIpairs(t)
        -- If there's no metatable, just use the default ipairs iterator.
        return getmetatable(t) == nil and ipairs_default_iter or ipairs_func, t, 0
    end
end

--[==[
An iterator which works like `indexIpairs`, but which only returns the value.]==]
function export.iterateList(t)
    local i = 0
    return function()
        i = i + 1
        return t[i]
    end
end

--[==[
This is an iterator for sparse arrays. It can be used like ipairs, but can handle nil values.]==]
function export.sparseIpairs(t)
    local keys, i = num_keys(t), 0
    return function()
        i = i + 1
        local k = keys[i]
        if k ~= nil then
            return k, t[k]
        end
    end
end
sparse_ipairs = export.sparseIpairs

--[==[
This returns the size of a key/value pair table. If `raw` is set, then metamethods will be ignored, giving the true table size.

For arrays, it is faster to use `export.length`.]==]
function export.size(t, raw)
    local i, iter, state, init = 0
    if raw then
        iter, state, init = next, t, nil
    else
        iter, state, init = pairs(t)
    end
    for _ in iter, state, init do
        i = i + 1
    end
    return i
end

--[==[
This returns the length of a table, or the first integer key n counting from 1 such that t[n + 1] is nil. It is a more reliable form of the operator `#`, which can become unpredictable under certain circumstances due to the implementation of tables under the hood in Lua, and therefore should not be used when dealing with arbitrary tables. `#` also does not use metamethods, so will return the wrong value in cases where it is desirable to take these into account (e.g. data loaded via `mw.loadData`). If `raw` is set, then metamethods will be ignored, giving the true table length.

For arrays, this function is faster than `export.size`.]==]
function export.length(t, raw)
    local n = 0
    if raw then
        for i in ipairs_default_iter, t, 0 do
            n = i
        end
        return n
    end
    repeat
        n = n + 1
    until t[n] == nil
    return n - 1
end
table_len = export.length

do
    local function is_equivalent(a, b, seen, include_mt)
        -- Simple equality check.
        if a == b then
            return true
            -- If not equal, a and b can only be equivalent if they're both tables.
        elseif not (type(a) == "table" and type(b) == "table") then
            return false
        end
        -- If `a` and `b` have been compared before, return the memoized result. This will usually be true, since failures normally fail the whole check outright, but match failures are tolerated during the laborious check without this happening, since it compares key/value pairs until it finds a match, so it could be false.
        local memo_a = seen[a]
        if memo_a then
            local result = memo_a[b]
            if result ~= nil then
                return result
            end
            -- To avoid recursive references causing infinite loops, assume the tables currently being compared are equivalent by memoizing the comparison as true; this will be corrected to false if there's a match failure.
            memo_a[b] = true
        else
            memo_a = { [b] = true }
            seen[a] = memo_a
        end
        -- Don't bother checking `memo_b` for `a`, since if `a` and `b` had been compared before then `b` would be in `memo_a`, but it isn't.
        local memo_b = seen[b]
        if memo_b then
            memo_b[a] = true
        else
            memo_b = { [a] = true }
            seen[b] = memo_b
        end
        -- If `include_mt` is set, check the metatables are equivalent.
        if include_mt and not is_equivalent(getmetatable(a), getmetatable(b), seen, true) then
            memo_a[b], memo_b[a] = false, false
            return false
        end
        -- Copy all key/values pairs in `b` to `remaining_b`, and count the size: this uses `pairs`, which will also be used to iterate over `a`, ensuring that `a` and `b` are iterated over using the same iterator. This is necessary to ensure that `deepEquals(a, b)` and `deepEquals(b, a)` always give the same result. Simply iterating over `a` while accessing keys in `b` for comparison would ignore any `__pairs` metamethod that `b` has, which could cause asymmetrical outputs if `__pairs` returns more or less than the complete set of key/value pairs accessible via `__index`, so using `pairs` for both `a` and `b` prevents this.
        -- TODO: handle exotic `__pairs` methods which return the same key multiple times with different values.
        local remaining_b, size_b = {}, 0
        for k_b, v_b in pairs(b) do
            remaining_b[k_b], size_b = v_b, size_b + 1
        end
        -- Fast check: iterate over the keys in `a`, checking if an equivalent value exists at the same key in `remaining_b`. As matches are found, key/value pairs are removed from `remaining_b`. If any keys in `a` or `remaining_b` are tables, the fast check will only work if the exact same object exists as a key in the other table. Any others from `a` that don't match anything in `remaining_b` are added to `remaining_a`, while those in `remaining_b` that weren't found will still remain once the loop ends. `remaining_a` and `remaining_b` are then compared at the end with the laborious check.
        local size_a, remaining_a = 0
        for k, v_a in pairs(a) do
            local v_b = remaining_b[k]
            -- If `k` isn't in `remaining_b`, `a` and `b` can't be equivalent unless it's a table.
            if v_b == nil then
                if type(k) ~= "table" then
                    memo_a[b], memo_b[a] = false, false
                    return false
                    -- Otherwise, add the `k`/`v_a` pair to `remaining_a` for the laborious check.
                elseif not remaining_a then
                    remaining_a = {}
                end
                remaining_a[k], size_a = v_a, size_a + 1
                -- Otherwise, if `k` exists in `a` and `remaining_b`, `v_a` and `v_b` must be equivalent for there to be a match.
            elseif is_equivalent(v_a, v_b, seen, include_mt) then
                remaining_b[k], size_b = nil, size_b - 1
            else
                memo_a[b], memo_b[a] = false, false
                return false
            end
        end
        -- Must be the same number of remaining keys in each table.
        if size_a ~= size_b then
            memo_a[b], memo_b[a] = false, false
            return false
            -- If the size is 0, there's nothing left to check.
        elseif size_a == 0 then
            return true
        end
        -- Laborious check: since it's not possible to use table lookups to check if two keys are equivalent when they're tables, check each key/value pair in `remaining_a` against every key/value pair in `remaining_b` until a match is found, removing the matching key/value pair from `remaining_b` each time, to ensure one-to-one equivalence.
        for k_a, v_a in next, remaining_a do
            local success
            for k_b, v_b in next, remaining_b do
                -- Keys/value pairs must be equivalent in order to match.
                if (-- More efficient to compare the values first, as they might not be tables.
                        is_equivalent(v_a, v_b, seen, include_mt) and
                                is_equivalent(k_a, k_b, seen, include_mt)
                ) then
                    -- Remove matched key from `remaining_b`, and break the inner loop.
                    success, remaining_b[k_b] = true, nil
                    break
                end
            end
            -- Fail if `remaining_b` runs out of keys, as the `k_a`/`v_a` pair still hasn't matched.
            if not success then
                memo_a[b], memo_b[a] = false, false
                return false
            end
        end
        -- If every key/value pair in `remaining_a` matched with one in `remaining_b`, `a` and `b` must be equivalent. Note that `remaining_b` will now be empty, since the laborious check only starts if `remaining_a` and `remaining_b` are the same size.
        return true
    end

    --[==[
    Recursively compare two values that may be tables, and returns true if all key-value pairs are structurally equivalent. Note that this handles arbitrary nesting of subtables (including recursive nesting) to any depth, for keys as well as values.

    If `include_mt` is true, then metatables are also compared.]==]
    function export.deepEquals(a, b, include_mt)
        return is_equivalent(a, b, {}, include_mt)
    end
    deep_equals = export.deepEquals
end

do
    local function get_nested(t, k, ...)
        if t == nil then
            return nil
        elseif select("#", ...) ~= 0 then
            return get_nested(t[k], ...)
        end
        return t[k]
    end

    --[==[
    Given a table and an arbitrary number of keys, will successively access subtables using each key in turn, returning the value at the final key. For example, if {t} is { {[1] = {[2] = {[3] = "foo"}}}}, {export.getNested(t, 1, 2, 3)} will return {"foo"}.

    If no subtable exists for a given key value, returns nil, but will throw an error if a non-table is found at an intermediary key.]==]
    function export.getNested(t, ...)
        if t == nil or select("#", ...) == 0 then
            error("Must provide a table and at least one key.")
        end
        return get_nested(t, ...)
    end
end

do
    local function set_nested(t, v, k, ...)
        if select("#", ...) == 0 then
            t[k] = v
            return
        end
        local next_t = t[k]
        if next_t == nil then
            -- If there's no next table while setting nil, there's nothing more to do.
            if v == nil then
                return
            end
            next_t = {}
            t[k] = next_t
        end
        return set_nested(next_t, v, ...)
    end

    --[==[
    Given a table, value and an arbitrary number of keys, will successively access subtables using each key in turn, and sets the value at the final key. For example, if {t} is { {} }, {export.setNested(t, "foo", 1, 2, 3)} will modify {t} to { {[1] = {[2] = {[3] = "foo"} } } }.

    If no subtable exists for a given key value, one will be created, but the function will throw an error if a non-table value is found at an intermediary key.

    Note: the parameter order (table, value, keys) differs from functions like rawset, because the number of keys can be arbitrary. This is to avoid situations where an additional argument must be appended to arbitrary lists of variables, which can be awkward and error-prone: for example, when handling variable arguments ({{lua|...}}) or function return values.]==]
    function export.setNested(t, ...)
        if t == nil or select("#", ...) < 2 then
            error("Must provide a table and at least one key.")
        end
        return set_nested(t, ...)
    end
end

do
    local function plain_equals(a, b)
        return a == b
    end

    -- `get_2_options` and `get_4_options` extract the options keys before any processing occurs, so that any modifications to `options` during processing (e.g. by a comparison function) will not affect the current call. This allows the same `options` table to be used with different values for recursive calls, which is more efficient than creating a new table for each call.

    -- `contains` and `insert_if_not` are both called by other functions, so the main work is done by local functions which take the extracted options as separate arguments, which avoids the need to access the `options` again at any point.

    local function get_2_options(options)
        if options == nil then
            return deep_equals
        end
        local comp_func = options.comparison
        if comp_func == nil then
            comp_func = deep_equals
        elseif comp_func == "==" then
            comp_func = plain_equals
        end
        return comp_func, options.key
    end

    local function get_4_options(options)
        local pos, combine_func
        if options ~= nil then
            if type(options) == "number" then
                pos, options = options, nil
            else
                pos, combine_func = options.pos, options.combine
            end
        end
        return pos, combine_func, get_2_options(options)
    end

    local function contains(list, x, comp_func, key_func)
        if key_func ~= nil then
            x = key_func(x)
        end
        local i = 0
        while true do
            i = i + 1
            local v = list[i]
            if v == nil then
                return false
            elseif key_func ~= nil then
                v = key_func(v)
            end
            if comp_func(v, x) then
                return i
            end
        end
    end

    --[==[
    Given a list and a value to be found, returns the value's index if the value is in the array portion of the list, or false if not found.

    `options` is an optional table of additional options to control the behavior of the operation. The following options are recognized:
    * `comparison`: Function of two arguments to compare whether `item` is equal to an existing item in `list`. If unspecified, items are considered equal if either the standard equality operator {==} or {deepEquals} return {true}. As a special case, if the string value {"=="} is specified, then the standard equality operator alone will be used.
    * `key`: Function of one argument to return a comparison key, which will be used with the comparison function. The key function is applied to both `item` and the existing item in `list` to compare against, and the comparison is done against the results.]==]
    function export.contains(list, x, options)
        return contains(list, x, get_2_options(options))
    end

    --[==[
    Given a table and a value to be found, returns the value's key if the value is in the table. Comparison is by value, using `deepEquals`.

    `options` is an optional table of additional options to control the behavior of the operation. The available options are the same as those for {contains}.

    Note: if multiple keys have the specified value, this function returns the first key found; it is not possible to reliably predict which key this will be.]==]
    function export.keyFor(t, x, options)
        local comp_func, key_func = get_2_options(options)
        if key_func ~= nil then
            x = key_func(x)
        end
        for k, v in pairs(t) do
            if key_func ~= nil then
                v = key_func(v)
            end
            if comp_func(v, x) then
                return k
            end
        end
    end

    local function insert_if_not(list, new_item, pos, combine_func, comp_func, key_func)
        local i = contains(list, new_item, comp_func, key_func)
        if i then
            if combine_func ~= nil then
                local newval = combine_func(list[i], new_item, i)
                if newval ~= nil then
                    list[i] = newval
                end
            end
            return false
        elseif pos == nil then
            insert(list, new_item)
        else
            insert(list, pos, new_item)
        end
        return true
    end

    --[==[
    Given a `list` and a `new_item` to be inserted, append the value to the end of the list if not already present (or insert at an arbitrary position, if `options.pos` is given; see below). Comparison is by value, using {deepEquals}.

    `options` is an optional table of additional options to control the behavior of the operation. The following options are recognized:
    * `pos`: Position at which insertion happens (i.e. before the existing item at position `pos`).
    * `comparison`: Function of two arguments to compare whether `item` is equal to an existing item in `list`. If unspecified, items are considered equal if either the standard equality operator {==} or {deepEquals} return {true}. As a special case, if the string value {"=="} is specified, then the standard equality operator alone will be used.
    * `key`: Function of one argument to return a comparison key, which will be used with the comparison function. The key function is applied to both `item` and the existing item in `list` to compare against, and the comparison is done against the results. This is useful when inserting a complex structure into an existing list while avoiding duplicates.
    * `combine`: Function of three arguments (the existing item, the new item and the position, respectively) to combine an existing item with `new_item`, when `new_item` is found in `list`. If unspecified, the existing item is left alone.

    Returns {false} if an entry is already found, or {true} if inserted. By default, {false} indicates that no change was made to the input table, but if the `combine` is used, {false} indicates that the pre-existing entry was modified.

    For compatibility, `pos` can be specified directly as the third argument in place of `options`, but this is not recommended for new code.

    NOTE: This function is O(N) in the size of the existing list. If you use this function in a loop to insert several items, you will get O(M*(M+N)) behavior, effectively O((M+N)^2). Thus it is not recommended to use this unless you are sure the total number of items will be small. (An alternative for large lists is to insert all the items without checking for duplicates, and use {removeDuplicates()} at the end.)]==]
    function export.insertIfNot(list, new_item, options)
        return insert_if_not(list, new_item, get_4_options(options))
    end

    --[==[
    Extend an existing list by a new list, using {export.insertIfNot()} for each item.

    `options` is an optional table of additional options to control the behavior of the operation. The following options are recognized:
    * `pos`: As in {insertIfNot()}.
    * `comparison`: As in {insertIfNot()}.
    * `key`: As in {insertIfNot()}.
    * `combine`: As in {insertIfNot()}.

    Unlike {export.insertIfNot()}, this function does not return a boolean indicating whether any items were inserted.]==]
    function export.extendIfNot(t, new_items, options)
        local i, pos, combine_func, comp_func, key_func = 0, get_4_options(options)
        while true do
            i = i + 1
            local item = new_items[i]
            if item == nil then
                return t
            end
            local success = insert_if_not(t, item, pos, combine_func, comp_func, key_func)
            if success then
                if pos ~= nil then
                    pos = pos + 1
                end
            end
        end
    end
end

do
    local types
    local function get_types()
        types, get_types = invert {
            "number",
            "boolean",
            "string",
            "table",
            "function",
            "thread",
            "userdata"
        }, nil
        return types
    end

    local function less_than(key1, key2)
        return key1 < key2
    end

    -- The default sorting function used in export.keysToList if `keySort` is not given.
    local function default_compare(key1, key2)
        local type1, type2 = type(key1), type(key2)
        if type1 ~= type2 then
            -- If the types are different, sort numbers first, functions last, and all other types alphabetically.
            return (types or get_types())[type1] < types[type2]
            -- `string_sort` fixes a bug in < which causes all codepoints above U+FFFF to be treated as equal.
        elseif type1 == "string" then
            return string_sort(key1, key2)
        elseif type1 == "number" then
            return key1 < key2
            -- Attempt to compare tables, in case there's a metamethod.
        elseif type1 == "table" then
            local success, result = pcall(less_than, key1, key2)
            if success then
                return result
            end
            -- Sort true before false.
        elseif type1 == "boolean" then
            return key1
        end
        return false
    end

    --[==[
    Returns a list of the keys in a table, sorted using either the default `table.sort` function or a custom `keySort` function.

    If there are only numerical keys, `export.numKeys` is probably faster.]==]
    function export.keysToList(t, keySort)
        local list, i = {}, 0
        for key in pairs(t) do
            i = i + 1
            list[i] = key
        end
        -- Use specified sort function, or otherwise `default_compare`.
        sort(list, keySort or default_compare)
        return list
    end
    keys_to_list = export.keysToList
end

--[==[
Iterates through a table, with the keys sorted using the keysToList function.

If there are only numerical keys, `export.sparseIpairs` is probably faster.]==]
function export.sortedPairs(t, keySort)
    local list, i = keys_to_list(t, keySort), 0
    return function()
        i = i + 1
        local k = list[i]
        if k ~= nil then
            return k, t[k]
        end
    end
end

--[==[
Iterates through a table using `ipairs` in reverse.

`__ipairs` metamethods will be used, including those which return arbitrary (i.e. non-array) keys, but note that this function assumes that the first return value is a key which can be used to retrieve a value from the input table via a table lookup. As such, `__ipairs` metamethods for which this assumption is not true will not work correctly.

If the value `nil` is encountered early (e.g. because the table has been modified), the loop will terminate early.]==]
function export.reverseIpairs(t)
    -- `__ipairs` metamethods can return arbitrary keys, so compile a list.
    local keys, i = {}, 0
    for k in ipairs(t) do
        i = i + 1
        keys[i] = k
    end
    return function()
        if i == 0 then
            return nil
        end
        local k = keys[i]
        -- Retrieve `v` from the table. These aren't stored during the initial ipairs loop, so that they can be modified during the loop.
        local v = t[k]
        -- Return if not an early nil.
        if v ~= nil then
            i = i - 1
            return k, v
        end
    end
end

local function getIteratorValues(i, j, step, t_len)
    i, j = i and signed_index(t_len, i), j and signed_index(t_len, j)
    if step == nil then
        i, j = i or 1, j or t_len
        return i, j, j < i and -1 or 1
    elseif step == 0 or not is_integer(step) then
        error("step must be a non-zero integer")
    elseif step < 0 then
        return i or t_len, j or 1, step
    end
    return i or 1, j or t_len, step
end

--[==[
Given an array `list` and function `func`, iterate through the array applying {func(r, k, v)}, and returning the result,
where `r` is the value calculated so far, `k` is an index, and `v` is the value at index `k`. For example,
{reduce(array, function(a, _, v) return a + v end)} will return the sum of `array`.

Optional arguments:
* `i`: start index; negative values count from the end of the array
* `j`: end index; negative values count from the end of the array
* `step`: step increment
These must be non-zero integers. The function will determine where to iterate from, whether to iterate forwards or
backwards and by how much, based on these inputs (see examples below for default behaviours).

Examples:
# No values for i, j or step results in forward iteration from the start to the end in steps of 1 (the default).
# step=-1 results in backward iteration from the end to the start in steps of 1.
# i=7, j=3 results in backward iteration from indices 7 to 3 in steps of 1 (i.e. step=-1).
# j=-3 results in forward iteration from the start to the 3rd last index.
# j=-3, step=-1 results in backward iteration from the end to the 3rd last index.]==]
function export.reduce(t, func, i, j, step)
    i, j, step = getIteratorValues(i, j, step, table_len(t))
    local ret = t[i]
    for k = i + step, j, step do
        ret = func(ret, k, t[k])
    end
    return ret
end

do
    local function replace(t, func, i, j, step, generate)
        local t_len = table_len(t)
        -- Normalized i, j and step, based on the inputs.
        local norm_i, norm_j, norm_step = getIteratorValues(i, j, step, t_len)
        if norm_step > 0 then
            i, j, step = 1, t_len, 1
        else
            i, j, step = t_len, 1, -1
        end
        -- "Signed" variables are multiplied by -1 if `step` is negative.
        local t_new, signed_i, signed_j = generate and {} or t, norm_i * step, norm_j * step
        for k = i, j, step do
            -- Replace the values iff they're within the i to j range and `step` wouldn't skip the key.
            -- Note: i > j if `step` is positive; i < j if `step` is negative. Otherwise, the range is empty.
            local signed_k = k * step
            if signed_k >= signed_i and signed_k <= signed_j and (k - norm_i) % norm_step == 0 then
                t_new[k] = func(k, t[k])
                -- Otherwise, add the existing value if `generate` is set.
            elseif generate then
                t_new[k] = t[k]
            end
        end
        return t_new
    end

    --[==[
    Given an array `list` and function `func`, iterate through the array applying {func(k, v)} (where `k` is an index, and
    `v` is the value at index `k`), replacing the relevant values with the result. For example,
    {apply(array, function(_, v) return 2 * v end)} will double each member of the array.

    Optional arguments:
    * `i`: start index; negative values count from the end of the array
    * `j`: end index; negative values count from the end of the array
    * `step`: step increment
    These must be non-zero integers. The function will determine where to iterate from, whether to iterate forwards or
    backwards and by how much, based on these inputs (see examples below for default behaviours).

    Examples:
    # No values for i, j or step results in forward iteration from the start to the end in steps of 1 (the default).
    # step=-1 results in backward iteration from the end to the start in steps of 1.
    # i=7, j=3 results in backward iteration from indices 7 to 3 in steps of 1 (i.e. step=-1).
    # j=-3 results in forward iteration from the start to the 3rd last index.
    # j=-3, step=-1 results in backward iteration from the end to the 3rd last index.]==]
    function export.apply(t, func, i, j, step)
        return replace(t, func, i, j, step, false)
    end

    --[==[
    Given an array `list` and function `func`, iterate through the array applying {func(k, v)} (where `k` is an index, and
    `v` is the value at index `k`), and return a shallow copy of the original array with the relevant values replaced. For example,
    {generate(array, function(_, v) return 2 * v end)} will return a new array in which each value has been doubled.

    Optional arguments:
    * `i`: start index; negative values count from the end of the array
    * `j`: end index; negative values count from the end of the array
    * `step`: step increment
    These must be non-zero integers. The function will determine where to iterate from, whether to iterate forwards or
    backwards and by how much, based on these inputs (see examples below for default behaviours).

    Examples:
    # No values for i, j or step results in forward iteration from the start to the end in steps of 1 (the default).
    # step=-1 results in backward iteration from the end to the start in steps of 1.
    # i=7, j=3 results in backward iteration from indices 7 to 3 in steps of 1 (i.e. step=-1).
    # j=-3 results in forward iteration from the start to the 3rd last index.
    # j=-3, step=-1 results in backward iteration from the end to the 3rd last index.]==]
    function export.generate(t, func, i, j, step)
        return replace(t, func, i, j, step, true)
    end
end

--[==[
Given an array `list` and function `func`, iterate through the array applying {func(k, v)} (where `k` is an index, and
`v` is the value at index `k`), and returning whether the function is true for all iterations.

Optional arguments:
* `i`: start index; negative values count from the end of the array
* `j`: end index; negative values count from the end of the array
* `step`: step increment
These must be non-zero integers. The function will determine where to iterate from, whether to iterate forwards or
backwards and by how much, based on these inputs (see examples below for default behaviours).

Examples:
# No values for i, j or step results in forward iteration from the start to the end in steps of 1 (the default).
# step=-1 results in backward iteration from the end to the start in steps of 1.
# i=7, j=3 results in backward iteration from indices 7 to 3 in steps of 1 (i.e. step=-1).
# j=-3 results in forward iteration from the start to the 3rd last index.
# j=-3, step=-1 results in backward iteration from the end to the 3rd last index.]==]
function export.all(t, func, i, j, step)
    i, j, step = getIteratorValues(i, j, step, table_len(t))
    for k = i, j, step do
        if not func(k, t[k]) then
            return false
        end
    end
    return true
end

--[==[
Given an array `list` and function `func`, iterate through the array applying {func(k, v)} (where `k` is an index, and
`v` is the value at index `k`), and returning whether the function is true for at least one iteration.

Optional arguments:
* `i`: start index; negative values count from the end of the array
* `j`: end index; negative values count from the end of the array
* `step`: step increment
These must be non-zero integers. The function will determine where to iterate from, whether to iterate forwards or
backwards and by how much, based on these inputs (see examples below for default behaviours).

Examples:
# No values for i, j or step results in forward iteration from the start to the end in steps of 1 (the default).
# step=-1 results in backward iteration from the end to the start in steps of 1.
# i=7, j=3 results in backward iteration from indices 7 to 3 in steps of 1 (i.e. step=-1).
# j=-3 results in forward iteration from the start to the 3rd last index.
# j=-3, step=-1 results in backward iteration from the end to the 3rd last index.]==]
function export.any(t, func, i, j, step)
    i, j, step = getIteratorValues(i, j, step, table_len(t))
    for k = i, j, step do
        if not not (func(k, t[k])) then
            return true
        end
    end
    return false
end

--[==[
Joins an array with serial comma and serial conjunction, normally {"and"}. An improvement on {mw.text.listToText},
which doesn't properly handle serial commas.

Options:
* `conj`: Conjunction to use; defaults to {"and"}.
* `punc`: Punctuation to use; default to {","}.
* `dontTag`: Don't tag the serial comma and serial {"and"}. For error messages, in which HTML cannot be used.
* `dump`: Each item will be serialized with {mw.dumpObject}. For warnings and error messages.]==]
function export.serialCommaJoin(seq, options)
    -- If the `dump` option is set, determine the table length as part of the
    -- dump loop, instead of calling `table_len` separately.
    local length
    if options and options.dump then
        local i, item = 1, seq[1]
        if item ~= nil then
            local dumped = {}
            repeat
                dumped[i] = dump(item)
                i = i + 1
                item = seq[i]
            until item == nil
            seq = dumped
        end
        length = i - 1
    else
        length = table_len(seq)
    end

    if length == 0 then
        return ""
    elseif length == 1 then
        return seq[1]
    end

    local conj = options and options.conj
    if conj == nil then
        conj = "and"
    end

    if length == 2 then
        return seq[1] .. " " .. conj .. " " .. seq[2]
    end

    local punc, dont_tag
    if options then
        punc = options.punc
        if punc == nil then
            punc = ","
        end
        dont_tag = options.dontTag
    else
        punc = ","
    end

    local comma
    if dont_tag then
        comma = "" -- since by default the serial comma doesn't display, when we can't tag we shouldn't display it.
        conj = " " .. conj .. " "
    else
        comma = "<span class=\"serial-comma\">" .. punc .. "</span>"
        conj = "<span class=\"serial-and\"> " .. conj .. "</span> "
    end

    return concat(seq, punc .. " ", 1, length - 1) .. comma .. conj .. seq[length]
end

--[==[
A function which works like `table.concat`, but respects any `__index` metamethod. This is useful for data loaded via `mw.loadData`.]==]
function export.concat(t, sep, i, j)
    local list, k = {}, 0
    while true do
        k = k + 1
        local v = t[k]
        if v == nil then
            return concat(list, sep, i, j)
        end
        list[k] = v
    end
end

--[==[
Concatenate all values in the table that are indexed by a number, in order.
* {sparseConcat{ a, nil, c, d }} => {"acd"}
* {sparseConcat{ nil, b, c, d }} => {"bcd"}]==]
function export.sparseConcat(t, sep, i, j)
    local list, k = {}, 0
    for _, v in sparse_ipairs(t) do
        k = k + 1
        list[k] = v
    end
    return concat(list, sep, i, j)
end

--[==[
Values of numeric keys in array portion of table are reversed: { { "a", "b", "c" }} -> { { "c", "b", "a" }}]==]
function export.reverse(t)
    local list, t_len = {}, table_len(t)
    for i = t_len, 1, -1 do
        list[t_len - i + 1] = t[i]
    end
    return list
end
table_reverse = export.reverse

--[==[
Invert a table. For example, {invert({ "a", "b", "c" })} -> { { a = 1, b = 2, c = 3 }}]==]
function export.invert(t)
    local map = {}
    for k, v in pairs(t) do
        map[v] = k
    end
    return map
end
invert = export.invert

do
    local function flatten(t, list, seen, n)
        seen[t] = true
        local i = 0
        while true do
            i = i + 1
            local v = t[i]
            if v == nil then
                return n
            elseif type(v) == "table" then
                if seen[v] then
                    error("loop in input list")
                end
                n = flatten(v, list, seen, n)
            else
                n = n + 1
                list[n] = v
            end
        end
    end

    --[==[
    Given a list, which may contain sublists, flatten it into a single list. For example, {flatten({ "a", { "b", "c" }, "d" })} ->
    { { "a", "b", "c", "d" }}]==]
    function export.flatten(t)
        local list = {}
        flatten(t, list, {}, 0)
        return list
    end
end

--[==[
Convert `list` (a table with a list of values) into a set (a table where those values are keys instead). This is a useful way to create a fast lookup table, since looking up a table key is much, much faster than iterating over the whole list to see if it contains a given value.

By default, each item is given the value true. If the optional parameter `value` is a function or functor, then it is called as an iterator, with the list index as the first argument, the item as the second (which will be used as the key), plus any additional arguments passed to {listToSet}; the returned value is used as the value for that list item. If `value` is anything else, then it is used as the fixed value for every item.]==]
function export.listToSet(list, value, ...)
    local set, i, callable = {}, 0
    if value == nil then
        value = true
    else
        callable = is_callable(value)
    end
    while true do
        i = i + 1
        local item = list[i]
        if item == nil then
            return set
        end
        if callable then
            set[item] = value(i, item, ...)
        else
            set[item] = value
        end
    end
end
list_to_set = export.listToSet

--[==[
Returns true if all keys in the table are consecutive integers starting from 1.]==]
function export.isArray(t)
    local i = 0
    for _ in pairs(t) do
        i = i + 1
        if t[i] == nil then
            return false
        end
    end
    return true
end

--[==[
Returns true if the first list, taken as a set, is a subset of the second list, taken as a set.]==]
function export.isSubsetList(t1, t2)
    t2 = list_to_set(t2)
    local i = 0
    while true do
        i = i + 1
        local v = t1[i]
        if v == nil then
            return true
        elseif t2[v] == nil then
            return false
        end
    end
end

--[==[
Returns true if the first map, taken as a set, is a subset of the second map, taken as a set.]==]
function export.isSubsetMap(t1, t2)
    for k in pairs(t1) do
        if t2[k] == nil then
            return false
        end
    end
    return true
end

--[==[
Add a list of aliases for a given key to a table. The aliases must be given as a table.]==]
function export.alias(t, k, aliases)
    for _, alias in pairs(aliases) do
        t[alias] = t[k]
    end
end

return export