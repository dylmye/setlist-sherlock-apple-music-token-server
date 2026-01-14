terraform {
  backend "s3" {
    # the below details are correct for setlist sherlock's setup
    # but may/will be different for yours :)
    bucket                      = "dmxr-terraform-state"
    key                         = "setlist-sherlock-apple-music-token-server.tfstate"
    region                      = "nl-ams"
    endpoint                    = "https://s3.nl-ams.scw.cloud"
    skip_credentials_validation = true
    skip_region_validation      = true
  }
}
