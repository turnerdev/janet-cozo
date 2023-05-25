# janet-cozo
Basic [CozoDB](https://github.com/cozodb/cozo) bindings for [Janet](https://github.com/janet-lang/janet), under development.

# Dependencies
* Currently only supports static linking and building cozo from source, as such requires [`cargo`]("https://doc.rust-lang.org/cargo/") for `janet build`

# Example usage

```janet
(import cozo)

(defn main
  [& args]
  (let [db (cozo/open-db "rocksdb" "testdb" "{}")
        result (cozo/run-query db "?[] <- [['hello', 'world', 'Cozo!']]")
        rows (get result "rows")]
    (print (string/format "Found %d row(s)" (length rows)))
    (each row rows
      (print (pp row))))
    (cozo/close-db db)))
```
