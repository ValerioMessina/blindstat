# Sport RealTime Data Provider API

Questa API è stata sviluppata con **FastAPI** e **SQLAlchemy** per gestire dati relativi a sport, atleti, club, tornei, match (individuali e a squadre) e altre statistiche sportive. L'API fornisce dati in tempo reale ed è destinata ad essere utilizzata come backend per applicazioni mobile e web.

---

## Sommario

- [Introduzione](#introduzione)
- [Tecnologie e Dipendenze](#tecnologie-e-dipendenze)
- [Struttura del Progetto](#struttura-del-progetto)
- [Setup e Installazione](#setup-e-installazione)
- [Configurazione del Database](#configurazione-del-database)
- [Struttura del Database](#struttura-del-database)
- [Endpoint API e Esempi di Risposta](#endpoint-api-e-esempi-di-risposta)
- [Autenticazione](#autenticazione)
- [Esecuzione con Ngrok](#esecuzione-con-ngrok)
- [Considerazioni Finali](#considerazioni-finali)

---

## Introduzione

La **Sport RealTime Data Provider API** consente di:
- Visualizzare informazioni su sport, club e tornei.
- Gestire e monitorare match individuali e a squadre.
- Restituire dettagli estesi dei match, inclusi eventi e statistiche per set.
- Supportare l'inserimento di dati (ad esempio, eventi in partita) da parte di arbitri e amministratori.

Questa API è ideale per progetti che richiedono dati sportivi in tempo reale, aggiornamenti dinamici e integrazione con app di scoring.

---

## Tecnologie e Dipendenze

- **Python 3.10+**
- **FastAPI** – Framework web veloce e moderno.
- **SQLAlchemy** – ORM per la gestione del database.
- **Pydantic** – Per la definizione degli schemi di risposta e validazione dei dati.
- **Uvicorn** – Server ASGI per eseguire l'applicazione FastAPI.
- **PostgreSQL** – Database relazionale.

---

## Struttura del Progetto

1. **Modelli del Database (SQLAlchemy):**  
   - Sport, Athlete, Club, AthleteClub, Team, TeamMember, Tournament, Match, MatchEvent, MatchStatistic, FavoriteAthlete, TeamMatch.  
   Questi modelli rappresentano le entità principali e le relazioni (molti-a-molti, uno-a-molti).

2. **Schemi di Risposta (Pydantic):**  
   - Schemi come `SportOut`, `AthleteOut`, `ClubOut`, `TournamentOut`, `MatchEventOut`, `MatchFullDetailOut` ecc.  
   - **Importante:** Ogni schema ha abilitato `orm_mode = True` e `from_attributes = True` per consentire l'uso di `from_orm`.

3. **Endpoint FastAPI:**  
   - Endpoints per recuperare sport, club, tornei, atleti, match e per inserire eventi.
   - Endpoint protetti per l'inserimento di dati, con autenticazione semplificata.

4. **Autenticazione:**  
   - Implementata in maniera semplificata con OAuth2PasswordBearer (stub per scopi di test).

---

## Setup e Installazione

### Prerequisiti

- Python (3.10 o superiore)
- PostgreSQL
- Ambiente virtuale (consigliato)

### Installazione delle Dipendenze

1. Creare e attivare un ambiente virtuale:
   ```bash
   python -m venv env
   source env/bin/activate   # Su Windows: env\Scripts\activate

