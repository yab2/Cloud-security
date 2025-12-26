"""
Lambda Function: Security Alert Enrichment
Phase 4 - Alert Delivery and Enrichment

This function is triggered by SNS notifications from CloudWatch Alarms.
It enriches security alerts with contextual information including:
- Source IP address extraction
- Geolocation approximation
- Alert severity classification
- Recommended response actions

The function logs enriched alerts to CloudWatch Logs for audit and analysis.
"""

import json
import re
import urllib.request
import urllib.error
from datetime import datetime


def lambda_handler(event, context):
    """
    Main Lambda handler function.

    Args:
        event: SNS event containing CloudWatch Alarm notification
        context: Lambda context object

    Returns:
        dict: Response with status code and enriched alert data
    """
    print(f"[INFO] Alert enrichment function triggered at {datetime.utcnow().isoformat()}Z")

    try:
        # Parse SNS message
        sns_message = json.loads(event['Records'][0]['Sns']['Message'])

        # Extract alarm details
        alarm_name = sns_message.get('AlarmName', 'Unknown')
        alarm_description = sns_message.get('AlarmDescription', 'No description')
        new_state_value = sns_message.get('NewStateValue', 'UNKNOWN')
        new_state_reason = sns_message.get('NewStateReason', '')
        timestamp = sns_message.get('StateChangeTime', datetime.utcnow().isoformat())

        print(f"[INFO] Processing alarm: {alarm_name}")
        print(f"[INFO] Alarm state: {new_state_value}")

        # Extract IP addresses from alarm reason
        ip_addresses = extract_ip_addresses(new_state_reason)

        # Determine detection type and severity
        detection_type = classify_detection_type(alarm_name)
        severity = determine_severity(alarm_name)

        # Enrich alert with geolocation (if IPs found)
        enriched_data = {
            'timestamp': timestamp,
            'alarm_name': alarm_name,
            'alarm_description': alarm_description,
            'state': new_state_value,
            'detection_type': detection_type,
            'severity': severity,
            'source_ips': [],
            'recommendations': get_recommendations(detection_type)
        }

        # Enrich with geolocation for each IP
        for ip in ip_addresses:
            geo_info = get_ip_geolocation(ip)
            enriched_data['source_ips'].append({
                'ip': ip,
                'geolocation': geo_info
            })

        # Log enriched alert
        print(f"[ALERT] {json.dumps(enriched_data, indent=2)}")

        # Return success
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Alert enrichment completed successfully',
                'enriched_data': enriched_data
            })
        }

    except Exception as e:
        print(f"[ERROR] Failed to enrich alert: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'message': 'Alert enrichment failed',
                'error': str(e)
            })
        }


def extract_ip_addresses(text):
    """
    Extract IP addresses from text using regex.

    Args:
        text (str): Text to search for IP addresses

    Returns:
        list: List of IP addresses found
    """
    ip_pattern = r'\b(?:[0-9]{1,3}\.){3}[0-9]{1,3}\b'
    ips = re.findall(ip_pattern, text)

    # Filter out invalid IPs (e.g., 999.999.999.999)
    valid_ips = []
    for ip in ips:
        octets = ip.split('.')
        if all(0 <= int(octet) <= 255 for octet in octets):
            valid_ips.append(ip)

    return valid_ips


def classify_detection_type(alarm_name):
    """
    Classify the type of security detection based on alarm name.

    Args:
        alarm_name (str): CloudWatch alarm name

    Returns:
        str: Detection type classification
    """
    alarm_lower = alarm_name.lower()

    if 'brute-force' in alarm_lower or 'failed' in alarm_lower:
        return 'SSH Brute Force Attack'
    elif 'root-login' in alarm_lower:
        return 'Root Login Attempt'
    elif 'invalid-user' in alarm_lower or 'enumeration' in alarm_lower:
        return 'User Enumeration Attack'
    elif 'port-scan' in alarm_lower:
        return 'Port Scanning Activity'
    else:
        return 'Unknown Threat'


