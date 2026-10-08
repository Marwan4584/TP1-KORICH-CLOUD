# Séance 1 — Mesures et réponses (parties 2 à 6)

> Mesures relevées le 2026-10-06 sur MacBook Air Apple Silicon (journaux complets dans `logs/`). 

---

## Partie 2 — Environnement

### Mesure 2 — identité du compte Azure

| Élément | Valeur |
|---|---|
| Identifiant d'abonnement | `e2b3938a-dd0b-466f-ab01-f58e431937ce` (Azure for Students, état *Enabled*) |
| Nom du locataire (tenant) | `Ynov` (`ynov.com`) |

### Question 2.1
Nombre de régions exposées par `az account list-locations` : **109**.

Deux critères qui imposent une région en entreprise pour des données européennes :
1. **Résidence et souveraineté des données** : rester dans l'UE pour le RGPD, et pour des données de santé françaises, choisir une région couverte par la certification HDS.
2. **Disponibilité des services et latence** : tous les services (GPU, Azure ML, Premium ACR…) ne sont pas ouverts partout ; la région doit proposer ce dont la plateforme a besoin, au plus près des utilisateurs. *(Autres critères recevables : coût, région appairée pour la reprise après sinistre.)*

### Mesure 3 — état du groupe de ressources
`ProvisioningState` = `Succeeded` (groupe `rg-dermascan-registre-mk07`, `francecentral`)

### Question 2.2
Non : un groupe de ressources est un conteneur logique de métadonnées, gratuit ; l'analyse des coûts ne montre aucune nouvelle ligne.

### Mesure 4 — environnement Docker

| Élément | Commande | Valeur |
|---|---|---|
| Version client | `docker version` | `29.4.3` (darwin/arm64) |
| Version démon | `docker version` | `29.4.3` (Docker Desktop 4.74.0, linux/arm64) |
| Architecture | `docker info` | `aarch64` (arm64 — Mac Apple Silicon) |
| Images déjà présentes | `docker info` | `3` |
| Mémoire allouée au démon | `docker info` | `3.827 GiB` |

---

## Partie 3 — Conteneurisation

### Question 3.1
Dans un conteneur, `127.0.0.1` est la boucle locale **du conteneur lui-même** : le trafic publié par `-p` arrive par son interface réseau virtuelle (`eth0`), qui n'est écoutée que si l'application est liée à `0.0.0.0`.

### Question 3.2
Oui. `EXPOSE` est purement déclaratif (documentation, et port utilisé par `docker run -P`) : c'est `-p hôte:conteneur` qui crée réellement la redirection. Vérification possible : commenter `EXPOSE`, reconstruire, relancer avec `-p` → `/health` répond toujours.

### Question 3.3
Sans `.dockerignore`, le `.venv/` de 400 Mo est envoyé au démon avec le contexte de build :
1. **Durée** : chaque build commence par transférer ces 400 Mo (« transferring context »), même si rien ne les utilise.
2. **Image** : avec un `COPY . ./` (cas du `Dockerfile.naif`), le `.venv` est embarqué dans l'image, qui grossit d'autant et contient des binaires compilés pour le poste et non pour Linux. Toute modification dans `.venv` invalide en plus le cache de la couche `COPY`.

### Mesure 5 — premier build

| Mesure | Valeur |
|---|---|
| Durée du premier build (cache vide) | `15,4 s` |
| Taille de l'image | `154 MB` (IMAGE ID `6198a39b5b25`) |
| Nombre de couches (`docker history`) | `19` lignes d'historique, dont **9 couches de fichiers** (les 9 couches poussées vers ACR) |
| Couche la plus lourde et instruction | `97,2 MB` — couche Debian bookworm de l'image de base (`debian.sh … bookworm`) ; côté projet : `RUN pip install` = `4,94 MB` |
| Taille de l'image de base seule | `≈ 149 MB` (97,2 + 8,42 + 43,6 MB, couches de `python:3.12.7-slim-bookworm`) |

