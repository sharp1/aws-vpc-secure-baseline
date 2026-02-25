
# Troubleshooting SSM (Session Manager) Connectivity

This repo manages EC2 instances using **AWS Systems Manager (SSM Session Manager)**.  
If an instance shows **Offline / Not connected**, use this quick checklist.

## Quick mental model
SSM requires **three things**:

1) **Agent** running (`amazon-ssm-agent`)
2) **IAM** instance profile credentials (via **IMDSv2**)
3) **Network** access to SSM over **HTTPS (TCP/443)**  
   - In this baseline, private instances use **VPC interface endpoints** with **Private DNS enabled**.

---

## Check 1 — Agent is running

### Amazon Linux (AL2/AL2023)
```bash
sudo systemctl status amazon-ssm-agent --no-pager
sudo systemctl enable --now amazon-ssm-agent
````

### Logs (most useful)

```bash
sudo tail -n 120 /var/log/amazon/ssm/amazon-ssm-agent.log
```

Common hints in logs:

* `no EC2 instance role found` → IAM instance profile missing or IMDS blocked
* `send request failed` / timeouts → network path blocked (endpoints/SG/NACL/DNS)
* `AccessDenied` → IAM policy missing permissions

---

## Check 2 — IAM role credentials via IMDSv2

> If IMDSv2 is required, you must fetch a token first.

### Fetch IMDSv2 token

```bash
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
echo "TOKEN_len=${#TOKEN}"
```

Expected: `TOKEN_len` > 0

### Confirm instance profile role name

```bash
ROLE=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  "http://169.254.169.254/latest/meta-data/iam/security-credentials/")
echo "ROLE=$ROLE"
```

Expected: a role name (e.g., `aws-vpc-secure-baseline-SSMInstanceRole`)

### Confirm credentials JSON is returned

```bash
curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  "http://169.254.169.254/latest/meta-data/iam/security-credentials/$ROLE" | head -n 30
```

Expected keys include:

* `Code : "Success"`
* `AccessKeyId`
* `Token`
* `Expiration`

If role/creds are missing:

* attach the EC2 **instance profile** with `AmazonSSMManagedInstanceCore`
* ensure EC2 **metadata service is enabled**

---

## Check 3 — DNS + HTTPS connectivity to SSM endpoints

In this baseline, **Private DNS is enabled** on the SSM interface endpoints, so AWS service hostnames should resolve to **private IPs** (endpoint ENIs).

### DNS resolution

```bash
getent hosts ssm.us-east-1.amazonaws.com
getent hosts ec2messages.us-east-1.amazonaws.com
getent hosts ssmmessages.us-east-1.amazonaws.com
```

Expected: RFC1918 addresses (e.g., `172.16.x.x`) when using VPC endpoints + Private DNS.

### HTTPS connectivity (TCP/443)

```bash
curl -I --max-time 8 https://ssm.us-east-1.amazonaws.com
curl -I --max-time 8 https://ec2messages.us-east-1.amazonaws.com
curl -I --max-time 8 https://ssmmessages.us-east-1.amazonaws.com
```

**Important:** A non-200 response is still a success here.

* ✅ **400 / 403 / 404 is OK** → you reached the endpoint over HTTPS
* ❌ **timeout** → network path blocked

If you see timeouts:

* confirm the **VPC endpoint security group** allows inbound **TCP/443** from the instance’s security group
* confirm route tables/NACLs allow traffic between instance subnets and endpoint ENIs
* confirm you created all three interface endpoints: `ssm`, `ssmmessages`, `ec2messages`

---

## Last resort — reset local SSM registration state

If IAM + network are correct but the instance remains Offline, re-register the agent:

```bash
sudo systemctl stop amazon-ssm-agent
sudo rm -rf /var/lib/amazon/ssm/*
sudo rm -rf /var/lib/amazon/ssm-agent/*
sudo systemctl start amazon-ssm-agent
sudo tail -n 120 /var/log/amazon/ssm/amazon-ssm-agent.log
```

---

## Security note

Do not paste IMDS credential output into tickets or chats. Treat `AccessKeyId`, `SecretAccessKey`, and `Token` as sensitive.

````



