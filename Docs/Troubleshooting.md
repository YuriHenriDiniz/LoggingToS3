# Dificuldades encontradas durante a realização do projeto:

1- RouterOS do roteador inicializa porém para de enviar logs para o servidor sem motivo aparente.
Durante os testes percebi que quando iniciava o Roteador ele parava de enviar logs para o Rsyslog. Pelo que 

2- Passar o PEM bundle através de parametro em template.

Para facilitar o deploy pensei em criar um parametro para passar a string PEM do certificado atraves dele. Porem, acaba que nao e confiavel ja que diferente
do console a api nao limpa o PEM logo se tiver algum caractere indevido como espaco na string da erro e mesmo que voce garanta que esta tudo certo o proprio cloudformation realiza o processamento
dessa string e pode introduzir caracteres indevidos. Dessa forma decide simplesmente passa-lo inline na template.

3- Reduzir os privilegios do daemon do rsyslog.

O Rsyslog tem uma diretiva global para reduzir os privilegios apos a inicialização. Dessa forma ele roda como root apenas na inicialização e reduz seus privilegios.
Porém estava tendo problemas com a diretiva dropPrivUser e toda vez que configurava ela o serviço simplesmente não iniciava. E pelo que procurei a documentação simplesmente não
trata disso com mais detalhes do que simplesmente dizer o que a diretiva faz. Dessa fora eu decide não utilizar essa diretiva e forçar o drop via systemd e passar as capabilities necessarias.

4- Deixar os nomes do parametros iguais aos logical ids dos recursos nos templates.

Inicialmente quanto tinha montado os templates tinha deixado alguns parametros de nome de recurso iguais aos identificadores logicos. E isso acaba que da comflito quando voce utiliza a função intrinsica como
!Ref ou Fn::Ref ja que existiriam duas referencias possiveis. Logo, alterei deixando-os distintos.

5- AWS CLI não conseguindo localizar o profile corretamente.

Estava com problemas me fazer com que o script logsync.sh que faz uso do aws cli usasse o profile adequado ao inves de usar o default. O problema se encontrava em que voce nao pode colocar um nome arbitrario se nao
o aws cli nao consegue identificar a secao do perfil dentro do config, voce tem que colocar [profile name] ou seja tem que ter esse profile antes. Dessa forma o script comecou a utilizar o perfil correto.

6- Usuario perdendo certos grupos quando alterado.

Enquanto configurava os grupos de um usuario queria coloca-lo no grupo ssh_users para poder acessar o servidor via ssh e tambem no grupo audit_users para que pudesse ter acesso aos arquivos de log do servidor.
Porem nao tinha configurado os dois na criacao do usuario logo executei o comando usermod para poder modificar os grupos do usuario. Porem, quando testei as permissoes do usuario ele simplesmente nao fazia mais parte
do grupo ssh_users ou seja nao conseguia conectar via ssh. Acabou que executei o usermod sei a flag -a que faz com que os grupos que voce passa pelo comando sao adicionados e nao redefinem o conjunto de grupos suplementares. 

7- LVM detectando PV ausente.

Durante o projeto decidi adicionar mais discos virtuais para simular melhor um ambiente real. Tive que rearranjar o layout do armazenamento removendo algumas particoes/pvs que tinha criado. Porem, nesse processo acabei que removi as particoes antes de remover os PVs. Deixando o VG em questao inconsistente. Removi os PVs usando o pvremove e restaurei a consistencia do VG utilizando

8- Multiplos topics em uma unica action no RouterOS.

No RouterOS voce para configura logging de forma a definir quais eventos sao encaminhados para o disco, quais ficam apenas no buffer da memoria, quais vao para o console e quais sao encaminhados para um servidor de log remoto. Esse eventos sao divididos em Topics e para cada Action voce pode definir um ou mais Topics, porem quando utilizei mais do que um topic em uma mesma action simplesmente parou de encaminhar para o servidor de logs, investiguei entao a documentacao porem ela nao diz nada sobre isso em especifico, logo decide simplesmente criar uma action para cada topics ja que os topics que usaria seriam apenas alguns.
