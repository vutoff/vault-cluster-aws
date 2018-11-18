resource "aws_route53_record" "vault_public" {
  count   = "${var.public_zone_id != "" ? 1 : 0}"
  zone_id = "${var.public_zone_id}"
  name    = "vault"
  type    = "A"

  alias {
    name                   = "${aws_elb.elb.dns_name}"
    zone_id                = "${aws_elb.elb.zone_id}"
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "vault_private" {
  count   = "${var.private_zone_id != "" ? 1 : 0}"
  zone_id = "${var.private_zone_id}"
  name    = "vault"
  type    = "A"

  alias {
    name                   = "${aws_elb.elb.dns_name}"
    zone_id                = "${aws_elb.elb.zone_id}"
    evaluate_target_health = false
  }
}
