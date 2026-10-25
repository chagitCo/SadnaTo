# Threat model — <scope>

- **Version / date:** <n> / <YYYY-MM-DD>
- **Inputs:** <stories>, <data-classification.md>, <logical-design.md>
- **Reviewer:** `security-reviewer` + <human>

## Data-flow diagram

```mermaid
flowchart LR
  U[Browser] -- TB1 HTTPS --> CF[CloudFront + WAF]
  CF -- TB2 --> APIGW[API Gateway + WAF]
  APIGW -- VPC link --> SVC[<service>]
  SVC -- TB3 TLS --> DB[(<svc> DB)]
  SVC -- TB4 --> SNS[(SNS topic)]
```

## Trust boundaries

| ID | Boundary | Crossing flows |
|---|---|---|
| TB1 | Internet ↔ edge | <…> |

## Threats (STRIDE)

| ID | STRIDE | Element / flow | Threat | Asset | Risk (H/M/L) | Mitigation (rule IDs / ADRs) | Test / evidence | Residual |
|---|---|---|---|---|---|---|---|---|
| T1 | S | <…> | <…> | <…> | | | | |

## Residual risks for acceptance

| Threat | Residual | Proposed owner | Accepted by / date |
|---|---|---|---|
| | | | pending |

## Changes since previous version

- <…>
