(declare-project
  :name "cozo"
  :description "Janet bindings to CozoDB"
  :version "0.0.1"
  :dependencies ["spork"])

(def build-path (os/getenv "JANET_BUILDPATH" "build"))
(def libcozo-path (string build-path "/release/libcozo_c.a"))

(defn build-cozo-lib-c
  "Build cozo-lib-c"
  []
  (let [project-dir (os/cwd)]
    (os/cd "./cozo/cozo-lib-c/")
    (os/execute ["cargo" "build" "--release" "-p" "cozo_c" "-F" "compact" "-F" "storage-rocksdb" "--target-dir" build-path] :p)
    (os/execute ["cp" libcozo-path build-path] :p)
    (os/cd project-dir)))

(unless (os/stat libcozo-path)
  (build-cozo-lib-c))

(declare-source
  :source @["cozo.janet"])

(declare-native
  :name "cozo-bindings"
  :lflags [(string "-L" build-path)
           "-l:libcozo_c.a"
           "-lm"
           "-lstdc++"]
  :source @["main.c"])
