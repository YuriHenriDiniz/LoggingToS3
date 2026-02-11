# Dificuldades encontradas durante a realização do projeto:


## RouterOS do roteador inicializa porém para de enviar logs para o servidor sem motivo aparente.
Durante os testes percebi que quando iniciava o Roteador ele parava de enviar logs para o Rsyslog. Pelo que 

## Passar o PEM bundle através de parametro em template.

Para facilitar o deploy, pensei em criar um parâmetro para passar a string PEM do certificado através dele. Porém, acaba que não é confiável, já que, diferente do console, a API não limpa o PEM. Logo, se tiver algum caractere indevido, como espaço na string, dá erro e, mesmo que você garanta que está tudo certo, o próprio CloudFormation realiza o processamento dessa string e pode introduzir caracteres indevidos. Dessa forma, decide simplesmente passá-lo inline na template.

## Reduzir os privilegios do daemon do rsyslog.

O Rsyslog tem uma diretiva global para reduzir os privilégios após a inicialização. Dessa forma, ele roda como root apenas na inicialização e reduz seus privilégios depois. Porém, estava tendo problemas com a diretiva dropPrivUser e toda vez que configurava-a, o serviço simplesmente não iniciava. E, pelo que procurei, a documentação simplesmente não trata disso com mais detalhes do que simplesmente dizer o que a diretiva faz. Dessa forma, eu decidi não utilizar essa diretiva e forçar o drop via systemd e passar as capabilities necessárias.

## Deixar os nomes do parametros iguais aos logical ids dos recursos nos templates.

Inicialmente, quando tinha montado os templates, tinha deixado alguns parâmetros de nome de recurso iguais aos identificadores lógicos E isso acaba que dá conflito quando você utiliza a função intrínseca como ! Ref ou Fn::Ref, já que existiriam duas referências possíveis. Logo, alterei, deixando-os distintos.

## AWS CLI não conseguindo localizar o profile corretamente.

Estava com problemas em fazer com que o script logsync.sh, que faz uso do AWS CLI, usasse o profile adequado em vez de usar o default. O problema se encontrava em que você não pode colocar um nome arbitrário, senão o AWS CLI não consegue identificar a seção do perfil dentro do config, você tem que colocar [profile name], ou seja, tem que ter esse profile antes. Dessa forma, o script começou a utilizar o perfil correto.

## Usuario perdendo certos grupos quando alterado.

Enquanto configurava os grupos de um usuário, queria colocá-lo no grupo ssh_users para poder acessar o servidor via ssh e também no grupo audit_users para que pudesse ter acesso aos arquivos de log do servidor. Porém, não tinha configurado os dois na criação do usuário, logo, executei o comando usermod para poder modificar os grupos do usuário. Porém, quando testei as permissões do usuário, ele simplesmente não fazia mais parte do grupo ssh_users, ou seja, não conseguia conectar via ssh. Acabou que executei o usermod sem a flag -a, que faz com que os grupos que você passa pelo comando sejam adicionados e não redefinam o conjunto de grupos suplementares. 

## LVM detectando PV ausente.

Durante o projeto decidi adicionar mais discos virtuais para simular melhor um ambiente real. Tive que rearranjar o layout do armazenamento removendo algumas particoes/pvs que tinha criado. Porem, nesse processo acabei que removi as particoes antes de remover os PVs. Deixando o VG em questao inconsistente. Removi os PVs usando o pvremove e restaurei a consistencia do VG utilizando

## Multiplos topics em uma unica action no RouterOS.

No RouterOS, você pode configurar o logging de forma a definir quais eventos são encaminhados para o disco, para a memória, para o console e quais são encaminhados para um servidor de log remoto. Esses eventos são segmentados em tópicos e, para cada ação, você pode definir um ou mais tópicos. Porém, quando utilizei mais do que um tópico em uma mesma ação, simplesmente parou de encaminhar para o servidor de logs. Investiguei então a documentação, porém ela não diz nada sobre isso em específico. Logo, decidi simplesmente criar uma ação para cada tópico, já que os tópicos que usaria seriam apenas alguns.
