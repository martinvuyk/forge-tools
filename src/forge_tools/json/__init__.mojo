"""Python-like JSON package.

### JSON specification:

(unescaped values are used to indicate sets)

Collection types have commas between content. Trailing commas are
dissallowed.

| Pseudotype    | Pseudocode set description |
|:--------------|:---------------------------|
|whitespace     | { SPACE, \\n, \\r, \\t }
|value          | { `Optional[whitespace]`, `Variant[string, number, object\
, array, true, false, null]`, `Optional[whitespace]` } |
|key_value      | { `string`, `Optional[whitespace]` , `:`, `value` } |
|object_content | { `Optional[whitespace]`, `Optional[key_value]` } |
|object         | { `{`, `Optional[object_content]`, `}` } |
|array_content  | { `Optional[whitespace]`, `value`,\
`Optional[whitespace]` } |
|array          | { `[`, `Optional[array_content]`, `]` } |
|string         | { `"`, `Optional[Variant[escaped_values, values]]`, `"` }|
|escaped_values | { `\\`, `Variant['"', '\\', '/', backspace, '\\f',\
'\\n', '\\r', '\\t', 'uHHHH']` } * |
|number         | { `Variant[int, float]` } |
|int            | { `Optional['-']`, `Optional['0']`, `Optional[digits]` } |
|float          | { `Optional['-']`, `Optional['0']`, `Optional[digits]`,\
Optional['.'], `Optional[digits]`, `Optional[ [ Variant['E', 'e'],\
Optional[Variant['+', '-']], digit, Optional[digits] ] ]` } |

*: note that `\\ANYTHING` is a single value, they are double only in
docstrings to escape them. 'uHHHH' is meant to be a u followed by 4
hexadecimal byte encoded values from unicode.
"""

from .reader import Reader
