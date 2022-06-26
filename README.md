> Note: Source code of this repo is a simple fork of https://github.com/terraform-alicloud-modules/terraform-alicloud-ecs-instance .


# How to Integrate Terraform Module With KubeVela?

In this blog, I will introduce how to integrate terraform with KubeVela by building an Alibaba ECS instance as example.
By doing this, you'll get the power of both KubeVela and Terraform including:

1. The power of gluing Terraform with Kubernetes ecosystem including all of the CRD controllers and Helm Charts.
2. Declarative model for all the resources, you won't be blocked by the network issues from terraform CLI, KubeVela will run the reconcile loop until succeed.
3. A powerful CUE based workflow that you can define any preferred steps in the application delivery process, such as canary rollout, multi-clusters/multi-env promotion, notification.

If you're familiar with KubeVela but not knowing much of Terraform, here's useful information you may need for the following tutorial:

* Installation of Terraform: https://www.terraform.io/intro/getting-started/install.html
* HCL language syntax of Terraform: https://www.terraform.io/docs/configuration/syntax.html
  - download the binary package and add it to your [PATH variable](https://en.wikipedia.org/wiki/PATH_(variable)).

If you're good at terraform but not familiar with KubeVela, just go with the tutorial.

## Part 1. Create and Test a Terraform Module

> If you already have a well-tested terraform module, just skip this part.

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

Then push the repo to github for use, here's mine:  https://github.com/wonderflow/terraform-alicloud-ecs-instance .

## Part 2. Integrate With Vela

KubeVela is a modern software delivery control plane that aims to make deploying and operating applications across today's hybrid, multi-cloud environments easier, faster and more reliable. You can read the brief introduction here: https://kubevela.net/docs/ .

### Install KubeVela

Before start, make sure you have [installed kubevela control plane](https://kubevela.net/docs/install#1-install-velad), don't worry if you don't have Kubernetes cluster, velad is enough for the quick demo.

* Enable Terraform Addon and Alibaba Provider

```
vela addon enable terraform
vela addon enable terraform-alibaba
```

* Add credentials as provider

```
vela provider add terraform-alibaba --ALICLOUD_ACCESS_KEY <"your-accesskey-id"> --ALICLOUD_SECRET_KEY "your-accesskey-secret" --ALICLOUD_REGION <your-region> --name terraform-alibaba-default
```

More details: https://kubevela.net/docs/reference/addons/terraform

### Extend Cloud Resource for KubeVela

We'll use the terraform module we have already prepared.

* Generate Component Definition

```
vela def init ecs --type component --provider alibaba --desc "Terraform configuration for Alibaba Cloud Elastic Compute Service" --git https://github.com/wonderflow/terraform-alicloud-ecs-instance.git > alibaa-ecs.yaml
```

* Apply it to the vela control plane

```
kubectl apply -f alibaa-ecs-def.yaml
```

Then the extension of ECS module has been added.

More details: https://kubevela.net/docs/platform-engineers/components/component-terraform

## Part 3. Use the power of the integration

The end user can use the terraform module as a KubeVela component now.

## Deploy a basic application including the resource

1. Check the parameters

```
vela show alibaba-ecs
```

Or you can view it from website by launching:

```
vela show alibaba-ecs --web
```

2. Deploy a basic application with the ecs resource.

```shell
cat <<EOF | vela up -f -
# YAML begins
apiVersion: core.oam.dev/v1beta1
kind: Application
metadata:
  name: ecs-demo
spec:
  components:
    - name: ecs-demo
      type: alibaba-ecs
      properties:
        providerRef:
          name: terraform-alibaba-default
        writeConnectionSecretToRef:
          name: outputs-ecs          
        name: "test-terraform-vela-123"
        instance_type: "ecs.n1.tiny"
        host_name: "test-terraform-vela"
        password: "Test-123456!"
        internet_max_bandwidth_out: "10"
        associate_public_ip_address: "true"
        instance_charge_type: "PostPaid"
        user_data_url: "https://raw.githubusercontent.com/wonderflow/terraform-alicloud-ecs-instance/master/userdata.sh"
        ports:
        - 8080
        - 8090
        tags:
          created_by: "Terraform-of-KubeVela"
          created_from: "module-tf-alicloud-ecs-instance"
# YAML ends
EOF
```

This application will deploy an ECS instance with a public ip.

3. Check the status and logs

```
vela status ecs-demo
vela logs ecs-demo
```

4. You can get the secret from the terraform resource contains the output values.

Check the visiting url by

```
kubectl get secret outputs-ecs --template={{.data.this_public_ip}} | base64 --decode
```


### Compose Terraform Resource in Workflow

1. Read ECS installation script from URL and mount it with the Terraform Controller.