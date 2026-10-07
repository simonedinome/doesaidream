# Capability Map: doandroidsdream

Approvata il 2026-10-07.

## Intento confermato

1. **Risultato.** Sito IT/EN con notizie brevi quotidiane sull'AI filtrate per rilevanza etica e sociale, approfondimenti quando una notizia lo merita (1-4 al mese), profili dei protagonisti pubblici collegati alle notizie, fonti linkate come in un aggregatore. Newsletter settimanale su Substack composta da n8n e inviata a mano.
2. **Lettore.** Chiunque sia interessato, tecnici compresi. Scrittura per non specialisti.
3. **Perché ora.** Parlare dei temi AI che interessano all'autore e costruire un progetto tecnico visibile su LinkedIn.
4. **Successo a 3 mesi.** 5-6 brevi a settimana per 12 settimane senza salti, motore che regge da solo, almeno un post LinkedIn che porta contatti professionali.
5. **Vincoli.** Massimo ~7 ore a settimana di lavoro umano. Ogni contenuto passa dall'autore prima della pubblicazione, tranne collegamenti e news aggiunti a profili già approvati. Database + CMS, n8n self-hosted, fonti a doppio livello di fiducia.
6. **Fuori dalla prima versione.** Video TikTok/Instagram, glossario dei termini, profili di privati e aziende, notizie AI senza implicazione etica, pubblicazione automatica su Substack.

## Moduli

| Module id | Responsabilità | Dipende da |
|---|---|---|
| platform-infra | Server n8n (Docker, HTTPS, backup, segreti) | — |
| data-store | Archivio: candidati, notizie, persone, dichiarazioni, fonti con livello di fiducia, numeri newsletter; regole di integrità e stati | — |
| source-ingest | Raccolta giornaliera, filtro etico, short list ≤5, ingresso manuale via Telegram | data-store |
| brief-drafting | Da seme a bozza breve con fatti e fonti, controlli automatici | data-store, source-ingest |
| review-console | Avvisi e scelte su Telegram, pagina privata di modifica e approvazione | data-store |
| publishing | Traduzione EN, controlli di coerenza, pubblicazione, rebuild del sito, export pubblico settimanale | data-store, review-console |
| public-site | Pagine notizia, approfondimento e persona IT/EN, "segnala un errore" | data-store |
| people-profiles | Riconoscimento del protagonista, match Wikidata, bozza o aggiornamento a tre livelli | data-store, brief-drafting |
| deep-dives | Bozza di approfondimento da una breve, su richiesta | data-store, brief-drafting |
| newsletter-composer | Composizione settimanale per Substack, inviata all'autore | data-store, publishing |

Il confine tra i moduli è `data-store`: ogni modulo scrive le sue bozze nell'archivio e `review-console` le rivede tutte allo stesso modo. Nessuna dipendenza circolare.

## Ordine di costruzione

1. platform-infra, data-store
2. source-ingest, brief-drafting, review-console
3. publishing, public-site → **traguardo 1: una breve attraversa il sistema fino al sito**
4. people-profiles, deep-dives
5. newsletter-composer

## Assunzioni approvate

1. Archivio su Supabase (Postgres gestito, regione UE).
2. Sito statico (es. Astro) su hosting gratuito, termini d'uso commerciale da verificare in SPEC-public-site.
3. Un solo fornitore di modelli via API per bozze e traduzioni, da scegliere in SPEC-brief-drafting.
4. n8n su VPS con Docker e HTTPS tramite reverse proxy.
5. Un solo repository GitHub; ogni modulo ha la sua spec `SPEC-<module-id>.md` accanto a questa mappa.
