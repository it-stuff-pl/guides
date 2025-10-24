# Konteneryzacja aplikacji WordPress i serwera reverse proxy z certyfikatem SSL

https://it-stuff.pl/2025/09/23/konteneryzacja-wordpressa-za-reverse-proxy/

> [!WARNING]
> Aby w pełni skorzystać z repozytorium wymagane jest posiadanie domeny oraz serwera z publicznym adresem IP. Należy utworzyć rekordy DNS u dostawcy domeny wskazujące na serwer reverse proxy i mieć dostęp do infrastruktury sieciowej w celu otwarcia portów serwera sieciowego.

Kontenery wymagają dostępu do określonych zmiennych środowiskowych w czasie wykonywania. Zmienne te obejmują zarówno informacje poufne takie jak: hasła dla administratora oraz użytkowników MySQL, a także niepoufne takie jak nazwa bazy danych czy hosta. 
Zmienne zostały wskazane w pliku `docker-compose.yaml` (plik konfiguracyjny dla kontenerów). Domyślnie to plik `.env` jest używany przez Docker Compose w celu pozyskania wartości wskazanych zmiennych. 
Utwórz plik i uzupełnij o hasło dla użytkownika i administratora bazy danych.
<br>
<br>
```dotenv
MYSQL_DB=wordpress
MYSQL_USER=wp-user
MYSQL_PASSWORD=user_password
MYSQL_ROOT_PASSWORD=admin_password
MYSQL_HOST=db:3306
```
> [!IMPORTANT]
> Przed uruchomieniem kontenerów w celu wygenerowania certyfikatów testowych uzupełnij plik `nginx.conf` wpisując adres domeny w polu `server_name`.
> Dla pliku `docker-compose.yaml` edytuj komendę startową kontenera `certbot`. Uzupełnij adres email `--email` oraz domenę `--d`.

Uruchom kontenery poleceniem
```
$ docker compose up -d
```
Opcja `-d` (detached) uruchomi kontenery w tle bez zajęcia okna terminala logami z kontenerów. W celu sprawdzenia logów z wybranego kontenera możemy posłużyć się poleceniem:
```
$ docker compose logs <nazwa_serwisu> --follow
```
Możemy sprawdzić czy certyfikat znajduje się w folderze `/etc/letsencrypt/live` wewnątrz kontenera. Do wykonywania komend kontenera służy polecenie `docker exec`. 
Wykonując polecenie z opcją `-it` możemy uruchomić shell kontenera i utrzymać ten proces w obecnym oknie terminala.
```
$ docker exec -it webserver /bin/bash
```
Następnie znajdując się wewnątrz systemu plików kontenera
```
$ ls /etc/letsencrypt/live
```
Output powinien wyświetlić zawartość folderu w którym znajduje się certyfikat dla twojej domeny.
```
total 16
drwx------ 3 root root 4096 Oct  1 10:04 .
drwxr-xr-x 7 root root 4096 Oct  1 10:15 ..
-rw-r--r-- 1 root root  740 Oct  1 10:04 README
drwxr-xr-x 2 root root 4096 Oct  1 10:15 nazwa_domeny
```
> [!IMPORTANT]
> Wiedząc, że wygenerowanie certyfikatu w wersji testowej przebiegło pomyślnie, możemy uzyskać prawidłowy certyfikat SSL. W tym celu edytuj konfigurację serwisu `certbot` w pliku `docker-compose.yaml`.
> Należy zastąpić opcję `--staging` na `--force-renewal`. W ten sposób certbot ponownie wygeneruje certyfikat dla domeny.

Po zmianach w konfiguracji należy ponownie utworzyć kontener certbot:
```
$ docker compose up --force-recreate --no-deps certbot
```

