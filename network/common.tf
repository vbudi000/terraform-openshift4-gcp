# Canonical internal state definitions for this module.
# read only: only locals and data source definitions allowed. No resources or module blocks in this file

data "google_compute_network" "preexisting_cluster_network" {
  count = var.preexisting_network ? 1 : 0

  name = var.cluster_network
}

data "google_compute_subnetwork" "preexisting_master_subnet" {
  count = var.preexisting_network ? 1 : 0

  name = "${var.cluster_id}-master-subnet"
}

data "google_compute_subnetwork" "preexisting_worker_subnet" {
  count = var.preexisting_network ? 1 : 0

  name = "${var.cluster_id}-worker-subnet"
}

data "google_compute_zones" "available" {}

locals {
  cluster_network    = var.preexisting_network ? data.google_compute_network.preexisting_cluster_network[0].self_link : google_compute_network.cluster_network[0].self_link
  master_subnet      = var.preexisting_network ? data.google_compute_subnetwork.preexisting_master_subnet[0].self_link : google_compute_subnetwork.master_subnet[0].self_link
  master_subnet_cidr = cidrsubnet(var.network_cidr, 3, 0) #master subnet is a smaller subnet within the vnet. i.e from /21 to /24
  worker_subnet_cidr = cidrsubnet(var.network_cidr, 3, 1) #node subnet is a smaller subnet within the vnet. i.e from /21 to /24
  zones              = data.google_compute_zones.available.names
}
