DC = docker-compose -f src/docker-compose.yml --env-file src/.env

up:
	$(DC) up

down:
	$(DC) down

.PHONY up down