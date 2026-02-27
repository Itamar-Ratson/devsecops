feature "deploy_eks" {
  default = true
}

exclude {
  if      = !feature.deploy_eks.value
  actions = ["apply", "plan", "destroy"]
}

terraform {
  source = "../../../../modules/aws/eks/vpc"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependencies {
  paths = ["./workspace"]
}
