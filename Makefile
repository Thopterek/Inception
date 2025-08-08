DC = docker-compose -f ./src/docker-compose.yml --env-file ./src/.env

up:
	mkdir -p /home/ndziadzi/data/mariadb
	$(DC) up

down:
	$(DC) down

.PHONY: up down