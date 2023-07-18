#!/bin/bash

# Función para la entrada del usuario
get_user_input() {
    echo "Ingrese $1:"
    read var
    echo $var
}

# Función para verificar la existencia del directorio
check_directory() {
    if [ ! -d "$1" ]
    then
        echo "Creando directorio: $1"
        mkdir -p $1
    fi
}

# Función para el registro de eventos
log_event() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] - $1" >> $LOG_FILE
}

# Inicializar variables con la entrada del usuario
HOST=$(get_user_input "el host de la base de datos")
DB_NAME=$(get_user_input "el nombre de la base de datos")
USERNAME=$(get_user_input "el nombre de usuario de la base de datos")
echo "Ingrese la contraseña de la base de datos:"
read -s PASSWORD
BACKUP_DIR=$(get_user_input "el directorio donde se almacenarán los respaldos")
LOG_FILE="/var/log/my_script.log"

# Verifica si el directorio de respaldo existe
check_directory $BACKUP_DIR

# Crear una variable para el nombre del archivo
BACKUP_FILE="${BACKUP_DIR}${DB_NAME}_PROD-$(date '+%Y%m%d_%H%M%S').sql"

log_event "Inicio del respaldo"

# Crear el respaldo
pg_dump -h $HOST -U $USERNAME -W $PASSWORD -F p -b -v -f $BACKUP_FILE $DB_NAME

# Obtener el tamaño del archivo
BACKUP_SIZE=$(du -h $BACKUP_FILE | cut -f1)

log_event "Respaldo completado: $BACKUP_FILE (Tamaño: $BACKUP_SIZE)"

# Pregunta al usuario si desea realizar la búsqueda y reemplazo
ANSWER=$(get_user_input "¿Desea buscar y reemplazar una cadena de texto en el archivo de respaldo? [s/n]")

if [ "$ANSWER" = "s" ]
then
    SEARCH=$(get_user_input "la cadena de texto a buscar")
    REPLACE=$(get_user_input "la cadena de texto para reemplazar")

    log_event "Inicio de la búsqueda y reemplazo"

    # Realiza la búsqueda y reemplazo en el archivo de respaldo
    sed -i "s/$SEARCH/$REPLACE/g" $BACKUP_FILE

    log_event "Búsqueda y reemplazo completado"
fi

# Pregunta al usuario si desea restaurar el respaldo
RESTORE_ANSWER=$(get_user_input "¿Desea restaurar el respaldo en la base de datos destino? [s/n]")

if [ "$RESTORE_ANSWER" = "s" ]
then
    DEST_HOST=$(get_user_input "el host de la base de datos destino")
    DEST_DB_NAME=$(get_user_input "el nombre de la base de datos destino")
    DEST_USERNAME=$(get_user_input "el nombre de usuario de la base de datos destino")
    echo "Ingrese la contraseña de la base de datos destino:"
    read -s DEST_PASSWORD

    log_event "Inicio de restauración"

    # Restaurar el respaldo en la base de datos destino
    psql -h $DEST_HOST -U $DEST_USERNAME -W $DEST_PASSWORD -d $DEST_DB_NAME -f $BACKUP_FILE

    log_event "Restauración completada"
fi
