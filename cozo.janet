(import cozo-bindings :as cozo)
(import spork/json)

(defn open-db
  [engine path options]
  (cozo/open-db engine path options))

(defn run-query
  [db statements]
  (let [query (string/join (flatten [statements]) "\n")]
    (json/decode (cozo/run-query db query))))

(defn close-db
  [db]
  (cozo/close-db db))
