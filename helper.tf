locals {
  major_version   = join(".", slice(split(".", var.openshift_version), 0, 2))
  rhcos_image     = lookup(lookup(jsondecode(data.http.images.body), "gcp"), "image")
  rhcos_image_uri = lookup(lookup(jsondecode(data.http.images.body), "gcp"), "url")
}

data "http" "images" {
  url = "https://raw.githubusercontent.com/openshift/installer/release-${local.major_version}/data/data/rhcos.json"
  request_headers = {
    Accept = "application/json"
  }
}
