
# Start the CloudWatch agent
cat << EOF > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
{
  "agent": {
    "run_as_user": "root"
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/ecs/nginx/*.log",
            "log_group_name": "${log_group_name}",
            "log_stream_name": "{instance_id}-nginx"
          },
          {
            "file_path": "/var/log/ecs/nodejs/*.log",
            "log_group_name": "${log_group_name}",
            "log_stream_name": "{instance_id}-nodejs"
          }
        ]
      }
    }
  }
}
EOF
