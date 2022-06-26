tags = {
  created_by   = "Terraform-of-KubeVela"
  created_from = "module-tf-alicloud-ecs-instance"
}
name                          = "test-terraform-vela-123"
host_name                     = "test-terraform-vela"
password                      = "Test-123456!"
internet_charge_type          = "PayByBandwidth"
internet_max_bandwidth_out    = "20"
associate_public_ip_address   = "true"
instance_charge_type          = "PostPaid"
user_data                     = ""
system_disk_category          = "cloud_efficiency"
system_disk_size              = "40"
dry_run                       = "false"
spot_strategy                 = "NoSpot"
spot_price_limit              = "0"
deletion_protection           = "false"
force_delete                  = "false"
security_enhancement_strategy = "Active"
instance_type                 = "ecs.n1.tiny"
ports                         = [8080, 9088]
