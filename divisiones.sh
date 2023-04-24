#!/bin/bash

# función para manejar la señal SIGINT (Ctrl+C)
function cleanup {
    tput cnorm
    tput setaf 3
    printf "\r%s%s %d%% %s\033[K\n" "$filled_bar" "${empty_bar:0:-1}" "$percent" "CANCELADA"
    echo -e "\nEJECUCIÓN CANCELADA\n"
    tput sgr0
    exit 1
}

# registrar el manejador de señal para la señal SIGINT
trap cleanup SIGINT

tput civis  # ocultar el cursor

ITER=$1  # valor inicial de ITER
N=$2  # valor inicial de N
NUM_ITER=$3  # número de iteraciones del bucle
FILE1=$4  # primer archivo a compilar
FILE2=$5  # segundo archivo a compilar

# compilar el primer archivo y generar el archivo ejecutable fichero1
ERRORS=$(gcc "$FILE1" -O0 -o fichero1 2>&1 >/dev/null)

if [ $? -eq 0 ]; then
    tput setaf 2
    printf "\n\"%s\" COMPILADO CON EXITO\n" "$FILE1"
    tput sgr0
else
    tput setaf 1
    printf "\nERROR al compilar \"%s\":\n" "$FILE1"
    printf "%s\n\n" "$ERRORS"
    tput sgr0
    exit 1
fi

# compilar el segundo archivo y generar el archivo ejecutable fichero2
ERRORS=$(gcc "$FILE2" -O0 -o fichero2 2>&1 >/dev/null)

if [ $? -eq 0 ]; then
    tput setaf 2
    printf "\n\"%s\" COMPILADO CON EXITO\n\n" "$FILE2"
    tput sgr0
else
    tput setaf 1
    printf "\nERROR al compilar \"%s\":\n" "$FILE2"
    printf "%s\n\n" "$ERRORS"
    tput sgr0
    exit 1
fi

# Comprueba si fichero1_out.txt existe
if [ -e "fichero1_out.txt" ]; then
  # Si existe, vacía su contenido
  echo "" > "fichero1_out.txt"
else
  # Si no existe, crea el archivo vacío
  touch "fichero1_out.txt"
fi

# Comprueba si fichero2_out.txt existe
if [ -e "fichero2_out.txt" ]; then
  # Si existe, vacía su contenido
  echo "" > "fichero2_out.txt"
else
  # Si no existe, crea el archivo vacío
  touch "fichero2_out.txt"
fi


# Medimos el tiempo total del script
start=$(date +%s.%N)

# Variables para medir el tiempo de fichero1
total_runtime1=0
avg_runtime1=0

# Variables para medir el tiempo de fichero2
total_runtime2=0
avg_runtime2=0

# calcular la longitud total de la barra de progreso
BAR_LEN=100

# bucle que se repetirá NUM_ITER veces
for ((i=0; i<$NUM_ITER; i++))
do

    # calcular el porcentaje de finalización
    percent=$(( (i+1) * 100 / NUM_ITER ))

    # calcular el número de caracteres de dibujo de caja para la barra de progreso
    filled_chars=$(( percent * BAR_LEN / 100 ))
    empty_chars=$(( BAR_LEN - filled_chars + 1 ))
    filled_bar=$(printf "█%0.s" $(seq 1 $filled_chars))
    empty_bar=$(printf "░%0.s" $(seq 1 $empty_chars))

    # agregar la cadena "EJECUTANDO..." al final de la barra de progreso
    case $(( i % 12 )) in
        0) dots=".";;
        4) dots="..";;
        8) dots="...";;
    esac
    message="EJECUTANDO$dots"

    # imprimir la barra de progreso con el mensaje
    if [ $percent -eq 100 ]; then
        tput setaf 2
        printf "\r%s%s %d%% %s\033[K\n" "$filled_bar" "${empty_bar:0:-1}" "$percent" "EXITO"
        tput sgr0
    else
        printf "\r%s%s %d%% %s\033[K" "$filled_bar" "${empty_bar:0:-1}" "$percent" "$message"
    fi

    # ejecutar el primer fichero con los valores actuales de ITER y N
    start1=$(date +%s.%N)
    ./fichero1 "$ITER" "$N" >> fichero1_out.txt
    end1=$(date +%s.%N)
    runtime1=$(echo "$end1 - $start1" | bc)
    total_runtime1=$(echo "$total_runtime1 + $runtime1" | bc)
    avg_runtime1=$(echo "scale=6; $total_runtime1 / ($i + 1)" | bc)

    # ejecutar el segundo fichero con los valores actuales de ITER y N
    start2=$(date +%s.%N)
    ./fichero2 "$ITER" "$N" >> fichero2_out.txt
    end2=$(date +%s.%N)
    runtime2=$(echo "$end2 - $start2" | bc)
    total_runtime2=$(echo "$total_runtime2 + $runtime2" | bc)
    avg_runtime2=$(echo "scale=6; $total_runtime2 / ($i + 1)" | bc)

    # actualizar los valores de ITER y N para la siguiente iteración
    ITER=$((ITER + 1))
    N=$((N - 1))
done

# Imprimimos el tiempo total y medio por iteración de archivo1
printf "\n\e[36mTiempo total de \"%s\":\e[0m $total_runtime1 segundos \033[0m\n" "$FILE1"
printf "\e[36mTiempo medio por iteración de \"%s\":\e[0m $avg_runtime1 segundos\n\n" "$FILE1"

# Imprimimos el tiempo total y medio por iteración de archivo2
printf "\e[36mTiempo total de \"%s\":\e[0m $total_runtime2 segundos\n" "$FILE2"
printf "\e[36mTiempo medio por iteración de \"%s\":\e[0m $avg_runtime2 segundos\n\n" "$FILE2"

# Imprimimos el tiempo total y medio por iteración del script completo
end=$(date +%s.%N)
runtime=$(echo "$end - $start" | bc)
avg_runtime=$(echo "scale=6; $runtime / $ITER" | bc)
printf "\e[36mTiempo total del script:\e[0m $runtime segundos\n"
printf "\e[36mTiempo medio por iteración del script:\e[0m $avg_runtime segundos\n"

# calcular la diferencia de velocidad entre los dos archivos
speed_difference=$(echo "$total_runtime2 - $total_runtime1" | bc)

# mostrar la diferencia de velocidad entre los dos archivos

if (( $(echo "$total_runtime1 < $total_runtime2" |bc -l) )); then
    tput setaf 3
    printf "\nEL ARCHIVO \"%s\" ES %.6f SEGUNDOS MÁS RÁPIDO.\n\n" "$FILE1" $(echo "$speed_difference" | bc)
    tput sgr0
else
    tput setaf 2
    printf "\nEL ARCHIVO \"%s\" ES %.6f SEGUNDOS MÁS RÁPIDO.\n\n" "$FILE2" $(echo "scale=6; -1 * $speed_difference" | bc)
    tput sgr0
fi

tput cnorm  # restaurar el cursor normal