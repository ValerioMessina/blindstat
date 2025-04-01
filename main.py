import datetime
from datetime import timedelta, datetime as dt
from typing import List, Optional

from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from pydantic import BaseModel
from sqlalchemy import (
    create_engine,
    Column,
    Integer,
    String,
    DateTime,
    Date,
    Text,
    Boolean,
    ForeignKey,
    Interval,
    func,
    desc,
)
from sqlalchemy.orm import sessionmaker, relationship, Session, declarative_base, joinedload

# Configurazione database (modifica DATABASE_URL con i dati reali)
DATABASE_URL = "postgresql://valeriomessina@localhost:5432/blindstat"

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# ------------------------
# MODELLI DATABASE (SQLAlchemy)
# ------------------------

class Sport(Base):
    __tablename__ = 'sports'
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False)
    logo_url = Column(String(255))
    created_at = Column(DateTime, default=dt.utcnow)
    updated_at = Column(DateTime, default=dt.utcnow)

class Athlete(Base):
    __tablename__ = 'athletes'
    id = Column(Integer, primary_key=True, index=True)
    first_name = Column(String(100), nullable=False)
    last_name = Column(String(100), nullable=False)
    birthdate = Column(Date)
    gender = Column(String(10))
    disability_info = Column(String(255))
    photo_url = Column(String(255))
    created_at = Column(DateTime, default=dt.utcnow)
    updated_at = Column(DateTime, default=dt.utcnow)
    # Relazione con i club (molti a molti)
    clubs = relationship("Club", secondary="athlete_clubs", back_populates="athletes")

# Nuovo modello per la join tra atleti e club
class AthleteClub(Base):
    __tablename__ = 'athlete_clubs'
    athlete_id = Column(Integer, ForeignKey('athletes.id'), primary_key=True)
    club_id = Column(Integer, ForeignKey('clubs.id'), primary_key=True)

class Club(Base):
    __tablename__ = 'clubs'
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False)
    address = Column(String(200))
    city = Column(String(100))
    region = Column(String(100))
    logo_url = Column(String(255))
    created_at = Column(DateTime, default=dt.utcnow)
    updated_at = Column(DateTime, default=dt.utcnow)
    # Relazione con gli atleti (molti a molti)
    athletes = relationship("Athlete", secondary="athlete_clubs", back_populates="clubs")

# Il modello Team rimane per i team utilizzati nei match a squadre
class Team(Base):
    __tablename__ = 'teams'
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False)
    club_id = Column(Integer)  # riferimento alla tabella clubs (semplificato)
    logo_url = Column(String(255))
    created_at = Column(DateTime, default=dt.utcnow)
    updated_at = Column(DateTime, default=dt.utcnow)
    # Relazione con i membri della squadra
    members = relationship("TeamMember", back_populates="team")

class TeamMember(Base):
    __tablename__ = 'team_members'
    team_id = Column(Integer, ForeignKey('teams.id'), primary_key=True)
    athlete_id = Column(Integer, ForeignKey('athletes.id'), primary_key=True)
    role = Column(String(50))
    team = relationship("Team", back_populates="members")
    athlete = relationship("Athlete")

class Tournament(Base):
    __tablename__ = 'tournaments'
    id = Column(Integer, primary_key=True, index=True)
    federation_id = Column(Integer)
    sport_id = Column(Integer)
    name = Column(String(150), nullable=False)
    start_date = Column(DateTime)
    end_date = Column(DateTime)
    location = Column(String(150))
    tournament_type = Column(String(50))
    competition_type = Column(String(20))
    is_open = Column(Boolean, default=False)
    notes = Column(Text)
    created_at = Column(DateTime, default=dt.utcnow)
    updated_at = Column(DateTime, default=dt.utcnow)

# Modello per i match individuali
class Match(Base):
    __tablename__ = 'matches'
    id = Column(Integer, primary_key=True, index=True)
    tournament_id = Column(Integer, ForeignKey('tournaments.id'))
    round = Column(Integer)
    scheduled_at = Column(DateTime)
    athlete1_id = Column(Integer, nullable=False)
    athlete2_id = Column(Integer, nullable=False)
    score1 = Column(Integer, default=0)
    score2 = Column(Integer, default=0)
    status = Column(String(20), default='SCHEDULED')
    winner_id = Column(Integer, nullable=True)
    created_at = Column(DateTime, default=dt.utcnow)
    updated_at = Column(DateTime, default=dt.utcnow)
    # Relazione con gli eventi in partita
    events = relationship("MatchEvent", back_populates="match")
    # Relazione con i risultati dei set / statistiche (ammesso che li usi per salvare i risultati per set)
    statistics = relationship("MatchStatistic", backref="match")

