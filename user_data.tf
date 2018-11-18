data "template_file" "vault" {
  template = "${file("${path.module}/templates/init.sh")}"

  vars = {
    vault_address  = "${aws_route53_record.vault_public.fqdn}"
    aws_region     = "${var.main_vars["region"]}"
    dynamodb_table = "${aws_dynamodb_table.vault.id}"
  }
}
