data "aws_caller_identity" "current" {}

############################################
#                  SNS                     #
############################################
resource "aws_sns_topic" "cloudwatch_investigation_notifications" {
  name = "${var.product}-cloudwatch-investigation-notifications"
  tags = var.tags
}

resource "aws_sns_topic_policy" "cloudwatch_investigation_notifications_policy" {
  arn = aws_sns_topic.cloudwatch_investigation_notifications.arn

  policy = jsonencode({
    Version = "2008-10-17",
    Id      = "__default_policy_ID",
    Statement = [
      {
        Sid      = "__default_statement_ID",
        Effect   = "Allow",
        Principal = {
          Service = "aiops.amazonaws.com"
        },
        Action = [
          "SNS:Publish",
          "SNS:SetTopicAttributes",
          "SNS:ListSubscriptionsByTopic",
          "SNS:GetTopicAttributes",
          "SNS:Subscribe"
        ],
        Resource  = aws_sns_topic.cloudwatch_investigation_notifications.arn,
        Condition = {
          StringEquals = {
            "AWS:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

resource "aws_sns_topic_subscription" "cloudwatch_investigation_notifications" {
  endpoint               = "https://global.sns-api.chatbot.amazonaws.com"
  endpoint_auto_confirms = true
  protocol               = "https"
  topic_arn              = aws_sns_topic.cloudwatch_investigation_notifications.arn
}

############################################
#               AWS Chatbot                #
############################################
resource "aws_iam_role" "chatbot_slack_notifications" {
  name = "${var.product}-chatbot-slack-notifications-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "chatbot.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "chatbot_cloudwatch_read_access" {
  name = "chatbot-cloudwatch-read-access"
  role = aws_iam_role.chatbot_slack_notifications.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "cloudwatch:Describe*",
          "cloudwatch:Get*",
          "cloudwatch:List*"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "chatbot_q_developer_access" {
  role       = aws_iam_role.chatbot_slack_notifications.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonQDeveloperAccess"
}

resource "aws_iam_role_policy_attachment" "chatbot_aiops_access" {
  role       = aws_iam_role.chatbot_slack_notifications.name
  policy_arn = "arn:aws:iam::aws:policy/AIOpsOperatorAccess"
}

resource "aws_chatbot_slack_channel_configuration" "cloudwatch_investigation_notifications" {
  configuration_name                = "${var.product}-cloudwatch-alarm-notifications-slack"
  slack_team_id  = var.cw_investigation_notifications.slack_workspace_id
  slack_channel_id    = var.cw_investigation_notifications.slack_channel_id
  sns_topic_arns      = [aws_sns_topic.cloudwatch_investigation_notifications.arn]
  logging_level       = "ERROR"
  iam_role_arn        = aws_iam_role.chatbot_slack_notifications.arn
}