class MatchEvent(Base):
    __tablename__ = 'match_events'
    id = Column(Integer, primary_key=True, index=True)
    match_id = Column(Integer, ForeignKey('matches.id'))
    event_time = Column(Interval)
    event_type = Column(String(50))
    description = Column(Text)
    athlete_id = Column(Integer, nullable=True)
    created_at = Column(DateTime, default=dt.utcnow)
    updated_at = Column(DateTime, default=dt.utcnow)
    match = relationship("Match", back_populates="events")

class MatchStatistic(Base):
    __tablename__ = 'match_statistics'
    id = Column(Integer, primary_key=True, index=True)
    match_id = Column(Integer, ForeignKey('matches.id'))
    athlete_id = Column(Integer, ForeignKey('athletes.id'))
    stat_key = Column(String(100))  # es. "set1", "set2", etc.
    stat_value = Column(String(50)) # es. "6-4" oppure "score1-score2"
    created_at = Column(DateTime, default=dt.utcnow)
    updated_at = Column(DateTime, default=dt.utcnow)

class FavoriteAthlete(Base):
    __tablename__ = 'favorite_athletes'
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, nullable=False)
    athlete_id = Column(Integer, nullable=False)
    created_at = Column(DateTime, default=dt.utcnow)
    # Unique constraint già definito a livello di schema nel database

# Nuovo modello per i team match (match a squadre)
class TeamMatch(Base):
    __tablename__ = 'team_matches'
    id = Column(Integer, primary_key=True, index=True)
    tournament_id = Column(Integer, ForeignKey('tournaments.id'))
    round = Column(Integer)
    scheduled_at = Column(DateTime)
    team1_id = Column(Integer, ForeignKey('teams.id'), nullable=False)
    team2_id = Column(Integer, ForeignKey('teams.id'), nullable=False)
    score1 = Column(Integer, default=0)
    score2 = Column(Integer, default=0)
    status = Column(String(20), default='SCHEDULED')
    winner_team_id = Column(Integer, ForeignKey('teams.id'))
    created_at = Column(DateTime, default=dt.utcnow)
    updated_at = Column(DateTime, default=dt.utcnow)
    # Relazioni per recuperare i dati dei team
    team1 = relationship("Team", foreign_keys=[team1_id])
    team2 = relationship("Team", foreign_keys=[team2_id])

# Creazione delle tabelle (solo per test; in produzione usa migrazioni con Alembic)
Base.metadata.create_all(bind=engine)

# ------------------------
# SCHEMI DI RISPOSTA (Pydantic)
# ------------------------

class SportOut(BaseModel):
    id: int
    name: str
    logo_url: Optional[str] = None

    class Config:
        orm_mode = True
        from_attributes = True

class AthleteOut(BaseModel):
    id: int
    first_name: str
    last_name: str
    photo_url: Optional[str] = None

    class Config:
        orm_mode = True
        from_attributes = True

# Schema per i Club
class ClubOut(BaseModel):
    id: int
    name: str
    address: Optional[str] = None
    city: Optional[str] = None
    region: Optional[str] = None
    logo_url: Optional[str] = None

    class Config:
        orm_mode = True
        from_attributes = True

# Schema esteso per l’atleta, con informazioni sul club (prendiamo il primo club associato, se presente)
class AthleteDetailOut(BaseModel):
    id: int
    first_name: str
    last_name: str
    photo_url: Optional[str] = None
    club: Optional[ClubOut] = None

    class Config:
        orm_mode = True
        from_attributes = True

# Schema per il Team (non esposto tramite endpoint, ma usato in TeamMatch)
class TeamOut(BaseModel):
    id: int
    name: str
    logo_url: Optional[str] = None

    class Config:
        orm_mode = True
        from_attributes = True

class TournamentOut(BaseModel):
    id: int
    name: str
    start_date: Optional[dt]
    end_date: Optional[dt]
    location: Optional[str] = None

    class Config:
        orm_mode = True
        from_attributes = True

# Schema semplificato per i dettagli del torneo
class TournamentDetailOut(BaseModel):
    id: int
    name: str

    class Config:
        orm_mode = True
        from_attributes = True

class MatchEventOut(BaseModel):
    id: int
    event_time: timedelta
    event_type: str
    description: Optional[str] = None

    class Config:
        orm_mode = True
        from_attributes = True

# Schema per il risultato di un set
class SetResultOut(BaseModel):
    set_number: int
    score1: int
    score2: int

    class Config:
        orm_mode = True
        from_attributes = True

# Schema base per i match
class MatchOut(BaseModel):
    id: int
    tournament_id: int
    round: Optional[int]
    scheduled_at: Optional[dt]
    athlete1_id: int
    athlete2_id: int
    score1: int
    score2: int
    status: str

    class Config:
        orm_mode = True
        from_attributes = True

