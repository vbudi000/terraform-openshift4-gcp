locals {
  labels = var.gcp_extra_labels

  master_subnet_cidr = cidrsubnet(var.openshift_machine_cidr, 3, 0) #master subnet is a smaller subnet within the vnet. i.e from /21 to /24
  worker_subnet_cidr = cidrsubnet(var.openshift_machine_cidr, 3, 1) #worker subnet is a smaller subnet within the vnet. i.e from /21 to /24
  public_endpoints   = var.gcp_publish_strategy == "External" ? true : false

  gcp_image = var.gcp_preexisting_image ? local.rhcos_image : google_compute_image.cluster[0].self_link
}

provider "google" {
  credentials = var.gcp_service_account
  project     = var.gcp_project_id
  region      = var.gcp_region
}

module "bootstrap" {
  source = "./bootstrap"

  bootstrap_enabled = var.gcp_bootstrap_enabled

  image            = local.gcp_image
  machine_type     = var.gcp_bootstrap_instance_type
  cluster_id       = module.ignition.infraID
  ignition         = module.ignition.bootstrap_ignition # var.ignition_bootstrap
  network          = module.network.network
  network_cidr     = var.openshift_machine_cidr
  public_endpoints = local.public_endpoints
  subnet           = module.network.master_subnet
  zone             = module.network.zones[0] # var.gcp_master_availability_zones[0]
  region           = var.gcp_region

  root_volume_size = var.gcp_master_root_volume_size
  root_volume_type = var.gcp_master_root_volume_type

  labels = local.labels
}

module "master" {
  source = "./master"

  image          = local.gcp_image
  instance_count = var.openshift_master_count
  machine_type   = var.gcp_master_instance_type
  cluster_id     = module.ignition.infraID
  ignition       = module.ignition.master_ignition # var.ignition_master
  subnet         = module.network.master_subnet
  zones          = distinct(module.network.zones)  # distinct(var.gcp_master_availability_zones)

  root_volume_size = var.gcp_master_root_volume_size
  root_volume_type = var.gcp_master_root_volume_type

  labels = local.labels
}

module "iam" {
  source = "./iam"

  cluster_id = module.ignition.infraID
}

module "network" {
  source = "./network"

  cluster_id         = module.ignition.infraID
  master_subnet_cidr = local.master_subnet_cidr
  worker_subnet_cidr = local.worker_subnet_cidr
  network_cidr       = var.openshift_machine_cidr
  public_endpoints   = local.public_endpoints

  bootstrap_lb              = var.gcp_bootstrap_enabled && var.gcp_bootstrap_lb
  bootstrap_instances       = module.bootstrap.bootstrap_instances
  bootstrap_instance_groups = module.bootstrap.bootstrap_instance_groups

  master_instances       = module.master.master_instances
  master_instance_groups = module.master.master_instance_groups

  preexisting_network = var.gcp_preexisting_network
  cluster_network     = var.gcp_cluster_network
  master_subnet       = var.gcp_control_plane_subnet
  worker_subnet       = var.gcp_compute_subnet
}

module "dns" {
  source = "./dns"

  cluster_id           = module.ignition.infraID
  public_dns_zone_name = var.gcp_public_dns_zone_name
  network              = module.network.network
  cluster_domain       = "${var.cluster_name}.${var.base_domain}"
  api_external_lb_ip   = module.network.cluster_public_ip
  api_internal_lb_ip   = module.network.cluster_ip
  public_endpoints     = local.public_endpoints
}

resource "google_compute_image" "cluster" {
  count = var.gcp_preexisting_image ? 0 : 1

  name = "${module.ignition.infraID}-rhcos-image"

  # See https://github.com/openshift/installer/issues/2546
  guest_os_features {
    type = "SECURE_BOOT"
  }
  guest_os_features {
    type = "UEFI_COMPATIBLE"
  }

  raw_disk {
    source = local.rhcos_image_uri
  }

  licenses = var.gcp_image_licenses
}


locals {
  tags = merge(
    {
      "kubernetes.io_cluster.${module.ignition.infraID}" = "owned"
    },
    var.gcp_extra_labels,
  )
}

module "ignition" {
  source = "./ignition"

  master_count                = var.openshift_master_count
  node_count                  = var.openshift_worker_count
  infra_count                 = var.openshift_infra_count
  project_id                  = var.gcp_project_id
  base_domain                 = var.base_domain
  public_dns_zone_name        = var.gcp_public_dns_zone_name
  cluster_name                = var.cluster_name
  cluster_network_cidr        = var.openshift_cluster_network_cidr
  cluster_network_host_prefix = var.openshift_cluster_network_host_prefix
  machine_cidr                = var.openshift_machine_cidr
  service_network_cidr        = var.openshift_service_network_cidr
  gcp_region                  = var.gcp_region
  openshift_pull_secret       = var.openshift_pull_secret
  master_vm_type              = var.gcp_master_instance_type
  worker_vm_type              = var.gcp_worker_instance_type
  infra_vm_type               = var.gcp_infra_instance_type
  master_os_disk_size         = var.gcp_master_root_volume_size
  worker_os_disk_size         = var.gcp_worker_root_volume_size
  infra_os_disk_size          = var.gcp_infra_root_volume_size
  master_os_disk_type         = var.gcp_master_root_volume_type
  worker_os_disk_type         = var.gcp_worker_root_volume_type
  infra_os_disk_type          = var.gcp_infra_root_volume_type
  zones                       = module.network.zones
  airgapped                   = var.airgapped
  serviceaccount_encoded      = chomp(base64encode(file(var.gcp_service_account)))
  openshift_version           = var.openshift_version
  public_ssh_key              = var.public_ssh_key
  additional_trust_bundle     = var.openshift_additional_trust_bundle
}

