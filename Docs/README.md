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

- Execute `git clone` passando a URL deste repositorio.
- Edite o arquivo `rsyslog.conf` inserindo o IP que será utilizado.
- Execute o `logsync.sh`.
- Gere o certificado da CA e do servidor Rsyslog.
- Execute os templates cloudformation na ordem indicada abaixo:

  - `Bucket.yaml`
  - `AuditRole.yaml`
  - `RolesAnywhere.yaml`
  - `Bucket-policies.yaml`

- Modifique o config passando os caminhos corretos e os ARNs
  

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

