# janet-cozo
Basic [CozoDB](https://github.com/cozodb/cozo) bindings for [Janet](https://github.com/janet-lang/janet), under development.

# Usage

```janet
(import cozo)

(let [db (cozo/open "test.db")
      result (cozo/q db "?[] <- [['hello', 'world', 'Cozo!']]")
      rows (get result "rows")]

  (print (string/format "Found %d row(s)" (length rows)))
  (each row rows
    (print (pp row)))

  (cozo/close db))
```

# Dependencies
Build links `$JANET_BUILDPATH/release/libcozo_c.a` if present, otherwise builds from source using the `cozo` git submodule.
