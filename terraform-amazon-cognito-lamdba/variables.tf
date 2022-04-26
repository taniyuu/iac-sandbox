variable "email_sender_address" {
  type        = string
  description = "SESから送信する送信元メールアドレス"
}

variable "user_pool_name" {
  type        = string
  description = "Cognitoのユーザプールの名前"
}

