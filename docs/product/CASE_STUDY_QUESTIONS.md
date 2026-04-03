# Lazzo — Case Study: Questions

---

## 1. O Problema & a Ideia

**Q1. O que é que te levou a querer construir o Lazzo?**
Qual foi o momento ou frustração concreta que fez click? (Ex: uma festa onde ninguém partilhou fotos, um grupo de WhatsApp caótico, etc.)

> *Resposta: Por vezes tentavamos organizar eventos com amigos (saídas à noite, convívios, idas à praia, jantares, etc.) que acabavam por não acontecer pois a mensagem era ignorada no grupo ou passava despercebida em grupos de Whatsapp e Instagram com conversas paralelas. Quando por vezes estavamos juntos a lembrar de histórias e acontecimentos passados reparavamos que não tinhamos fotos pois em certos grupos não tiravamos fotos e quem tirava acabava por não as partilhar no dia a seguir. Estas fotos também estão desorganizadas na galeria. A ideia inicial era resolver a dor de combinar eventos com amigos e guardar as memórias num único lugar.*

---

**Q2. Que alternativas consideraste e descartaste antes de definires o produto?**
(Ex: grupo de WhatsApp, Google Photos shared albums, BeReal, Partiful, etc.) Porquê é que nenhuma resolvia o problema?

> *Resposta: Grupos de Whatsapp embora sendo a melhor alternativa é bastante usado para outros assuntos (trabalho, conversa do dia a dia, etc.) e por vezes são criados bastantes grupos únicos para um evento grande (festas de aniversário, passagens de ano, viagens, etc.). Por mais que o whatsapp é uma chat app que não se foca em decidir o que combinar nem um RSVP para marcar presenças. Google Photos é usado apenas para eventos grandes e de vários dias como viagens mas requer o setup, ter espaço na drive e as pessoas lembrarem-se de adicionar as fotos.*

---

## 2. Validação antes de Construir

**Q3. O que é que a pesquisa de mercado nas 2 semanas de Julho revelou?**
Falas com quem? O que é que ouviste que te convenceu (ou surpreendeu)?

> *Resposta: As 2 semanas foi apenas para procurar áreas e problemas de interesse e chegamos à conclusão de resolver saídas com amigos. Durante os outros 2 meses até início de Setembro foi passado a fazer questionários e versões Figmas para tesstar UI e comportamente, foram feitas 6 Versões ao todo. Estes iteradas de acordo com o feedback dos users, tenho tudo documentado num word separado por versões. Eu e o meu co-founder falamos com 23 (número preciso) amigos/conhecidos de idades a rondar os 14-30 anos. Percebemos que todos combinam por message apps ou por chamada e reconhecem que estes métodos não são 100% eficazes. Identificamos também com 2 pessoas que costumam ser os hosts já procuraram soluções alternativas, exemplo de um tester que tentou usar Apple Invites mas este apenas permite criar convites com apple storage paga. Os principais sinais de feedback que percebemos foi:*  
> *- 7 das 23 pessoas partilha fotos em eventos sociais no Instagram, principalmente em contas pessoais ou close friends.*  
> *- As fotos são enviadas por airdrop ou grupo de whatsapp quase sempre no dia a seguir (24 hrs) a seguir e tem de ser quase sempre alguém a lembrar para terem as fotos todas*  
> *- Grande parte tira poucas fotos ou nenhuma mas um pequeno grupo de pessoas tira quase todas as fotos do evento*  
> *-* O uso do **MBWay** (Cache app) é quase unânime para pagamentos rápidos, enquanto o **Splitwise** é reservado para viagens ou eventos com maior logística.

---

**Q4. O que é que os testes de Figma com os 30+ amigos mudaram concretamente no produto?**
Havia alguma ideia que achavam boa mas que os utilizadores rejeitaram? Alguma coisa que não estavam à espera?

