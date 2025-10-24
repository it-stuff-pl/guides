#!/bin/bash

# Zamień nazwę użytkownika i wskaż poprawną lokalizację folderu projektu
cd /home/nazwa_uzytkownika/dockerize-wp-nginx-ssl/

# Usuń opcję --dry-run po poprawnym odnowieniu w trybie testowym
docker compose run certbot renew --dry-run && docker compose exec webserver nginx -s reload
docker system prune -af
