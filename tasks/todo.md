# Todo: data-store

Spec: `SPEC-data-store.md`. Piano: `tasks/plan.md`. Comandi di verifica standard: `supabase db reset` e `supabase test db`.

## Task 0a: Ambiente di sviluppo in Codespaces

**Description:** Preparare il devcontainer con Docker-in-Docker e Supabase CLI, inizializzare Supabase in locale e predisporre `.gitignore`, `.env.example` e README.

**Acceptance criteria:**
- [x] Il Codespace si avvia con Docker funzionante e Supabase CLI installata
- [x] `supabase start` avvia lo stack locale e `supabase db reset` esegue su database vuoto
- [x] Nessuna chiave o stringa di connessione nel repository; i segreti sono elencati solo in `.env.example`

**Verification:**
- [x] `supabase status` mostra i servizi attivi
- [x] Manual check: `git grep` non trova password, chiavi o stringhe di connessione

**Stato (2026-10-07):** completato. Verificato dall'autore in un Codespace da 2 core sul branch `claude/gifted-brahmagupta-6eae08`: creazione senza errori; `supabase start` riuscito con Studio, REST, GraphQL e database che rispondono; `supabase status` con i servizi spenti in `config.toml` in stato Stopped e "Not linked" (il link è nel Task 0b); `supabase db reset` concluso con il solo avviso atteso `no files matched pattern: supabase/seed.sql` (il seed arriva nel Task 9); porte 54321, 54322 e 54323 private.

**Dependencies:** None

**Files likely touched:**
- `.devcontainer/devcontainer.json`
- `supabase/config.toml`
- `.gitignore`
- `.env.example`
- `README.md`

**Estimated scope:** Small

## Task 0b: Progetto Supabase remoto (azione dell'autore)

**Description:** L'autore crea il progetto Supabase sul piano gratuito in regione UE e salva la password del database nei segreti di Codespaces. L'agente esegue solo `supabase link`. Circa 10 minuti dell'autore.

**Acceptance criteria:**
- [ ] Progetto creato sul piano gratuito, regione UE
- [ ] Password del database solo nei segreti di Codespaces, non nel repository
- [ ] `supabase link` riuscito

**Verification:**
- [ ] `supabase projects list` mostra il progetto collegato

**Dependencies:** Task 0a

**Files likely touched:**
- nessuno (i file di collegamento in `supabase/.temp/` sono esclusi da `.gitignore`)

**Estimated scope:** XS

## Task 0c: Verifica connessione di engine_writer (spike, rischio alto)

**Description:** Verificare per prima cosa che un ruolo Postgres personalizzato con permessi limitati si connetta al database remoto con lo stesso tipo di stringa di connessione che userà n8n. La migrazione crea il ruolo senza password; l'autore imposta la password dall'editor SQL di Supabase. Se la verifica fallisce, l'agente si ferma e riporta le alternative invece di proseguire.

**Acceptance criteria:**
- [ ] `engine_writer` si connette al database remoto dall'esterno
- [ ] `engine_writer` legge una tabella di prova a cui ha accesso e riceve errore su una a cui non ha accesso
- [ ] Nessuna password nella migrazione né nel repository

**Verification:**
- [ ] `scripts/check_engine_connection.sh` termina con esito positivo
- [ ] Manual check: l'autore conferma la connessione, prima che la migrazione venga applicata in remoto con `supabase db push`

**Dependencies:** Task 0b

**Files likely touched:**
- `supabase/migrations/<ts>_engine_writer_role.sql`
- `scripts/check_engine_connection.sh`
- `README.md`

**Estimated scope:** Small

## Task 1: Fonti e candidati (R10)

**Description:** Creare gli enum di base, le tabelle `sources` e `seeds`, la funzione di normalizzazione degli URL e la funzione `expire_stale_seeds()` che porta a `expired` i candidati `proposed` più vecchi di 7 giorni.

