# Consolidado de Entrega CI/CD: ClimaColombia

Este documento consolida el historial de cambios, soluciones a problemas comunes (troubleshooting), responsabilidades del equipo y las opiniones finales respecto a la integración de la plataforma de software con herramientas de Integración y Entrega Continua (CI/CD) y contenedores.

---

## 1. Historial de Cambios Consolidado

La evolución del proyecto para alcanzar la entrega actual se ha realizado de forma progresiva, adaptándose a las restricciones del proyecto y optando por soluciones 100% gratuitas:

1.  **Dockerización Base:** Se empaquetó el `Frontend` (React/Vite) y el `Backend` (Node.js/Express) en contenedores independientes mediante sus respectivos `Dockerfile`. Se implementó un `docker-compose.yml` central para orquestar la comunicación de ambos servicios y de un servidor `Nginx`.
2.  **Integración de Jenkins:** Se implementó el archivo `Jenkinsfile` definiendo las etapas del pipeline de automatización (Instalación, Linting, Testing, Build de Imágenes y Publicación/Despliegue). La plataforma quedó certificada como totalmente integrada con contenedores y Jenkins.
3.  **Migración de Travis CI y Codeship:** Debido a restricciones del proyecto, se eliminaron los archivos de configuración `.travis.yml`, `codeship-services.yml` y `codeship-steps.yml`. En su lugar, se implementaron soluciones utilizando las capas gratuitas de plataformas alternativas.
4.  **Integración de GitHub Actions:** Se creó el archivo `.github/workflows/ci.yml` para conectar el repositorio a GitHub Actions. Se configuró para ejecutar en cada push y pull request: instalación de dependencias (`npm ci`), análisis estático (Linter), pruebas automatizadas y validación de construcción de las imágenes Docker.
5.  **Integración de GitLab CI/CD:** Se añadió el archivo `.gitlab-ci.yml` con un pipeline estructurado en stages (`install`, `test`, `build`) que emplea la funcionalidad *Docker-in-Docker* para construir los contenedores en la nube de GitLab.
6.  **Integración de CircleCI:** Se implementó el archivo `.circleci/config.yml` aprovechando los executors de Docker para replicar el pipeline de validación y construcción.
7.  **Script de Ejecución Automática:** Se crearon los archivos `start.bat` y `start.sh` para levantar localmente el ecosistema completo (Backend, Frontend y Nginx) con un solo comando usando Docker Compose.

---

## 2. Guía de Solución de Problemas (Troubleshooting)

A continuación, documentamos los errores encontrados durante los cambios de código y migración, junto con las sugerencias exactas para solucionarlos:

### A. Fallos en el Pipeline de GitLab CI/CD (Docker-in-Docker)
*   **Problema:** El job `build_images` falla al intentar ejecutar `docker-compose build` con el error "Cannot connect to the Docker daemon".
*   **Causa:** El runner de GitLab no tiene el servicio Docker habilitado correctamente o no se definió la variable del driver.
*   **Solución Exacta:** Asegurar que el archivo `.gitlab-ci.yml` incluya el servicio `docker:24.0.5-dind` y que esté configurada la variable global `DOCKER_DRIVER: overlay2` u otra compatible.

### B. Fallos en GitHub Actions por Archivos "node_modules"
*   **Problema:** El pipeline toma demasiado tiempo o falla por conflictos al hacer `npm ci` o build.
*   **Causa:** La carpeta `node_modules` fue subida por accidente al repositorio, causando conflictos con el entorno Linux de GitHub Actions.
*   **Solución Exacta:** Eliminar `node_modules` del caché de Git ejecutando `git rm -r --cached .` y añadir `node_modules/` al archivo `.gitignore`. Posteriormente, hacer commit y push.

### C. Conflicto de Puertos al ejecutar `start.bat` o `start.sh`
*   **Problema:** Al ejecutar el script automático, se muestra el error: `Bind for 0.0.0.0:80 failed: port is already allocated` o similar para los puertos `3000` y `5173`.
*   **Causa:** Otro proceso local (como otro contenedor, un servidor XAMPP, u otra app React/Node) está ocupando esos puertos.
*   **Solución Exacta:** Detener los servicios locales que ocupan el puerto, o modificar los puertos expuestos en el archivo `docker-compose.yml` (por ejemplo, cambiar `- "80:80"` a `- "8080:80"`).

---

## 3. Responsabilidades y Opiniones

El éxito de la migración y de la plataforma requiere la definición clara de roles, responsabilidades y el análisis técnico sobre el uso de estas herramientas gratuitas:

### Distribución de Responsabilidades
*   **Desarrolladores (Frontend/Backend):**
    *   Responsables de asegurar que su código pasa exitosamente por los scripts de `npm run lint` y `npm run test` localmente **antes** de hacer push.
    *   Mantener la cobertura de pruebas (Coverage) del Backend.
    *   Actualizar los `Dockerfile` de aplicación si el stack de dependencias base cambia.
*   **Líder Técnico / DevOps:**
    *   Mantenimiento de los archivos de configuración de infraestructura como código (`.github/workflows/ci.yml`, `.gitlab-ci.yml`, `.circleci/config.yml`, `Jenkinsfile`).
    *   Gestión de secretos y credenciales en las plataformas CI/CD (GitHub, GitLab, CircleCI).
    *   Mantenimiento y actualización de los scripts automáticos (`start.bat` y `start.sh`).
*   **QA Automatizador:**
    *   Añadir pruebas e2e o de integración profundas a los pipelines sin comprometer los tiempos de ejecución y las cuotas de las capas libres.

### Opiniones Técnicas sobre las Herramientas Gratuitas
1.  **Sobre la Migración a Soluciones Gratuitas:** 
    *   *Opinión del Equipo:* La decisión de abandonar Travis CI y Codeship por restricciones del proyecto fue acertada. Descubrimos que las capas libres de GitHub Actions y GitLab CI/CD no solo cumplen con los requerimientos, sino que en muchos aspectos superan las opciones anteriores gracias a su profunda integración con los repositorios y extensos ecosistemas de "acciones" comunitarias.
2.  **Sobre GitHub Actions:** 
    *   *Opinión Técnica:* Es la herramienta más intuitiva y conveniente si el código reside en GitHub. Evita tener que autorizar aplicaciones de terceros. Sin embargo, hay que vigilar el consumo de minutos mensuales (2,000 min en repos privados) en la capa gratuita.
3.  **Sobre GitLab CI/CD:** 
    *   *Opinión Técnica:* Posee un modelo de configuración en stages muy robusto y predecible. La capacidad de usar *Docker-in-Docker* nativo simplifica enormemente la construcción de imágenes, siendo una herramienta de nivel empresarial que ofrece excelentes prestaciones sin costo inicial.
4.  **Sobre CircleCI:**
    *   *Opinión Técnica:* La configuración de `executors` brinda mucha flexibilidad y rapidez. Aunque su capa gratuita también es limitada, permite diversificar la carga de integración continua.
5.  **Sobre la ejecución local (Docker Compose):**
    *   *Opinión Técnica:* La adición de un script automatizado unifica el ecosistema y reduce a cero la fricción de entrada para nuevos desarrolladores. Orquestar Front, Back y Nginx en local permite probar la arquitectura real antes de desplegar.
