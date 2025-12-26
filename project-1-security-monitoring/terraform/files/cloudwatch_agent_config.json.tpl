{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "root",
    "logfile": "/opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log"
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/secure",
            "log_group_name": "${log_group_secure}",
            "log_stream_name": "{instance_id}/var/log/secure",
            "timestamp_format": "%b %d %H:%M:%S",
            "timezone": "UTC"
          },
          {
            "file_path": "/var/log/messages",
            "log_group_name": "${log_group_system}",
            "log_stream_name": "{instance_id}/var/log/messages",
            "timestamp_format": "%b %d %H:%M:%S",
            "timezone": "UTC"
          }
        ]
      }
    },
    "force_flush_interval": 15
  }
}
