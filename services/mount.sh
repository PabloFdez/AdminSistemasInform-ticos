#!/bin/bash
# ==============================================================================================================
# Autores:
# --------
# - Pablo Fernández Díaz, v130148
# - Víctor Viller Mori, t110010
# ==============================================================================================================
# Fichero: ./mount.sh
# --------------------------------
# Fichero de ejecución del servicio "MOUNT". Configura y comprueba los argumentos de entrada para efectuar
#	el montaje de un sistema de ficheros.
# ==============================================================================================================

#1er argumento ip
#2o argumento fichero
#	- 1a linea dispositivo
#	- 2a liena directorio

# 1º Comprobar que mount está instalado
# 2º Si NO existe punto de montaje -> mount
# 3º Si existe punto de montaje:
#			- Comprubea que dicho directorio esta vacio
#			-> mount

# Comprobamos si el paquete mount está instalado	

# Comprobacion de argumentos. Debe de ser 3 (./mount disco punto_montaje)
if [ $# -ne 2 ]; then
	echo "Error 11: El número de argumentos de la ejecución a de ser únicamente 2."
	exit 11
fi

IP=$1;			#Guardamos en IP el primer argumento
NUM_LINEA=0;
DISP='';		#En el fichero leido la primera linea será el dispositivo
PUNTO='';		#y el segundo sera el punto de montaje
while read linea
do
   	if [ $NUM_LINEA -eq 0 ]; then
	    DISP=$linea
	elif [ $NUM_LINEA -eq 1 ]; then
	    PUNTO=$linea
	fi
NUM_LINEA=$((NUM_LINEA+1))
done < $2

if [ $NUM_LINEA -ne 2 ]; then
	echo "Error 12: El número de lineas del fichero de configuracion debe de ser únicamente 2."
	exit 12
fi	


# Comprobamos si existe el directorio pasado por parámetros
ssh -oStrictHostKeyChecking=no $IP '
	# Comprobamos si el paquete "mount" está instalado en el sistema
	if dpkg -l | grep "mount" > /dev/null ; then 
		echo "El paquete está instalado";
	else
		echo "El paquete no existe. Se procederá a instalarlo...";
		export DEBIAN_FRONTEND=noninteractive;
		sudo apt-get -y -o Dpkg::Options::="--force-confnew" install mount;
	fi;

	if [ -d '$PUNTO' ]; then 
		if [ $(ls -1A '$PUNTO' | wc -l) -eq 0 ]; then
			if [ -b '$DISP' ]; then
				sudo mount -t auto '$DISP' '$PUNTO'; echo "¡Montaje realizado con éxito!"; 
				echo "'$DISP' '$PUNTO' ext4 defaults 0 0" | sudo tee -a /etc/fstab;
				exit 0;
			else
				echo "Error 13: el dispositivo no existe"
				exit 13;
			fi
		else 
			echo "Error 14: el punto de montaje no esta vacio"
			exit 14;
		fi 
	else 
		echo "Aviso: El punto de montaje elegido no existe"
		mkdir '$PUNTO'
		echo "Aviso: El punto de montaje elegido ha sido creado"
		if [ -b '$DISP' ]; then
			sudo mount -t auto '$DISP' '$PUNTO'; echo "¡Montaje realizado con éxito!";
			echo "'$DISP' '$PUNTO' ext4 defaults 0 0" | sudo tee -a /etc/fstab;
			exit 0;
		else
			echo "Error 13: el dispositivo no existe"
			exit 13;
		fi
	fi' < /dev/null