> *Resposta: Pontos positivos que fizeram dar o sinal de avançar:*  
> *-* **Rapidez no Planeamento:** A criação de eventos foi amplamente elogiada por ser intuitiva, clara e rápida (muitas vezes em menos de 30 segundos).  
>
> - **Modos de Câmara (Disposable):** A ideia de modos diferentes, especialmente a "Disposable Camera", foi vista como um dos conceitos mais interessantes e diferenciadores da aplicação.  
> - **Gestão de Datas e Votação:** O sistema de sugestão de datas e a visualização de quem pode ou não ir ajudam a resolver a "dor" de falta de consenso em grupos.  
> - **O Valor das Memórias:** A funcionalidade de "Memory" (recap do evento) é considerada o ponto mais forte para partilha social e marketing, sendo o motivo principal pelo qual muitos usariam a app.  
> - **Integração de Despesas:** A inclusão de despesas diretamente na página do grupo ou evento foi considerada uma grande mais-valia.
>
> Outros pontos:  
>
> - Ninguém gosta de anúncios e alguns pagariam por Funcionalidades inovadoras, vídeos curtos ou armazenamento extra. O valor sugerido ronda os **2€ a 3.5€/mês**.  
> - Não pagariam por limitação de fotos ou espaço de armazenamento básico. Impor limites rígidos de fotos pode levar à desistência do uso da app.  
> - **Modo Offline:** Embora importante para alguns , muitos utilizadores consideram-no irrelevante por andarem sempre com dados móveis.  
> - **Tutorial Necessário:** Muitos utilizadores sugeriram um tutorial inicial (3-5 slides) para explicar os modos de evento e o conceito de "Viver" vs "Recordar".  
> - Opinião unânime que: A app tem mais tração para "saídas à noite", "jantares de grupo" e "viagens" do que para cafés casuais.

---

**Q5. Houve alguma decisão que tomaram *contra* o feedback dos testes, e porquê?**
(Ex: "toda a gente disse X, mas nós fizemos Y porque…")

> *Resposta: **  
> *- Modos de câmera deixamos de parte no início pois era algo situacional em alguns eventos e novo, o que podia morrer a longo prazo. Também não resolvia nenhum problema em concreto e era apenas "giro". Foi posto como uma possibilidade se a app toma-se o rumo de night focus.*  
> *- Videos deixamos de parte de início e calendário de disponibilidades de cada pessoa poris isso envolve cada pessoa colocar e ter o calendar (iOS ou Google) sincronizado. Muitas das pessoas não adicionavam eventos ao calendário no dia a dia.*  
> *- Fotos colocamos limitadas inicialmente para teste e ser mais previsível o scalling. Decidimos que era melhor tirar liberdade e depois adicionar do que ao contrário. O número de fotos decididas foram máx(N5,20) pois no pior do caso em média quem tira poucas fotos ou quase nada tira no máximo 4 fotos.*  
> *- Curadoria com voto das fotos foi também retirado. Não resolvia um problema significante*  
> *- Offline first foi adiada pois não é essencial para beta e quase todos têm dados móveis sempre ligados*

---

## 3. Decisões de Produto

**Q6. Porquê iOS-first e não web-first desde o início?**
Foi uma decisão deliberada (target, distribuição, stack) ou uma assunção que nunca questionaram?

> *Resposta: Notificações para lembretes de adicionar fotos, lembrete de RSPV, mensagens, alterações de planos, votações, etc. Também é mais normal usar uma app nativa do que web-app. Mais confiança app real e adicionar fotos/tirar fotos é mais fácil. A grande maioria usa IOS e não Android.*

---

**Q7. Porquê 24h para upload de fotos e não outra janela (ex: 48h, 1 semana, indefinido)?**
Houve raciocínio explícito ou foi uma estimativa? Alguma vez testaram outra janela?

> *Resposta: Grande parte das pessoas dizia que 24hrs é suficiente para depois do evento adicionar as fotos e cria urgência nas pessoas para adicionar. Grande parte das pessoas partilha ou vê as fotos no dia a seguir em caso de saídas à noite.*

---

