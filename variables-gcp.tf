variable "gcp_project_id" {
  type        = string
  description = "The target GCP project for the cluster."
}

variable "gcp_service_account" {
  type        = string
  description = "The service account for authenticating with GCP APIs."
}

variable "gcp_region" {
  type        = string
  description = "The target GCP region for the cluster."
}

variable "gcp_extra_labels" {
  type = map(string)

  description = <<EOF
(optional) Extra GCP labels to be applied to created resources.
Example: `{ "key" = "value", "foo" = "bar" }`
EOF

  default = {}
}

variable "gcp_bootstrap_enabled" {
  type = bool
  description = "Setting this to false allows the bootstrap resources to be disabled."
  default = true
}

variable "gcp_bootstrap_lb" {
  type = bool
  description = "Setting this to false allows the bootstrap resources to be removed from the cluster load balancers."
  default = true
}

variable "gcp_bootstrap_instance_type" {
  type = string
  description = "Instance type for the bootstrap node. Example: `n1-standard-4`"
  default = "n1-standard-4"
}

variable "gcp_master_instance_type" {
  type = string
  description = "Instance type for the master node(s). Example: `n1-standard-4`"
  default     = "n1-standard-4"
}

variable "gcp_worker_instance_type" {
  type        = string
  description = "Instance type for the bootstrap node. Example: `n1-standard-4`"
  default     = "n1-standard-8"
}

variable "gcp_infra_instance_type" {
  type        = string
  description = "Instance type for the master node(s). Example: `n1-standard-4`"
  default     = "n1-standard-4"
}

#variable "gcp_image_uri" {
#  type = string
#  description = "URL to Raw Image for all nodes. This is used in case a new image needs to be generated for the nodes."
#}

#variable "gcp_image" {
#  type = string
#  description = "URL to the Image for all nodes."
#}

variable "gcp_preexisting_image" {
  type = bool
  default = true
  description = "Specifies whether an existing GCP Image should be used or a new one created for installation"
}

variable "gcp_master_root_volume_type" {
  type = string
  description = "The type of volume for the root block device of master nodes."
  default = "pd-ssd"
}

variable "gcp_master_root_volume_size" {
  type = string
  description = "The size of the volume in gigabytes for the root block device of master nodes."
  default     = 200
}

variable "gcp_worker_root_volume_type" {
  type = string
  description = "The type of volume for the root block device of master nodes."
  default = "pd-ssd"
}

variable "gcp_worker_root_volume_size" {
  type = string
  description = "The size of the volume in gigabytes for the root block device of master nodes."
  default     = 200
}

variable "gcp_infra_root_volume_type" {
  type = string
  description = "The type of volume for the root block device of master nodes."
  default = "pd-ssd"
}

variable "gcp_infra_root_volume_size" {
  type = string
  description = "The size of the volume in gigabytes for the root block device of master nodes."
  default     = 200
}

variable "gcp_public_dns_zone_name" {
  type = string
  default = null
  description = "The name of the public DNS zone to use for this cluster"
}

#variable "gcp_master_availability_zones" {
#  type = list(string)
#  description = "The availability zones in which to create the masters. The length of this list must match master_count."
#}

variable "gcp_preexisting_network" {
  type = bool
  default = false
  description = "Specifies whether an existing network should be used or a new one created for installation."
}

variable "gcp_cluster_network" {
  type = string
  description = "The name of the cluster network, either existing or to be created."
  default     = ""
}

variable "gcp_control_plane_subnet" {
  type = string
  description = "The name of the subnet for the control plane, either existing or to be created."
  default     = ""
}

variable "gcp_compute_subnet" {
  type = string
  description = "The name of the subnet for worker nodes, either existing or to be created"
  default     = ""
}

variable "gcp_publish_strategy" {
  type        = string
  description = "The cluster publishing strategy, either Internal or External"
  default     = "External"
}

variable "gcp_image_licenses" {
  type        = list(string)
  description = "The licenses to use when creating compute instances"
  default     = []
}

variable "cluster_name" {
  type = string
  description = "The name of the cluster - will be used to construct the private domain"
}

variable "base_domain" {
  type = string
  description = "The base domain name of the cluster - will be used to construct the private domain"
}

variable "openshift_master_count" {
  type        = string
  description = "Number of master nodes - default is 3"
  default     = 3
}

variable "openshift_worker_count" {
  type        = string
  description = "Number of worker nodes - default is 3"
  default     = 3
}

variable "openshift_infra_count" {
  type        = string
  description = "Number of infra nodes - default is 3"
  default     = 0
}

variable "openshift_pull_secret" {
  type    = string
  default = "pull-secret"
}

variable "openshift_version" {
  type        = string
  description = "Version of OpenShift to be installed - 4.x.y"
  default     = "4.6.31"
}

variable "openshift_ssh_key" {
  type        = string
  description = "SSH key for OpenShift nodes"
  default     = ""
}

variable "openshift_machine_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "openshift_cluster_network_cidr" {
  type    = string
  default = "10.128.0.0/14"
}

variable "openshift_cluster_network_host_prefix" {
  type    = string
  default = 23
}

variable "openshift_service_network_cidr" {
  type    = string
  default = "172.30.0.0/16"
}

variable "public_ssh_key" {
  type        = string
  default     = ""
  description = "Public key for the OpenShift nodes"
}

variable "openshift_additional_trust_bundle" {
  type        = string
  default     = ""
  description = "Additional certificates that the cluster will trust - typically used for proxies and mirror registry."
}

variable "airgapped" {
  type = map(string)
  default = {
    enabled    = false
    repository = ""
  }
}