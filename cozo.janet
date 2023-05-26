(import cozo-bindings :as cozo)
(import spork/json)

(defn open
  [&opt path engine options]
  (default engine (if path "rocksdb" "mem"))
  (default path "")
  (default options "{}")
  (cozo/open-db engine path options))

(defn q
  [db statements]
  (let [query (string/join (flatten [statements]) "\n")]
    (json/decode (cozo/run-query db query))))

(defn close
  [db]
  (cozo/close-db db))