Zwróc uwagę na logi kontenera:
```
certbot  | Saving debug log to /var/log/letsencrypt/letsencrypt.log
certbot  | Account registered.
certbot  | Renewing an existing certificate for nazwa_domeny and www.nazwa_domeny
certbot  | 
certbot  | Successfully received certificate.
certbot  | Certificate is saved at: /etc/letsencrypt/live/nazwa_domeny/fullchain.pem
certbot  | Key is saved at:         /etc/letsencrypt/live/nazwa_domeny/privkey.pem
certbot  | This certificate expires on 2025-12-30.
certbot  | These files will be updated when the certificate renews.
certbot  | NEXT STEPS:
certbot  | - The certificate will need to be renewed before it expires. Certbot can automatically renew the certificate in the background, but you may need to take steps to enable that functionality. See https://certbot.org/renewal-setup for instructions.
certbot  | 
certbot  | - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
certbot  | If you like Certbot, please consider supporting our work by:
certbot  |  * Donating to ISRG / Let's Encrypt:   https://letsencrypt.org/donate
certbot  |  * Donating to EFF:                    https://eff.org/donate-le
certbot  | - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
certbot exited with code 0
```
Powyższy output mówi o tym że wygenerowanie certyfikatu SSL dla domeny przebiegło poprawnie. Wskazana jest lokalizacja gdzie zapisywany jest klucz oraz plik certyfikatu wraz z datą ważności certyfikatu, która wynosi 90 dni.
<br>
<br>
Teraz zajmiemy się zmianą konfiguracji dla kontenera `webserver`, podmieniając pliki Nginx-a i otwierając port dla nasłuchiwania żądań HTTPS. W tym celu zatrzymaj kontener komendą:
```
$ docker compose stop webserver
```
> [!IMPORTANT]
> W pliku `docker-compose.yaml` wskaż plik `nginx-ssl.conf` zamiast `nginx.conf` w defincji woluminów dla kontenera `webserver` oraz dodaj otwarty port `443` w sekcji `ports`.
> Dla `nginx-ssl.conf` wpisz nazwę domeny w polu `server_name` oraz w `ssl_certificate` oraz `ssl_certificate_key`.

Podobnie jak w przypadku zmiany konfiguracji dla certbota, należy ponownie utworzyć kontener wcześniej wspomnianą komendą:
```
$ docker-compose up -d --force-recreate --no-deps webserver
```
Po upływie 90 dni certyfikat dla twojej domeny utraci ważność. W celu automatycznego odnawiania certyfikatu utworzony został prosty skrypt `cert-renew.sh`, który będzie uruchamiał się okresowo przy pomocy narzędzia cron. Na początek nadaj uprawnienia do wykonania skryptu:
```
$ chmod +x ./cert-renew.sh
```
> [!IMPORTANT]
> Najpierw uruchamiamy odnowienie certyfikatu w trybie testowym za pomocą opcji `--dry-run`. Pamiętaj żeby podać ścieżkę aboslutną do skryptu tylko wtedy zadanie w cron zostanie wykonane poprawnie !

Na początku napiszmy zadanie które będzie sprawdzać ważność certyfikatu co 5 minut, w celu sprawdzenia czy wszystko przebiegło pomyślnie. Uruchom narzędzie cron poleceniem:
<br>
```
$ sudo crontab -e
```
Następnie uzupełnij o następującą zawartość:
```
 */5 * * * * /home/nazwa_uzytkownika/folder_projektu/cert-renew.sh >> /var/log/cron.log 2>&1
```
Po 5 minutach sprawdź plik `cron.log`, który jest tworzony w celu zapisania danych wyjściowych, które powstały po wykonaniu skryptu. Poprawne odnowienie certyfikatu powinno wygenerować poniższy output.
```
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Processing /etc/letsencrypt/renewal/nazwa_domeny.conf
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Simulating renewal of an existing certificate for nazwa_domeny and www.nazwa_domeny

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Congratulations, all simulated renewals succeeded: 
/etc/letsencrypt/live/nazwa_domeny/fullchain.pem (success)
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
2025/10/01 15:42:42 [notice] 33#33: signal process started
```
Usuń `--dry-run` ze skryptu `cert-renew.sh` i ponownie uruchom crontab. Po poprawnym przetestowaniu skryptu zaplanujemy jego uruchomienie na godzinę 12:00 codziennie.
```
0 12 * * * /home/nazwa_uzytkownika/folder_projektu/cert-renew.sh >> /var/log/cron.log 2>&1
```
