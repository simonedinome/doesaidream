# Spec: data-store

Stato: approvata (2026-10-07). Modulo id: `data-store`. Dipende da: nessuno.

## Objective

L'archivio è l'unica fonte di verità del progetto e il confine tra tutti i moduli. Ogni modulo scrive qui le sue bozze, `review-console` le rivede e `publishing` legge solo ciò che è approvato. Il modulo non contiene logica editoriale: contiene il modello dati, gli stati e le regole che non devono dipendere dall'attenzione umana.

Utenti del modulo:

1. **Il motore (n8n)**, che scrive candidati, bozze, collegamenti e news sui profili.
2. **L'autore**, che approva, modifica e rifiuta tramite `review-console`.
3. **Il sito pubblico**, che legge solo contenuti pubblicati tramite viste dedicate.

### Regole che il database deve garantire

| Id | Regola |
|---|---|
| R1 | Una notizia non può diventare `approved` se non ha almeno un fatto, o se un suo fatto non è valido. |
| R2 | Un fatto è valido se ha un `source_url` e almeno una di queste condizioni: la fonte è `guaranteed`, esiste un `second_source_url`, oppure `verification = 'author_verified'`. |
| R3 | Una persona non può diventare `approved` senza `wikidata_qid` e senza fonte valida per ogni fatto del profilo. |
| R4 | Una dichiarazione richiede `said_on` e `source_url`; l'estratto letterale, se presente, non supera 25 parole. |
| R5 | Un approfondimento (`deep_dive`) deve puntare a una breve (`brief`) già pubblicata. |
| R6 | Il passaggio a `approved` può farlo solo l'autore. Il motore può portare `approved` a `published`, mai `in_review` ad `approved`. |
| R7 | Su una persona pubblicata il motore può solo aggiungere collegamenti a notizie e news (con testata, data, link). Ogni modifica a identità, ruolo, organizzazione, affiliazioni o dichiarazioni diventa una proposta in `person_revisions`. |
| R8 | Il ruolo anonimo legge solo le viste pubbliche, che espongono solo righe `published` e mai colonne interne (estratti di origine, note, punteggi). |
| R9 | Ogni cambio di stato è registrato in `status_events` con attore, data e stati di partenza e arrivo. |
| R10 | Un URL di candidato è unico dopo normalizzazione (schema, `www.`, parametri di tracciamento, slash finale). |

### Macchina degli stati (notizie, persone, numeri newsletter)

`draft` → `in_review` → `approved` → `published`. Da ogni stato non pubblicato si può andare a `rejected`. Un contenuto pubblicato non torna indietro: le correzioni si fanno con una nuova revisione, registrata in `status_events`.

## Tech Stack

1. Supabase (Postgres gestito, regione UE). Versione di Postgres: quella di default del progetto Supabase alla creazione, da annotare in `supabase/config.toml`.
2. Supabase CLI per sviluppo locale, migrazioni e test.
3. pgTAP per i test del database (supportato da `supabase test db`).
4. Estensioni: `pgcrypto` per `gen_random_uuid()`. Nessun'altra estensione senza approvazione.

## Commands

```
Avvio locale:       supabase start
Reset + migrazioni: supabase db reset
Nuova migrazione:   supabase migration new <nome_in_snake_case>
Test:               supabase test db
Diff schema:        supabase db diff --local
Deploy remoto:      supabase db push
Stop locale:        supabase stop
```

## Project Structure

```
/CAPABILITY-MAP.md          → mappa dei moduli (indice delle spec)
/SPEC-data-store.md         → questa spec
/supabase/config.toml       → configurazione progetto
/supabase/migrations/       → migrazioni SQL, una per argomento, mai modificate dopo l'applicazione
/supabase/tests/            → test pgTAP, un file per regola o gruppo di regole
/supabase/seed.sql          → dati di esempio con persone e testate inventate
```

### Tabelle

