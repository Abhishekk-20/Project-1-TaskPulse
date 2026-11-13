resource "random_id" "cognito_domain" {
  byte_length = 4
}

resource "aws_cognito_user_pool" "taskpulse" {
  name                     = "taskpulse-users"
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]
  mfa_configuration        = "ON"

  software_token_mfa_configuration {
    enabled = true
  }

  password_policy {
    minimum_length                   = 12
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = true
    require_uppercase                = true
    temporary_password_validity_days = 1
  }

  admin_create_user_config {
    allow_admin_create_user_only = true
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  tags = {
    Name = "taskpulse-users"
  }
}

resource "aws_cognito_user_pool_domain" "taskpulse" {
  domain       = "taskpulse-${random_id.cognito_domain.hex}"
  user_pool_id = aws_cognito_user_pool.taskpulse.id
}

resource "aws_cognito_user_pool_client" "taskpulse_alb" {
  name                                 = "taskpulse-alb"
  user_pool_id                         = aws_cognito_user_pool.taskpulse.id
  generate_secret                      = true
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["openid", "email"]
  supported_identity_providers         = ["COGNITO"]
  callback_urls                        = ["https://taskpulse.smokebyte.space/oauth2/idpresponse"]
  logout_urls                          = ["https://taskpulse.smokebyte.space/"]
  prevent_user_existence_errors        = "ENABLED"
  access_token_validity                = 15
  id_token_validity                    = 15
  refresh_token_validity               = 1

  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }
}
