terraform {
  source = "../../modules/transit-vault"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

inputs = {
  vault_version = "1.21.2"
}
