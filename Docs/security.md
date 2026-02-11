# Decisões de segurança


## Utilizar Bucket policies
Se tratando de um ambiente single-account, não seria estritamente necessário configurar bucket policies, já que as políticas IAM valem para todo acesso da conta, ou seja, se ela já não permite alguma operação sobre algum recurso, isso já é o suficiente para barrar acesso indevido. Mas, se tratando de um bucket de logs, resolvi reforçar a segurança com elas mesmo assim, já que mesmo se alguém cometesse um erro no IAM, ou seja, liberando acesso da forma que não deve no recurso que não deve, as Bucket policies ainda bloqueariam. Além de claramente dar a possibilidade já de expansão para um ambiente multi-account como uma organização.

## Deny explícito
Como consequência da escolha anterior, decidi então adicionar um deny geral explícito porque, como a ideia é continuar bloqueando mesmo se algum erro for cometido no IAM, isso seria necessário já que, se o IAM permite, porém a bucket policy não diz nada a respeito, ou seja, não permite explicitamente nem nega explicitamente, o S3 confia no IAM da conta e acaba permitindo o acesso.

## IAM User vs IAM Role vs RolesAnywhere
No projeto existe uma limitação de se utilizar um servidor on-premises, ou seja, o Rsyslog não estaria sendo executado dentro de uma instância EC2. O problema aqui é que não dá para utilizar IAM Roles nesse caso, simplesmente não é suportado. Inicialmente, pensei em utilizar um IAM User tradicional com access-key, porém utilizá-lo não seria recomendado do ponto de vista de segurança e também por questões de gerenciamento, já que não há a rotação de credenciais. Já o RolesAnywhere faz as mesmas coisas que uma IAM Role normal faz, mas com um porém: permite a autenticação de servidores on-premises, o que é perfeito para o caso apresentado nesse projeto.

## Uso da AuditRole
Configurei uma Role de auditoria voltada para usuários que realizam auditorias e precisam acessar os logs armazenados nos buckets. Obviamente, configurei as permissões para serem limitadas a apenas leitura, sem poder realizar qualquer tipo de alteração, ferindo assim o princípio da imutabilidade desses logs. O uso de roles permite credenciais temporárias, o que melhora a segurança, além de facilitar a auditoria dos acessos. Você consegue saber qual usuário assumiu qual role em qual momento.

## Rsyslog operando com usuário próprio
Por padrão, o Rsyslog é executado como root. Porém, isso é perigoso, já que se o serviço puder ser explorado enquanto executado com acesso privilegiado, o impacto pode ser muito grande, afetando o sistema como um todo. Agora, se ele operar com um usuário próprio com somente as permissões necessárias ao seu funcionamento adequado, mesmo que seja comprometido, o impacto se torna bem mais restrito. Logo, o configurei com usuário próprio sem login e com as capabilities necessárias.

## Permissões adequadas para os arquivos/diretórios de logs
Da mesma forma que é importante proteger os logs no bucket S3, é importante proteger os logs locais no servidor, já que, de acordo com o projeto, eles passaram um período sendo armazenados lá. Portanto, configurei os diretórios com o ownership e as permissões adequadas, oferecendo acesso somente ao daemon do Rsyslog, ao logsync e, por fim, ao grupo de auditoria. E configurei o módulo omfile para gerar arquivos da mesma maneira, com ownership e permissões adequadas.
