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
purge: clean
	@bash scripts/purge.sh
init:
	@echo "orden de llamada provisional:"
	@echo "1: setup.sh"
	@echo "	- Archivos de dependencia: Ninguno."
	@echo "	- Objetivo : comprueba instalacion de depensdencias necesarias (Docker,k3d y kubectl)."
	@echo "2: cluster.sh"
	@echo "	- Archivos de dependencia: depende de conf/k3d-config.yaml"
	@echo "	- Objetivo: lee la configuracion del archivo y crea el cluster con esas condiciones"
	@echo "3: namespace.sh"
	@echo "	- Archivos de dependencia: Ninguno."
	@echo "	- Objetivo: crea los espacion necesarios dentro del cluster ('argocd' y 'dev')"
	@echo "4: initArgo.sh"
	@echo "	- Archivos de dependencia: depende del Manifiesto oficial de instalación de Argo CD."
	@echo "	- Objetivo: Aplica los despliegues oficiales de Argo CD dentro del namespace argocd para que arranque su panel y sus controladores."
	@echo "5: gitops.sh"
	@echo "	- Archivos de dependencia: depende de conf/argocd-app.yaml y la carpeta k8s/ en GitHub."
	@echo "	- Objetivo: Espera a que los CRDs de Argo CD estén listos y aplica el archivo argocd-app.yaml. Este archivo le indica a Argo CD que vigile tu repo de GitHub (específicamente la carpeta k8s/ con el deployment.yaml y service.yaml en v1)."
prueba: setup
	@bash scripts/cluster.sh
	@bash scripts/namespace.sh
clean:
	@bash scripts/clean.sh


.PHONY: setup purge