**Q8. O que é que despoletou o pivot de Janeiro?**
Foi um momento específico (uma sessão de teste, uma conversa, um dado)? O que é que aconteceu concretamente que vos fez perceber que o install friction era o bloqueador?

> *Resposta: Ao testar a app mesmo com vários users muitos destes pareciam 'obrigados' a instalar a app e no mundo real não instalariam uma app só para dizer que sim. Vimos que o público alvo de combinar era mais para o host, que geralmente é a pessoa que manda mensagem para o grupo. No pivot da v2 tiramos também chat, grupos (eventos passam a ser singulares), expenses e polls com as sugestões de datas/location. Chat e grupos pois não queriamos quebrar os hábitos existentes das pessoas. Eles continuam a combinar no grupo de whatsapp como fazem normalmente e falam por lá, nós apenas funcionamos como complemento para o host conseguir combinar e gerir o evento. Percebemos também que a app não seria usada em eventos casuais de poucas pessoas pois estas já conseguem combinar sem problema. Ou seja, o foco ficou em eventos um pouco maiores e com pessoas diferentes muitas vezes. Por exemplo: festas de aniversários, jantares maiores, festas temáticas (exemplo passagens de ano e carnaval), viagens, etc.. Expenses retiramos pois muitas pessoas usam ativamente apps como Splitwise para controlar despesas neste tipo de app e não é a prioridade de agora. Resolver primeiro problema principal de RSVP host e memórias. Depois focamo-nos no resto. Este tipo de eventos também já têm uma data definida e se não têm isto é decido por mensagem geralmente, por isso tiramos polls com suggestions. A maior alteração foi suporte web que permite aos users que não instalam a app receber e carregar no RSVP rapidamente e depois ter o ciclo completo a adicionar fotos, ver memória, etc. Para criar evento tem de se ter a app pois a experiência é melhor e temos de trazer as pessoas para a app. Para o host mandar um link com um card estilo e-card também chama mais a atenção e é mais fácil para os guests carregarem e votarem logo.*

---

**Q9. Quando fizeram o pivot para web companion, o que é que descartaram ou adiaram para o conseguir entregar?**
Qual foi o custo real do pivot em termos de tempo e escopo?

> *Resposta: A app anteriormente servia apenas para receber os convites e direcionar para a app. Agora com o pivot era uma extensão e crrítica para o workflow da v1, por isso lançamos ao mesmo tempo com a v1. Ou seja, final de fevereiro*

---

**Q10. Porquê priorizar o Share Card em vez de outras funcionalidades pós-evento?**
Foi por acreditar que era o loop de crescimento (partilha → novos utilizadores), ou havia outra razão?

> *Resposta: Ter retenção e viralidade da app e as pessoas gostam do formato VSCO. Esse card também mais tarde iria permitir para pessoas que vissem o card nas redes sociais carregassem e vissem a memória completa, com permissões como é óbvio. Estilo VSCO. Reparamos também que as pessoas que colocam nas stories fazem 1 ou 2 stories e por vezes o formato de card, com várias fotos na mesma story.*

---

**Q11. Removeram grupos e despesas em v2. Porquê existiam em v1?**
E o que vos fez perceber que estavam a complicar em vez de ajudar?

> *Resposta: Respondido na Q8*

---

## 4. Beta & Métricas

**Q12. Quantos eventos reais foram criados durante o beta (Fev–Abr)?**
Mesmo que seja uma estimativa (~10, ~30, ~50). E quantos hosts diferentes?

> *Resposta:*

---

**Q13. Qual foi o padrão de uploads que observaram?**
Havia eventos com muitas fotos e outros com zero? O que diferenciava uns dos outros?

> *Resposta:*

---

**Q14. O host repeat rate — alguém criou mais do que 2–3 eventos? Ou a maioria usou uma vez e não voltou?**

> *Resposta:*

---

**Q15. Qual foi a maior fricção que os utilizadores reportaram ou que observaram diretamente?**
(Ex: o onboarding web, o upload, o timing, a notificação de "memory ready", etc.)

> *Resposta:*

