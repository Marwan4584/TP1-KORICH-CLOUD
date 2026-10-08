# Image de base : variante slim (légère), version Python ET distribution fixées.
# Jamais "latest" : la construction doit être reproductible.
FROM python:3.12.7-slim-bookworm

# Répertoire de travail absolu, créé s'il n'existe pas ; le CMD s'y exécute.
WORKDIR /app

# Pas de .pyc dans une image jetable ; logs non tamponnés (docker logs lisible) ;
# port par défaut, cohérent avec EXPOSE et les -p du TP.
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=8000

# 1) Ce qui change le moins souvent : la liste des dépendances seule.
COPY requirements.txt ./

# 2) Installation : couche lourde, réutilisée tant que requirements.txt ne change pas.
RUN pip install --no-cache-dir -r requirements.txt

# 3) Ce qui change à chaque modification : le code, copié le plus tard possible.
COPY app.py ./

# 4) Durcissement : utilisateur non privilégié (uid/gid 10001), propriétaire de /app.
RUN groupadd --gid 10001 appuser \
    && useradd --uid 10001 --gid 10001 --no-create-home --shell /usr/sbin/nologin appuser \
    && chown -R appuser:appuser /app

# 5) Le processus final ne tourne pas en root (uid numérique : vérifiable par un orchestrateur).
USER 10001:10001

# 6) Purement déclaratif : seul -p au lancement publie le port.
EXPOSE 8000

# 7) Forme exec (tableau JSON) : python est PID 1 et reçoit SIGTERM au docker stop.
CMD ["python", "app.py"]
