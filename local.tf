locals {
  subscription = var.instance_charge_type == "PostPaid" ? {} : var.subscription
  # compatible with old parametes instance_tags and disk_tags
  instance_tags      = var.tags
  volume_tags        = var.volume_tags
  name               = var.name
  security_group_ids = var.security_group_ids
}
