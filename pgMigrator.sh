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
export PGPASSWORD=$PASSWORD

BACKUP_DIR="/Backups/PostgreSQL/LUGH/"

# Crear una variable para el nombre del archivo
BACKUP_FILE="${BACKUP_DIR}${DB_NAME}_PROD-$(date '+%Y%m%d_%H%M%S').sql"

# Crear una variable para el archivo log
LOG_FILE="/var/log/pgMigrator.log"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] - Inicio el respaldo de $DB_NAME" >> $LOG_FILE

# Crear el respaldo
pg_dump -h $HOST -U $USERNAME -F p -b -v -f $BACKUP_FILE $DB_NAME

# Obtener el tamaño del archivo
BACKUP_SIZE=$(du -h $BACKUP_FILE | cut -f1)

echo "[$(date '+%Y-%m-%d %H:%M:%S')] - Respaldo completado: $BACKUP_FILE (Tamaño: $BACKUP_SIZE)" >> $LOG_FILE

# Pregunta al usuario si desea realizar la búsqueda y reemplazo
echo "¿Desea buscar y reemplazar una cadena de texto en el archivo de respaldo? [s/n]"
read ANSWER

while [ "$ANSWER" = "s" ]
do
    # Pregunta al usuario la cadena de texto a buscar y reemplazar
    echo "Ingrese la cadena de texto a buscar:"
    read SEARCH
    echo "Ingrese la cadena de texto para reemplazar:"
    read REPLACE

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] - Inicio de la búsqueda y reemplazo de '$SEARCH' por '$REPLACE'" >> $LOG_FILE

    # Realiza la búsqueda y reemplazo en el archivo de respaldo
    sed -i "s/$SEARCH/$REPLACE/g" $BACKUP_FILE

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] - Búsqueda y reemplazo completado" >> $LOG_FILE

    # Pregunta al usuario si desea realizar otra búsqueda y reemplazo
    echo "¿Desea buscar y reemplazar otra cadena de texto en el archivo de respaldo? [s/n]"
    read ANSWER
done

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
    export PGPASSWORD=$DEST_PASSWORD

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] - Inicio la restauración de $DEST_DB_NAME" >> $LOG_FILE

    # Restaurar el respaldo en la base de datos destino
    psql -h $DEST_HOST -U $DEST_USERNAME -d $DEST_DB_NAME -f $BACKUP_FILE

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] - Restauración completada" >> $LOG_FILE
fi

# Pregunta al usuario si desea cambiar los permisos del propietario
echo "¿Desea cambiar los permisos del propietario? [s/n]"
read CHANGE_OWNER

if [ "$CHANGE_OWNER" = "s" ]
then
    # Pregunta al usuario la información del DBA y el usuario al que otorgará permisos
    echo "Ingrese el nombre de usuario DBA:"
    read DBA_USERNAME
    echo "Ingrese la contraseña del DBA:"
    read -s DBA_PASSWORD
    export PGPASSWORD=$DBA_PASSWORD
    echo "Ingrese el nombre de usuario al que se otorgarán permisos:"
    read GRANT_USERNAME

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] - Inicio de cambio de permisos del propietario a $GRANT_USERNAME" >> $LOG_FILE

    # Ejecutar los comandos para otorgar permisos
    psql -h $DEST_HOST -U $DBA_USERNAME -d $DEST_DB_NAME -c "GRANT CONNECT ON DATABASE $DEST_DB_NAME TO $GRANT_USERNAME; \
    GRANT USAGE ON SCHEMA public TO $GRANT_USERNAME; \
    GRANT ALL PRIVILEGES ON DATABASE $DEST_DB_NAME TO $GRANT_USERNAME; \
    GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO $GRANT_USERNAME; \
    GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO $GRANT_USERNAME; \
    GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO $GRANT_USERNAME;"

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] - Cambio de permisos del propietario a $GRANT_USERNAME completado" >> $LOG_FILE
fi

# Pregunta al usuario si desea dar permisos de lectura a un usuario
echo "¿Desea otorgar permisos de lectura a un usuario? [s/n]"
read READ_PERMISSION

if [ "$READ_PERMISSION" = "s" ]
then
    # Pregunta al usuario el nombre del usuario al que otorgará permisos de lectura
    echo "Ingrese el nombre de usuario al que se otorgarán permisos de lectura:"
    read READ_USERNAME

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] - Inicio de otorgamiento de permisos de lectura a $READ_USERNAME" >> $LOG_FILE

    # Ejecutar los comandos para otorgar permisos de lectura
    psql -h $DEST_HOST -U $DBA_USERNAME -d $DEST_DB_NAME -c "GRANT CONNECT ON DATABASE $DEST_DB_NAME TO $READ_USERNAME; \
    GRANT USAGE ON SCHEMA public TO $READ_USERNAME; \
    GRANT SELECT ON ALL TABLES IN SCHEMA public TO $READ_USERNAME;"

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] - Otorgamiento de permisos de lectura a $READ_USERNAME completado" >> $LOG_FILE
fi