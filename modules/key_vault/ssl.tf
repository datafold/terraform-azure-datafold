# Creates a private key in PEM format
resource "tls_private_key" "private_key" {
  algorithm = "RSA"
}

# Creates an account on the ACME server using the private key and an email
resource "acme_registration" "reg" {
  account_key_pem = tls_private_key.private_key.private_key_pem
  email_address   = "nobody@datafold.com"
}

# As the certificate will be generated in PFX a password is required
resource "random_password" "cert" {
  length  = 24
  special = true
}

# Gets a certificate from the ACME server
resource "acme_certificate" "cert" {
  account_key_pem          = acme_registration.reg.account_key_pem
  common_name              = var.domain_name
  certificate_p12_password = random_password.cert.result

  dns_challenge {
    provider = "route53"

    config = {
      AWS_PROFILE = "acme"
      # [profile acme]
      # role_arn = arn:aws:iam::710753145501:role/ACMERoute53CertificateChallanger
      # source_profile = default
      # region = us-west-2
    }
  }
}