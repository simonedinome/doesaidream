# doandroidsdream

Notizie brevi quotidiane sull'AI filtrate per rilevanza etica e sociale, approfondimenti, profili dei protagonisti pubblici, sito IT/EN e newsletter.

Modulo in costruzione: `data-store`, l'archivio Supabase che fa da confine tra tutti i moduli.

## Documenti

1. `CAPABILITY-MAP.md`: moduli, dipendenze e intento confermato
2. `SPEC-data-store.md`: regole R1-R10, tabelle, ruoli, criteri di successo
3. `tasks/plan.md`: decisioni e rischi
4. `tasks/todo.md`: task in ordine, con criteri di accettazione
5. `CLAUDE.md`: istruzioni per l'agente

## Ambiente di sviluppo (GitHub Codespaces)

Il devcontainer in `.devcontainer/` prepara:

1. Node.js 22 (immagine `mcr.microsoft.com/devcontainers/javascript-node:22-bookworm`)
2. Docker-in-Docker, necessario per `supabase start`
3. Supabase CLI, versione fissata in `package.json` e `package-lock.json`, installata con `npm ci` e disponibile come comando `supabase`
4. Client `psql`, per le verifiche di connessione al database remoto

Primo avvio: dalla pagina del repository, **Code → Codespaces → Create codespace on `<branch>`**. Alla prima creazione lo script `.devcontainer/post-create.sh` installa tutto e stampa le versioni (alcuni minuti). Basta la macchina da 2 core e 8 GB.

Poi, nel terminale del Codespace:

```
supabase start     # la prima volta scarica le immagini Docker
supabase status    # deve mostrare API, DB e Studio attivi
supabase db reset
```

Per aggiornare la CLI: `npm install -D supabase@<versione>`, poi commit di `package.json` e `package-lock.json` e ricostruzione del Codespace.

### Servizi locali

In `supabase/config.toml` sono spenti i servizi che `data-store` non usa: realtime, storage, edge functions, analytics e server email di prova. Restano attivi database, API, autenticazione e Studio. Si riattivano impostando `enabled = true` nella sezione corrispondente.

`auto_expose_new_tables = false`: come nei nuovi progetti Supabase remoti, una tabella o vista è raggiungibile dall'API solo con un `GRANT` esplicito.

## Comandi

```
supabase start
supabase db reset
supabase migration new <nome_in_snake_case>
supabase test db
supabase db diff --local
supabase db push        # solo dopo conferma dell'autore
supabase stop
```

## Segreti

I valori dei segreti stanno solo nei segreti di GitHub Codespaces assegnati a questo repository (**github.com → Settings → Codespaces → Secrets**). `.env.example` elenca i nomi, mai i valori. Nel repository non vanno mai password, chiavi o stringhe di connessione, nemmeno le chiavi locali stampate da `supabase status`.

I file di collegamento al progetto remoto creati da `supabase link` stanno in `supabase/.temp/`, escluso da `supabase/.gitignore`.

## Struttura

```
/.devcontainer/          → ambiente Codespaces
/supabase/config.toml    → configurazione del progetto Supabase locale
/supabase/migrations/    → migrazioni SQL, mai modificate dopo l'applicazione
/supabase/tests/         → test pgTAP
/supabase/seed.sql       → dati di esempio con persone e testate inventate
/tasks/                  → piano e task di data-store
```
