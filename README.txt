resolv! | Serviços entre vizinhos
Global Solution 2 de 2026 • CitizenTech • Turma 3SIOA

Quem conserta uma dobradiça solta? No resolv!, o morador pode mostrar o problema
aos vizinhos ou procurar alguém que atenda seu bairro. Quem costura, dá aulas ou
faz pequenos reparos pode usar o mesmo perfil para divulgar seu trabalho. Ao
aproximar autônomos de possíveis clientes da região, a proposta se relaciona ao
ODS 8 da ONU (Trabalho decente e crescimento econômico).
https://brasil.un.org/pt-br/sdgs/08

Como rodar no Android Studio
----------------------------

1. Use o Android Studio com o plugin Flutter e o Flutter SDK no PATH. O projeto
   foi testado com Flutter 3.47.7 e Dart 3.13.5. No SDK Manager, instale a
   plataforma Android SDK 36.
2. Abra a pasta que contém pubspec.yaml. No terminal dessa pasta, baixe as
   dependências com o comando abaixo.

       flutter pub get

3. No Device Manager, inicie um emulador com Android 7.0 (API 24) ou superior.
   Selecione esse dispositivo na barra do Android Studio, abra lib/main.dart e
   clique em Run. O app abre no Mural, sem pedir login.

O MVP funciona em um aparelho e já vem com moradores fictícios e seis conversas
de exemplo. Os dados ficam salvos entre sessões. A demonstração permite negociar
valores localmente, sem troca de mensagens entre dispositivos ou pagamentos.

O que dá para fazer
-------------------

Mural — Publique um pedido com título, descrição e tag. Foto e orçamento são
opcionais. Se estiver em dúvida sobre quem chamar, use “Preciso de orientação”.
Os vizinhos podem comentar e o autor pode marcar o pedido como resolvido.

Vitrine — Busque por nome ou serviço. “Encanador”, por exemplo, encontra quem
trabalha com hidráulica. A busca começa no bairro e avança para os vizinhos até
encontrar alguém que atenda a região. Se ninguém atender, dá para abrir um pedido.

Perfil e Serviços — Ative “Quero oferecer serviços” e escolha especialidades e
bairros. Seu perfil passa a aparecer na Vitrine. Em Serviços, você vê os pedidos
abertos de outros moradores que combinam com suas escolhas. Ao resolver um pedido
seu, você pode avaliar quem fez o trabalho, de 1 a 5 estrelas.

Conversas — O chat pode começar por um pedido ou pela Vitrine. O resumo mostra
o serviço e a estimativa em reais, com a unidade de cobrança. Cada nova proposta
fica no histórico daquela conversa. O valor também pode ficar “A combinar”.

Um percurso para testar
-----------------------

1. Em Perfil, ative “Quero oferecer serviços”. Marque “Pequenos reparos” e
   “Centro” e salve as preferências.
2. Em Serviços, abra “Quem conserta essa dobradiça?” e toque em “Conversar com
   o morador”. O título e a descrição do pedido já aparecem no chat.
3. Toque no lápis do resumo, informe R$ 80,00 por visita e envie a proposta.
   Ao voltar ao Mural, confira que o orçamento público continua como foi
   publicado. Ao reabrir o app, a proposta estará em Conversas.

Como o código está organizado
-----------------------------

Flutter e Dart cuidam das telas e das regras do app. No Android, a MainActivity
em Kotlin abre o seletor de fotos e usa SharedPreferences para salvar os dados.
Assim, o tutor consegue testar o app no emulador sem configurar um servidor.

• lib/data.dart — AppData mantém o estado. addPost() publica um pedido,
  setProfessional() salva as preferências do prestador e reviewService() limita
  a avaliação a uma por pedido resolvido.
• lib/directory.dart — findProviders() busca quem atende a região.
  neighborhoodDistance() conta as ligações entre bairros e serviceRequests()
  seleciona os pedidos que aparecem para cada prestador.
• lib/chat_models.dart e lib/job_summary.dart — Conversation reúne as mensagens
  do chat. JobSummary guarda o serviço e Estimate representa o preço em centavos.
  AppData.updateJobSummary() registra a contraproposta na conversa.

Para poupar memória, o Mural monta os itens conforme entram na tela. As fotos
anexadas são reduzidas para até 1.600 pixels no maior lado. Ao fechar uma tela,
dispose() libera os controladores de texto e de rolagem que ela usou.

Banco de dados e testes
-----------------------

Na raiz do projeto, estes comandos verificam o código e executam os testes do app.

    flutter analyze
    flutter test

A parte de banco é demonstrada separadamente no Oracle Database Free. O pacote
RV_ATENDIMENTO registra pedidos, propostas e avaliações. O modelo de entidades
e relacionamentos (MER), os diagramas (DER) e a explicação das rotinas estão em
docs/modelo-de-dados.md.

Para testar o banco, abra SQL*Plus ou SQLcl na raiz do projeto. Conecte-se a um
esquema no Oracle Database Free 23ai ou compatível, com as permissões indicadas
no modelo de dados, e execute os scripts em ordem.

    @database/instalar.sql
    @database/testar.sql

O segundo script verifica seis grupos de cenários e desfaz os dados que criou.
