# Data classification — <intent id>

Classes: **Public**, **Internal**, **Confidential** (business data, PII), **Restricted**
(credentials, secrets, tokens). Logging follows SEC-11.

| Data element | Service / store | Class | PII | Retention | Residency | Encryption | Logging rule |
|---|---|---|---|---|---|---|---|
| <field> | <svc>.<table> | Confidential | yes/no | <period> | <region> | KMS CMK at rest, TLS | never logged / ids only / allowed |

## Flows of classified data

| From → To | Elements | Protection |
|---|---|---|
| | | |

## Non-production rule

Synthetic data only (SEC-18). Seed source: <file>.
