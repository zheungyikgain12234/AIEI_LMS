import 'package:supabase_flutter/supabase_flutter.dart';

/// Turns a raw Postgres/Supabase error into copy an admin can act on.
///
/// Every unique column in the schema (code, name, ...) is backed by either
/// a plain `unique` constraint or an explicit `unique index on (lower(...))`
/// named `<table>_code_..._key` / `<table>_name_ci_idx` — see schema.sql.
/// Postgrest surfaces a unique-violation as error code `23505` with the
/// failing constraint/index name inside `message`, so we sniff `_code_` vs
/// `_name_` there instead of showing the admin a raw Postgres error.
String friendlyErrorMessage(Object error) {
  if (error is PostgrestException && error.code == '23505') {
    final message = error.message.toLowerCase();
    if (message.contains('_code_')) {
      return 'This code is already in use. Please choose a different code.';
    }
    if (message.contains('_name_')) {
      return 'This name is already in use. Please choose a different name.';
    }
    return 'This entry already exists. Please use different values.';
  }
  return error.toString();
}
