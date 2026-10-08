# Fiche d'identité — conteneur `dermascan-health`

> Valeurs relevées le 2026-10-06 par `docker image inspect`, `python --version` et `pip freeze` sur l'image tirée d'ACR.

| # | Rubrique | Valeur |
|---|---|---|
| 1 | Nom de l'artefact et tag | `dermascan-health:0.1.0` |
| 2 | Digest sha256 | `sha256:c10ff14f5f2e0c18563f8adc4af83c37f83e0e4b943b8dade903ba96afc5d6f9` |
| 3 | Image de base, tag exact | `python:3.12.7-slim-bookworm` (Debian 12, variante slim) |
| 4 | Version de Python | `Python 3.12.7` |
| 5 | Dépendances directes | `Flask==3.0.3` (`requirements.txt`) |
| 6 | Dépendances transitives | `blinker==1.9.0`, `click==8.5.0`, `itsdangerous==2.2.0`, `Jinja2==3.1.6`, `MarkupSafe==3.0.4`, `Werkzeug==3.1.9` |
| 7 | Licences et obligations | Flask, Werkzeug, Jinja2, MarkupSafe, itsdangerous, click : BSD-3-Clause ; blinker : MIT ; CPython : PSF License — obligation : conserver notices et textes de licence. Paquets Debian : GPL/LGPL entre autres — en cas de redistribution, fournir ou offrir le code source correspondant. |
| 8 | Architecture et OS | `linux/amd64` (reconstruite depuis un Mac arm64 pour les hôtes Azure) |
| 9 | Utilisateur d'exécution | `10001:10001` (appuser, non root) |
| 10 | Port et endpoint de santé | Port 8000 (`EXPOSE 8000`, `ENV PORT=8000`) ; `GET /health` → 200 + JSON `status, service, version, hostname, uptime_seconds` |
| 11 | Producteur | Marwan KORICH, M2 YNOV Montpellier 2026-2027 — construit le `2026-10-06T12:59:40Z` |
| 12 | Registre de publication | `acrdermascanmk07.azurecr.io` (ACR Basic, région `italynorth`), dépôt `dermascan-health`, tag `0.1.0` |
| 13 | Destination connue | Séance 2 : base de l'API d'inférence (requirements enrichi de scikit-learn, pandas, numpy) |
| 14 | Limites connues et risques résiduels | 1. **Aucun scan de vulnérabilités** (ni Trivy, ni Docker Scout, ni Defender for Containers) : les CVE de la base Debian et des paquets Python sont inconnues. 2. **Serveur de développement Flask** : mono-processus, non prévu pour la production ; à remplacer par gunicorn en séance 2. 3. **Base fixée par tag, pas par digest** : `3.12.7-slim-bookworm` peut être reconstruite par l'éditeur ; seul `@sha256:` garantit une reproduction exacte. 4. **Tag mutable** : `0.1.0` peut être réécrit dans ACR ; seul le digest de la rubrique 2 fait foi. 5. **Pas de `HEALTHCHECK` ni de signature/SBOM** : la sonde n'est pas exploitée par Docker lui-même, et l'origine de l'image n'est pas prouvable cryptographiquement. 6. `/health` ne fait que constater que le processus répond (liveness), pas qu'il est prêt à servir (readiness). |
