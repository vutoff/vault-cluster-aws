#!/bin/bash

groupadd vault
useradd -g vault -d/opt/vault vault
apt-get update && apt-get -y install unzip python-pip jq && pip install awscli
mkdir -p /opt/vault/bin /opt/vault/conf /opt/vault/data
curl --output /tmp/vault.zip https://releases.hashicorp.com/vault/0.11.4/vault_0.11.4_linux_amd64.zip
unzip /tmp/vault.zip -d /opt/vault/bin
rm -f /tmp/vault.zip
chown -R vault:vault /opt/vault

# Vault config file
touch /opt/vault/conf/vault.hcl

cat <<EOF > /opt/vault/conf/vault.hcl
api_addr = "https://${vault_address}:8200/"
ui = true

storage "dynamodb" {
  ha_enabled = "true"
  region = "${aws_region}"
  table = "${dynamodb_table}"
}

listener "tcp" {
  address = "0.0.0.0:8200"
  tls_disable = 1
  cluster_address = "0.0.0.0:8201"
}
disable_mlock = true
EOF

# Vault auto unsealing
touch /opt/vault/bin/post_start
cat <<'EOF' >/opt/vault/bin/post_start
#!/bin/bash
key=$$(aws --region=${aws_region} ssm get-parameter --name vault-${vault_address}-key --with-decryption |jq .Parameter.Value | tr -d \")
if [ ! -z $key ]; then
  /opt/vault/bin/vault \
    operator unseal \
    -address=http://localhost:8200 \
    $$key
fi
EOF
chmod +x /opt/vault/bin/post_start

#Setup systemd Unit file
touch /etc/systemd/system/vault.service
cat <<EOF > /etc/systemd/system/vault.service
[Unit]
Description=vault Agent
Requires=network-online.target
After=network-online.target

[Service]
Environment="GOMAXPROCS=`nproc`"
Environment=VAULT_ADDR=http://localhost:8200
Restart=on-failure
User=vault
Group=vault
PermissionsStartOnly=true
ExecStartPre=/sbin/setcap CAP_NET_BIND_SERVICE=+eip /opt/vault/bin/vault
ExecStart=/opt/vault/bin/vault server -config=/opt/vault/conf/vault.hcl
ExecStartPost=/bin/sleep 3
ExecStartPost=/opt/vault/bin/post_start > /dev/null
ExecReload=/bin/kill -HUP $MAINPID
KillSignal=SIGINT

[Install]
WantedBy=multi-user.target
EOF

systemctl enable vault.service
systemctl start vault.service

# Initialize vault
INITIALIZED=$(curl --silent  http://127.0.0.1:8200/v1/sys/init |jq .initialized)
if [ $INITIALIZED == 'false' ]; then
  curl \
      --silent \
      --request PUT \
      --data '{"secret_shares": 1, "secret_threshold": 1}' \
      http://localhost:8200/v1/sys/init | tee \
      >(jq -r .root_token > /tmp/root_token) \
      >(jq -r .keys[0] > /tmp/key)
  aws --region=${aws_region} ssm \
    put-parameter \
    --name vault-${vault_address}-key \
    --type "SecureString" \
    --value $$(cat /tmp/key)
  aws --region=${aws_region} ssm \
    put-parameter \
    --name vault-${vault_address}-root-token \
    --type "SecureString" \
    --value $$(cat /tmp/root_token)
fi
# Unseal
/opt/vault/bin/post_start > /dev/null
