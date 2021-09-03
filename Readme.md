## Terraform Example with Google Cloud Platform

It creates https://github.com/kelseyhightower/kubernetes-the-hard-way infrastructure project third module.

It needs `gcloud auth application-default login`

https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/03-compute-resources.md

---
### Steps

1. `gcloud auth application-default login`
2. Add `terraform.tfvars` file that includes `project_name` property.
3. `terraform init`
4. `terraform apply`