### Question 3.4
Part de l'image de base = 149 / 154 × 100 ≈ **97 %**. Notre apport (Flask + dépendances + code + utilisateur) ne pèse que ≈ 5 Mo : l'essentiel est l'OS Debian et l'interpréteur Python.

### Mesure 6 — sonde `/health` locale

| Mesure | Valeur |
|---|---|
| Code HTTP | `200 OK` |
| `hostname` | `378014833e0f` |
| `version` | `0.1.0` |
| `status` | `ok` |

### Question 3.5
`hostname` vaut l'identifiant court (12 caractères) du conteneur, que Docker donne comme nom d'hôte. Après `docker rm -f` + `docker run`, il change : `378014833e0f` → `9d4f02b8a95d`. Un conteneur n'a pas d'identité stable : il est jetable et interchangeable, donc rien (logs, traçabilité, état) ne doit reposer sur son nom d'hôte ; l'identité durable est celle de l'**image** (son digest).

### Question 3.6
Oui : `version` vaut `0.1.0-recette` sur le second conteneur (port 8001, hostname `0dbfa4112c21`) alors que l'image est la même (même IMAGE ID). L'image est un artefact immuable construit une fois ; la configuration lui est injectée au lancement et varie selon l'environnement (dev, recette, prod) — on promeut le même artefact au lieu de reconstruire.

### Mesure 7 — ordre des instructions et cache

| Scénario | Durée | Étapes CACHED | `pip install` rejoué ? |
|---|---|---|---|
| A — bon ordre, après modif. d'`app.py` | `2,6 s` | `3` (WORKDIR, COPY requirements, pip install) | Non |
| B — mauvais ordre, après modif. d'`app.py` | `4,4 s` | `1` (WORKDIR seul) | Oui (3,4 s) |
| Écart A/B | `1,8 s` | | |

### Question 3.7
Docker associe à chaque instruction une couche identifiée par l'instruction elle-même, la couche parente et, pour `COPY`/`ADD`, une empreinte du contenu des fichiers copiés. Au build suivant, une couche est réutilisée si ces trois éléments sont identiques. Dès qu'une couche est invalidée (instruction modifiée ou fichier copié différent), **toutes les couches suivantes sont reconstruites**, même si leur instruction n'a pas changé, car leur parente n'est plus la même. D'où la règle : du plus stable au plus changeant.

