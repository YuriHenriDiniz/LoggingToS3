# Hybrid Logging Lab – Rsyslog + S3 + IAM Roles Anywhere

Projeto de laboratório simulando ambiente híbrido on-premises + AWS
com coleta centralizada de logs e arquivamento seguro no S3.

## Arquitetura

- On-prem:
  - Debian 13
  - Rsyslog
  - systemd timer para sincronização
- AWS:
  - S3 (logs + archive)
  - IAM Role
  - Trust Anchor
  - Bucket Policies

## Decisões Técnicas

As principais decisões de arquitetura estão documentadas em
[Decisions.md](Decisions.md).

Entre elas:

- Uso de IAM Roles Anywhere ao invés de Access Keys
- Uso de systemd timer ao invés de cron
- Separação de buckets para retenção e staging
