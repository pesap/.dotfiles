; Arco KDL highlights (standalone — cannot inherit kdl because `node` was overridden)

; --- KDL base highlights (adapted for arco_kdl tree structure) ---

(identifier) @variable

(kdl_node
  (identifier) @tag)

(type
  (identifier) @type)

(prop
  (identifier) @property)

["=" "+" "-"] @operator

(string) @string
(escape) @string.escape
(number) @number
(number (decimal) @number.float)
(number (exponent) @number.float)
(boolean) @boolean
"null" @constant.builtin

["{" "}"] @punctuation.bracket
["(" ")"] @punctuation.bracket
";" @punctuation.delimiter

[(single_line_comment) (multi_line_comment)] @comment @spell

(kdl_node
  (node_comment)
  (#set! priority 105)) @comment

(kdl_node
  (node_field
    (node_field_comment)
    (#set! priority 105)) @comment)

(node_children
  (node_children_comment)
  (#set! priority 105)) @comment

; --- Arco-specific highlights ---

; Math keyword nodes
(arco_pure_math_node
  name: _ @keyword)

(arco_constraint_node
  name: _ @keyword)

; Bare identifiers used as values
(bare_identifier) @variable

; Math text body — highlighted via Lua (after/plugin/arco_kdl.lua)
(arco_math_text) @string.special
