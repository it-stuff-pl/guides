# Jenkins za Ngrok reverse proxy ze statycznym adresem domeny

https://it-stuff.pl/2025/10/15/jak-zintegrowac-jenkinsa-z-repozytorium-na-githubie/

Do autentykacji z chmurą Ngrok i utworzenia tunelu pomiędzy lokalnym serwisem a globalnym reverse proxy jest wymagany token, który znajduje się na utworzonym koncie Ngrok. 
Należy utworzyć plik `.env` w folderze projektu wraz ze zmienną `NGROK_AUTHTOKEN`, która jest wskazana w Docker Compose. 
Drugą zmienną jest `DOMAIN_NAME`, która jest adresem statycznej domeny Ngrok.
```dotenv
NGROK_AUTHTOKEN=<token_value>
DOMAIN_NAME=<ngrok_static_domain>
```
Uruchom kontenery poleceniem:
```
$ docker compose up -d
```
Uruchomione kontenery, ich status, nazwę czy otwarte porty można sprawdzić komendą `docker ps`, natomiast adres domeny przypisany dla lokalnego serwisu można sprawdzić w interfejsie webowym agenta Ngrok na porcie `4040`. 
Znajdując się na stronie internetowej naszego serwisu należy przeprowadzić początkową konfiguracje Jenkinsa wpisując losowo wygenerowane hasło administratora znajdujące się w lokalizacji `/var/jenkins_home/secrets/initialAdminPassword`. 
Aby dostać się do powłoki i systemu plików kontenera Jenkins w celu skopiowania hasła należy wpisać:
```
$ docker exec -it jenkins-blueocean /bin/bash
```
Następnie wydrukować hasło administratora poleceniem:
```
$ cat /var/jenkins_home/secrets/initialAdminPassword
```
