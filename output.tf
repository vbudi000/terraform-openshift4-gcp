output "cluster_id" {
  value = module.ignition.infraID
}

output "bootstrap_address" {
  value = module.bootstrap.bootstrap_address
}
