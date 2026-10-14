# Projet BDD : gestion des rallyes sportifs

Projet du module « Systèmes de gestion de bases de données » (MOD 11.1, École Centrale de Lyon, 2026-27).

Base de données pour une société qui organise des rallyes (auto, camion, moto) : rallyes et étapes, équipes, équipages, véhicules, résultats et classements. Le projet comprend la modélisation Entité-Association (DB-MAIN), l'implantation sous PostgreSQL, l'alimentation de la base et une interface web.

## Organisation du dépôt

```
dbmain/         projet DB-MAIN (schémas conceptuel et relationnel)
sql/            scripts de création de la base (tables, triggers, vues, index) et requêtes
alimentation/   notebook de génération des données
app/            application web (Flask)
docs/           rapport et manuels
```

## Technologies

- PostgreSQL 17
- Python 3 : psycopg2, Faker, Jupyter
- Flask, Flask-SQLAlchemy, Flask-Login, Bootstrap

## Installation

À compléter.
