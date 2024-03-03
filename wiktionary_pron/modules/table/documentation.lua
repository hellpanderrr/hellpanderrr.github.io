This module provides functions for dealing with Lua tables. All of them, except for two helper functions, take a table as their first argument.

Some functions are available as methods in the arrays created by [[Module:array]].

Functions by what they do:
* Create a new table:
** {{#invoke:string|gsub|shallowClone, shallowcopy, deepcopy, removeDuplicates, numKeys, affixNums, numData, compressSparseArray, keysToList, reverse, invert, listToSet|%a+|3=<code class="n">%1</code>}}
* Create an array:
** {{#invoke:string|gsub|removeDuplicates, numKeys, affixNums, compressSparseArray, keysToList, reverse|%a+|3=<code class="n">%1</code>}}
* Return information about the table:
** {{#invoke:string|gsub|size, length, contains, keyFor, isArray, deepEquals|%a+|3=<code class="n">%1</code>}}
* Treat the table as an array (that is, operate on the values in the array portion of the table: values indexed by consecutive integers starting at {{code|lua|1}}):
** {{#invoke:string|gsub|removeDuplicates, length, contains, serialCommaJoin, reverseIpairs, reverse, invert, listToSet, isArray|%a+|3=<code class="n">%1</code>}}
* Treat a table as a sparse array (that is, operate on values indexed by non-consecutive integers):
** {{#invoke:string|gsub|numKeys, maxIndex, compressSparseArray, sparseConcat, sparseIpairs|%a+|3=<code class="n">%1</code>}}
* Generate an iterator:
** {{#invoke:string|gsub|sparseIpairs, sortedPairs, reverseIpairs|%a+|3=<code class="n">%1</code>}}
* Other:
** {{#invoke:string|gsub|sparseConcat, serialCommaJoin, reverseConcat|%a+|3=<code class="n">%1</code>}}

The original version was a copy of {{w|Module:TableTools}} on Wikipedia via [[c:Module:TableTools|Module:TableTools]] on Commons, but new functions have been added since then.

<includeonly>
[[Category:Lua metamodules]]
</includeonly>