**Acceptance criteria:**
- [ ] Due URL che differiscono solo per schema, `www.`, parametri di tracciamento o slash finale vengono rifiutati come duplicati
- [ ] `expire_stale_seeds()` aggiorna solo i candidati `proposed` con più di 7 giorni
- [ ] RLS attivo e `COMMENT ON` su entrambe le tabelle

**Verification:**
- [ ] Test `R10` positivo e negativo passano con `supabase test db`
- [ ] Test di `expire_stale_seeds()` passa

**Dependencies:** Task 0a (eseguito dopo il Task 0c, così un fallimento dello spike blocca tutto prima di scrivere tabelle)

**Files likely touched:**
- `supabase/migrations/<ts>_sources_and_seeds.sql`
- `supabase/tests/r10_seeds_test.sql`

**Estimated scope:** Small

## Task 2: Notizie e fatti (R1, R2)

**Description:** Creare l'enum degli stati, la tabella `articles` (campi della breve in IT ed EN), la tabella `facts` con vincolo XOR articolo/persona, e le funzioni `fact_is_valid()` e `article_is_approvable()`.

**Acceptance criteria:**
- [ ] Un fatto senza `source_url` non si può inserire
- [ ] `fact_is_valid()` restituisce vero solo nei tre casi di R2
- [ ] `article_is_approvable()` è falso senza fatti o con un fatto non valido

**Verification:**
- [ ] Test `R1` e `R2` positivi e negativi passano

**Dependencies:** Task 1

**Files likely touched:**
- `supabase/migrations/<ts>_articles_and_facts.sql`
- `supabase/tests/r1_r2_facts_test.sql`

**Estimated scope:** Medium

## Task 3: Transizioni di stato e registro (R6, R9)

**Description:** Creare il ruolo `author` collegato all'utente autenticato, le funzioni `submit_for_review`, `approve`, `reject` e `publish`, il trigger che blocca gli `UPDATE` diretti di `status` e la tabella `status_events`. Il ruolo `engine_writer` esiste già dal Task 0c.

**Acceptance criteria:**
- [ ] `engine_writer` non può chiamare `approve` e può chiamare `publish` su un contenuto approvato
- [ ] L'autore approva solo se `article_is_approvable()` è vero
- [ ] Ogni transizione scrive una riga in `status_events` con attore, stato di partenza e di arrivo

**Verification:**
- [ ] Test `R6` e `R9` passano impersonando `engine_writer` e `author`

**Dependencies:** Task 2, Task 0c

**Files likely touched:**
- `supabase/migrations/<ts>_transitions.sql`
- `supabase/tests/r6_r9_transitions_test.sql`

**Estimated scope:** Medium

## Checkpoint A: dopo i Task 0a-3
- [ ] Tutti i test passano
- [ ] `engine_writer` verificato dall'esterno (Task 0c)
- [ ] Revisione con l'autore

## Task 4: Accesso pubblico e segnalazioni (R8)

**Description:** Attivare le policy RLS per i tre ruoli, creare la vista `public_articles` con sole colonne pubbliche e righe `published`, e la tabella `error_reports` con inserimento anonimo e lettura riservata all'autore.

**Acceptance criteria:**
- [ ] Con `anon` le tabelle non sono leggibili e la vista mostra solo righe `published`
- [ ] `source_excerpt`, note e punteggi non compaiono in nessuna vista
- [ ] `anon` può inserire in `error_reports` ma non leggerla

**Verification:**
- [ ] Test `R8` positivi e negativi passano impersonando `anon`

**Dependencies:** Task 3

**Files likely touched:**
- `supabase/migrations/<ts>_public_access.sql`
- `supabase/tests/r8_public_access_test.sql`

**Estimated scope:** Medium

## Task 5: Persone (R3)

**Description:** Creare la tabella `people`, collegare i fatti di profilo tramite `facts.person_id` e `field`, e la regola di approvazione delle persone.

**Acceptance criteria:**
- [ ] Una persona senza `wikidata_qid` non si può approvare
- [ ] Una persona con un fatto di profilo non valido non si può approvare
- [ ] `wikidata_qid` è unico

