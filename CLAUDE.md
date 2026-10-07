# CLAUDE.md

Progetto doandroidsdream: notizie brevi quotidiane sull'AI filtrate per rilevanza etica e sociale, approfondimenti, profili dei protagonisti pubblici, sito IT/EN e newsletter. Modulo in costruzione: `data-store`.

## Leggi prima di iniziare, in quest'ordine

1. `CAPABILITY-MAP.md`: moduli, dipendenze e intento confermato
2. `SPEC-data-store.md`: regole R1-R10, tabelle, ruoli, boundaries, criteri di successo
3. `tasks/plan.md`: decisioni e rischi
4. `tasks/todo.md`: i task da eseguire, in ordine

## Come lavori

1. Un task alla volta, nell'ordine di `tasks/todo.md`. Non iniziare il successivo finché tutte le caselle del corrente non sono spuntate.
2. Per ogni task: implementa, esegui `supabase db reset` e `supabase test db`, spunta le caselle in `tasks/todo.md`, poi fai un commit con messaggio `data-store: Task <id> <titolo breve>`.
3. Scrivi prima il test negativo di una regola (deve fallire per il motivo giusto), poi l'implementazione.
4. Se un criterio di accettazione non si può soddisfare, fermati e spiega il problema con le alternative. Non indebolire un test e non cambiare una regola per farlo passare.
5. Parla con l'autore in italiano. Codice, nomi di tabelle e funzioni in inglese; documentazione e commenti di migrazione in italiano.

## Quando ti fermi e chiedi all'autore

1. A ogni checkpoint (A, B, C): riassumi cosa è stato fatto, l'esito dei test e cosa viene dopo.
2. Task 0b: la creazione del progetto Supabase remoto la fa l'autore.
3. Task 0c: la password di `engine_writer` la imposta l'autore dall'editor SQL di Supabase.
4. Prima di ogni `supabase db push` o qualsiasi operazione sul database remoto.
5. Per tutto ciò che la spec elenca in "Ask first".

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

## Never

1. Committare password, chiavi o stringhe di connessione, o stamparle nei log. I segreti stanno solo nei segreti di Codespaces; `.env.example` elenca i nomi, mai i valori.
2. Modificare una migrazione già applicata: crea sempre una nuova migrazione.
3. Disattivare RLS o i trigger delle regole, anche temporaneamente.
4. Usare la chiave di servizio di Supabase al posto del ruolo `engine_writer` per simulare il motore.
5. Inserire nomi di persone reali in `seed.sql` o nei test.
