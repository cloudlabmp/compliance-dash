variable "secrets_map" {
  description = "Map of secret_name => secret_value (plaintext values passed in via TF_VAR_*, will not be persisted to state)."
  type        = map(string)
}
