(import /src :as cozo)

(def nodes-url "https://raw.githubusercontent.com/cozodb/cozo/dev/cozo-core/tests/air-routes-latest-nodes.csv")
(def edges-url "https://raw.githubusercontent.com/cozodb/cozo/dev/cozo-core/tests/air-routes-latest-edges.csv")

(def schema
  {"airport" [{"code" :string}
              {"icao" :string
               "desc" :string
               "region" :string
               "runways" :int
               "longest" :float
               "elev" :float
               "country" :string
               "city" :string
               "lat" :float
               "lon" :float}]
   "country" [{"code" :string}
              {"desc" :string}]
   "continent" [{"code" :string}
                {"desc" :string}]
   "contain" [{"entity" :string
               "contained" :string}]
   "route" [{"fr" :string
             "to" :string}
            {"dist" :float}]})

(def create-airports
  (let [cols '[idx label typ code icao desc region runways longest elev country city lat lon]
        types (map cozo/api/cozo-dt [:int :any :any :any :any :any :any :int? :float? :float? :any :any :float? :float?])]
    ~[(res ,cols <= (csv-reader :types ,types
                                :url ,nodes-url
                                :has-headers true))
      (? ,(slice cols 3) := res ,cols (eq label "airport"))
      (:replace airport ,(get schema "airport"))]))

(def create-countries
  (let [cols '[idx label typ code icao desc]
        types (map cozo/api/cozo-dt [:int :any :any :any :any :any])]
    ~[(res ,cols <= (csv-reader :types ,types
                                :url ,nodes-url
                                :has-headers true))
      (? [code desc] := res ,cols (eq label "country"))
      (:replace country ,(get schema "country"))]))

(def create-continents
  (let [cols '[idx label typ code icao desc]
        types (map cozo/api/cozo-dt [:int :any :any :any :any :any])]
    ~[(res ,cols <= (csv-reader :types ,types
                                :url ,nodes-url
                                :has-headers true))
      (? [idx code desc] := res ,cols (eq label "continent"))
      (:replace continent ,(get schema "continent"))]))

(def create-idx2code
  (let [cols '[idx label typ code]
        types (map cozo/api/cozo-dt [:int :any :any :any])]
    ~[(res ,cols <= (csv-reader :types ,types
                                :url ,nodes-url
                                :has-headers true))
      (? [idx code] := res ,cols)
      (:replace idx2code [{idx :int} {code :any}])]))

(def create-contains
  (let [cols '[idx fr_i to_i typ]
        types (map cozo/api/cozo-dt [:int :int :int :string])]
    ~[(res [] <= (csv-reader :types ,types
                             :url ,edges-url
                             :has-headers true))
      (? [entity contained] := res ,cols
         (eq typ "contains")
         *idx2code [fr_i entity]
         *idx2code [to_i contained])
      (:replace contain {entity :string contained :string})]))

(def create-routes
  (let [types (map cozo/api/cozo-dt [:int :int :int :string :float?])]
    ~[(res [] <= (csv-reader :types ,types
                             :url ,edges-url
                             :has-headers true))
      (? [fr to dist] :=
         res [idx fr_i to_i typ dist]
         (eq typ "route")
         *idx2code [fr_i fr]
         *idx2code [to_i to])
      (:replace route ,(get schema "route"))]))

# Open database and download sample data
(def db (cozo/open))
(cozo/q db create-airports)
(cozo/q db create-countries)
(cozo/q db create-continents)
(cozo/q db create-idx2code)
(cozo/q db create-contains)
(cozo/q db create-routes)
(cozo/q db ~(::remove idx2code))
(cozo/q db ~(::relations))

# Query format heuristics
(cozo/q db ~([? [(count-unique to)] := *route {:fr "FRA" :to ?}]))
(cozo/q db ~(? [(count-unique to)] := *route {:fr "FRA" :to ?}))
(cozo/q db [`?[count_unique(to)] := *route{fr: "FRA", to}`])
(cozo/q db `?[count_unique(to)] := *route{fr: "FRA", to}`)

(defn test-result
  # run test, print results
  [db rules expected]
  (def query (cozo/api/make-query rules))
  (def result (cozo/q db rules))
  (printf "\n%p\n%s" rules query)
  (if (= (string/format "%p" expected) (string/format "%p" result))
    (printf "OK! %p" result)
    (printf "ERR Want: %p\n    Got:  %p" expected result)))

# How many airports are directly connected to FRA?
(test-result
  db
  ~(? [(count-unique to)] := *route {:fr "FRA" :to ?})

  @[@{(keyword "count_unique(to)") 310}])


# How many airports are reachable from FRA by one stop?
(test-result
  db
  ~(? [(count-unique to)] :=
      *route {:fr "FRA" :to stop}
      *route {:fr stop :to ?})

  @[@{(keyword "count_unique(to)") 2222}])


# How many airports are reachable from FRA by any number of stops?
(test-result
  db
  ~[(reachable [to] := *route {:fr "FRA" :to ?})
    (reachable [to] := reachable [stop] *route {:fr stop :to ?})
    (? [(count-unique to)] := reachable [to])]

  @[@{(keyword "count_unique(to)") 3462}])


# What are the two most difficult-to-reach airports by the minimum number of hops required, starting from FRA?
(test-result
  db
  ~[(shortest_paths [to (shortest path)] :=
                    *route {:fr "FRA" :to ?}
                    path = ["FRA" to])
    (shortest_paths [to (shortest path)] :=
                    shortest_paths [stop prev_path]
                    *route {:fr stop :to ?}
                    path = (append prev_path to))
    (? [to path p_len] :=
       shortest_paths [to path]
       p_len = (length path))
    (:order -p_len)
    (:limit 2)]

  @[@{:p_len 8 :path @["FRA" "YYZ" "YTS" "YMO" "YFA" "ZKE" "YAT" "YPO"] :to "YPO"}
    @{:p_len 7 :path @["FRA" "AUH" "BNE" "ISA" "BQL" "BEU" "BVI"] :to "BVI"}])


# What is the shortest path between FRA and YPO, by actual distance travelled?
(test-result
  db
  ~[(start [] <- [["FRA"]])
    (end [] <- [["YPO"]])
    (? [src dst distance path] <= (shortest-path-dijkstra *route [] start [] end []))]

  @[@{:distance 4544
      :dst "YPO"
      :path @["FRA" "YUL" "YVO" "YKQ" "YMO" "YFA" "ZKE" "YAT" "YPO"]
      :src "FRA"}])
