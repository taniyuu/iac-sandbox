locals {
  common_tags = {
    enviroment = "develop"
  }
}

data "aws_ses_email_identity" "sender" {
  email = "ytaniyama@tance.co.jp"
}

resource "aws_cognito_user_pool" "mypool" {
  name              = "poc-taniyama-tf"
  mfa_configuration = "OFF"
  # メール属性に関する設定
  auto_verified_attributes = ["email"]
  username_attributes = [
    "email",
  ]
  email_configuration {
    email_sending_account = "DEVELOPER"
    source_arn            = data.aws_ses_email_identity.sender.arn
  }
  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
  }
  schema {
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    name                     = "email"
    required                 = true

    string_attribute_constraints {
      max_length = "2048"
      min_length = "0"
    }
  }
  # パスワードに関する設定
  password_policy {
    minimum_length                   = 8
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = true
    require_uppercase                = true
    temporary_password_validity_days = 7
  }
  # ラムダトリガ
  lambda_config {
    custom_message = aws_lambda_function.cognito_triggers.arn
  }
  username_configuration {
    case_sensitive = false
  }
  tags = local.common_tags
}

resource "aws_cognito_user_pool_client" "myclient" {
  name         = "poc-taniyama-client-tf"
  user_pool_id = aws_cognito_user_pool.mypool.id
  explicit_auth_flows = [
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_PASSWORD_AUTH",
  ]
  # oauth連携がないので以下のパラメータはOFF
  allowed_oauth_flows                  = []
  allowed_oauth_flows_user_pool_client = false
  allowed_oauth_scopes                 = []
  supported_identity_providers         = []

  # トークン有効期限
  access_token_validity  = 5
  id_token_validity      = 5
  refresh_token_validity = 60
  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "minutes"
  }

  generate_secret               = true      # client secret
  prevent_user_existence_errors = "ENABLED" # ユーザ存在エラーを隠す


  # 属性の読み書きを許可
  read_attributes = [
    "email",
    "email_verified",
    "name",
  ]
  write_attributes = [
    "email",
    "name",
  ]
}

resource "aws_iam_role" "role_cognito_triggers" {
  name = "iam_for_lambda"
  tags = local.common_tags

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "basic_policy_cognito_triggers" {
  role       = aws_iam_role.role_cognito_triggers.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Lambda binary file
data "archive_file" "cognito_triggers" {
  type        = "zip"
  source_file = "${path.module}/cognito_triggers/main"
  output_path = "${path.module}/cognito_triggers/build.zip"
}

# Lambda trigger
resource "aws_lambda_function" "cognito_triggers" {
  function_name    = "poc-cognito-trigger-taniyama-tf"
  role             = aws_iam_role.role_cognito_triggers.arn
  architectures    = ["x86_64"]
  runtime          = "go1.x"
  handler          = "main"
  filename         = data.archive_file.cognito_triggers.output_path
  source_code_hash = data.archive_file.cognito_triggers.output_base64sha256
  publish          = false
  memory_size      = 128
  timeout          = 3

  tags = local.common_tags
}

resource "aws_lambda_permission" "cognito_triggers" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cognito_triggers.arn
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = aws_cognito_user_pool.mypool.arn
}
