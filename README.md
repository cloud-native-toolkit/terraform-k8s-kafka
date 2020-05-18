# Kafka terraform module

Installs a Kafka instance using the Strimzi operator. For the time being this module installs the 
same Strimzi operator from the community catalog across IKS, OCP 3.11, and OCP 4.3 due to an issue
with the RedHat AQM Streams operator. When the issue is eventually resolved then the module will install
the RedHat AQM Streams operator on OCP 4.3.  Fortunately, the RedHat AQM Streams operator uses the 
Strimzi operator underneath so all the same CRDs apply for configuring the cluster.

## Supported platforms

- IKS
- OCP 3.11
- OCP 4.3

## Software dependencies

### Terraform

- helm provider
- null provider

### Shell

- kubectl

## Suggested companion modules

- Cluster
- OLM
- Namespace

## Example usage

```hcl-terraform
module "dev_infra_kafka" {
  source = "github.com/ibm-garage-cloud/terraform-infrastructure-kafka.git?ref=v1.0.0"

  cluster_config_file = module.dev_cluster.config_file_path
  cluster_type        = module.dev_cluster.type
  ingress_subdomain   = module.dev_cluster.ingress_hostname
  app_namespace       = module.dev_cluster_namespaces.tools_namespace_name
  olm_namespace       = module.dev_software_olm.olm_namespace
  operator_namespace  = module.dev_software_olm.target_namespace
  name                = "kafka"
}
```
