#!/bin/bash

# Pide al usuario la información de la base de datos
echo "Ingrese el host de la base de datos:"
read HOST
echo "Ingrese el nombre de la base de datos:"
read DB_NAME
echo "Ingrese el nombre de usuario de la base de datos:"
read USERNAME
echo "Ingrese la contraseña de la base de datos:"
read -s PASSWORD

# Pregunta por el directorio de respaldo
echo "Ingrese el directorio donde se almacenarán los respaldos:"
read BACKUP_DIR

# Verifica si el directorio de respaldo existe
if [ ! -d "$BACKUP_DIR" ]
then
    # Crea el directorio si no existe
    echo "Creando directorio: $BACKUP_DIR"
    mkdir -p $BACKUP_DIR
fi

# Crear una variable para el nombre del archivo
BACKUP_FILE="${BACKUP_DIR}${DB_NAME}_PROD-$(date '+%Y%m%d_%H%M%S').sql"

# Crear una variable para el archivo log
LOG_FILE="/var/log/pgMigrator.log"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] - Inicio del respaldo" >> $LOG_FILE

# Crear el respaldo
pg_dump -h $HOST -U $USERNAME -W $PASSWORD -F p -b -v -f $BACKUP_FILE $DB_NAME

# Obtener el tamaño del archivo
BACKUP_SIZE=$(du -h $BACKUP_FILE | cut -f1)

echo "[$(date '+%Y-%m-%d %H:%M:%S')] - Respaldo completado: $BACKUP_FILE (Tamaño: $BACKUP_SIZE)" >> $LOG_FILE

# Pregunta al usuario si desea realizar la búsqueda y reemplazo
echo "¿Desea buscar y reemplazar una cadena de texto en el archivo de respaldo? [s/n]"
read ANSWER

if [ "$ANSWER" = "s" ]
then
    # Pregunta al usuario la cadena de texto a buscar y reemplazar
    echo "Ingrese la cadena de texto a buscar:"
    read SEARCH
    echo "Ingrese la cadena de texto para reemplazar:"
    read REPLACE

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] - Inicio de la búsqueda y reemplazo" >> $LOG_FILE

    # Realiza la búsqueda y reemplazo en el archivo de respaldo
    sed -i "s/$SEARCH/$REPLACE/g" $BACKUP_FILE

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] - Búsqueda y reemplazo completado" >> $LOG_FILE
fi

# Pregunta al usuario si desea restaurar el respaldo
echo "¿Desea restaurar el respaldo en la base de datos destino? [s/n]"
read RESTORE_ANSWER

if [ "$RESTORE_ANSWER" = "s" ]
then
    # Pregunta al usuario la información de la base de datos destino para restaurar el respaldo
    echo "Ingrese el host de la base de datos destino:"
    read DEST_HOST
    echo "Ingrese el nombre de la base de datos destino:"
    read DEST_DB_NAME
    echo "Ingrese el nombre de usuario de la base de datos destino:"
    read DEST_USERNAME
    echo "Ingrese la contraseña de la base de datos destino:"
    read -s DEST_PASSWORD

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] - Inicio de restauración" >> $LOG_FILE

    # Restaurar el respaldo en la base de datos destino
    psql -h $DEST_HOST -U $DEST_USERNAME -W $DEST_PASSWORD -d $DEST_DB_NAME -f $BACKUP_FILE

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] - Restauración completada" >> $LOG_FILE
fi
