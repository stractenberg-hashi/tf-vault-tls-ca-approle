# tf-vault-tls-ca-approle
Configures Vault PKI and Approle for TLS certs

**This is code is for testing/learning purposes only and NOT to be used in Production.**

This code builds out the same infrastructure as explained in the Hashicorp Vault Tutorial "Build Your Own Certificate Authority (CA)" (steps 1-3) found here:

https://web.archive.org/web/20220420032735/https://learn.hashicorp.com/tutorials/vault/pki-engine?in=vault/secrets-management#step-1-generate-root-ca

Then it adds the Approle auth method and role necessary for servers running Vault Agent to obtain a TLS cert.

Before running `terraform plan` or `terraform apply`: export the following VAULT environment variables:

export VAULT_ADDR=""
export VAULT_CACERT=""
export VAULT_TLS_SERVER_NAME=""
export VAULT_TOKEN=""
