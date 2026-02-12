# Hybrid Logging Lab – Rsyslog + S3 + IAM Roles Anywhere

Projeto educacional de laboratório simulando ambiente híbrido on-premises + AWS
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
Para melhor entendimento da arquitetura veja o [diagrama de arquitetura]](architecture.jpg).

## Objetivo

O objetivo desse projeto é configurar, simular e documentar um ambiente onde logs são, através de um servidor de logs, coletados, organizados e retidos localmente e posteriormente enviados para buckets do Amazon S3. Tendo uma política de retenção local e de arquivamento definida conforme questões de criticidade, utilidade e volume. O projeto inclui um script de deploy e também templates CloudFormation que recriam o ambiente para quem quiser testar.

## Tecnologias utilizadas
- Amazon S3 Standard, Infrequent Access (IA) e Glacier Archive
- Rsyslog
- NXLog
- OpenSSL
- Amazon Identity and Access Management (IAM)
- Roles Anywhere
- Debian (systemd, nftables, OpenSSH, etc)
- Hyper-V
- CloudFormation

## Deploy

### Considerações:

O projeto foi realizado utilizando Debian 13 Trixie e o aws_signing_helper presente no repositório foi compilado para essa versão. O binário já está compilado aqui por conveniência, porém, caso encontre algum problema, recomendo acessar o repositório [Oficial](https://github.com/aws/rolesanywhere-credential-helper/tree/main) e realizar o build no seu ambiente.

### Passo a passo:

- Execute `git clone` passando a URL deste repositório.
- Edite o arquivo `rsyslog.conf` inserindo o IP que será utilizado.
- Execute o `logsync.sh`.
- Gere o certificado da CA e do servidor Rsyslog.
- Execute os templates CloudFormation na ordem indicada abaixo:

  1. `Bucket.yaml`
  2. `AuditRole.yaml`
  3. `RolesAnywhere.yaml`
  4. `Bucket-policies.yaml`

- Modifique o `config` passando os caminhos corretos e os ARNs.

## Decisões Técnicas

As principais decisões de arquitetura estão documentadas em
[Decisions.md](Decisions.md).

Entre elas:

- Uso de IAM Roles Anywhere ao invés de Access Keys
- Uso de systemd timer ao invés de cron
- Separação de buckets para retenção e staging

## Troubleshooting

Erros reais encontrados durante o desenvolvimento estão documentados em
[troubleshooting.md](troubleshooting.md).

## Segurança

Decisões em relação à segurança tomadas durante o desenvolvimento estão documentadas em
[Security.md](Security.md).

## Referências

- AWS IAM Roles Anywhere – documentação oficial (https://docs.aws.amazon.com/rolesanywhere/)
- Rsyslog Documentation – documentação oficial (https://www.rsyslog.com/doc/index.html)
- RFC 5424 – The Syslog Protocol (https://datatracker.ietf.org/doc/html/rfc5424)
- RouterOS Documentation - documentação oficial (https://help.mikrotik.com/docs/spaces/ROS/pages/328119/Getting+started)
- NXLog Community Edition Reference Manual - manual da comunidade (https://docs.nxlog.co/ce/current/index.html)
