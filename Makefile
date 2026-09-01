docker_compose_file = ./srcs/docker-compose.yml

up : down
	@mkdir -p /home/$(USER)/data/mariadb
	@mkdir -p /home/$(USER)/data/wordpress
	@docker compose -f $(docker_compose_file) up --build -d

down : 
	@docker compose -f $(docker_compose_file) down