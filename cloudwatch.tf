resource "aws_iam_role_policy_attachment" "cw_agent_attach" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_cloudwatch_log_group" "web_app_logs" {
  name              = "/aws/ec2/project3/web-servers"
 # retention_in_days = 7

  tags = { Name = "Project-1-CloudWatch-Logs" }
}

resource "aws_cloudwatch_metric_alarm" "high_cpu_alarm" {
  alarm_name          = "project-3-web-asg-high-cpu"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "75"
  alarm_description   = "Notification when the Web Servers' CPU usage hits the red zone"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web_asg.name
  }
}