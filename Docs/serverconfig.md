# Principais configuraçoes feitas no servidor #

## Firewall
Utilizei o nftables para criar regras de filtragem para hardening basico. Onde apenas SSH (Porta TCP 22), Rsyslog (Porta TCP e UDP 514) e ICMP (Protocolo IP 1) estão liberados para entrada. Enquanto tráfego de saida
apenas servicos essenciais como http (Porta TCP 80 e 443) para acessar os repositorios configurados, NTP (Porta UDP 123) para manter o tempo local sincronizado, DNS (Porta TCP e UDP 53) para resolver nomes de dominio.

## NTP
Utilizei o chronyd como cliente NTP. Configurei ele para utilizar tres servidores NTP locais que então sincronizam com pools de servidores externos como time.cloudflare.com, a.ntp.br e b.ntp.br. Dessa maneira com o tempo e a timezone correta tanto no servidor quanto nos clientes os logs podem entao ser correlacionados de maneira assertiva.

## Network
Utilizei o systemd-networkd para configurar a interface de rede usando arquivos de configuração .link e .network. Configuração estatica simples incluindo IP estático, Gateway e nome adequado para a interface. Assim desse forma as configuraçoes de rede persistem entre reinicializaçoes.

## SSH
O SSH foi configurado de forma segura usando configurações como: impedir login como root, impedir autenticacao por senha, apenas permitir acesso de usuarios do grupo ssh_users, desabilitar fowarding, limitar numero de sessoes por usuario, numero maximo de tentativas de autenticacao, etc.

## Journald
O journald e o coletor de logs padrao nas distros que utilizam systemd. Nesse caso o nosso coletor seria o Rsyslog, entao configurei o journald apenas como relay onde ele nao armazena nenhum log de forma persistente.
Apenas faz o fowarding para o Rsyslog atraves do modulo imuxsock.

## MTA
Instalei o msmtp para enviar emails de alerta usando gmail como relay smtp. Para simplicidade utilizei uma conta gmail minha usando app-password para autenticar o servidor. O unattended-upgrades por exemplo, caso ocorra um erro no processo de instalação das atualizaçoes de segurança me notifica atraves desse meu email.

## PackageManager
Configurei o sources.list do apt para utilizar apenas pacotes das suites trixie, trixie-updates e trixie-security. Usando explicitamente trixie ao inves de stable para fixar a release e evitar upgrade automatico de release. Dessas suites apenas pacotes dos componentes main e non-free firmware sao considerados. E para upgrades automaticos que sao muito importantes no caso de updates de seguranca para corrigir vulnerabilidades utilizei o unattended-upgrades para atualizar o sistema automaticamente de acordo com novas atualizacoes de seguranca.

## Kernel
Customizei alguns parametros do kernel por questoes de seguranca. Desativando funcoes como fowarding e ativando protecoes como icmp-request/icmp-reply como broadcast (Smurf Attack), protecoes contra tcp syn-flood, verficacao de origem para evitar IP spoofing, verificacao de arquivos word-writable, desabilitar ipv6 já que não estou utilizando no lab, etc.

## Storage
Como os logs vao ser armazenados localmente por um periodo. Separei /, /boot e /var por seguranca, principalmente caso o /var fique cheio e haja corrupcao do sistema de arquivos protegendo assim arquivos essenciais do sistema e protegendo o processo de boot. Alem de utilizar LVM por questoes de flexibilidade pensando em expansoes futuras com a possibilidade de expandir LVs (Logical Volumes) para multiplos discos, ou pensando em cenarios de troca de discos utilizando a movimentacao online de extends entre PVs.
