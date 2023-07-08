(use /cozo)
(use /cozo/api)

(def tests
  [[~(? [] <- [[1 2 3]])
    `?[] <- [[1, 2, 3]]`]

   [~(? [] <- [[1 2 3] ["a" "b" "c"]])
    `?[] <- [[1, 2, 3], ["a", "b", "c"]]`]

   [~(res [a b c] <= (csv-reader :types ["Int" "Float?"]
                                 :url "https://example.com"
                                 :has-headers true))
    `res[a, b, c] <~ CsvReader(url: "https://example.com", types: ["Int", "Float?"], has_headers: true)`]

   [~(? [entity contained] :=
        res [idx fr_i to_i typ]
        (eq typ "contains")
        *idx2code [fr_i entity]
        *idx2code [to_i contained])
    `?[entity, contained] := res[idx, fr_i, to_i, typ], eq(typ, "contains"), *idx2code[fr_i, entity], *idx2code[to_i, contained]`]

   [~(:replace contain {entity :string contained :string})
    `:replace contain {
entity: String,
contained: String}`]

   [~(:replace contain [{a :string b :string} {c :float? d :any?}])
    `:replace contain {
a: String,
b: String
=>
c: Float?,
d: Any?
}`]

   [~(::remove idx2code)
    "::remove idx2code"]

   [~(? [(count-unique to)] := *route {:fr "FRA" :to ?})
    `?[count_unique(to)] := *route{to, fr: "FRA"}`]

   [~(:limit 2)
    `:limit 2`]

   [~(? [a] := a = (length b))
    `?[a] := a = length(b)`]

   [~(? [] := (shortest-path-dijkstra a [b c] d [e f]))
    `?[] := ShortestPathDijkstra(a[b, c], d[e, f])`]

   [~(? [] := a {:to ?} path [b c])
    `?[] := a{to}, path[b, c]`]

   [~(? [to (shortest d)] := a {:to ?} path [b c])
    `?[to, shortest(d)] := a{to}, path[b, c]`]

   [~(:rm rel)
    `:rm rel`]])

(each [query expected] tests
  (def queryd (to-cozo query))
  (if (= queryd expected)
    (print "OK")
    (printf "Expected %s\nActual   %s" expected queryd)))
