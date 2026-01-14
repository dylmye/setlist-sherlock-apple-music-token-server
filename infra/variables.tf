variable "zone" {
  type = string
}

variable "region" {
  type = string
}

variable "project_id" {
  type        = string
  description = "Scaleway Project ID"
}

variable "scw_access_key" {
  type        = string
  description = "Scaleway Access Key"
  sensitive   = true
}

variable "scw_secret_key" {
  type        = string
  description = "Scaleway Secret Key"
  sensitive   = true
}

variable "apple_team_id" {
  type        = string
  description = "Apple Developer Team ID"
  sensitive   = true
}

variable "musickit_private_key_secret" {
  type        = string
  description = "Apple Music API Media Services private key secret"
  sensitive   = true
}

variable "musickit_private_key_id" {
  type        = string
  description = "Apple Music API Media Services private key id"
  sensitive   = true
}
