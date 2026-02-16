# Principais configuraçoes feitas no servidor #

## Firewall
Utilizei o nftables para criar regras de filtragem para hardening basico. Onde apenas SSH (Porta 22), Rsyslog (Porta 514) e ICMP (Protocolo IP 1) estão liberados para entrada. Enquanto tráfego de saida
apenas servicos essenciais como http/https (Porta 80 443) para acessar os repositorios configurados, NTP (Porta 123) para manter o tempo local sincronizado, DNS (Porta 53) para resolver nomes de dominio.

## NTP
Utilizei o chronyd como cliente NTP. Configurei ele para utilizar tres servidores NTP locais que então sincronizam com pools de servidores externos como time.cloudflare.com, a.ntp.br e b.ntp.br.

## Network
Utilizei o systemd-networkd para configurar a interface de rede usando arquivos de configuração .link e .network. Configuração estatica simples incluindo IP estático, Gateway e nome adequado para a interface.

## SSH
O SSH foi configurado de forma segura usando configurações como: impedir root-login, sem autenticacao por senha, apenas permitir acesso de usuarios no grupo ssh_users, desabilitar fowarding, limitar numero de sessoes por
usuario, numero maximo de tentativas de autenticacao, etc.

## Journald
O journald e o coletor de logs padrao nas distros que utilizam systemd. Nesse caso o nosso coletor seria o Rsyslog, entao configurei o journald apenas como relay onde ele nao armazena nenhum log de forma persistente.
Apenas faz o fowarding para o Rsyslog atraves de unix socket.

## MTA
Instalei o msmtp para enviar emails de alerta usando gmail como relay smtp. Para simplicidade utilizei uma conta gmail minha usando app-password para autenticar o servidor.

## PackageManager
Configurei o sources.list do apt para utilizar apenas pacotes das suites trixie, trixie-updates e trixie-security. Usando trixie ao inves de stable para fixar a release e evitar upgrade automatico de release. Desses suites apenas pacotes dos componentes main e non-free firmware sao considerados. E para upgrades automaticos muito importantes no caso de updates de seguranca para corrigir vulnerabilidades utilizei o unattended-upgrades para atualizar o sistema automaticamente de acordo como novas atualizacoes de seguranca.

## Kernel
Customizei alguns parametros do kernel por questoes de seguranca. Desativando funcoes como fowarding, icmp-request/icmp-reply como broadcast (Smurf Attack), protecoes contra tcp syn-flood, verficacao de origem para evitar
IP spoofing, verificacao de arquivos word-writable, etc. 
