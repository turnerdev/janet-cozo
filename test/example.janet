(import cozo)

# Test memory DB
(let [db (cozo/open-db "mem" "" "{}")]
  (print "db:" db)
  (print (cozo/run-query db "?[] <- [['hello', 'world', 'Cozo!']]"))
  (cozo/close-db db))

# Persistent rocksdb - store
(let [db (cozo/open-db "rocksdb" "testdb" "{}")]
  (print "db:" db)
  (cozo/run-query db "?[address, company_name, department_name, head_count] <- [[\"Main St\", \"Jupiter Inc\", \"Dept A\", 2]]")
  (cozo/run-query db "?[address, company_name, department_name, head_count] <- [[\"North St\", \"Neptune Corp\", \"Dept B\", 3]]")
  (cozo/run-query db ":create dept_info { company_name, department_name => head_count, address }")
  (cozo/close-db db))

# Persistent rocksdb - retrieve
(let [db (cozo/open-db "rocksdb" "testdb" "{}")]
  (print "db:" db)

  (let [result (cozo/run-query db "?[] := *dept_info{ company_name: \"Neptune Corp\", department_name: \"Dept B\"}")]
    (map print [(not (nil? (string/find "Neptune" result)))
                (nil? (string/find "Jupiter" result))]))

  (let [result (cozo/run-query db "?[] := *dept_info{ company_name: \"Jupiter Inc\", department_name: \"Dept A\"}")]
    (map print [(nil? (string/find "Neptune" result))
                (not (nil? (string/find "Jupiter" result)))]))

  (cozo/close-db db))
