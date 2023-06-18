(import cozo-bindings :as cozo)
(import ./api :export true)

(defn open
  # open a database, defaults to in-memory rocksdb
  [&opt path engine options]
  (default engine (if path "rocksdb" "mem"))
  (default path "")
  (default options "{}")
  (cozo/open-db engine path options))

(defn close
  # close a database
  [db]
  (cozo/close-db db))

(defn q
  # query the database
  [db & rules]
  (def query (api/make-query ;rules))
  (def result (api/make-result (cozo/run-query db query)))
  (def {:ok ok :headers headers :rows rows} result)
  (if ok
    (if (= (first headers) "_0")
      rows
      (map |(zipcoll (map keyword headers) $) rows))
    (error (or (result :display) (result :message)))))
