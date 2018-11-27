#!/bin/sh
# ==============================================================================================================
# Autores:
# --------
# - Pablo Fernández Díaz, v130148
# - Víctor Viller Mori, t110010
# ==============================================================================================================
# Fichero: ./raid.sh
# --------------------------------
# Fichero de ejecución del servicio "RAID". Configura y comprueba los argumentos de entrada para efectuar una
# 	conexión SSH a la IP proporcionada anteriormente y ejecutar un "mdadm" en dicha máquina.
# ==============================================================================================================

# Comprobacion de argumentos. Debe de ser 2 (./raid IP fichero)
if [ $# -ne 2 ]; then
	echo "Error 31: El número de argumentos de la ejecución a de ser únicamente 2."
	exit 21
fi

# Asignación y creación de variables
IP=$1;
NUM_LINEA=0;
DISP_RAID=''
NIVEL_RAID=''
DISPOSITIVOS_RAID=''
NUM_DISPOSITIVOS_RAID=0

# Lectura de fichero de configuración y asignación de parámetros
while read linea
do
	# Asignación del dispositivo RAID
	if [ $NUM_LINEA -eq 0 ]; then
		DISP_RAID=$linea
	# Asignación del nivel de RAID. Da un error si el RAID no existe.
	elif [ $NUM_LINEA -eq 1 ]; then
		if [ $linea -eq 0 ]; then
			NIVEL_RAID='stripe'
		elif [ $linea -eq 1 ]; then
			NIVEL_RAID='mirror'
		elif [ $linea -eq 4 ] || [ $linea -eq 5 ]; then
			NIVEL_RAID=$linea
		else
		    echo "Error 23: Nivel de RAID inválido."
		    exit 23
		fi
	# La última línea es la cantidad de dispositivos RAID sobre el que se desea
	#	ejecutar el servicio.
	elif [ $NUM_LINEA -eq 2 ]; then
	    DISPOSITIVOS_RAID=$linea
		for palabra in $linea; do
			NUM_DISPOSITIVOS_RAID=$((NUM_DISPOSITIVOS_RAID+1))
		done
	# No debe de haber más de tres líneas en el fichero de configuración. De ser así la ejecución
	#	debe de terminar
	else
		echo "Error 22: El fichero de entrada de raid debe de tener únicamente 3 líneas."
		exit 22
	fi
NUM_LINEA=$((NUM_LINEA+1))
done < $2	# Lectura del fichero de configuración

# Ejecución del servicio por vía SSH
ssh -oStrictHostKeyChecking=no $IP '
	# Comprobamos si el paquete "mdadm" está instalado en el sistema. De no ser así se instalará
	#	en la máquina destino.
	if dpkg -l | grep "mdadm" > /dev/null ; then 
		echo "El paquete está instalado";
	else
		echo "El paquete no existe. Se procederá a instalarlo...";
		export DEBIAN_FRONTEND=noninteractive;
		sudo apt-get -y -o Dpkg::Options::="--force-confnew" install mdadm;
	fi;
	
	# Ejecución del mandato.
	yes | sudo mdadm --create '$DISP_RAID' --level='$NIVEL_RAID' --raid-devices='$NUM_DISPOSITIVOS_RAID' --spare-devices=0 '$DISPOSITIVOS_RAID';
	' < /dev/null
