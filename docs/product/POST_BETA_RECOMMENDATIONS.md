# Lazzo — Post-Beta Recommendations

**Date:** Feb 23, 2026
**Context:** Feature-complete MVP, transitioning to instrumented cohort testing.

---

## 1) Strategic Recommendations

### 1.1 — PostHog é a decisão certa, mas limita o scope inicial

PostHog Cloud EU para analytics + flags + errors é pragmático para uma equipa de 2. Mas:

- **Session replay:** desativa no início. Consome quota e não é prioritário. Liga apenas se precisares de entender um bug específico que os logs não explicam.
- **Error tracking do PostHog** é funcional mas não substitui Sentry/Crashlytics a longo prazo. Para a beta é suficiente. Avalia migração para Sentry se o volume de erros crescer ou se precisares de stack traces mais ricos.
- **Feature flags do PostHog** funcionam bem para A/B simples. Não tentes setups complexos (multi-step experiments, mutual exclusion groups) — isso é para fases posteriores.

**Recomendação:** Usa PostHog para tudo agora. Reavalia no final da Phase 4 se precisas de ferramentas especializadas.

### 1.2 — O memory moat é tudo, foca aí

O produto não vence no planning (Partiful é melhor). Vence no **ciclo completo**: planning rápido + captura fácil + recap bonito. O verdadeiro diferenciador é a experiência de recap/memory.

**Prioridade absoluta nos próximos 2 meses:**
1. Guests fazem upload sem fricção
2. O recap é bonito e shareable
3. O host vê valor e cria outro evento

Se tiveres que cortar scope, corta features de planning antes de cortar features de memory.

### 1.3 — Não subestimes o web guest experience

A maioria dos teus utilizadores vai ser web guests — não hosts. O host é 1 pessoa, os guests são 5–50. A qualidade da experiência web determina:
- Se alguém faz RSVP
- Se alguém faz upload
- Se alguém vê o recap

**Recomendação:** Aloca pelo menos 40% do tempo de dev à web experience. Testa em iOS Safari + Android Chrome real (não simulador).

---

## 2) Technical Recommendations

### 2.1 — Cria o `AnalyticsService` antes de tudo

Antes de instrumentar eventos, cria o serviço base:

```
lib/services/analytics_service.dart
```

Padrão recomendado:
- Classe estática (como os outros services)
- Wrapper fino sobre PostHog SDK — se mudares de provider, mudas num sítio
- Nunca chamado do domain layer (só presentation + services)
- Inclui método `isFeatureEnabled()` para flags

### 2.2 — Shared event taxonomy document

Cria um ficheiro partilhado entre o repo da app e o repo da web com os nomes exatos dos eventos e propriedades. Pode ser um JSON schema ou um markdown simples. O importante é que **ambas as plataformas usem exatamente os mesmos nomes**.

Se `rsvp_submitted` na app se chamar `rsvp_voted` na web, os dashboards ficam inúteis.

### 2.3 — Limpa o codebase antes da beta

Antes de convidar o primeiro cohort:

- [ ] Remove `lib/features/group_invites/` (está morto, DI removido)
- [ ] Remove comentários `// LAZZO 2.0: Groups removed` e código comentado no `main.dart`
- [ ] Corre `./scripts/clean_prints.sh` — zero prints em production
- [ ] Corre `flutter analyze` e resolve todos os warnings
- [ ] Revê imports não usados e código morto

Isto não é cosmético — código morto cria confusão para ti e para o copilot.

### 2.4 — Deploy pipeline é Phase 0, não Phase 1

O roadmap já reflete isto, mas reforço: **não comeces cohort testing sem deploy pipeline estável**. Vais precisar de fazer hotfixes mid-week durante cohorts. Se o deploy leva 1h manual, perdes momentum.

Mínimo viável:
- **iOS:** Script/Action que faz `flutter build ipa` + upload para TestFlight
- **Web:** Vercel auto-deploy no push para `main` (provavelmente já tens isto)
- **Rollback:** saber voltar à build anterior em < 5 min

### 2.5 — Staging vs Production no Supabase

Se não tens ambiente de staging, pelo menos:
- Documenta como fazer rollback de migrations
- Nunca faças migrations em production durante um cohort weekend
- Tem um SQL dump recente antes de cada migration

Para a beta isto é suficiente. Staging environment formal pode esperar para pré-public.

---

## 3) Product Recommendations

### 3.1 — O primeiro cohort é para instrumentação, não para features

Não tentes adicionar features novas no Cohort #1. O objetivo é:
1. Confirmar que PostHog está a capturar tudo corretamente
2. Ver o funnel real pela primeira vez
3. Identificar os 3 maiores pontos de fricção

Só depois de teres dados é que sabes o que construir a seguir.

### 3.2 — Qualitative > quantitative no início

Com 5–7 hosts e ~30 guests, os números não são estatisticamente significativos. Usa PostHog para **ver padrões**, não para tirar conclusões.

O mais valioso no Cohort #1:
- **Observação direta:** vê alguém usar o produto pela primeira vez
- **Conversas post-event:** "O que foi confuso? O que foi fácil? Mostraste o recap a alguém?"
- **PostHog funnel:** onde é que as pessoas saem? (auth? RSVP? upload?)

### 3.3 — Define "sucesso" para cada cohort ANTES de começar

Para cada cohort, escreve 3 perguntas que queres responder:

**Cohort #1 (amigos):**
1. O funnel completo funciona sem intervenção manual?
2. Pelo menos 60% dos eventos chegam a Memory Ready?
3. Quais são os 3 maiores pontos de fricção reportados?

