-----------------------------------------------------------
-- 1. Tabella degli SPORT
-----------------------------------------------------------
CREATE TABLE sports (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    logo_url VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-----------------------------------------------------------
-- 2. Tabella delle FEDERAZIONI
-----------------------------------------------------------
CREATE TABLE federations (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    address VARCHAR(200),
    contact_email VARCHAR(100),
    contact_phone VARCHAR(50),
    api_submission_method VARCHAR(50) DEFAULT 'INTERNAL',
    external_api_url VARCHAR(255),
    external_api_token VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-----------------------------------------------------------
-- 3. Tabella di JOIN FEDERAZIONI <-> SPORT
-----------------------------------------------------------
CREATE TABLE federation_sports (
    federation_id INT NOT NULL REFERENCES federations(id),
    sport_id INT NOT NULL REFERENCES sports(id),
    PRIMARY KEY (federation_id, sport_id)
);

-----------------------------------------------------------
-- 4. Tabella dei CLUB (SQUADRE)
-----------------------------------------------------------
CREATE TABLE clubs (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    address VARCHAR(200),
    city VARCHAR(100),
    region VARCHAR(100),
    logo_url VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-----------------------------------------------------------
-- 5. Tabella di JOIN CLUB <-> SPORT
-----------------------------------------------------------
CREATE TABLE club_sports (
    club_id INT NOT NULL REFERENCES clubs(id),
    sport_id INT NOT NULL REFERENCES sports(id),
    PRIMARY KEY (club_id, sport_id)
);

-----------------------------------------------------------
-- 6. Tabella di JOIN FEDERAZIONI <-> CLUB
-----------------------------------------------------------
CREATE TABLE federation_clubs (
    federation_id INT NOT NULL REFERENCES federations(id),
    club_id INT NOT NULL REFERENCES clubs(id),
    PRIMARY KEY (federation_id, club_id)
);

-----------------------------------------------------------
-- 7. Tabella degli ATLETI
-----------------------------------------------------------
CREATE TABLE athletes (
    id SERIAL PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    birthdate DATE,
    gender VARCHAR(10),
    disability_info VARCHAR(255),
    photo_url VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-----------------------------------------------------------
-- 8. Tabella di JOIN ATLETI <-> CLUB
-----------------------------------------------------------
CREATE TABLE athlete_clubs (
    athlete_id INT NOT NULL REFERENCES athletes(id),
    club_id INT NOT NULL REFERENCES clubs(id),
    PRIMARY KEY (athlete_id, club_id)
);

-----------------------------------------------------------
-- 9. Tabella dei TORNEI (CAMPIONATI/EVENTI)
-----------------------------------------------------------
CREATE TABLE tournaments (
    id SERIAL PRIMARY KEY,
    federation_id INT NOT NULL REFERENCES federations(id),
    sport_id INT NOT NULL REFERENCES sports(id),
    name VARCHAR(150) NOT NULL,
    start_date TIMESTAMP WITH TIME ZONE,
    end_date TIMESTAMP WITH TIME ZONE,
    location VARCHAR(150),
    tournament_type VARCHAR(50), -- es. 'Round Robin', 'Elim. Diretta'
    competition_type VARCHAR(20) CHECK (competition_type IN ('INDIVIDUAL', 'TEAM', 'RACE')) DEFAULT 'INDIVIDUAL',
    is_open BOOLEAN DEFAULT FALSE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-----------------------------------------------------------
-- 10. Tabella di JOIN TORNEI <-> ATLETI (per competizioni individuali)
-----------------------------------------------------------
CREATE TABLE tournament_athletes (
    id SERIAL PRIMARY KEY,
    tournament_id INT NOT NULL REFERENCES tournaments(id),
    athlete_id INT NOT NULL REFERENCES athletes(id),
    seeding INT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (tournament_id, athlete_id)
);

-----------------------------------------------------------
-- 11. Tabella degli INCONTRI (MATCHES) per competizioni individuali
-----------------------------------------------------------
CREATE TABLE matches (
    id SERIAL PRIMARY KEY,
    tournament_id INT NOT NULL REFERENCES tournaments(id),
    round INT,
    scheduled_at TIMESTAMP WITH TIME ZONE,
    athlete1_id INT NOT NULL REFERENCES athletes(id),
    athlete2_id INT NOT NULL REFERENCES athletes(id),
    score1 INT DEFAULT 0,
    score2 INT DEFAULT 0,
    status VARCHAR(20) DEFAULT 'SCHEDULED',
    winner_id INT REFERENCES athletes(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (tournament_id, round, athlete1_id, athlete2_id)
);

-----------------------------------------------------------
-- 12. Tabella degli EVENTI IN PARTITA (per incontri individuali)
-----------------------------------------------------------
CREATE TABLE match_events (
    id SERIAL PRIMARY KEY,
    match_id INT NOT NULL REFERENCES matches(id),
    event_time INTERVAL,         -- tempo trascorso dall'inizio dell'incontro
    event_type VARCHAR(50),      -- es. 'Punto', 'Fallo', 'Cambio set', 'Mossa'
    description TEXT,
    athlete_id INT REFERENCES athletes(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-----------------------------------------------------------
-- 13. Tabella delle STATISTICHE INDIVIDUALI per incontro (generiche)
-----------------------------------------------------------
CREATE TABLE match_statistics (
    id SERIAL PRIMARY KEY,
    match_id INT NOT NULL REFERENCES matches(id),
    athlete_id INT NOT NULL REFERENCES athletes(id),
    stat_key VARCHAR(100),       -- es. 'ace', 'double_fault', 'movimenti', 'colpi', 'mosse'
    stat_value VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-----------------------------------------------------------
-- 14. Tabella delle SQUADRE (per competizioni a squadre)
-----------------------------------------------------------
CREATE TABLE teams (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    club_id INT REFERENCES clubs(id),
    logo_url VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-----------------------------------------------------------
-- 15. Tabella di JOIN per gli ATLETI nelle SQUADRE
-----------------------------------------------------------
CREATE TABLE team_members (
    team_id INT NOT NULL REFERENCES teams(id),
    athlete_id INT NOT NULL REFERENCES athletes(id),
    role VARCHAR(50),            -- es. 'attaccante', 'difensore', 'portiere'
    PRIMARY KEY (team_id, athlete_id)
);

-----------------------------------------------------------
-- 16. Tabella di JOIN TORNEI <-> SQUADRE (per competizioni a squadre)
-----------------------------------------------------------
CREATE TABLE tournament_teams (
    id SERIAL PRIMARY KEY,
    tournament_id INT NOT NULL REFERENCES tournaments(id),
    team_id INT NOT NULL REFERENCES teams(id),
    seeding INT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (tournament_id, team_id)
);

-----------------------------------------------------------
-- 17. Tabella degli INCONTRI a SQUADRE
-----------------------------------------------------------
CREATE TABLE team_matches (
    id SERIAL PRIMARY KEY,
    tournament_id INT NOT NULL REFERENCES tournaments(id),
    round INT,
    scheduled_at TIMESTAMP WITH TIME ZONE,
    team1_id INT NOT NULL REFERENCES teams(id),
    team2_id INT NOT NULL REFERENCES teams(id),
    score1 INT DEFAULT 0,
    score2 INT DEFAULT 0,
    status VARCHAR(20) DEFAULT 'SCHEDULED',
    winner_team_id INT REFERENCES teams(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (tournament_id, round, team1_id, team2_id)
);

-----------------------------------------------------------
-- 18. Tabella degli EVENTI IN PARTITA (per incontri a squadre)
-----------------------------------------------------------
CREATE TABLE team_match_events (
    id SERIAL PRIMARY KEY,
    team_match_id INT NOT NULL REFERENCES team_matches(id),
    event_time INTERVAL,         -- tempo trascorso dall'inizio dell'incontro
    event_type VARCHAR(50),      -- es. 'Punto', 'Errore', 'Cambio giocatore'
    description TEXT,
    team_id INT REFERENCES teams(id),
    athlete_id INT REFERENCES athletes(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-----------------------------------------------------------
-- 19. Tabella delle STATISTICHE per incontri a squadre (generiche)
-----------------------------------------------------------
CREATE TABLE team_match_statistics (
    id SERIAL PRIMARY KEY,
    team_match_id INT NOT NULL REFERENCES team_matches(id),
    team_id INT NOT NULL REFERENCES teams(id),
    stat_key VARCHAR(100),       -- es. 'gol', 'errori', 'inning', 'colpi'
    stat_value VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-----------------------------------------------------------
-- 20. Tabella dei RISULTATI PER LE GARE (RACES)
-----------------------------------------------------------
CREATE TABLE race_results (
    id SERIAL PRIMARY KEY,
    tournament_id INT NOT NULL REFERENCES tournaments(id),
    athlete_id INT REFERENCES athletes(id),
    team_id INT REFERENCES teams(id),
    finish_time INTERVAL,
    rank INT,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CHECK (
      (athlete_id IS NOT NULL AND team_id IS NULL) OR 
      (athlete_id IS NULL AND team_id IS NOT NULL)
    )
);

-----------------------------------------------------------
-- 21. Tabella degli ARBITRI
-----------------------------------------------------------
CREATE TABLE referees (
    id SERIAL PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    birthdate DATE,
    gender VARCHAR(10),
    contact_email VARCHAR(100),
    contact_phone VARCHAR(50),
    photo_url VARCHAR(255),
    certification VARCHAR(100),
    bio TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-----------------------------------------------------------
-- 22. Tabella di JOIN ARBITRI <-> FEDERAZIONI
-----------------------------------------------------------
CREATE TABLE referee_federations (
    referee_id INT NOT NULL REFERENCES referees(id),
    federation_id INT NOT NULL REFERENCES federations(id),
    PRIMARY KEY (referee_id, federation_id)
);

-----------------------------------------------------------
-- 23. Tabella di JOIN ARBITRI <-> SPORT
-----------------------------------------------------------
CREATE TABLE referee_sports (
    referee_id INT NOT NULL REFERENCES referees(id),
    sport_id INT NOT NULL REFERENCES sports(id),
    PRIMARY KEY (referee_id, sport_id)
);

-----------------------------------------------------------
-- 24. Tabella di JOIN ARBITRI <-> INCONTRI INDIVIDUALI
-----------------------------------------------------------
CREATE TABLE match_referees (
    match_id INT NOT NULL REFERENCES matches(id),
    referee_id INT NOT NULL REFERENCES referees(id),
    PRIMARY KEY (match_id, referee_id)
);

-----------------------------------------------------------
-- 25. Tabella di JOIN ARBITRI <-> INCONTRI A SQUADRE
-----------------------------------------------------------
CREATE TABLE team_match_referees (
    team_match_id INT NOT NULL REFERENCES team_matches(id),
    referee_id INT NOT NULL REFERENCES referees(id),
    PRIMARY KEY (team_match_id, referee_id)
);

-----------------------------------------------------------
-- 26. Tabella degli UTENTI (viewer)
-----------------------------------------------------------
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(100) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    registration_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-----------------------------------------------------------
-- 27. Tabelle dei PREFERITI (separati per garantire integrità referenziale)
-----------------------------------------------------------
CREATE TABLE favorite_matches (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(id),
    match_id INT NOT NULL REFERENCES matches(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (user_id, match_id)
);

CREATE TABLE favorite_tournaments (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(id),
    tournament_id INT NOT NULL REFERENCES tournaments(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (user_id, tournament_id)
);

CREATE TABLE favorite_athletes (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(id),
    athlete_id INT NOT NULL REFERENCES athletes(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (user_id, athlete_id)
);

CREATE TABLE favorite_teams (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(id),
    team_id INT NOT NULL REFERENCES teams(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (user_id, team_id)
);

-----------------------------------------------------------
-- 28. Tabella delle NOTIFICHE per UTENTI
-----------------------------------------------------------
CREATE TABLE notifications (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(id),
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-----------------------------------------------------------
-- 29. Tabelle delle STATISTICHE AGGREGATE DEL TORNEO (separate)
-----------------------------------------------------------
CREATE TABLE tournament_athlete_statistics (
    id SERIAL PRIMARY KEY,
    tournament_id INT NOT NULL REFERENCES tournaments(id),
    athlete_id INT NOT NULL REFERENCES athletes(id),
    stat_key VARCHAR(100),
    stat_value VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (tournament_id, athlete_id, stat_key)
);

CREATE TABLE tournament_team_statistics (
    id SERIAL PRIMARY KEY,
    tournament_id INT NOT NULL REFERENCES tournaments(id),
    team_id INT NOT NULL REFERENCES teams(id),
    stat_key VARCHAR(100),
    stat_value VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (tournament_id, team_id, stat_key)
);

-----------------------------------------------------------
-- 30. Tabelle dedicate per statistiche specifiche per sport
-----------------------------------------------------------
-- Esempio per Baseball
CREATE TABLE baseball_match_statistics (
    id SERIAL PRIMARY KEY,
    match_id INT NOT NULL REFERENCES matches(id),
    inning INT NOT NULL,
    runs_scored INT DEFAULT 0,
    errors INT DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (match_id, inning)
);

-- Esempio per Scacchi
CREATE TABLE chess_match_statistics (
    id SERIAL PRIMARY KEY,
    match_id INT NOT NULL REFERENCES matches(id),
    moves_count INT,
    average_time_per_move INTERVAL,
    result VARCHAR(20),  -- es. 'Vittoria Bianco', 'Vittoria Nero', 'Patta'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Esempio per Ciclismo (statistiche di gara)
CREATE TABLE cycling_race_statistics (
    id SERIAL PRIMARY KEY,
    race_result_id INT NOT NULL REFERENCES race_results(id),
    average_speed DECIMAL(5,2),   -- km/h
    total_distance DECIMAL(7,2),  -- km
    elevation_gain DECIMAL(7,2),  -- metri
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-----------------------------------------------------------
-- 31. Tabella di LOG per Versionamento e Cronologia
-----------------------------------------------------------
CREATE TABLE change_logs (
    id SERIAL PRIMARY KEY,
    table_name VARCHAR(100) NOT NULL,
    record_id INT NOT NULL,
    operation VARCHAR(10) NOT NULL,  -- es. 'INSERT', 'UPDATE', 'DELETE'
    changed_data JSONB,              -- dati modificati
    changed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    changed_by INT                 -- opzionale: id dell'utente o sistema che ha effettuato il cambiamento
);