**Verification:**
- [ ] Test `R3` positivi e negativi passano

**Dependencies:** Task 3

**Files likely touched:**
- `supabase/migrations/<ts>_people.sql`
- `supabase/tests/r3_people_test.sql`

**Estimated scope:** Small

## Task 6: Aggiornamenti dei profili (R4, R7)

**Description:** Creare `statements` (estratto massimo 25 parole), `person_news`, `article_people` e `person_revisions`, il trigger che impedisce a `engine_writer` di modificare i campi principali di una persona pubblicata, e le viste `public_people` e `public_statements`.

**Acceptance criteria:**
- [ ] Una dichiarazione senza `said_on` o `source_url`, o con estratto oltre 25 parole, viene rifiutata
- [ ] Su una persona pubblicata `engine_writer` può aggiungere news e collegamenti, non modificare identità, ruolo, organizzazione o affiliazioni
- [ ] Le modifiche proposte finiscono in `person_revisions` e le applica solo l'autore

**Verification:**
- [ ] Test `R4` e `R7` positivi e negativi passano

**Dependencies:** Task 4, Task 5

**Files likely touched:**
- `supabase/migrations/<ts>_profile_updates.sql`
- `supabase/tests/r4_r7_profiles_test.sql`

**Estimated scope:** Medium

## Checkpoint B: dopo i Task 4-6
- [ ] Test R1-R10 tranne R5 passano
- [ ] Nessuna bozza visibile con `anon`
- [ ] Revisione con l'autore

## Task 7: Approfondimenti (R5)

**Description:** Aggiungere il campo `body` in IT ed EN per gli approfondimenti e il vincolo che un `deep_dive` punti a una breve pubblicata.

**Acceptance criteria:**
- [ ] Un approfondimento senza breve di riferimento, o con breve non pubblicata, viene rifiutato
- [ ] Una breve non può avere `parent_article_id`

**Verification:**
- [ ] Test `R5` positivi e negativi passano

**Dependencies:** Task 3

**Files likely touched:**
- `supabase/migrations/<ts>_deep_dives.sql`
- `supabase/tests/r5_deep_dives_test.sql`

**Estimated scope:** Small

## Task 8: Newsletter

**Description:** Creare `newsletter_issues` (uno per lingua per settimana) e `newsletter_issue_articles`, con la stessa macchina degli stati e le stesse funzioni di transizione.

**Acceptance criteria:**
- [ ] Un secondo numero per la stessa settimana e lingua viene rifiutato
- [ ] Si possono includere solo notizie pubblicate
- [ ] Le transizioni scrivono in `status_events`

**Verification:**
- [ ] Test della newsletter positivi e negativi passano

**Dependencies:** Task 3

**Files likely touched:**
- `supabase/migrations/<ts>_newsletter.sql`
- `supabase/tests/newsletter_test.sql`

**Estimated scope:** Small

## Task 9: Dati di esempio e verifica finale

**Description:** Scrivere `seed.sql` con persone e testate inventate, aggiungere un test che verifica `COMMENT ON` su ogni tabella, ed eseguire tutti i criteri di successo della spec. Infine applicare le migrazioni al progetto remoto.

**Acceptance criteria:**
- [ ] Dopo `seed.sql` le viste pubbliche mostrano solo i contenuti pubblicati di esempio
- [ ] Tutti i 7 criteri di successo della spec sono soddisfatti
- [ ] `supabase db push` applica le migrazioni al progetto remoto senza errori

**Verification:**
- [ ] `supabase db reset` e `supabase test db` passano
- [ ] Manual check: nessun nome di persona reale in `seed.sql`

**Dependencies:** Task 6, Task 7, Task 8

**Files likely touched:**
- `supabase/seed.sql`
- `supabase/tests/comments_test.sql`

**Estimated scope:** Small

## Checkpoint C: modulo completo
- [ ] Tutti i criteri di successo della spec soddisfatti
- [ ] Migrazioni applicate in remoto
- [ ] Revisione finale con l'autore
