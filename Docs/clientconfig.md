# Visão de geral da configuração dos clientes:

## MikroTik RouterOS
A configuração do roteador foi bem simples, subi a máquina virtual na rede virtual correta e configurei a interface de rede com um IP estático. Criei o usuário que iria utilizar, importei a minha chave pública e vinculei a ele. Após isso, criei uma nova ação para mandar os logs para o servidor Rsyslog, selecionando apenas os tópicos genéricos: critical, warning, error e info. Existem mais 3 desses, porém: debug não envio para o servidor, packet e raw registram o conteúdo dos pacotes que chegam no roteador. Por questão de carga e volume, não seria adequado enviar esses logs para o servidor. Esse conjunto de tópicos genéricos já casa com todas as mensagens, não tem por que configurar tópico a tópico, já que a organização dos logs vive no servidor. E, obviamente, a timezone correta e os servidores NTP foram configurados para garantir coerência temporal.

## Windows
Na configuracao do windows foi mais simples. Instalei o agente NXLog e configurei ele para enviar logs para o servidor Rsyslog usando o modulo im_msvistalog que coleta logs do EventViewer atraves de queries. Ai depois de coletadas o modulo de extensao xm_syslog permite converter o formato em mensagens syslog, assim mandando no formato correto para o servidor.
