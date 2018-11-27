#!/bin/bash
# ==============================================================================================================
# Autores:
# --------
# - Pablo Fernández Díaz, v130148
# - Víctor Viller Mori, t110010
# ==============================================================================================================
# Fichero: ./lvm.sh
# --------------------------------
# Fichero de ejecución del servicio "LVM". Configura y comprueba los argumentos de entrada para 
# realizar el montado de volúmenes lógicos.
# ==============================================================================================================

#Argumentos (minimo 3)
#nombre-del-grupo-de-volumenes
#lista-de-dispositivos-en-el-grupo
#nombre-del-primer-volumen tamano-del-primer-volumen
#nombre-del-segundo-volumen tamano-del-segundo-volumen ...

#1º Comprobar que cabe en el grupo
#2º Inicializamos pvcreate
#3º Creamos el grupo (arg 1)
#4º Creamos los volumenes logicos

# Comprobamos si el paquete mount está instalado

#Se le deben pasar 3 argumentos. El tercero es la lista de volumenes del fichero de configuración
#GRUPO=$1 #Nombre del grupo de volúmenes
#DISPOSITIVOS=$2 #Lista de dispositivos
#CADENA=$3 #Lista de volumenes a crear

#Comprobamos el número de argumentos
if [ $# -ne 2 ]; then
	echo "Error 31: El número de argumentos de la ejecución a de ser 2."
	exit 31
fi
	
IP=$1;			#Guardamos en IP el primer argumento


NUM_LINEA=1;
GRUPO='';				#Nombre del grupo de volúmenes
DISPOSITIVOS='';		#Lista de dispositivos
CADENA="\"";				#Lista de volumenes a crear
while read linea
do
	if [ $NUM_LINEA -eq 1 ]; then
		GRUPO="\""$linea"\""
	elif [ $NUM_LINEA -eq 2 ]; then
		DISPOSITIVOS="\""$linea"\""	
	elif [ $NUM_LINEA -ge 3 ]; then
	    
		CADENA+=""$linea""
		CADENA+=" "
	fi

NUM_LINEA=$((NUM_LINEA+1))
done < $2
CADENA+="\""

ssh -oStrictHostKeyChecking=no $IP '
# Comprobamos si el paquete "lvm2" está instalado en el sistema. De no ser así se instalará
#	en la máquina destino.
if dpkg -l | grep "lvm2" > /dev/null ; then 
		echo "El paquete para nis está instalado";
	else
		echo "El paquete no existe. Se procederá a instalarlo...";
		export DEBIAN_FRONTEND=noninteractive;
		sudo apt-get -y -o Dpkg::Options::="--force-confnew" install lvm2;
	fi;


NUM_LINEA='$NUM_LINEA'
GRUPO='$GRUPO'
DISPOSITIVOS='$DISPOSITIVOS'
CADENA='$CADENA'

if [ $NUM_LINEA -lt 3 ]; then
	echo "Error 32: El número de lineas del fichero de configuracion debe de ser de al menos 3."
	exit 32
fi

LONG=0
for palabra in $CADENA; do
	LONG=$((LONG+1))
done

if [ $LONG -eq 0 ]; then
	echo "Error: Se debe indicar al menos 1 volumen."
	exit 33
fi	

#Funcion que obtiene la memoria total en bytes

function cap {
    DIR="/../../../proc/meminfo"
	AUX=0
	while IFS='' read -r line || [[ -n "$line" ]]; do
		AUX=$(($AUX +1))
		#En la primera linea de meminfo se encuentra la memoria total
		if [ "$AUX" -eq 1 ]; then
			#Cojo la primera línea y la debo multiplicar por 1000
			VALOR=$line
			NUM=${VALOR//[!0-9]/}
			CAP=$(($NUM*1000)) 
		fi
	done < "$DIR"
}

#Función que convierte un resultado en GB,KB,MB... en Bytes
function conv {
	NUM=${CADENA[$LONG]}
	#Coge el valor numérico
	A=${NUM//[!0-9]/}

	#Coge la medida de peso (GB,KB,MB)
	NUM2=`echo $NUM | sed 's/[^a-zA-Z]//g'` 

	case $NUM2 in
  	  "K" )
		RES=$(($A*1000));;
  	  "M" )
		RES=$(($A*1000000));;
	  "G" )
		RES=$(($A*1000000000));;
	  "T" )
		RES=$(($A*1000000000000));;
	  "KB" )
		RES=$(($A*1000));;
  	  "MB" )
		RES=$(($A*1000000));;
	  "GB" )
		RES=$(($A*1000000000));;
	  "TB" )
		RES=$(($A*1000000000000));;
	esac	
}

#Función que realiza todos los pasos de lvm
function hace_lvm {
		#Volvemos a guardar la longitud del array por si ha sufrido modificaciones
		#NEW_LONG=${#CADENA[@]}
		LONG=0
		for palabra in $CADENA; do
			LONG=$((LONG+1))
		done
		#Inicializamos los dispositivos
		sudo pvcreate ${DISPOSITIVOS[@]} 
		#Creamos un grupo
		sudo vgcreate $GRUPO ${DISPOSITIVOS[@]}

		#Creamos los volumenes logicos 
		NUM_P=0

			AUX03=''
			AUX04=''
			
			for palabra in $CADENA; do
				if [ $((NUM_P%2)) -eq 0 ]; then
					AUX03=$palabra
				else
					AUX04=$palabra
					sudo lvcreate -L$AUX04 -n $AUX03 $GRUPO
				fi
				NUM_P=$((NUM_P+1))
			done

}

#Bucle que dada una lista coge solo los elementos pares
 while [ $LONG -ge 0 ]; do
 	if [ $((LONG%2)) -ne 0 ]; then
 		conv
 		RES_FINAL=$((RES_FINAL + RES))
 	fi
 	LONG=$(($LONG-1))
 done
 
#Llamamos a cap
cap

#Comprobamos si se puede hacer lvm
 if [[ $CAP -lt $RES_FINAL ]]; then
    echo "Error: No hay suficiente capacidad para crear los volúmenes lógicos"
     exit 34
else
     hace_lvm
     echo "LVM creado correctamente"
 fi' < /dev/null
