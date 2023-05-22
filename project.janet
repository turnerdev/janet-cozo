(declare-project
  :name "cozo"
  :description "Janet bindings to CozoDB"
  :version "0.0.1")

# (declare-native
#   :name "cozo"
#   :deps
#   :source @["main.c"])


# (declare-project
#   :name "template")


(defn build-cozo-lib-c
  "Build cozo-lib-c"
  []
  (let [project-dir (os/cwd)]
    (os/cd "./cozo/cozo-lib-c/")
    (def re (os/execute ["cargo" "build" "--release" "-p" "cozo_c" "-F" "compact" "-F" "storage-rocksdb" "--target-dir" "../../build/"] :p))
    (os/cd project-dir)
    (os/mkdir "build")))

(unless (os/stat "./build/release/libcozo_c.a")
  (build-cozo-lib-c))

(declare-native
  :name "cozo"
  :lflags ["-L./build/release"
           "-l:libcozo_c.a"
           "-lm"
           "-lstdc++"]
  :source @["main.c"])

# (post-deps
#   (declare-native
#     :name "cozo"
#     :source @["main.c"]

#     (phony "build-rust-code" []
#            # (os/cd "./cozo/cozo-lib-c/")
#            (os/execute ["cargo" "build" "--release" "--target-dir" "target" "--quiet"] :p)
#            # (os/cd "../..")
# )

#     (phony "cp-lib" []
#            # (os/execute ["mkdir" "-p" "build"] :p)
#            # (os/execute ["cp" "target/release/libstr_ext.so" "build/str-ext.so"] :p)
#            # (os/execute ["cp" "target/release/libstr_ext.a" "build/str-ext.a"] :p)
# )

#     # (phony "build-debug" []
#     #   (os/execute ["cargo" "build" "--debug" "--target-dir" "target" "--quiet"] :p)
#     #   (os/execute ["mkdir" "-p" "build"] :p)
#     #   (os/execute ["cp" "target/debug/libstr_ext.so" "build/str-ext.so"] :p)
#     #   (os/execute ["cp" "target/debug/libstr_ext.a" "build/str-ext.a"] :p))

#     (phony "all" ["build-rust-code" "cp-lib"])

#     (add-dep "build" "all")

#     # (phony "clean-target" []
#     #   (os/execute ["rm" "-rf" "target"] :p))

#     # (add-dep "clean" "clean-target")
# ))


# (defn build-mingw []
#   (declare-native
#    :name "xbuild"
#    #:embedded @["bench_lib.janet"]
#    :cflags ["-I./" "-std=c99" "-Wall" "-Wextra"
#             #"-fsanitize=address" "-g"
#             "-fPIC" "-shared" "-static" "-D_WIN32_WINNT=0x0600"]
#    :lflags ["-Wl,--out-implib,libxbuild_dll.a" "-lm" "-pthread" "-lwinmm"
#             "-lws2_32"
#             "-lmswsock"
#             "-ladvapi32"
#             "-L./"
#             "-l:libjanet_dll.a"]
#    :source @["xbuild.c"]))

