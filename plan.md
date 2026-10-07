# Implementation Plan: data-store

Spec di riferimento: `SPEC-data-store.md` (approvata il 2026-10-07). Task dettagliati in `tasks/todo.md`.

## Overview

Costruire l'archivio Supabase che fa da confine tra tutti i moduli: schema, macchina degli stati, ruoli, regole R1-R10 garantite dal database, viste pubbliche e dati di esempio. Il modulo è finito quando tutti i criteri di successo della spec passano con `supabase db reset` e `supabase test db`.

## Architecture Decisions

1. **Regole nel database, non nel motore.** Ogni regola R1-R10 vive in un vincolo, un trigger o una funzione, così nessun modulo può aggirarla per errore.
2. **Una funzione per regola.** Per esempio `fact_is_valid()` e `article_is_approvable()`, usate sia dai trigger sia dai test: la regola esiste in un solo punto.
3. **Transizioni di stato solo tramite funzioni.** `submit_for_review`, `approve`, `reject` e `publish` controllano ruolo e regole; un trigger blocca gli `UPDATE` diretti di `status`.
4. **Sviluppo in GitHub Codespaces.** Devcontainer con Docker-in-Docker e Supabase CLI, perché `supabase start` richiede Docker.
5. **Rischio alto per primo.** Il ruolo personalizzato `engine_writer` e la sua connessione dall'esterno si verificano nel Task 0c, prima di qualsiasi tabella.
6. **Azioni dell'autore separate.** La creazione del progetto remoto (Task 0b) e le password restano azioni dell'autore; l'agente si ferma e chiede quando servono.

## Task List

### Phase 1: Fondamenta
- [ ] Task 0a: Ambiente di sviluppo in Codespaces
- [ ] Task 0b: Progetto Supabase remoto (azione dell'autore)
- [ ] Task 0c: Verifica connessione di engine_writer (spike, rischio alto)
- [ ] Task 1: Fonti e candidati (R10)
- [ ] Task 2: Notizie e fatti (R1, R2)
- [ ] Task 3: Transizioni di stato e registro (R6, R9)

### Checkpoint A: dopo i Task 0a-3
- [ ] `supabase db reset` e `supabase test db` passano
- [ ] `engine_writer` si connette dall'esterno con la stessa stringa che userà n8n
- [ ] Revisione con l'autore prima di proseguire

### Phase 2: Accessi e persone
- [ ] Task 4: Accesso pubblico e segnalazioni (R8)
- [ ] Task 5: Persone (R3)
- [ ] Task 6: Aggiornamenti dei profili (R4, R7)

### Checkpoint B: dopo i Task 4-6
- [ ] Test R1-R10 tranne R5 passano
- [ ] Con la chiave `anon` nessuna bozza è visibile
- [ ] Revisione con l'autore prima di proseguire

### Phase 3: Completamento
- [ ] Task 7: Approfondimenti (R5)
- [ ] Task 8: Newsletter
- [ ] Task 9: Dati di esempio e verifica finale

### Checkpoint C: modulo completo
- [ ] Tutti i 7 criteri di successo della spec soddisfatti
- [ ] Migrazioni applicate al progetto Supabase remoto con `supabase db push`
- [ ] Revisione finale con l'autore

## Stima

Circa 13-16 ore di lavoro di implementazione in totale, più circa 1 ora dell'autore per i tre checkpoint. Stima indicativa.

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Il ruolo `engine_writer` non riesce a connettersi da fuori (pooler o connessione diretta) con i permessi previsti | High | Spike nel Task 0c, prima di qualsiasi tabella; se fallisce l'agente si ferma e riporta le alternative |
| Docker in Codespaces lento o senza risorse sufficienti | Medium | Devcontainer con Docker-in-Docker; macchina Codespaces più grande se `supabase start` fallisce |
| Regole nei trigger difficili da debuggare | Medium | Una funzione per regola e almeno un test negativo per ciascuna |
| Pausa del piano gratuito durante lo sviluppo, quando nessuno scrive nel database remoto | Low | Riattivazione dal pannello; lo sviluppo avviene in locale |

## Open Questions

1. Nome del repository GitHub (sul tuo account personale).
2. Chi implementa: Claude Code in Codespaces seguendo `tasks/todo.md`, oppure codice scritto qui in chat.
