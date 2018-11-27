#!/bin/sh
# ==============================================================================================================
# Autores:
# --------
# - Pablo Fernández Díaz, v130148
# - Víctor Viller Mori, t110010
# ==============================================================================================================
# Fichero: ./backup_client.sh
# --------------------------------
# Fichero de ejecución del servicio "BACKUP_CLIENT". Configura y comprueba los argumentos de entrada para
# efectuar una conexión SSH a la IP proporcionada anteriormente y ejecutar un backup por parte de un cliente.
# ==============================================================================================================

# Comprobacion de argumentos. Debe de ser 2 (./backup_client.sh fichero)
if [ $# -ne 2 ]; then
	echo "Error 91: El número de argumentos de la ejecución a de ser únicamente 2."
	exit 91
fi

# Creación y asignación de variables.
IP=$1
fichero=$2
NUM_LINEA=0
DIR_ORIGEN=''
IP_DESTINO=''
DIR_DESTINO=''
HORAS=''

# Asignación de valores respecto al fichero de configuración. Tiene que ser únicamente 4 líneas.
while read linea
do
	if [ $NUM_LINEA -eq 0 ]; then
		DIR_ORIGEN=$linea
	elif [ $NUM_LINEA -eq 1 ]; then
		IP_DESTINO=$linea
	elif [ $NUM_LINEA -eq 2 ]; then
		DIR_DESTINO=$linea
	elif [ $NUM_LINEA -eq 3 ]; then
		HORAS=$linea
	else
		echo "Error 92: El número de líneas del fichero tiene que ser únicamente 4."
		exit 92
	fi
	NUM_LINEA=$((NUM_LINEA+1))
done < $fichero		# Fichero de configuración

# El número de líneas proporcionadas tiene que ser 4.
if [ $NUM_LINEA -ne 4 ];  then
	echo "Error 92: El número de líneas del fichero tiene que ser únicamente 4."
	exit 92
fi
	
# TODO: COMPROBAR QUE LAS LÍNEAS PROPORCIONADAS SON VÁLIDAS
# Comprobación de IP válida
./checks/ipaddress.sh $IP_DESTINO 0

# Comprobación de la existencia de la ruta remota en base  a la IP
ssh -oStrictHostKeyChecking=no $IP_DESTINO 'if [ ! -d '$DIR_DESTINO' ]; then exit 93; fi;' < /dev/null
if [ $? = *"93"* ]; then
	echo "Error 93: El directorio remoto especificado no existe."
	exit 93	
fi

# Comprobación de que el directorio origen existe.
if [ ! -d $DIR_ORIGEN ]; then 
	echo "Error 94: El directorio local  especificado no existe."
	exit 94; 
fi;
# TODO: Comprobacion de horas.

# Realización de la copia de seguridad
ssh -oStrictHostKeyChecking=no $IP '
	IP_DESTINO='$IP_DESTINO'
	DIR_DESTINO='$DIR_DESTINO'
	NOM_DESTINO='$NOM_DESTINO'
	DIR_ORIGEN='$DIR_ORIGEN'
	HORAS='$HORAS'

	# Realización de la copia
	sudo scp -o "StrictHostKeyChecking no" -r $DIR_ORIGEN/* $IP_DESTINO:$DIR_DESTINO/

	# Realización de la copia diaria
	echo "0 $HORAS * * * root sudo scp -o \"StrictHostKeyChecking no\" -r $DIR_ORIGEN/* $IP_DESTINO:$DIR_DESTINO/" | sudo tee -a /etc/crontab
	' < /dev/null