### Question 3.8
Coût ≈ 20 × (durée d'un `pip install` rejoué). Avec Flask seul, le `pip install` rejoué dure 3,4 s (écart A/B 1,8 s), soit ≈ 20 × 3,4 ≈ **70 s par jour** — négligeable ici. Avec scikit-learn, pandas et numpy (plusieurs dizaines de Mo de roues à télécharger et décompresser à chaque fois), un `pip install` prend typiquement de l'ordre de 30 s à 1 min et plus : 20 itérations représentent alors **10 à 20 minutes perdues par jour et par développeur**, plus autant de couches de plusieurs centaines de Mo à pousser au registre.

### Mesure 8 — utilisateur non-root

| Contrôle | Attendu | Observation |
|---|---|---|
| `id` dans le conteneur | uid non nul | `uid=10001(appuser) gid=10001(appuser) groups=10001(appuser)` |
| `.Config.User` | non vide | `10001:10001` |
| Écriture dans `/etc` | refusée | `touch: cannot touch '/etc/preuve_root': Permission denied` |

### Question 3.9
En root, l'attaquant peut modifier tout le système de fichiers du conteneur (binaires, `/etc`, installer des outils via `apt`) et lire tous les secrets montés ; surtout, une faille du noyau ou un montage mal protégé (socket Docker, volume hôte) lui donne alors directement root sur **l'hôte**, l'uid 0 n'étant pas remappé par défaut.

---

## Partie 4 — Azure Container Registry

> **Incident de région.** `az acr create` en `francecentral` a été refusé (`RequestDisallowedByAzure`) : la politique de l'abonnement Azure for Students n'autorise que `belgiumcentral, italynorth, spaincentral, polandcentral, denmarkeast`. Il a aussi fallu enregistrer le fournisseur `Microsoft.ContainerRegistry` (`az provider register`, erreur `MissingSubscriptionRegistration`). Registre créé en `italynorth`, dans le groupe resté en `francecentral`.

### Mesure 9 — registre créé

| Élément | Valeur |
|---|---|
| `loginServer` | `acrdermascanmk07.azurecr.io` (région **italynorth**) |
| SKU | `Basic` |
| État d'approvisionnement | `Succeeded` (créé le 2026-10-06T12:59:02Z, admin désactivé) |
| Coût mensuel annoncé | ≈ 5 $/mois (≈ 0,167 $/jour, documentation Microsoft) |

### Question 4.1

| SKU | Stockage inclus | Fonctionnalités |
|---|---|---|
| Basic | 10 Gio | API identique, débit et nombre de webhooks limités ; pour l'apprentissage et le dev |
| Standard | 100 Gio | Plus de débit et de webhooks ; défaut raisonnable pour une prod mono-région |
| Premium | 500 Gio | Géo-réplication, points de terminaison privés (Private Link), règles réseau, clés gérées par le client, plus fort débit concurrent |

Le stockage seul ne justifie pas Premium (on peut dépasser le quota inclus, en payant le Go). Pour DermaScan, Premium devient nécessaire quand **le registre ne doit plus être joignable depuis Internet** (accès via point de terminaison privé, exigence plausible d'un audit HDS) ou quand des centres de dépistage dans plusieurs régions doivent tirer les images localement (**géo-réplication**).

### Question 4.2
`~/.docker/config.json` contient une entrée `auths` pour `acrdermascanmk07.azurecr.io`, avec soit un jeton (`identitytoken`) en clair, soit — sous Docker Desktop — une référence au gestionnaire d'identifiants du système (`"credsStore": "desktop"`), le jeton étant alors rangé dans le trousseau. **Observé ici :** `"auths": {"acrdermascanmk07.azurecr.io": {}}` avec `"credsStore": "desktop"` — l'entrée est vide dans le fichier, le jeton est rangé dans le trousseau macOS. C'est un secret : quiconque obtient ce jeton peut pousser et tirer des images sur le registre en votre nom (remplacer une image de production par une image piégée) jusqu'à son expiration.

### Question 4.3
L'utilisateur administrateur est déconseillé car :
1. **Compte unique partagé** : tout le monde utilise le même identifiant, donc aucune traçabilité de qui a poussé quoi, et révoquer une personne impose de changer le mot de passe de tous.
2. **Droits maximaux et secret statique** : il a tous les droits push/pull, sans rôle ni périmètre (impossible d'appliquer le moindre privilège via RBAC Entra ID), avec un mot de passe long terme qui fuit dans les scripts et pipelines, hors MFA et accès conditionnel.

### Mesure 10 — premier push

| Mesure | Valeur |
|---|---|
| Durée du push | `36,4 s` |
| Couches poussées | `9` |
| IMAGE ID local = IMAGE ID taggé ? | Oui — `6198a39b5b25` pour les deux noms (simple alias). Image ensuite reconstruite en `linux/amd64` pour Azure (Mac arm64). |
| Digest | `sha256:c10ff14f5f2e0c18563f8adc4af83c37f83e0e4b943b8dade903ba96afc5d6f9` (taille compressée dans ACR : 47,7 MB, `linux/amd64`) |

### Question 4.4
Le second push est quasi instantané (`1,6 s` contre 36,4 s) : chaque couche affiche `Layer already exists`. Le registre stocke les couches de façon **adressée par contenu** (chaque couche est identifiée par son empreinte sha256) : le client vérifie si l'empreinte est déjà présente et n'envoie que les couches manquantes. Corollaire : deux images partageant la même base ne la stockent qu'une fois.

### Mesure 11 — exécution depuis ACR

| Mesure | Valeur |
|---|---|
| Durée du `docker run` avec téléchargement | `1,6 s` (les 9 couches existaient déjà localement : `Already exists`, seul le manifeste a été tiré) |
| JSON identique à 3.4 ? | Oui (`status: ok`, `version: 0.1.0`), sauf `hostname` et `uptime_seconds` |
| `hostname` changé ? | Oui — `baf1a5866631` (nouveau conteneur) |

---

## Partie 5 — Gouvernance

### Question 5.1
`requirements.txt` ne déclare qu'un paquet (Flask==3.0.3) ; `pip freeze` en liste **7**, soit **6 de plus** : **Werkzeug 3.1.9, Jinja2 3.1.6, MarkupSafe 3.0.4, itsdangerous 2.2.0, click 8.5.0, blinker 1.9.0** — les dépendances transitives de Flask, choisies et versionnées par pip au moment du build. Un audit de licences doit porter sur `pip freeze` car c'est l'inventaire de **ce qui est réellement embarqué et redistribué** : une licence contraignante peut arriver par une dépendance transitive que personne n'a déclarée, et ses versions peuvent changer d'un build à l'autre si elles ne sont pas figées.

### Question 5.2
- **Flask** : BSD-3-Clause (permissive : conserver la notice de copyright).
- **CPython** : PSF License (permissive, compatible GPL : conserver la notice).
- **Paquets système Debian** de l'image de base : licences multiples, dont **GPL** (bash, coreutils…) et LGPL (glibc).

La **GPL des paquets système** est la plus contraignante : si DermaScan redistribue l'image à un centre client, elle distribue ces binaires et doit fournir (ou offrir par écrit) leur code source correspondant et le texte des licences — les licences permissives n'exigent que la conservation des notices.

---

## Nettoyage

### Mesure 12

*État relevé en fin de séance, le 2026-10-06 (avant la suppression du 2026-10-07 décrite plus bas).*

| Contrôle | Observation |
|---|---|
| Espace libéré par `docker system prune` | Non relevé : Docker Desktop a été quitté avant le `prune` (moteur arrêté, aucun conteneur actif) |
| Ressources actives dans `$RG` | 1 — le registre `acrdermascanmk07` |
| SKU et coût journalier | Basic, ≈ 0,17 $/jour |
| Date `a_detruire` | `2027-06-30` |
| Groupes de ressources m'appartenant | 1 — `rg-dermascan-registre-mk07` |
| Crédit restant (Cost Management) | Non relevé |

### Question 6.1
> « Registre ACR `acrdermascanmk07` (SKU Basic, `italynorth`, ≈ 0,17 $/jour) dans le groupe `rg-dermascan-registre-mk07` : conservé volontairement car il héberge l'image `dermascan-health` consommée par les séances 2 à 4 et le projet fil rouge ; à détruire avec son groupe (`az group delete`) au plus tard le 2027-06-30, après la soutenance — propriétaire : Marwan KORICH. »

### Question 6.2
`--no-wait` rend la main dès que la demande est acceptée, pas quand elle a abouti : la suppression peut encore être en cours, ou **échouer** (verrou sur une ressource, dépendance, erreur transitoire), et les ressources continuent alors d'être facturées sans que personne ne le sache. Je m'en assure en interrogeant `az group exists --name "$RG"` jusqu'à obtenir `false`, en vérifiant `az group list`, puis en contrôlant le lendemain dans Cost Management que le coût journalier est tombé à zéro.

### Note sur la capture du portail ACR
Le groupe `rg-dermascan-registre-mk07` (et donc le registre) a été supprimé le 2026-10-07 pour stopper la facturation (≈ 0,17 $/jour) entre deux séances. La capture du portail n'a donc pas pu être prise après coup. Preuve de la présence du dépôt et du tag dans le registre : `captures/preuve_registre_acr.txt`, extrait du journal réel d'exécution (`az acr create`, `az acr repository list` → `dermascan-health`, `show-tags` → `0.1.0`, digest `sha256:c10ff14f…`). Le registre sera recréé à l'identique (`az acr create` + `docker push`) avant la séance 2.