# Schema per i dettagli del match, con eventi (rimane invariato)
class MatchDetailOut(MatchOut):
    events: List[MatchEventOut] = []

    class Config:
        orm_mode = True
        from_attributes = True

# Schema per il match con dettagli estesi (atleti, torneo, set_results e eventi)
class MatchFullDetailOut(BaseModel):
    id: int
    tournament: TournamentDetailOut
    round: Optional[int]
    scheduled_at: Optional[dt]
    athlete1: AthleteDetailOut
    athlete2: AthleteDetailOut
    score1: int
    score2: int
    status: str
    set_results: List[SetResultOut] = []
    events: List[MatchEventOut] = []
    
    class Config:
        orm_mode = True
        from_attributes = True

# Schema per i team match (match a squadre)
class TeamMatchOut(BaseModel):
    id: int
    tournament_id: int
    round: Optional[int]
    scheduled_at: Optional[dt]
    team1_id: int
    team2_id: int
    score1: int
    score2: int
    status: str
    winner_team_id: Optional[int] = None

    class Config:
        orm_mode = True
        from_attributes = True

# ------------------------
# AUTENTICAZIONE (ESEMPIO SEMPLIFICATO)
# ------------------------

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

def fake_decode_token(token: str):
    # In produzione decodifica e valida un JWT
    return {"username": token}

async def get_current_user(token: str = Depends(oauth2_scheme)):
    user = fake_decode_token(token)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Credenziali non valide",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return user

# ------------------------
# DIPENDENZA PER IL DB
# ------------------------

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# ------------------------
# INIZIALIZZAZIONE FASTAPI
# ------------------------

app = FastAPI(
    title="Sport RealTime Data Provider",
    description="API per visualizzare dati in tempo reale e per inserimenti da parte di arbitri e amministratori",
    version="1.0.0"
)

# ------------------------
# ENDPOINT PUBBLICI
# ------------------------

@app.get("/sports", response_model=List[SportOut])
def get_sports(db: Session = Depends(get_db)):
    """Restituisce l'elenco degli sport."""
    sports = db.query(Sport).all()
    return sports

# Endpoint per ottenere l'elenco dei club
@app.get("/clubs", response_model=List[ClubOut])
def get_clubs(db: Session = Depends(get_db)):
    """Restituisce l'elenco dei club (squadre non competitive)."""
    clubs = db.query(Club).all()
    return clubs

# Endpoint per ottenere gli atleti relativi a un team match (tramite i membri del team)
@app.get("/teams/{team_id}/athletes", response_model=List[AthleteOut])
def get_team_athletes(team_id: int, db: Session = Depends(get_db)):
    """Restituisce l'elenco degli atleti relativi a un team."""
    team_members = db.query(TeamMember).filter(TeamMember.team_id == team_id).all()
    if not team_members:
        raise HTTPException(status_code=404, detail="Team non trovato o nessun atleta associato")
    athletes = [member.athlete for member in team_members]
    return athletes

@app.get("/tournaments", response_model=List[TournamentOut])
def get_tournaments(db: Session = Depends(get_db)):
    """Restituisce l'elenco dei campionati (tornei)."""
    tournaments = db.query(Tournament).all()
    return tournaments

@app.get("/athletes/top", response_model=List[AthleteOut])
def get_top_athletes(db: Session = Depends(get_db)):
    """
    Restituisce gli atleti più votati.
    Viene effettuato un join con la tabella dei preferiti per contare le votazioni.
    """
    top_athletes = (
        db.query(Athlete, func.count(FavoriteAthlete.athlete_id).label("votes"))
        .join(FavoriteAthlete, Athlete.id == FavoriteAthlete.athlete_id)
        .group_by(Athlete.id)
        .order_by(desc("votes"))
        .limit(10)
        .all()
    )
    # Estrae solo l'oggetto Athlete
    return [athlete for athlete, votes in top_athletes]

@app.get("/matches/highlights", response_model=List[MatchOut])
def get_highlight_matches(db: Session = Depends(get_db)):
    """
    Restituisce le partite individuali in evidenza.
    In questo esempio consideriamo "in evidenza" quelle partite che hanno almeno un evento associato.
    """
    matches = db.query(Match).join(MatchEvent).group_by(Match.id).all()
    return matches

