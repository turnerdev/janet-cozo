(import spork/json)

(defn- table-from-symbols
  [symbols]
  (table ;(mapcat |(tuple $ (string $)) symbols)))

(def cozo-dt
  {:string "String"
   :string? "String?"
   :float "Float"
   :float? "Float?"
   :int "Int"
   :int? "Int?"
   :any "Any"
   :any? "Any?"})

(def cozo-rule
  {'<- "<-"
   '<= "<~"
   ':= ":="})

(def cozo-ops
  {:replace :replace
   :create :create})

(def cozo-funcs
  (merge
    (table-from-symbols
      ['and 'or 'eq 'shortest 'append 'length])
    {'csv-reader "CsvReader"
     'shortest-path-dijkstra "ShortestPathDijkstra"
     'count-unique "count_unique"}))

(defn- list?
  [value]
  (or (tuple? value) (array? value)))

(defn- to-cozo-fields
  [s]
  (string/join
    (map (fn [[field dt]]
           (string/format "%s: %s" field (cozo-dt dt)))
         (pairs s)) ",\n"))

(defn- stored-op
  [op & args]
  (match args
    ([table fields] (dictionary? fields)) (stored-op op table [fields])
    [table [keys fields]] (string/format ":%s %s {\n%s\n=>\n%s\n}" op table (to-cozo-fields keys) (to-cozo-fields fields))
    [table [fields]] (string/format ":%s %s {\n%s}" op table (to-cozo-fields fields))
    ([tables] (dictionary? tables)) (map |(stored-op op ;$) (pairs tables))))

(defn to-cozo
  [stmt &opt ctx]
  (default ctx 0)
  (def to-cozo |(to-cozo $ (+ 1 ctx)))
  (def dbg (fn [& args]))

  (let [fmt string/format
        csv |(string/join $ ", ")
        spaced |(string/join $ " ")
        to-cozos (fn [a] (map |(to-cozo [$]) a))
        delim |(fmt "%s%s" (if (empty? $) "" ", ") (to-cozo $))]

    (defn get-kwargs
      [args]
      (var res nil)
      (when (even? (length args))
        (def kwargs (table ;args))
        (when (every? (map keyword? (keys kwargs)))
          (set res
               (csv
                 (map (fn [kv]
                        (match kv
                          [k (@ '?)] (string/replace "-" "_" k)
                          [k v] (fmt "%s: %s" (string/replace "-" "_" k) (to-cozo [v]))))
                      (pairs kwargs))))))
      res)

    (match stmt
      [(@ '.) & next]
      (fmt ", %s" (to-cozo next))

      # Handle tuple body
      ([rulename head rule & xs] (cozo-rule rule) (list? (get-in xs [0 0])))
      (do
        (dbg "R1")
        (fmt "%s %s %s" (to-cozo [rulename head]) (to-cozo rule) (to-cozo xs)))

      ([rulename head rule & xs] (cozo-rule rule))
      (do
        (dbg "R2 %p %p %p %p" rulename head rule xs)
        (fmt "%s %s %s" (to-cozo [rulename head]) (to-cozo rule) (to-cozo xs)))

      ([rulename head & next] (and (symbol? rulename) (list? head)))
      (do
        (dbg "R3 %p %p %p" rulename head next)
        (if (cozo-funcs (first head)) # is this really a list, or function application
          (fmt "%s, %s%s" rulename (to-cozo head) (delim next))
          (fmt "%s[%s]%s" rulename (to-cozo head) (delim next))))

      ([rulename head & next] (and (symbol? rulename) (dictionary? head)))
      (do
        (dbg "R4")
        (fmt "%s{%s}%s" rulename (to-cozo head) (delim next)))

      # func application with args e.g. (f 1 2)
      ([[func & xs] & next] (cozo-funcs func))
      (do
        (dbg "FUN f: %p xs: %p nx: %p" func xs next)
        (def kwargs (get-kwargs xs))
        (fmt "%s(%s)%s%s"
             (cozo-funcs func)
             (or kwargs (to-cozo xs))
             (if (> (length next) 0) ", " "")
             (to-cozo next)))

      # func application with args
      [a '= b]
      (fmt "%s = %s" ;(to-cozos [a b]))

      ([op & next] (cozo-ops op))
      (stored-op op ;next)

      ([kw & next] (and (keyword? kw) (= ":" (string/slice kw 0 1))))
      (fmt ":%s %s" kw (spaced (to-cozos next)))

      ([kw & next] (keyword? kw))
      (fmt ":%s %s" kw (spaced (to-cozos next)))

      ([x & xs] (cozo-funcs x))
      (do
        (dbg "FUN")
        (fmt "%s(%s)" (cozo-funcs x) (csv (map to-cozo xs))))

      # lists
      ([val & next] (list? val))
      (do
        (dbg "LIST %p" val)
        (fmt "[%s]%s" (to-cozo val) (delim next)))

      # if no other composites match, delimit next value
      [val & next]
      (fmt "%s%s" (to-cozo val) (delim next))

      # Atoms
      (a (and (list? a) (empty? a)))
      ""

      (val (cozo-rule val))
      (cozo-rule val)

      (val (boolean? val))
      (string val)

      (val (symbol? val))
      (string val)

      (val (number? val))
      (fmt "%s" (string val))

      (val (string? val))
      (fmt "%p" val)

      (val (keyword? val))
      (or (cozo-dt val) (string/replace "-" "_" val))

      (val (dictionary? val))
      (do
        (dbg "DICT %p" val)
        (get-kwargs (kvs val)))

      _ (do
          (printf "Bad statement: %p" stmt)))))

(defn make-result
  # convert cozo response to a more janet-friendly structure
  [result]
  (def r @{})
  (eachp [k v] (json/decode result)
    (put r (keyword k) v))
  (table/to-struct r))

(defn make-query
  # detect query format, accept cozoscript strings or quasiquoted expressions
  [& rules]
  (match rules
    ([[a]] (or (symbol? a) (keyword? a))) (string/join (map to-cozo rules) "\n")
    ([a] (string? a)) (string/join rules "\n")))