| Tabella | Contenuto | Note |
|---|---|---|
| `sources` | Domini delle fonti: `domain` (unico), `name`, `trust_level` (`guaranteed` / `unverified`) | L'elenco `guaranteed` lo gestisce solo l'autore |
| `seeds` | Candidati: `url` normalizzato (unico), `title`, `origin` (`engine` / `manual`), `ethical_reason`, `status` (`proposed`, `selected`, `rejected`, `expired`, `drafted`), `proposed_on` | I candidati `proposed` diventano `expired` dopo 7 giorni |
| `articles` | Notizie: `kind` (`brief` / `deep_dive`), `parent_article_id`, `seed_id`, `status`, `slug` (unico), campi IT ed EN | Breve: `title`, `lead`, `why_it_matters`, `open_question`, `author_note`. Approfondimento: in più `body` in markdown |
| `facts` | Fatti con `source_url`, `source_id`, `second_source_url`, `verification`, `source_excerpt` (interno, mai pubblicato) | Appartiene a un articolo **oppure** a una persona (vincolo XOR); per le persone `field` indica il campo del profilo |
| `people` | Persone pubbliche del settore AI: `wikidata_qid` (unico), `full_name`, `category`, `current_role`, `organization`, `ai_relation`, `interests_affiliations` (IT ed EN), `status`, `last_refreshed_at`, `slug` | Solo persone pubbliche (vedi Boundaries) |
| `person_revisions` | Proposte di modifica a persone pubblicate: `person_id`, `changes` (jsonb), `status` | Applicate solo dall'autore (R7) |
| `statements` | Dichiarazioni: `person_id`, `said_on`, `paraphrase_it`, `paraphrase_en`, `excerpt`, `source_url`, `status` | R4 |
| `person_news` | News sul profilo: `person_id`, `title`, `outlet`, `published_on`, `url` | Aggiunta automatica ammessa (R7) |
| `article_people` | Collegamento notizia–persona con `role` (`protagonist` / `mentioned`) | Aggiunta automatica ammessa (R7) |
| `newsletter_issues` | Numero settimanale per lingua: `week_start`, `lang`, `body_markdown`, `status`, `sent_at` | Uno per lingua per settimana |
| `newsletter_issue_articles` | Notizie incluse in un numero | |
| `error_reports` | Segnalazioni dal sito: `target_type`, `target_id`, `message`, `reporter_email` (facoltativa), `status` | Scrittura anonima ammessa, lettura solo autore |
| `status_events` | Registro dei cambi di stato: `entity_type`, `entity_id`, `from_status`, `to_status`, `actor`, `note`, `at` | R9 |

### Ruoli e accessi

| Ruolo | Può | Non può |
|---|---|---|
| `engine_writer` (n8n) | Inserire candidati, bozze, fatti, collegamenti, news; portare `approved` → `published` | Approvare, modificare persone pubblicate, leggere `error_reports` |
| `author` (autore autenticato tramite Supabase Auth) | Tutto, tramite funzioni di transizione | Disattivare RLS o i trigger |
| `anon` (sito pubblico) | Leggere le viste `public_*`; inserire in `error_reports` | Leggere tabelle, bozze, colonne interne |

Le transizioni di stato passano solo da funzioni (`submit_for_review`, `approve`, `reject`, `publish`) che verificano ruolo e regole. Gli `UPDATE` diretti sulla colonna `status` sono bloccati da trigger.

## Code Style

Nomi in inglese, `snake_case`, tabelle al plurale, enum come tipi Postgres, vincoli con nome esplicito, `COMMENT ON` per ogni tabella. Ogni tabella ha `id uuid` e `created_at`. Una migrazione tratta un solo argomento.

