# Principais configuraçoes feitas no servidor #

## Firewall
Utilizei o nftables para criar regras de filtragem para hardening básico Onde apenas SSH (Porta TCP 22), Rsyslog (Porta TCP e UDP 514) e ICMP (Protocolo IP 1) estão liberados para entrada. Enquanto tráfego de saída, apenas serviços essenciais como http (Porta TCP 80 e 443) para acessar os repositórios configurados, NTP (Porta UDP 123) para manter o tempo local sincronizado, DNS (Porta TCP e UDP 53) para resolver nomes de domínio.

## NTP
Utilizei o chronyd como cliente NTP. Configurei-o para utilizar três servidores NTP locais que então sincronizam com pools de servidores externos como time.cloudflare.com, a.ntp.br e b.ntp.br. Dessa maneira, com o tempo e a timezone correta tanto no servidor quanto nos clientes, os logs podem então ser correlacionados de maneira assertiva.

## Network
Utilizei o systemd-networkd para configurar a interface de rede usando arquivos de configuração .link e .network. Configuração estática simples incluindo IP estático, Gateway e nome adequado para a interface. Assim, dessa forma, as configurações de rede persistem entre reinicializações.

## SSH
O SSH foi configurado de forma segura usando configurações como: impedir login como root, impedir autenticação por senha, apenas permitir acesso de usuários do grupo ssh_users, desabilitar forwarding, limitar número de sessões por usuário, número máximo de tentativas de autenticação, etc.

## Journald
O journald é o coletor de logs padrão nas distros que utilizam systemd. Nesse caso, o nosso coletor seria o Rsyslog, então configurei o journald apenas como relay, onde ele não armazena nenhum log de forma persistente. Apenas faz o forwarding para o Rsyslog através do módulo imuxsock.

## MTA
Instalei o msmtp para enviar e-mails de alerta usando o Gmail como relay SMTP para simplicidade, utilizei uma conta Gmail minha usando app-password para autenticar o servidor. O unattended-upgrades, por exemplo, caso ocorra um erro no processo de instalação das atualizações de segurança, me notifica através desse meu email.

## PackageManager
Configurei o sources.list do apt para utilizar apenas pacotes das suites trixie, trixie-updates e trixie-security. Usando explicitamente trixie ao invés de stable para fixar a release e evitar upgrade automático de release. Dessas suítes, apenas pacotes dos componentes main e non-free firmware são considerados. E para upgrades automáticos, que são muito importantes no caso de updates de segurança para corrigir vulnerabilidades, utilizei o unattended-upgrades para atualizar o sistema automaticamente de acordo com novas atualizações de segurança.

## Kernel
Customizei alguns parâmetros do kernel por questões de segurança desativando funções como forwarding e ativando proteções como icmp-request/icmp-reply como broadcast (Smurf Attack), proteções contra tcp syn-flood, verificação de origem para evitar IP spoofing, verificação de arquivos word-writable, desabilitar ipv6 já que não estou utilizando no lab, etc.

## Storage
Como os logs vão ser armazenados localmente por um período Separei /, /boot e /var por segurança, principalmente caso o /var fique cheio e haja corrupção do sistema de arquivos, protegendo assim arquivos essenciais do sistema e protegendo o processo de boot. Além de utilizar LVM por questões de flexibilidade, pensando em expansões futuras com a possibilidade de expandir LVs (Logical Volumes) para múltiplos discos, ou pensando em cenários de troca de discos utilizando a movimentação online de extends entre PVs.