@app.get("/matches/{match_id}", response_model=MatchFullDetailOut)
def get_match_full_detail(match_id: int, db: Session = Depends(get_db)):
    """Restituisce i dettagli estesi di una partita individuale (atleti, torneo, risultati per set ed eventi)."""
    match = db.query(Match).options(
        joinedload(Match.events),
        joinedload(Match.statistics)
    ).filter(Match.id == match_id).first()
    if not match:
        raise HTTPException(status_code=404, detail="Partita non trovata")

    tournament = db.query(Tournament).filter(Tournament.id == match.tournament_id).first()
    athlete1 = db.query(Athlete).options(joinedload(Athlete.clubs)).filter(Athlete.id == match.athlete1_id).first()
    athlete2 = db.query(Athlete).options(joinedload(Athlete.clubs)).filter(Athlete.id == match.athlete2_id).first()

    # Elaborazione dei risultati dei set (assumendo che stat_key inizi con "set" e stat_value nel formato "score1-score2")
    set_results = []
    for stat in match.statistics:
        if stat.stat_key.lower().startswith("set"):
            try:
                set_number = int(stat.stat_key.lower().replace("set", ""))
                scores = stat.stat_value.split("-")
                score1_set = int(scores[0])
                score2_set = int(scores[1])
                set_results.append(SetResultOut(set_number=set_number, score1=score1_set, score2=score2_set))
            except Exception as e:
                # Se il parsing fallisce, ignora questo risultato
                continue
    set_results.sort(key=lambda x: x.set_number)

    response = {
        "id": match.id,
        "tournament": {"id": tournament.id, "name": tournament.name} if tournament else None,
        "round": match.round,
        "scheduled_at": match.scheduled_at,
        "athlete1": {
            "id": athlete1.id,
            "first_name": athlete1.first_name,
            "last_name": athlete1.last_name,
            "photo_url": athlete1.photo_url,
            "club": {"id": athlete1.clubs[0].id, "name": athlete1.clubs[0].name} if athlete1.clubs else None
        } if athlete1 else None,
        "athlete2": {
            "id": athlete2.id,
            "first_name": athlete2.first_name,
            "last_name": athlete2.last_name,
            "photo_url": athlete2.photo_url,
            "club": {"id": athlete2.clubs[0].id, "name": athlete2.clubs[0].name} if athlete2.clubs else None
        } if athlete2 else None,
        "score1": match.score1,
        "score2": match.score2,
        "status": match.status,
        "set_results": [set_result.dict() for set_result in set_results],
        "events": [MatchEventOut.from_orm(event) for event in match.events]
    }
    return response

# Endpoint per ottenere i team match (match a squadre)
@app.get("/team-matches", response_model=List[TeamMatchOut])
def get_team_matches(db: Session = Depends(get_db)):
    """Restituisce l'elenco dei match a squadre."""
    team_matches = db.query(TeamMatch).all()
    return team_matches

# ------------------------
# ESEMPIO DI ENDPOINT PROTETTO (inserimento dati)
# ------------------------

class MatchEventIn(BaseModel):
    event_time: timedelta
    event_type: str
    description: Optional[str] = None
    athlete_id: Optional[int] = None

    class Config:
        orm_mode = True
        from_attributes = True

@app.post("/matches/{match_id}/events", response_model=MatchEventOut)
def create_match_event(match_id: int, event: MatchEventIn, db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    """
    Endpoint protetto per gli arbitri per inserire dati relativi agli eventi in una partita individuale.
    Richiede autenticazione.
    """
    match = db.query(Match).filter(Match.id == match_id).first()
    if not match:
        raise HTTPException(status_code=404, detail="Partita non trovata")
    new_event = MatchEvent(
        match_id=match_id,
        event_time=event.event_time,
        event_type=event.event_type,
        description=event.description,
        athlete_id=event.athlete_id,
        created_at=dt.utcnow(),
        updated_at=dt.utcnow(),
    )
    db.add(new_event)
    db.commit()
    db.refresh(new_event)
    return new_event

# ------------------------
# ENDPOINT DI AUTENTICAZIONE (stub per ottenere il token)
# ------------------------

@app.post("/token")
def login(form_data: OAuth2PasswordBearer = Depends()):
    # Questo è un esempio estremamente semplificato.
    # In produzione dovresti verificare username e password.
    return {"access_token": "fake-token", "token_type": "bearer"}

# ------------------------
# ISTRUZIONI PER L'ESPOSIZIONE PUBBLICA CON NGROK
# ------------------------
#
# 1. Assicurati di avere ngrok installato (scaricabile da https://ngrok.com/)
# 2. Avvia il server FastAPI, ad esempio:
#      uvicorn main:app --reload --port 8000
# 3. In un altro terminale, esegui il comando:
#      ngrok http 8000
# 4. Ngrok ti fornirà un URL pubblico (ad es. https://xxxxxxxx.ngrok.io) che potrai utilizzare
#    nelle tue applicazioni mobile per raggiungere le API.
#
# In questo modo, il provider sarà accessibile pubblicamente tramite l’URL generato da ngrok.

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)

