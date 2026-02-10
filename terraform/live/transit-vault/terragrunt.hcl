terraform {
  source = "../../modules/transit-vault"
}

include "root" {
  path = find_in_parent_folders()
}

inputs = {
  vault_version = "1.21.2"
}
