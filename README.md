# TP1 — DermaScan : conteneurisation et registre Azure

Marwan KORICH — M2 YNOV Montpellier — séance 1 (6 octobre 2026)

Conteneurisation de la sonde de santé `dermascan-health` (Flask) puis publication dans un registre Azure Container Registry.

| Fichier | Contenu |
|---|---|
| `reponses_partie1.md` | Partie 1 : tableaux IaaS/PaaS/SaaS, NIST, exploration du portail, questions 0.1 à 1.3 |
| `Dockerfile` | Image finale : `python:3.12.7-slim-bookworm`, cache optimisé, utilisateur non-root 10001 |
| `Dockerfile.naif` | Variante de l'expérience B (mauvais ordre des instructions) |
| `.dockerignore` | Exclusions du contexte de build |
| `app.py`, `requirements.txt` | Fichiers fournis, inchangés |
| `MESURES.md` | Mesures 2 à 12 et questions 2.1 à 6.2 |
| `FICHE_IDENTITE.md` | Fiche d'identité de l'image (14 rubriques) |
| `captures/` | Sortie de `curl /health` et preuve de présence de l'image dans ACR |

Image publiée : `acrdermascanmk07.azurecr.io/dermascan-health:0.1.0` — digest `sha256:c10ff14f5f2e0c18563f8adc4af83c37f83e0e4b943b8dade903ba96afc5d6f9` (registre supprimé le 7 octobre pour stopper la facturation).
