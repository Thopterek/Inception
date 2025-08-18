DC = docker-compose -f./src/docker-compose.yml --env-file ./src/.env

up:
	mkdir -p /home/ndziadzi/data/mariadb
	mkdir -p /home/ndziadzi/data/wordpress
	$(DC) up --build -d

down:
	$(DC) down

.PHONY: up down