DC = docker-compose -f srcs/docker-compose.yml --env-file srcs/.env

up:
	$(DC) up

down:
	$(DC) down

.PHONY up down