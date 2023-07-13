#include "cozo_c.h"
#include <janet.h>

static Janet cfun_OpenDB(int32_t argc, Janet *argv) {
  janet_fixarity(argc, 3);
  int32_t db_id;
  const char *engine = janet_getcstring(argv, 0);
  const char *path = janet_getcstring(argv, 1);
  const char *options = janet_getcstring(argv, 2);
  char *err = cozo_open_db(engine, path, options, &db_id);
  if (err) {
    janet_panicf("%s", err);
    cozo_free_str(err);
    return janet_wrap_nil();
  }
  return janet_wrap_integer(db_id);
}

static Janet cfun_CloseDB(int32_t argc, Janet *argv) {
  janet_fixarity(argc, 1);
  int32_t db_id = janet_getinteger(argv, 0);
  return janet_wrap_boolean(cozo_close_db(db_id));
}

static Janet cfun_RunQuery(int32_t argc, Janet *argv) {
  janet_fixarity(argc, 2);
  int32_t db_id = janet_getinteger(argv, 0);
  const char *query = janet_getcstring(argv, 1);
  const char *empty_params = "{}";
  char *res = cozo_run_query(db_id, query, empty_params, false);
  return janet_cstringv(res);
}

/*****************************************************************************/

static const JanetReg cfuns[] = {{"open-db", cfun_OpenDB,
                                  "(open-db engine path options)\n\n"
                                  "Instantiate a CozoDB \n"
                                  " - engine   = [\"mem\", path]  \n"
                                  " - path   = file path if engine"
                                  " - options = See CozoDB docs \n"
                                  "returns a reference to a CozoDB instance"},
                                 {"close-db", cfun_CloseDB,
                                  "(close-db db-id)\n\n"
                                  "Closes a CozoDB"},
                                 {"run-query", cfun_RunQuery,
                                  "(run-query db query)\n\n"
                                  "Queries a CozoDB"
                                  " - db-id  = CozoDB instance"
                                  " - query  = See CozoDB docs"},
                                 {NULL, NULL, NULL}};

JANET_MODULE_ENTRY(JanetTable *env) { janet_cfuns(env, "cozo", cfuns); }
