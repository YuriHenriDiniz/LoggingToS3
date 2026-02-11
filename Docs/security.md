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

##
