# DECISÕES DO PROJETO

## Uso do Roles Anywhere vs IAM User:

Como o Rsyslog está sendo executado em uma VM local, não dá para utilizar IAM Roles tradicionais, e a alternativa de se utilizar IAM Users é menos segura, já que suas credenciais são estáticas e não há rotação automática. Logo, foi utilizado o Roles Anywhere, que garante os mesmos benefícios das IAM Roles, porém permite autenticação de workloads locais. 

## Módulos do Rsyslog (imuxsock vs imjournal):

Ambos coletam logs locais, porém as mensagens recebidas pelo imjournal são mais ricas em contexto, mas há uma perda significativa de performance em relação ao imuxsock, além de que esse último é oficialmente suportado pelo Rsyslog. Para esse projeto, o imuxsock foi escolhido.

## Usar buckets distintos ao invés de retenção por objeto:

No S3, não é possível definir políticas de retenção segmentando por prefixos ou tags. Se quiser fazer esse controle com granularidade, você precisa especificar no upload do objeto. 
Para simplificar o script, decidi separar os logs em dois buckets, cada um com uma política global de retenção diferente.

## ABAC vs. bucket policy:

Usar ABAC (Attribute Based Access Control) é mais flexível e dinâmico, sendo especialmente bom para buckets compartilhados por múltiplos times e projetos.
Esse não é o caso, logo, bucket policies em conjunto com políticas IAM tradicionais fazem mais sentido, principalmente pela simplicidade, sem ficar se preocupando com as tags dos objetos, além das permissões que os
usuários têm para adicionar tags.

## Usar .tar.gz ao invés de apenas compactar, preservando a estrutura dos diretórios:

As classes de acesso menos frequente (IA e Glacier) possuem um tamanho mínimo de objeto para cobrança.
Para reduzir o número de objetos pequenos no bucket (objetos com menos de 128kb), decidi diminuir a granularidade, empacotando logs por host antes de fazer o upload para o S3, em vez de preservar a organização local que segmenta logs por facility e app.

## Usar CA intermediária ao invés de apenas raiz:

Usar a CA raiz diretamente para assinar certificados finais é um risco, já que, se comprometida, afeta todos os certificados na cadeia de confiança.
Logo, utilizei uma CA intermediária para assinar o certificado do servidor Rsyslog ao invés de utilizar direto a raiz, que então foi apenas usada como Trust Anchor no Roles Anywhere.

## Bucket com retenção:

Como o bucket armazena arquivos de log que, em princípio, devem ser imutáveis, foi decidida a ativação da função de bloqueio de objeto no bucket para impedir o apagamento de logs e modificações definitivas.
Caso um objeto seja alterado, as múltiplas versões são mantidas e ficam bloqueadas até o tempo de retenção expirar.

## UDP ou TCP ou Ambos:

TCP é o padrão atual, já que é confiável, ou seja, mensagens não correm o risco de não chegarem no servidor e nunca serem registradas. 
Porém, dispositivos mais antigos ou mais simples ainda suportam apenas UDP, logo, para manter compatibilidade, resolvi utilizar ambos.

## Sincronizar com o bucket diariamente ao invés de no final do mês:

Inicialmente, pensei em enviar os logs todo final de mês para o S3, visando economia, já que os logs passariam mais tempo no armazenamento local. Porém, existe a possibilidade de algum erro eventual ocorrer, o que potencialmente impactaria todos os logs do mês. Logo, resolvi rotacionar e enviar todo dia.

## LVM vs particionamento tradicional (MBR/GPT):

LVM permite maior facilidade na hora da expansão, já que posso mover PVs de forma online, além da possibilidade de expandir volumes para além de um único disco.
Considerando um aumento do número de equipamentos em uma infraestrutura, o volume de logs aumenta, requerendo upgrade do armazenamento. O LVM facilita isso.

## Tratar diferentes severidades:

Devido a fatores como volume, utilidade e criticidade, foi definido quais níveis de severidade seriam mantidos localmente no servidor (info e notice) e quais iriam para o S3 (warning em diante). O nível de severidade também foi levado em conta para determinar a política de ciclo de vida no S3. Logs mais críticos (emerg, alert e crit) após 165 dias vão para o Glacier, ficando armazenados por 2 anos no total, enquanto err e warning são descartados após esse período.

## Rsyslog vs syslog-ng:

O syslog-ng, quando se trata de filtros e pipelines complexos de logs, se destaca em relação ao Rsyslog. Porém, o Rsyslog é mais performático e mais simples de configurar. 
Como o projeto não utiliza nenhum pipeline complexo, a facilidade de configuração do Rsyslog pesou mais e por isso foi escolhido.




