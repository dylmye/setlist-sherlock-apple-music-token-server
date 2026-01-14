// create fn folder
data "archive_file" "function_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../dist"
  output_path = "${path.module}/function.zip"
}

// todo: should link to existing namespace
resource "scaleway_function_namespace" "func_ns" {
  name        = "setlist-sherlock-fns"
  description = "Functions that enable Setlist Sherlock functionality"
  project_id  = var.project_id
}

resource "scaleway_function" "func_func" {
  namespace_id = scaleway_function_namespace.func_ns.id
  name         = "setlist-sherlock-token-gen"
  description  = "Generates Apple Music Auth Tokens for Setlist Sherlock users"

  runtime  = "node22"
  handler  = "index.handler"
  zip_file = data.archive_file.function_zip.output_path
  zip_hash = data.archive_file.function_zip.output_base64sha256

  deploy      = true
  privacy     = "public"
  http_option = "redirected"

  min_scale = "0"
  max_scale = "2"

  secret_environment_variables = {
    APPLE_TEAM_ID           = var.apple_team_id
    MUSICKIT_PRIVATE_KEY    = var.musickit_private_key_secret
    MUSICKIT_PRIVATE_KEY_ID = var.musickit_private_key_id
  }
}
