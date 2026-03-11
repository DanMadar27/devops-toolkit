# GCP Terraform

Links:

- [Hashicorp tutorial](https://developer.hashicorp.com/terraform/tutorials/gcp-get-started)
- [Hashicorp registry](https://registry.terraform.io/providers/hashicorp/google/latest)

## GCP CLI

Login to your account:

```bash
gcloud init
```

See current profile:

```bash
# List accounts whose credentials are stored on the local system
gcloud auth list

# List the properties in your active gcloud CLI configuration
gcloud config list
```

Set up application default credentials for Terraform:
```bash
gcloud auth application-default login
```
