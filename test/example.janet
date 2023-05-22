(import cozo)

(def db-path "janet-cozo-test-db")
(defn delete-db [] (os/execute ["rm" "-rf" (string/format "./%s" db-path)] :p))

# Test memory DB
(let [db (cozo/open-db "mem" "" "{}")]
  (print "db:" db)
  (let [result (cozo/run-query db "?[] <- [['hello', 'world', 'Cozo!']]")
        rows (get result "rows")]
    (print (string/format "Found %d row(s)" (length rows)))
    (each row rows
      (print (pp row))))
  (cozo/close-db db))

# Persistent rocksdb - store
(defer (delete-db)

  (let [db (cozo/open-db "rocksdb" db-path "{}")]
    (print "db:" db)
    (cozo/run-query db ["?[address, company_name, department_name, head_count] <- [['Main St', 'Jupiter Inc', 'Dept A', 2],['North St', 'Mercury Corp', 'Dept B', 3]]"
                        ":create dept_info { company_name, department_name => head_count, address }"])
    (cozo/close-db db))

  # Persistent rocksdb - retrieve
  (let [db (cozo/open-db "rocksdb" db-path "{}")]
    (print "db:" db)
    (let [result (cozo/run-query db ["?[company_name, address, head_count] := *dept_info{ company_name, department_name, head_count, address }"])
          rows (get result "rows")]
      (if (not (get result "ok"))
        (print (get result "display"))
        (do
          (print (string/format "Found %d row(s)" (length rows)))
          (each row rows
            (print (pp row))))))

    (cozo/close-db db)))
