help:
	@echo "==================================================="
	@echo "           comandos disponibles                    "
	@echo "==================================================="
	@echo "make setup: Comprobacion de dependencias necesarias"
	@echo "make init: Comando de inicializacion de todo el programa"
	@echo "make fclean: Comando de limpieza destruye el cluster,namespaces y recusos de ArgoCD"
	@echo "make re: fclean + init"
	@echo "make purge: fclean mas eliminacion de instalaciones necesarias (Docker,k3d,kubectl)"
setup:
	@bash scripts/setup.sh
purge:
	@bash scripts/purge.sh
.PHONY: setup purge