def determine_severity(alarm_name):
    """
    Determine severity level based on alarm name.

    Args:
        alarm_name (str): CloudWatch alarm name

    Returns:
        str: Severity level (CRITICAL, HIGH, MEDIUM, LOW)
    """
    alarm_lower = alarm_name.lower()

    if 'root-login' in alarm_lower:
        return 'CRITICAL'
    elif 'brute-force' in alarm_lower or 'port-scan' in alarm_lower:
        return 'HIGH'
    elif 'invalid-user' in alarm_lower or 'enumeration' in alarm_lower:
        return 'MEDIUM'
    else:
        return 'LOW'


def get_ip_geolocation(ip_address):
    """
    Get geolocation information for an IP address.
    Uses free ip-api.com service (no API key required, 45 requests/minute limit).

    Args:
        ip_address (str): IP address to lookup

    Returns:
        dict: Geolocation information or error message
    """
    try:
        # Skip private/internal IP addresses
        if is_private_ip(ip_address):
            return {
                'country': 'Internal/Private',
                'city': 'N/A',
                'isp': 'Private Network',
                'note': 'This is a private IP address'
            }

        # Call free geolocation API
        url = f"http://ip-api.com/json/{ip_address}?fields=status,message,country,city,isp,org,as,query"

        with urllib.request.urlopen(url, timeout=5) as response:
            data = json.loads(response.read().decode())

            if data.get('status') == 'success':
                return {
                    'country': data.get('country', 'Unknown'),
                    'city': data.get('city', 'Unknown'),
                    'isp': data.get('isp', 'Unknown'),
                    'organization': data.get('org', 'Unknown'),
                    'asn': data.get('as', 'Unknown')
                }
            else:
                return {
                    'error': data.get('message', 'Geolocation lookup failed')
                }

    except urllib.error.URLError as e:
        print(f"[WARN] Geolocation lookup failed for {ip_address}: {str(e)}")
        return {
            'error': 'Geolocation service unavailable',
            'note': 'Unable to fetch geolocation data'
        }
    except Exception as e:
        print(f"[WARN] Unexpected error during geolocation lookup: {str(e)}")
        return {
            'error': 'Geolocation lookup error'
        }


def is_private_ip(ip_address):
    """
    Check if IP address is in private range.

    Args:
        ip_address (str): IP address to check

    Returns:
        bool: True if private IP, False otherwise
    """
    octets = [int(x) for x in ip_address.split('.')]

    # Check private ranges: 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16
    if octets[0] == 10:
        return True
    if octets[0] == 172 and 16 <= octets[1] <= 31:
        return True
    if octets[0] == 192 and octets[1] == 168:
        return True
    if octets[0] == 127:  # Loopback
        return True

    return False


def get_recommendations(detection_type):
    """
    Get recommended response actions based on detection type.

    Args:
        detection_type (str): Type of security detection

    Returns:
        list: List of recommended actions
    """
    recommendations = {
        'SSH Brute Force Attack': [
            '1. Review the source IP and determine if it is legitimate',
            '2. Consider blocking the IP at Security Group or NACL level',
            '3. Verify SSH key-based authentication is enforced',
            '4. Consider implementing fail2ban or similar tools',
            '5. Review user accounts for any unauthorized access'
        ],
        'Root Login Attempt': [
            '1. IMMEDIATE ACTION REQUIRED - Root SSH should be disabled',
            '2. Verify PermitRootLogin is set to "no" in /etc/ssh/sshd_config',
            '3. Identify the source IP and block if malicious',
            '4. Review all authentication logs for suspicious activity',
            '5. Consider implementing 2FA for administrative access'
        ],
        'User Enumeration Attack': [
            '1. Review logs to identify targeted usernames',
            '2. Block source IP if confirmed malicious',
            '3. Monitor for escalation to brute force attacks',
            '4. Consider implementing rate limiting',
            '5. Review user account security policies'
        ],
        'Port Scanning Activity': [
            '1. Identify the source IP and assess threat level',
            '2. Verify Security Groups have minimum required ports open',
            '3. Consider implementing IP allowlisting for sensitive services',
            '4. Review NACL rules for additional protection',
            '5. Monitor for follow-up exploitation attempts'
        ]
    }

    return recommendations.get(detection_type, [
        '1. Review the alert details and assess severity',
        '2. Investigate logs for additional context',
        '3. Implement appropriate security controls',
        '4. Document the incident and response actions'
    ])
