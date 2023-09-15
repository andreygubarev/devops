### Params ###################################################################
locals {
  resource = yamldecode(file("${get_terragrunt_dir()}/resource.yml"))
}

### Terraform #################################################################
terraform {
  source = "${get_terragrunt_dir()}//src"
}

### Inputs ####################################################################
inputs = merge(local.resource.spec, {
  metadata = local.resource.metadata
})

generate "inputs" {
  path      = "inputs.terragrunt.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
variable "metadata" {
  type = object({
    name     = string
    labels   = object({
{%- set labels = cookiecutter.terraform_metadata_labels.split() %}
{%- for label in labels %}
      {{ label }} = string
{%- endfor %}
    })
    annotations = map(string)
  })
}
EOF
}

### Backend ###################################################################
{%- set backend = cookiecutter.terraform_remote_state_backend %}
{%- set backend_name = backend.split("://") | first %}

{%- if backend_name == "s3" %}
### Backend | S3 ##############################################################

{%- set backend_s3_bucket = (backend.split("://") | last).split("/") | first %}
{%- set backend_s3_key = (backend.split("://") | last).split("/", 1) | last %}
{%- if cookiecutter.terraform_remote_state_locking -%}
{%- set backend_dynamodb = (backend.split("://") | last).split("/") | first %}
{%- else %}
{%- set backend_dynamodb = "" %}
{%- endif %}

remote_state {
  backend = "{{ backend_name }}"
  generate = {
    path      = "backend.terragrunt.tf"
    if_exists = "overwrite"
  }
  config = {
    {%- if backend_dynamodb %}
    dynamodb_table           = "{{ backend_dynamodb }}"
    {%- endif %}
    bucket                   = "{{ backend_s3_bucket }}"
    key                      = "{{ backend_s3_key }}"
    encrypt                  = true
    skip_bucket_root_access  = true
    skip_bucket_enforced_tls = true
    region                   = "{{ cookiecutter.terraform_remote_state_region }}"
  }
}
{%- endif %}
