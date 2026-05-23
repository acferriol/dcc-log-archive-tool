#!/bin/bash


#Ejecutar: ./log-archive-acferriol.sh ./acferriol-logs --store-dir=./archives --autoclean --sizereport --retenttime
#CONST AND VARS


STORAGE_DIR="./archives"
LOG_DIR="acferriol_logs"
ACT_LOGS="archives_log.txt"
AUTO_CLEAN=false
SIZE_REPORT=false
RETENT_TIME=false
TIME=$(date +"%Y%m%d_%H%M%S")

#La ayuda para correrlo, sino la ejecución
if [ "$1" = "--help" ]; then
    echo "Para utilizar el script:"
    echo "./log-archive-acferriol.sh <log-dir> [opciones]"
    echo "Opciones:"
    echo "--store-dir=./archives Directorio para guardar"
    echo "--autoclean Limpiar"
    echo "--sizereport Devolver tamanno"
    echo "--retenttime=<00:00:00:00> Dias:horas:minutos:segundos"
    exit 1
fi

LOG_DIR="$1"
shift

while [ $# -gt 0 ]; do #De todo lo que vi esta fue la forma que mas me gusto para leer los parametros
  case "$1" in
    --store-dir=*)
      STORAGE_DIR="${1#--store-dir=}"
      shift
      ;;
    --autoclean)
      AUTO_CLEAN=true
      shift
      ;;
    --sizereport)
      SIZE_REPORT=true
      shift
      ;;
    --retenttime)
      RETENT_TIME=true
      shift
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 2
      ;;
  esac
done


echo "Log Directory: $LOG_DIR"
if [ ! -d "$LOG_DIR" ]; then
    echo "Error: '$LOG_DIR' no existe"
    exit 1
fi


echo "Storage Directory: $STORAGE_DIR"
if [ ! -d "$STORAGE_DIR" ]; then
    echo "Creando directorio '$STORAGE_DIR'"
    mkdir -p "$STORAGE_DIR"
fi



echo "Auto Clean: $AUTO_CLEAN"
echo "Size Report: $SIZE_REPORT"
echo "Retention Time: $RETENT_TIME"
echo "Timestamp: $TIME"

# Acá me queda la duda de si el sizereport es a este directorio o al de almacenar,
# porque hacerlo a este no debe verse el cambio, a no ser que se utilice el clean.

#Size report antes de comprimir
if [ "$SIZE_REPORT" = true ]; then
    echo "Tamanno antes: $(du -sh "$LOG_DIR")"
fi


# Comprimir los logs
nombre_archivo="logs_archive_${TIME}.tar.gz"
tar -czvf "${STORAGE_DIR}/${nombre_archivo}" -C "$LOG_DIR" .

echo "Archivo de registro: $ACT_LOGS"
if [ ! -f "$LOG_DIR/$ACT_LOGS" ]; then
    echo "Creando archivo de registro '$ACT_LOGS'"
    touch "$LOG_DIR/$ACT_LOGS"
    echo "fecha--hora--nombre" >> "$LOG_DIR/$ACT_LOGS"
fi
fecha=$(date +"%Y-%m-%d")
hora=$(date +"%H:%M:%S")
echo "$fecha--$hora--$nombre_archivo" >> "$LOG_DIR/$ACT_LOGS"


# AutoClean
if [ "$AUTO_CLEAN" = true ]; then
    echo "Limpiando logs originales..."
    rm -rf "$LOG_DIR"/*.log
fi

#Size report despues de comprimir
if [ "$SIZE_REPORT" = true ]; then
    echo "Tamanno despues: $(du -sh "$LOG_DIR")"
fi

#Retention Acá igual la duda de si son los archivos de los logs o los archivos comprimidos
if [ "$RETENT_TIME" = true ]; then
    echo "Eliminando archivos comprimidos con mas de 7 dias..."
    borrar=$(find "$STORAGE_DIR" -type f -name "*.tar.gz" -mtime +7)
    echo "Archivos eliminados: $borrar"
    find "$STORAGE_DIR" -type f -name "*.tar.gz" -mtime +7 -exec rm {} \;
fi