```sql
create type fact_verification as enum (
  'auto_guaranteed', 'second_source', 'author_verified', 'unverified'
);

create table facts (
  id uuid primary key default gen_random_uuid(),
  article_id uuid references articles (id) on delete cascade,
  person_id uuid references people (id) on delete cascade,
  field text,
  position int not null default 0,
  text_it text not null,
  text_en text,
  source_url text not null,
  source_id uuid references sources (id),
  second_source_url text,
  verification fact_verification not null default 'unverified',
  source_excerpt text,
  created_at timestamptz not null default now(),
  constraint facts_owner_xor check (num_nonnulls(article_id, person_id) = 1),
  constraint facts_person_field check (person_id is null or field is not null)
);

comment on table facts is
  'Fatti verificabili di notizie e profili. source_excerpt è interno e non va mai esposto.';
```

La validità di un fatto (R2) è calcolata da una funzione `fact_is_valid(facts)` usata sia dal trigger di approvazione sia dai test, così la regola vive in un solo punto.

## Testing Strategy

1. **Strumento.** pgTAP tramite `supabase test db`, file in `supabase/tests/`.
2. **Copertura richiesta.** Ogni regola da R1 a R10 ha almeno un test che passa (caso consentito) e uno che fallisce (caso vietato), con i nomi dei test che citano l'id della regola, per esempio `R1: approvazione rifiutata con fatto senza fonte`.
3. **Ruoli.** I test di R6, R7 e R8 eseguono le operazioni impersonando `engine_writer`, `author` e `anon`.
4. **Dati di esempio.** `seed.sql` contiene tre brevi, un approfondimento, una persona inventata (non reale), due testate inventate (una `guaranteed`, una `unverified`).
5. **Esclusioni.** La logica di n8n e del sito non si testa qui: questo modulo verifica solo schema, regole, ruoli e viste.

## Boundaries

1. **Always.** Ogni cambiamento allo schema passa da una nuova migrazione. Eseguire `supabase db reset` e `supabase test db` prima di ogni commit. Attivare RLS su ogni nuova tabella nella stessa migrazione che la crea. Aggiungere `COMMENT ON` a ogni nuova tabella.
2. **Ask first.** Modifiche alla macchina degli stati o agli enum. Modifiche alle regole R1–R10 o ai livelli di fiducia delle fonti. Nuove estensioni. Rimozione di colonne. Cambio di piano o di regione Supabase.
3. **Never.** Modificare una migrazione già applicata. Disattivare RLS o i trigger delle regole. Committare chiavi o stringhe di connessione. Esporre bozze o colonne interne al ruolo `anon`. Inserire in `people` persone che non siano figure pubbliche del settore AI. Cancellare definitivamente contenuti pubblicati.

## Success Criteria

1. `supabase db reset` applica tutte le migrazioni su un database vuoto senza errori.
2. `supabase test db` passa con almeno un test positivo e uno negativo per ciascuna regola R1–R10.
3. Con la chiave `anon`, ogni query su righe non pubblicate restituisce 0 righe e le colonne interne non compaiono in nessuna vista.
4. Con il ruolo `engine_writer`, `approve` fallisce e `publish` su un contenuto approvato riesce.
5. Con il ruolo `author`, approvare una breve con un fatto da fonte `unverified` senza seconda fonte fallisce, e riesce dopo aver impostato `verification = 'author_verified'`.
6. Dopo `seed.sql`, le viste `public_articles`, `public_people` e `public_statements` restituiscono solo i contenuti pubblicati di esempio.
7. Ogni tabella ha un `COMMENT ON`.

## Decisioni (domande aperte chiuse il 2026-10-07)

1. L'estratto letterale di una dichiarazione non supera 25 parole (R4).
2. Una notizia pubblicata resta online durante la correzione; la correzione è registrata in `status_events`.
3. I candidati non scelti diventano `expired` dopo 7 giorni.
4. Si parte con il piano Supabase gratuito; la raccolta quotidiana evita la pausa per inattività.
5. n8n si connette con il ruolo Postgres dedicato `engine_writer`, mai con la chiave di servizio di Supabase.
