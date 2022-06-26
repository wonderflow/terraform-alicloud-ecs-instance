# Alibaba ECS with Terraform

> Note: This repo is a simple fork of https://github.com/terraform-alicloud-modules/terraform-alicloud-ecs-instance .

Some information you may need:

* Installation of Terraform: https://www.terraform.io/intro/getting-started/install.html
* HCL language syntax of Terraform: https://www.terraform.io/docs/configuration/syntax.html
  - download the binary package and add it to your [PATH variable](https://en.wikipedia.org/wiki/PATH_(variable))

## Test the module

* Download the latest stable version of the Alibaba Cloud provider
```shell
terraform init
```

* Configure the Alibaba Cloud provider

```shell
export ALICLOUD_ACCESS_KEY="your-accesskey-id"
export ALICLOUD_SECRET_KEY="your-accesskey-secret"
export ALICLOUD_REGION="your-region-id"
```

You can also create an `provider.tf` including the credentials instead:

```hcl
provider "alicloud" {
    access_key  = "your-accesskey-id"
    secret_key   = "your-accesskey-secret"
    region           = "cn-hangzhou"
}
```

* Create the resources in the cloud
```shell
terraform apply -var-file=test/test.tfvars
```

* Delete all resources after tests

```shell
terraform destroy  -var-file=test/test.tfvars
```



