#!/bin/sh
	
# Comprobacion de argumentos. Debe de ser 2
if [ $# -ne 2 ]; then
	echo "Error 81: El número de argumentos de la ejecución a de ser únicamente 2."
	exit 81
fi

IP=$1;			#Guardamos en IP el primer argumento
NUM_LINEA=1;
PUNTO='';		#y el segundo sera el punto de montaje
while read linea
do
	if [ $NUM_LINEA -eq 1 ]; then
		PUNTO=$linea
	fi
#NUM_LINEA=$((NUM_LINEA+1))
done < $2

if [ $NUM_LINEA -ne 1 ]; then
	echo "Error 82: El número de lineas del fichero de configuracion debe de ser únicamente 1."
	exit 82
fi	

# Comprobamos si el punto de backup es válido

ssh -oStrictHostKeyChecking=no $IP 'if [ -d '$PUNTO' ]; then 
	VAR=ls -1A $PUNTO | wc -l
	if [ $VAR -gt 0 ]; then
			echo "Error 83: el punto de backup no esta vacio"
			exit 83;
	fi
	if [ -w $PUNTO ]; then 
		echo "Punto de backup: APTO "
		exit 0;
	else
			echo "Error 84: el punto de backup no puede ser escrito"
			exit 84;
	fi 
else 
	 echo "Error: El punto de montaje elegido no existe."
	 exit 85;
fi' < /dev/null
