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
purge: fclean
	@bash scripts/purge.sh
init: setup
	@bash scripts/cluster.sh
	@bash scripts/namespace.sh
	@bash scripts/initArgo.sh
	@bash scripts/gitops.sh
	@bash scripts/argoUI.sh
fclean:
	@bash scripts/clean.sh
re: fclean init
prueba:
	@bash scripts/setup.sh
	@bash scripts/cluster.sh
	@bash scripts/namespace.sh
	@bash scripts/gitlab.sh


.PHONY: setup purge