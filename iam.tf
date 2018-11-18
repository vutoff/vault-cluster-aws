resource "aws_iam_instance_profile" "generic" {
  name_prefix = "${var.service_vars["service_name"]}-"
  role        = "${aws_iam_role.generic.name}"

  # The below lines are due to issue https://github.com/hashicorp/terraform/issues/1885
  provisioner "local-exec" {
    command = "sleep 90"
  }
}

resource "aws_iam_role" "generic" {
  name_prefix = "${var.service_vars["service_name"]}-"
  path        = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_policy" "dynamodb" {
  name_prefix = "${var.service_vars["service_name"]}-${aws_dynamodb_table.vault.id}-"
  path        = "/"
  description = "Required permission for Vault to operate"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "dynamodb:*"
      ],
      "Effect": "Allow",
      "Resource": "${aws_dynamodb_table.vault.arn}"
    },
    {
      "Effect": "Allow",
      "Action": [
          "ssm:DescribeParameters"
      ],
      "Resource": "*"
    },
    {
      "Action": [
        "ssm:*"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:ssm:${var.main_vars["region"]}:${data.aws_caller_identity.current.account_id}:parameter/vault-*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "generic" {
  role       = "${aws_iam_role.generic.name}"
  policy_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/global-ec2-descirbe-tags-${var.main_vars["env"]}-${var.main_vars["region"]}"
}

resource "aws_iam_role_policy_attachment" "dynamodb" {
  role       = "${aws_iam_role.generic.name}"
  policy_arn = "${aws_iam_policy.dynamodb.arn}"
}
