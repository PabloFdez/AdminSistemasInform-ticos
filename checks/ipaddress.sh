#!/bin/sh
# ==============================================================================================================
# Autores:
# --------
# - Pablo Fernández Díaz, v130148
# - Víctor Viller Mori, t110010
# ==============================================================================================================
# Fichero: ./ipaddress.sh
# --------------------------------
# Script que comprueba si una dirección IP proporcionada es correcta. Tiene que estar formado por cuatro
#	octetos con un rango comprendido entre 0 y 255.
# ==============================================================================================================

# Comprobación de argumentos. Debe de ser 1 (./ipaddress.sh direccionIP)
if [ $# -ne 2 ]; then
	echo "Error 1: El número de argumentos de la ejecución a de ser únicamente 2."
	exit 1
fi

# Comprobación de que cada octeto está comprendido en un rango entre 0 y 255, al igual que esté formado por
#	cuatro octetos.
OIFS=$IFS        
IFS='.'
numOcteto=0;
for octeto in $1; do
	if [ $octeto -ge 256 ] || [ $octeto -lt 0 ]; then
		echo "Error 5: En la línea "$2" existe una IP no válida: Índice de octeto fuera de rango."
		exit 5
	fi
	numOcteto=$((numOcteto+1))
done

if [ $numOcteto -ne 4 ]; then
	echo "Error 6: En la línea "$2" existe una IP no válida: Formato de IP incorrecto."
	exit 6
fi
IFS=$OIFS
echo "Formato de IP en línea "$2" correcto."
