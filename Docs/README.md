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

## Objetivo

O objetivo desse projeto é configurar, simular e documentar um ambiente onde logs são, atraves de um servidor de logs,
coletados, organizados e retidos localmente e posteriormente enviados para buckets do amazon s3. Tendo uma
politica de retenção local e de arquivamento definida conforme questoes de criticidade, utilidade e volume.
O projeto inclui um script de deploy e tambem templates cloudformation que recriam o ambiente para quem quiser
testar.

## Tecnologias utilizadas

## Deploy

Inicialmente clone o repositorio com git clone

## Decisões Técnicas

As principais decisões de arquitetura estão documentadas em
[Decisions.md](Decisions.md).

Entre elas:

- Uso de IAM Roles Anywhere ao invés de Access Keys
- Uso de systemd timer ao invés de cron
- Separação de buckets para retenção e staging

## Troubleshooting

## Segurança

## Referências

