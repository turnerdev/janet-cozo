(declare-project
  :name "cozo"
  :description "Janet bindings to CozoDB"
  :version "0.0.1")

(defn build-cozo-lib-c
  "Build cozo-lib-c"
  []
  (let [project-dir (os/cwd)]
    (os/cd "./cozo/cozo-lib-c/")
    (def re (os/execute ["cargo" "build" "--release" "-p" "cozo_c" "-F" "compact" "-F" "storage-rocksdb" "--target-dir" "../../build/"] :p))
    (os/cd project-dir)))

(unless (os/stat "./build/release/libcozo_c.a")
  (build-cozo-lib-c))

(declare-native
  :name "cozo"
  :lflags ["-L./build/release"
           "-l:libcozo_c.a"
           "-lm"
           "-lstdc++"]
  :source @["main.c"])
