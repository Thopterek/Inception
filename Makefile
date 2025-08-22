DC = docker compose -f ./src/docker-compose.yml --env-file ./src/.env

up:
	mkdir -p /home/ndziadzi/data/mariadb
	mkdir -p /home/ndziadzi/data/wordpress
	$(DC) up --build -d

down:
	$(DC) down

logs:
	$(DC) logs -f

clean:
	$(DC) down -v --remove-orphans
	rm -rf /home/ndziadzi/data
	docker system prune --volumes -af
	

.PHONY: up down logs clean