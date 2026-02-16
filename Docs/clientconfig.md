# Visão de geral da configuração dos clientes:

## MikroTik RouterOS

A configuracao do roteador foi bem simples, subi a maquina virtual na rede virtual correta e configurei a interface de rede com um IP estatico. Criei o usuario que iria utilizar, e importei a minha chave publica vinculada a
este usuario. Apos, isso criou uma nova action para mandar os logs para o servidor Rsyslog selecionando apenas os topicos genericos: critical, warning, error e info. Existem mais 3 desses: debug nao envio para o servidor, packet
e raw registram o conteudo dos pacotes que chegam no roteador. Por questao de carga e volume nao seria adequado enviar esses logs para o servidor. Esse conjunto de topicos genericos ja casa com todas as mensagens, nao tem porque configurar
topico a topico ja que a organizacao dos logs vive no servidor. E obviamente a timezone correta e os servidoes NTP foram configurados para garantir coerencia temporal.

## Windows

Na configuracao do windows foi mais simples. Instalei o agente NXLog e configurei ele para enviar logs para o servidor Rsyslog usando um modulo que coleta logs do EventViewer atraves de queries. Ai depois de coletadas o modulo
de extensao XXXXX permite converter o formato em mensagens syslog, assim mandando no formato correto para o servidor.
