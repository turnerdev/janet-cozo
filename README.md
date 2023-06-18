# janet-cozo
[Janet](https://github.com/janet-lang/janet) bindings for [CozoDB](https://github.com/cozodb/cozo), an embeddable Datalog database.

# Usage

```janet
(import cozo)

(let [db (cozo/open "test.db")
      rows (cozo/q db "?[] <- [['hello', 'world', 'Cozo!']]")]

  (printf "Found %d row(s)" (length rows))
  (each row rows
    (pp row))

  (cozo/close db))
```

As an alternative to querying with CozoScript, there is also an experimental quasiquote syntax. See `test` for more examples.

```janet
(import cozo)

(let [db (cozo/open "test.db")
      rows (cozo/q db ~(? [] <- [["hello", "world", "Cozo!"]]))]

  (printf "Found %d row(s)" (length rows))
  (each row rows
    (pp row))

  (cozo/close db))
```

# Dependencies
Build links `$JANET_BUILDPATH/release/libcozo_c.a` if present, otherwise builds from source using the `cozo` git submodule.
