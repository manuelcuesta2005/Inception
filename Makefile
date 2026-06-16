LOGIN = mcuesta-
DATA_DIR = /home/$(LOGIN)/data

all: setup up

setup:
	@echo "[-] Creando directorios físicos con privilegios..."
	@sudo mkdir -p $(DATA_DIR)/mariadb
	@sudo mkdir -p $(DATA_DIR)/wordpress
	@echo "[-] Ajustando permisos de los directorios para el usuario actual..."
	@sudo chown -R $(USER):$(USER) $(DATA_DIR)

up:
	@echo "[-] Asegurando permisos del socket de Docker..."
	@sudo chmod 666 /var/run/docker.sock
	@echo "[-] Compilando y levantando contenedores..."
	@docker compose -f ./srcs/docker-compose.yml up --build -d

down:
	@echo "[-] Deteniendo contenedores..."
	@docker compose -f ./srcs/docker-compose.yml down

clean: down
	@echo "[-] Eliminando contenedores, imágenes y redes..."
	@docker system prune -a -f

fclean: clean
	@echo "[-] Eliminando volúmenes físicos y datos persistentes..."
	@docker volume rm $$(docker volume ls -q) 2>/dev/null || true
	@sudo rm -rf $(DATA_DIR)

re: fclean all

.PHONY: all setup up down clean fclean re