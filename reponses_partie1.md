# Séance 1 — Réponses partie 1

> Marwan KORICH — M2 YNOV Montpellier — séance 1, 6 octobre 2026.

## Tableau de décisions

| Décision | Valeur retenue |
|---|---|
| Suffixe personnel | `mk07` |
| Région Azure | Groupe : `francecentral` — Registre : `italynorth` (`francecentral` refusée par la politique Azure for Students, cf. MESURES §4) |
| Groupe de ressources | `rg-dermascan-registre-mk07` |
| Registre ACR | `acrdermascanmk07` |
| Nom de l'image | `dermascan-health` |
| Tag initial | `0.1.0` |
| Image de base | `python:3.12.7-slim-bookworm` |
| Répertoire de travail | `/app` |
| Port d'écoute | `8000` |
| uid d'exécution | `10001` |

**Justifications courtes.** `francecentral` visée en premier : données de santé de patients français, résidence des données dans l'UE (RGPD), région certifiée HDS, latence minimale depuis Montpellier. La politique de l'abonnement étudiant n'autorise que `belgiumcentral`, `italynorth`, `spaincentral`, `polandcentral` et `denmarkeast` : repli sur `italynorth` (Milan), région UE la plus proche de Montpellier — les données restent dans l'UE. Port 8000 : valeur par défaut d'`app.py`, aucune surcharge nécessaire. Base `slim-bookworm` : Debian minimal, plus léger que l'image complète, sans les incompatibilités musl d'Alpine pour les roues numpy/scikit-learn de la séance 2.

**Question 0.1** — L'unicité globale trahit que chaque registre est exposé sous un nom DNS public `<nom>.azurecr.io`, qui sert de `loginServer` : le nom du registre est un sous-domaine d'un espace de noms DNS partagé par tout Azure, d'où aussi l'interdiction des tirets et majuscules.

---

## 1.1 — Les trois modèles de service

| Modèle | Ce que le fournisseur gère | Ce qui reste à votre charge | Exemple Azure |
|---|---|---|---|
| IaaS | Matériel, réseau physique, virtualisation | OS, mises à jour, runtime, application, données | Azure Virtual Machines |
| PaaS | Tout l'IaaS **+** système d'exploitation, correctifs, runtime/middleware, infrastructure de mise à l'échelle et équilibrage | Code de l'application, sa configuration, choix de la version du runtime et des règles de scaling, données, gestion des accès | Azure App Service |
| SaaS | Tout, application comprise (code, disponibilité, mises à jour fonctionnelles) | Données saisies, comptes utilisateurs et droits d'accès, paramétrage fonctionnel | Microsoft 365 |

## 1.2 — Où s'arrête votre responsabilité

| Couche | Dernier modèle où c'est à vous |
|---|---|
| Correctifs de sécurité de l'OS | IaaS |
| Version du runtime Python | IaaS *(en PaaS on choisit une version dans une liste, mais c'est le fournisseur qui l'installe et la maintient)* |
| Code de l'application | PaaS |
| Dimensionnement du nombre d'instances | PaaS *(on fixe le nombre d'instances ou les règles d'autoscaling ; en SaaS c'est invisible)* |
| Vos données métier | SaaS |

**Question 1.1** — Les **données métier** restent à votre charge dans les trois modèles. Conséquence RGPD : quel que soit le niveau d'abstraction, DermaScan reste responsable de traitement ; le fournisseur n'est qu'un sous-traitant (art. 28). Pour des photos et mesures de lésions — données de santé (art. 9) — il faut en plus un hébergeur certifié HDS, une base légale, et la maîtrise de la localisation et de la durée de conservation des données d'entraînement.

## 1.3 — Les cinq caractéristiques NIST

| Caractéristique | Traduction opérationnelle |
|---|---|
| Libre-service à la demande | Je crée une ressource sans ouvrir de ticket ni attendre l'accord d'un humain. |
| Accès réseau large | Je pilote et j'utilise mes ressources depuis n'importe quel poste connecté, par le portail, le CLI ou une API, avec des protocoles standards. |
| Mise en commun des ressources | Mon registre tourne sur une infrastructure partagée avec d'autres clients ; je choisis une région, jamais un serveur physique précis. |
| Élasticité rapide | Je peux augmenter ou réduire la capacité en quelques minutes, parfois automatiquement, sans rien acheter ni installer. |
| Service mesuré | Chaque ressource est comptée (temps d'existence, stockage, trafic) et facturée sur ce relevé, visible dans Cost Management. |

**Question 1.2** — Le **service mesuré**. La facturation dépend du temps pendant lequel une ressource est réservée, pas de son utilisation : une ressource oubliée continue d'être comptée et décompte le crédit chaque jour, même si personne ne l'appelle.

## 1.4 — Exploration du portail

### Mesure 1 — relevé d'exploration

| # | Observation | Réponse |
|---|---|---|
| 1 | Champs obligatoires de création d'un Container Registry | 5 : abonnement, groupe de ressources, nom du registre, emplacement (région), plan tarifaire (SKU) |
| 2 | Identifiant et état de l'abonnement | `e2b3938a-dd0b-466f-ab01-f58e431937ce` — état : Actif (*Enabled*) — nom : Azure for Students |
| 3 | Nombre de groupes de ressources | 1 (`rg-dermascan-registre-mk07`) |
| 4 | Crédit restant | Non relevé |
| 5 | Quota limitant pour 10 VM | « Total Regional vCPUs » (limité à quelques vCPU par région sur Azure for Students) ; voir aussi le quota par famille de VM et les adresses IP publiques |
| 6 | Rôle de l'onglet Étiquettes | Attacher des paires clé/valeur aux ressources pour imputer les coûts à un projet, filtrer et retrouver ce qui doit être détruit. |

### Classement

| Service Azure | Modèle |
|---|---|
| Azure Virtual Machines | IaaS |
| Azure App Service | PaaS |
| Azure Container Registry | PaaS |
| Azure Machine Learning (espace managé) | PaaS |
| Microsoft 365 | SaaS |

**Question 1.3**

- **Deux groupes à la fois ?** Non. Une ressource appartient à exactement un groupe de ressources ; on peut la déplacer, pas la partager.
- **Suppression du groupe ?** Toutes les ressources qu'il contient sont supprimées avec lui, de façon irréversible. C'est ce qui fait du groupe l'unité naturelle de nettoyage.
- **La région du groupe contraint-elle celle des ressources ?** Non — vérifié dans ce TP : le groupe `rg-dermascan-registre-mk07` est en `francecentral` et contient le registre créé en `italynorth`. La région du groupe indique seulement où sont stockées ses **métadonnées** (la description du déploiement), ce qui compte pour la conformité et la disponibilité des opérations de gestion.
