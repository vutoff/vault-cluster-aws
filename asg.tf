resource "aws_launch_configuration" "launch_config" {
  name_prefix          = "alc-${var.service_vars["service_name"]}-${var.main_vars["env"]}-"
  image_id             = "${var.ami_id}"
  instance_type        = "${var.service_vars["instance_type"]}"
  iam_instance_profile = "${aws_iam_instance_profile.generic.id}"
  enable_monitoring    = true
  key_name             = "${var.key_name}"
  security_groups      = ["${var.security_groups}"]
  user_data            = "${data.template_file.vault.rendered}"
  ebs_optimized        = "${lookup(var.service_vars, "ebs_optimized", "false")}"

  root_block_device {
    volume_size = "${var.service_vars["instance_storage"]}"
    volume_type = "gp2"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "main_asg" {
  depends_on                = ["aws_launch_configuration.launch_config"]
  name_prefix               = "asg-${var.service_vars["service_name"]}-${var.main_vars["env"]}-"
  availability_zones        = ["${var.network_vars["availability_zones"]}"]
  vpc_zone_identifier       = ["${var.private_subnet_ids}"]
  launch_configuration      = "${aws_launch_configuration.launch_config.id}"
  max_size                  = "${var.service_vars["max_instances"]}"
  min_size                  = "${var.service_vars["min_instances"]}"
  desired_capacity          = "${var.service_vars["min_instances"]}"
  health_check_grace_period = 15
  health_check_type         = "EC2"
  load_balancers            = ["${aws_elb.elb.name}"]
  termination_policies      = ["OldestInstance"]

  tag {
    key                 = "Name"
    value               = "${var.service_vars["service_name"]}-${var.main_vars["env"]}"
    propagate_at_launch = true
  }
}
