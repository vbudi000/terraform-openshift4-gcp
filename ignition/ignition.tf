locals {
  installer_workspace     = "${path.root}/installer-files"
  openshift_installer_url = "${var.openshift_installer_url}/${var.openshift_version}"
}

terraform {
  required_providers {
    ignition = {
      source = "community-terraform-providers/ignition"
      version = "2.1.2"
    }
  }
}

resource "null_resource" "download_binaries" {
  provisioner "local-exec" {
    when    = create
    command = <<EOF
test -e ${path.root}/installer-files || mkdir ${path.root}/installer-files
case $(uname -s) in
  Darwin)
    wget -r -l1 -np -nd -q ${local.openshift_installer_url} -P ${path.root}/installer-files -A 'openshift-install-mac-4*.tar.gz'
    tar zxvf ${path.root}/installer-files/openshift-install-mac-4*.tar.gz -C ${path.root}/installer-files
    wget -r -l1 -np -nd -q ${local.openshift_installer_url} -P ${path.root}/installer-files -A 'openshift-client-mac-4*.tar.gz'
    tar zxvf ${path.root}/installer-files/openshift-client-mac-4*.tar.gz -C ${path.root}/installer-files
    wget https://github.com/stedolan/jq/releases/download/jq-1.6/jq-osx-amd64 -O ${path.root}/installer-files/jq > /dev/null 2>&1\
    ;;
  Linux)
    wget -r -l1 -np -nd -q ${path.root}/installer-files -P ${path.root}/installer-files -A 'openshift-install-linux-4*.tar.gz'
    tar zxvf ${path.root}/installer-files/openshift-install-linux-4*.tar.gz -C ${path.root}/installer-files
    wget -r -l1 -np -nd -q ${local.openshift_installer_url} -P ${path.root}/installer-files -A 'openshift-client-linux-4*.tar.gz'
    tar zxvf ${path.root}/installer-files/openshift-client-linux-4*.tar.gz -C ${path.root}/installer-files
    wget https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 -O ${path.root}/installer-files/jq
    ;;
  *)
    exit 1;;
esac
chmod u+x ${path.root}/installer-files/jq
rm -f ${path.root}/installer-files/*.tar.gz ${path.root}/installer-files/robots*.txt* ${path.root}/installer-files/README.md
if [[ "${var.airgapped["enabled"]}" == "true" ]]; then
  ${path.root}/installer-files/oc adm release extract -a ${path.root}/${var.openshift_pull_secret} --command=openshift-install ${var.airgapped["repository"]}:${var.openshift_version}
  mv ${path.root}/openshift-install ${path.root}/installer-files
fi
EOF
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm -rf ${path.root}/installer-files"
  }

}


resource "null_resource" "generate_manifests" {
  triggers = {
    install_config = data.template_file.install_config_yaml.rendered
  }

  depends_on = [
    null_resource.download_binaries,
    local_file.install_config_yaml,
  ]

  provisioner "local-exec" {
    command = <<EOF
${path.root}/installer-files/openshift-install --dir=${path.root}/installer-files create manifests
rm ${path.root}/installer-files/openshift/99_openshift-cluster-api_worker-machineset-*
rm ${path.root}/installer-files/openshift/99_openshift-cluster-api_master-machines-*
EOF
  }
}

# see templates.tf for generation of yaml config files

resource "null_resource" "generate_ignition" {
  depends_on = [
    null_resource.download_binaries,
    local_file.install_config_yaml,
    null_resource.generate_manifests,
    local_file.cluster-infrastructure-02-config,
    local_file.cluster-dns-02-config,
    local_file.cloud-provider-config,
    # local_file.openshift-cluster-api_master-machines,
    local_file.openshift-cluster-api_worker-machineset,
    local_file.openshift-cluster-api_infra-machineset,
    local_file.ingresscontroller-default,
    local_file.cloud-creds-secret,
    local_file.cluster-scheduler-02-config,
    local_file.cluster-monitoring-configmap,
    # local_file.private-cluster-outbound-service,
  ]

  provisioner "local-exec" {
    command = <<EOF
${path.root}/installer-files/openshift-install --dir=${path.root}/installer-files create ignition-configs
EOF
  }
}

resource "google_storage_bucket" "ignition" {
  name = "${data.local_file.infrastructureID.content}-ignition"
}

resource "google_storage_bucket_object" "ignition_bootstrap" {
  bucket = google_storage_bucket.ignition.name
  name   = "bootstrap.ign"
  source = "${path.root}/installer-files/bootstrap.ign"

  depends_on = [
    null_resource.generate_ignition
  ]
}

data "google_storage_object_signed_url" "bootstrap_ignition_url" {
  bucket   = google_storage_bucket.ignition.name
  path     = "bootstrap.ign"
  duration = "24h"

  depends_on = [
    null_resource.generate_ignition
  ]
}

resource "google_storage_bucket_object" "ignition_master" {
  bucket = google_storage_bucket.ignition.name
  name   = "master.ign"
  source = "${path.root}/installer-files/master.ign"

  depends_on = [
    null_resource.generate_ignition
  ]
}

data "google_storage_object_signed_url" "master_ignition_url" {
  bucket   = google_storage_bucket.ignition.name
  path     = "master.ign"
  duration = "24h"

  depends_on = [
    null_resource.generate_ignition
  ]
}

resource "google_storage_bucket_object" "ignition_worker" {
  bucket = google_storage_bucket.ignition.name
  name   = "worker.ign"
  source = "${path.root}/installer-files/worker.ign"

  depends_on = [
    null_resource.generate_ignition
  ]
}

data "google_storage_object_signed_url" "worker_ignition_url" {
  bucket   = google_storage_bucket.ignition.name
  path     = "worker.ign"
  duration = "24h"

  depends_on = [
    null_resource.generate_ignition
  ]
}

data "ignition_config" "bootstrap_redirect" {
  replace {
    source = data.google_storage_object_signed_url.bootstrap_ignition_url.signed_url
  }
}

data "ignition_config" "master_redirect" {
  replace {
    source = data.google_storage_object_signed_url.master_ignition_url.signed_url
  }
}

data "ignition_config" "worker_redirect" {
  replace {
    source = data.google_storage_object_signed_url.worker_ignition_url.signed_url
  }
}