**Cohort #2 (fora da bolha):**
1. As pessoas entendem o produto sem explicação do founder?
2. A variante memories-first melhora uploads sem prejudicar RSVP?
3. Os hosts sentem valor suficiente para considerar criar outro evento?

### 3.4 — Não lances landing page cedo demais

A landing page (Phase 4) só faz sentido quando sabes:
- Que o produto funciona (Cohort #1 confirma)
- Que funciona fora da tua bolha (Cohort #2 confirma)
- Que tens capacidade de suportar novos utilizadores

Se lançares a landing sem validar, arriscas dar uma primeira impressão má a pessoas que nunca voltarão.

### 3.5 — O referral loop é o growth engine mais natural

O produto tem um loop de sharing natural: o host partilha o recap → os amigos vêem → querem fazer o mesmo para o evento deles → tornam-se hosts.

Mede este loop o mais cedo possível:
- `recap_shared` → quantos dos que vêem o recap acabam por criar um evento?
- Isto é o teu product-market fit signal mais forte.

---

## 4) Operacional Recommendations

### 4.1 — Cadência semanal real para 2 pessoas

Não tentes o modelo startup de "daily standups" com 2 pessoas. É overhead.

**Recomendação:**
- **Monday sync (30min):** O que vamos fazer esta semana? Quem faz o quê?
- **Async rest of week:** mensagens quando precisares
- **Friday release:** ambos fazem deploy + escrevem 3 bullets do que mudou

### 4.2 — Bug triage realista

Com 2 pessoas, não podesixer tudo ao mesmo tempo. Define:

| Severidade | Descrição | SLA |
|------------|-----------|-----|
| P0 | Bloqueia fluxo core (não consigo criar evento, upload falha sempre) | Mesmo dia |
| P1 | Degradação mas existe workaround (UI glitch, notificação não chega) | 48h |
| P2 | Nice to fix (copy typo, alignment off) | Próximo sprint |

### 4.3 — Release notes template

Mantém simples. Para cada release:

```
## v1.0.2 (Feb 28, 2026)

### O que melhorou
- Upload de fotos mais rápido e com retry automático
- [Web] Tela de RSVP simplificada

### Corrigido
- Crash ao abrir evento sem localização
- [Web] Auth flow não funcionava em Safari 16

### Notas internas
- PostHog event `photo_uploaded` agora inclui `upload_duration_ms`
```

---

## 5) O Que Pode Correr Mal (E Como Evitar)

### 5.1 — "Estamos a construir features em vez de medir"

**Sinal:** Chegaste à Week 4 e ainda não tens dashboards a funcionar.
**Fix:** A instrumentação é a feature mais importante. Não construas nada novo até PostHog estar a funcionar end-to-end.

### 5.2 — "Os guests não fazem upload"

**Sinal:** Upload rate < 30% nos primeiros cohorts.
**Fix progressivo:**
1. Verifica se o problema é técnico (uploads falham?) vs UX (não encontram o botão?)
2. Testa nudges diferentes (PostHog flags)
3. Adiciona preview do recap ANTES do upload ("Vê como vai ficar")
4. Simplifica o upload para 1 tap

### 5.3 — "O host não volta"

**Sinal:** Host repeat rate < 10%.
**Fix:** Entrevista os hosts. Duas causas comuns:
- Não viram valor no recap (→ melhora a recap experience)
- O processo de criação é demasiado longo (→ mas tu já tens < 30s, confirma com dados)

### 5.4 — "Cross-platform tracking não funciona"

**Sinal:** PostHog mostra utilizadores diferentes para a mesma pessoa na app vs web.
**Fix:** Confirma que `distinct_id` é o Supabase `user_id` em ambas as plataformas. Se o guest usa web sem auth, usa `anonymous_id` primeiro e faz `alias()` quando faz auth.

---

## 6) Decisões Que Precisam de Ser Tomadas (Não Documentadas)

Estas decisões devem ser tomadas antes do fim da Phase 1:

1. **Android:** Está explicitamente fora do scope dos próximos 2 meses? (O roadmap assume que sim.)
2. **Multi-language:** O app vai ser English-only na beta, ou PT/EN? (O roadmap diz EN-only.)
3. **Web auth placement:** Auth antes de ver o evento ou depois? Isto é o primeiro A/B test ideal.
4. **Supabase staging:** Vais criar um projeto Supabase separado para staging ou usas production com cuidado?
5. **TestFlight distribution:** Internal testing (equipa) ou External testing (beta users)? External requer Apple review.
6. **Push notifications na beta:** Já funcionam em TestFlight? Certificados APNS configurados?
7. **Memory window:** 24h é o tempo certo? Ou devias permitir uploads por mais tempo durante a beta para maximizar conteúdo?
8. **Consent/GDPR:** Precisas de cookie banner na web e opt-out de analytics na app. Implementar antes do primeiro cohort.

---

## 7) Resumo: Os 5 Mandamentos da Post-Beta

1. **Instrumenta primeiro, constrói depois.** Sem dados, estás a voar cego.
2. **Memory é o moat.** Tudo o que melhore a experiência de recap é prioridade.
3. **Web guests são a maioria.** Trata a web experience como produto principal, não como companion.
4. **Mantém o scope apertado.** 2 pessoas + AI = funciona, mas só se não tentares fazer tudo.
5. **Feedback qualitativo > métricas nos primeiros cohorts.** Os números vêm depois; agora ouve.
