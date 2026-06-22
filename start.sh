#!/bin/bash
echo "Iniciando ClimaColombia con Docker Compose..."
docker-compose up --build -d
echo ""
echo "Los contenedores se estan ejecutando en segundo plano."
echo "Para ver la pagina web, abre tu navegador en: http://localhost"
echo ""
