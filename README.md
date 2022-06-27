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

### Enable addon for cloud resources

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

### Deploy an `frp` tunnel server within ECS

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
        user_data_url: "https://raw.githubusercontent.com/wonderflow/terraform-alicloud-ecs-instance/master/frp.sh"
        ports:
        - 8080
        - 8081
        - 8082
        - 8083
        - 9090
        - 9091
        - 9092
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

You may already see the result in `vela logs`, you can also check the output information from Terraform by:

```shell
$ kubectl get secret outputs-ecs --template={{.data.this_public_ip}} | base64 --decode
["121.196.106.174"]
```

5. In the user_data url, we already installed [frp](https://github.com/fatedier/frp) which is a fast reverse proxy to help you expose a local server behind a NAT or firewall to the internet.

You can visit the frp server admin page on port `:9091`, the `admin` password is `vela123` in the script.


### Use frp client as a sidecar trait for service

Use a sidecar to visiting app from the public IP.

```shell
cat <<EOF | vela up -f -
# YAML begins
apiVersion: core.oam.dev/v1beta1
kind: Application
metadata:
  name: vela-app-with-sidecar
spec:
  components:
    - name: web
      type: webservice
      properties:
        image: oamdev/hello-world:v2
        ports:
          - port: 8000
      traits:
        - type: sidecar
          properties:
            name: frp-client
            image: oamdev/frpc:0.43.0
            env:
              - name: server_addr
                value: "121.196.106.174"
              - name: server_port
                value: "9090"
              - name: local_port
                value: "8000"
              - name: remote_port
                value: "8082"
# YAML ends
EOF
```

Wow! Then you can visiting the webservice by:

```
curl 121.196.106.174:8082
```

You can visit any of your service with a public IP in this way!