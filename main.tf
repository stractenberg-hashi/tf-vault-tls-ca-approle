provider "vault" {}

##### PKI CA ROOT #####
# Enable the pki engine at the pki path
resource "vault_mount" "root" {
  path                      = "pki"
  type                      = "pki"
  max_lease_ttl_seconds     = 315360000 #87600h
  description = "root"
}

# Generate the root cert
resource "vault_pki_secret_backend_root_cert" "example" {
  depends_on            = [vault_mount.root]
  backend               = vault_mount.root.path
  type                  = "internal"
  common_name           = "Root CA"
  ttl                   = 315360000
  format                = "pem"
  private_key_format    = "der"
  key_type              = "rsa"
  key_bits              = 4096
  exclude_cn_from_sans  = true
  ou                    = "example.com"
  organization          = "Example Dot Com"
}

# Configure the CA and CRL URLs
resource "vault_pki_secret_backend_config_urls" "root_urls" {
  backend = vault_mount.root.path
  issuing_certificates = [
    "https://${var.server_url}:8200/v1/pki/ca",
  ]
  crl_distribution_points = [
    "https://${var.server_url}:8200/v1/pki/crl",
  ]
}

##### PKI INT CA #####
# Enable the pki engine at the pki_int path
resource "vault_mount" "intermediate" {
  path                      = "pki_int"
  type                      = "pki"
  #default_lease_ttl_seconds = 864000
  max_lease_ttl_seconds     = 157680000 #43800h
  description = "intermediate"
}

# Create a role - this is 100% identical to the Learn tutorial
resource "vault_pki_secret_backend_role" "role" {
  backend          = vault_mount.intermediate.path
  name             = "example-dot-com"
  max_ttl          = 2592000 #720h
  # key_bits         = 4096
  allowed_domains  = ["example.com"]
  allow_subdomains = true
  not_before_duration = "30s"
}

# Create CSR
resource "vault_pki_secret_backend_intermediate_cert_request" "intermediate" {
  depends_on  = [vault_mount.intermediate]
  backend     = vault_mount.intermediate.path
  type        = "internal"
  common_name = "example.com Intermediate CA"
}

# Sign the intermediate cert
resource "vault_pki_secret_backend_root_sign_intermediate" "example" {
  depends_on           = [vault_pki_secret_backend_intermediate_cert_request.intermediate]
  backend              = vault_mount.root.path
  csr                  = vault_pki_secret_backend_intermediate_cert_request.intermediate.csr
  common_name          = "example.com Intermediate Authority"
  ttl = 157680000 #43800h
}

# signed cert imported into Vault (set-signed)
resource "vault_pki_secret_backend_intermediate_set_signed" "example" {
  backend     = vault_mount.intermediate.path
  certificate = vault_pki_secret_backend_root_sign_intermediate.example.certificate
}

########################################################################################################################################################
# Create Vault Policy to get PKI certs
resource "vault_policy" "pki" {
  name = "pki"

  policy = <<EOT
path "pki_int/issue/example-dot-com" {
  capabilities = [ "update" ]
}
EOT
}

# Enable Approle Auth 
resource "vault_auth_backend" "approle" {
  type = "approle"
}

# Create Approle Role
resource "vault_approle_auth_backend_role" "example" {
  backend        = vault_auth_backend.approle.path
  role_name      = "pki"
  token_policies = ["pki"]
  token_max_ttl = 14400
  token_ttl = 3600
}

# Generate Secret_ID
resource "vault_approle_auth_backend_role_secret_id" "id" {
  backend   = vault_auth_backend.approle.path
  role_name = vault_approle_auth_backend_role.example.role_name
}