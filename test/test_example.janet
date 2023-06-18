(import /cozo)

(def db-path "janet-cozo-test-db")
(defn delete-db [] (os/execute ["rm" "-rf" (string/format "./%s" db-path)] :p))

# Test memory DB
(let [db (cozo/open)]
  (print "db:" db)
  (let [rows (cozo/q db "?[] <- [['hello', 'world', 'Cozo!']]")]
    (print (string/format "Found %d row(s)" (length rows)))
    (each row rows
      (print (pp row))))
  (cozo/close db))

# Persistent rocksdb - store
(defer (delete-db)

  (let [db (cozo/open db-path)]
    (print "db:" db)
    (cozo/q db
            "?[address, company_name, department_name, head_count] <- [['Main St', 'Jupiter Inc', 'Dept A', 2],['North St', 'Mercury Corp', 'Dept B', 3]]"
            ":create dept_info { company_name, department_name => head_count, address }")
    (cozo/close db))

  # Persistent rocksdb - retrieve
  (let [db (cozo/open db-path)]
    (print "db:" db)
    (let [rows (cozo/q db "?[company_name, address, head_count] := *dept_info{ company_name, department_name, head_count, address }")]
      (do
        (print (string/format "Found %d row(s)" (length rows)))
        (each row rows
          (print (pp row)))))

    (cozo/close db)))
