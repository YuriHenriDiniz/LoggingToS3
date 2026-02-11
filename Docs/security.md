# Decisões de segurança


## Utilizar Bucket policies
Se tratando de um ambiente single-account não seria estritamente necessario configurar bucket policies já as politicas IAM valem para todo acesso da conta ou seja se ela ja nao permite alguma operação sobre algum recurso isso já
é o suficiente para barrar acesso indevido. Mas, se tratando de um bucket de logs resolvi reforçar a segurança com elas mesmo assim já que mesmo se alguém cometesse um erro no IAM ou seja liberando acesso da forma que não deve no 
recurso que não deve, as Bucket policies ainda bloqueariam. Além de claramente dar a possibilidade já de expansão para um ambiente multi-account como uma organização.

## Deny explicito
Como consequencia da escolha anterior, decidi entao adicionar um deny geral explicito. Porque como a ideia e continuar bloqueando mesmo se algum erro for cometido no IAM, isso seria necessario já que se o IAM permite porém a bucket
policy não diz nada a respeito ou seja não permite explicitamente nem nega explicitamente, o S3 confia no IAM da conta e pode acabar permitindo o acesso.

## IAM User vs IAM Role vs RolesAnywhere
No projeto existe uma limitação de se usar um servidor on-premisse ou seja o Rsyslog não estaria sendo executado dentro de uma instancia EC2. O problema aqui e que não da para utilizar IAM Roles nesse caso, simplesmente não é 
suportado. Inicialmente pensei em utilizar um IAM User tradicional com access-key, porém utiliza-lo não seria recomendado do ponto de vista de segurança e tambem por questoes de gerenciamento ja que não a rotação de credenciais.
Já o RolesAnywhere faz as mesmas coisas que uma IAM Role normal faz mas com um porém, permite a autenticação de servidores on-premisse, o que é perfeito para o caso apresentado nesse projeto.

## Uso da AuditRole
Configurei uma Role auditoria voltado para usuarios que realizam auditorias e precisem acessar os logs armazenados nos buckets. Obviamente, configurei as permissoes para serem limitadas a apenas leitura, sem poder realizar
qualquer tipo de alteração ferindo assim o principio da imutabilidade desses logs. O uso de roles permite credenciais temporarias o que melhora a segurnaça, alem de facilitar auditoria dos acessos, voce consegue saber qual
usuario assumiu qual role em qual momento.

## Rsyslog operando com usuário proprio
Por padrao o Rsyslog e executado como root. Porem, isso e perigoso ja que se o servico puder ser explorado emquanto executada com acesso privilegiado o impacto pode ser muito grande afetando o sistema como um todo. Agora, se 
ele operar com um usuario proprio com somente as permissoes necessarias ao seu funcionamento adequado mesmo que seja comprometido o impacto se torna bem mais restrito. Logo, o configurei com usuario proprio sem login e com as
capabilities necessarias.

## Permissoes adequadas para os arquivos/diretorios de logs
Da mesma forma que é importante proteger os logs no bucket S3, é proteger os logs locais no servidor, já que de acordo com o projeto eles passaram um periodo sendo armazenados lá. Portanto, configurei os diretorios com o ownership e as permissoes adequadas, oferencendo acesso somente ao daemon do Rsyslog, ao logsync e por fim ao grupo de auditoria. E configurei o modulo omfile para gerar arquivos com da mesma maneira ownership e permissoes adequadas.
