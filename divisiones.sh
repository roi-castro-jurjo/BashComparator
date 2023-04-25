#!/bin/bash

# función para manejar la señal SIGINT (Ctrl+C)
function cleanup {
    tput cnorm
    tput setaf 3
    printf "\r%s%s %d%% %s\033[K\n" "$filled_bar" "${empty_bar:0:-1}" "$percent" "CANCELADA"
    echo -e "\nEJECUCIÓN CANCELADA\n"
    tput sgr0
    tput cnorm  # restaurar el cursor normal
    exit 1
}

# registrar el manejador de señal para la señal SIGINT
trap cleanup SIGINT

GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"
CYAN="\e[36m"
DEFAULT="\e[0m"

tput civis  # ocultar el cursor

# Valores iniciales
N=${N:-1000}
ITER=${ITER:-1}
NUM_ITER=${NUM_ITER:-100}

# Opciones
long_opts="f1:,f2:,n:,iter:,numiter:"

# Parsear argumentos
args=$(getopt -o '' --long "$long_opts" -- "$@")
eval set -- "$args"

while true; do
  case "$1" in
    --f1) FILE1_PATH=$2; shift 2; FILE1_NAME=$(basename "$FILE1_PATH");;
    --f2) FILE2_PATH=$2; shift 2; FILE2_NAME=$(basename "$FILE2_PATH");;
    --n) N=$2; shift 2;;
    --iter) ITER=$2; shift 2;;
    --numiter) NUM_ITER=$2; shift 2;;
    --) shift; break;;
    *) printf "\033[31mERROR: ARGUMENTO INVÁLIDO"; tput cnorm;exit 1;;
  esac
done

# Comprobamos que se hayan introducido los argumentos obligatorios
if [ -z "$FILE1_PATH" ] || [ -z "$FILE2_PATH" ]; then
  printf "\033[31mERROR: FALTAN FICHEROS DE ENTRADA\n"
  tput cnorm  # restaurar el cursor normal
  exit 1
fi

# Imprimimos los argumentos proporcionados
printf "\n\e[36mArchivo 1: \e[0m$FILE1_NAME\n"
printf "\e[36mArchivo 2: \e[0m$FILE2_NAME\n"
printf "\e[36mNúmero de iteraciones: \e[0m$NUM_ITER\n"
if [ -n "$ITER" ]; then
  printf "\e[36mValor inicial de ITER: \e[0m$ITER\n"
fi
if [ -n "$N" ]; then
  printf "\e[36mValor inicial de N: \e[0m$N\n\n"
fi

# Crea el directorio "assembly" si no existe
if [ ! -d "assembly" ]; then
    mkdir assembly
    tput setaf 2
    printf "\nDIRECTORIO \"assembly\" CREADO CON EXITO\n"
    tput sgr0
fi

# Crea el directorio "executables" si no existe
if [ ! -d "executables" ]; then
    mkdir executables
    tput setaf 2
    printf "DIRECTORIO \"executables\" CREADO CON EXITO\n"
    tput sgr0
fi

# Crea el directorio "output" si no existe
if [ ! -d "output" ]; then
    mkdir output
    tput setaf 2
    printf "DIRECTORIO \"output\" CREADO CON EXITO\n"
    tput sgr0
fi

# Crea el directorio "plot" si no existe
if [ ! -d "plot" ]; then
    mkdir plot
    tput setaf 2
    printf "DIRECTORIO \"plot\" CREADO CON EXITO\n"
    tput sgr0
fi

# compilar el primer archivo y generar el archivo con el codigo assembly
ERRORS=$(gcc "$FILE1_PATH" -S -o assembly/"${FILE1_NAME%.*}".s 2>&1 >/dev/null)

if [ $? -eq 0 ]; then
    tput setaf 2
    printf "ARCHIVO \"%s\" CREADO CON EXITO\n"  assembly/"${FILE1_NAME%.*}".s
    tput sgr0
else
    tput setaf 1
    printf "ERROR AL CREAR \"%s\":\n"  assembly/"${FILE1_NAME%.*}".s
    printf "%s\n\n" "$ERRORS"
    tput sgr0
fi

# compilar el segundo archivo y generar el archivo con el codigo assembly
ERRORS=$(gcc "$FILE2_PATH" -S -o assembly/"${FILE2_NAME%.*}".s 2>&1 >/dev/null)

if [ $? -eq 0 ]; then
    tput setaf 2
    printf "ARCHIVO \"%s\" CREADO CON EXITO\n"  assembly/"${FILE2_NAME%.*}".s
    tput sgr0
else
    tput setaf 1
    printf "\nERROR AL CREAR \"%s\":\n"  assembly/"${FILE2_NAME%.*}".s
    printf "%s\n\n" "$ERRORS"
    tput sgr0
fi

# Compara los dos archivos .s en el directorio "assembly" y guarda el resultado en un archivo llamado "assembly_diff.txt"
diff assembly/"${FILE1_NAME%.*}".s assembly/"${FILE2_NAME%.*}".s > assembly/assembly_diff.txt 2>&1
if [ $? -ge 0 ]; then
    tput setaf 2
    printf "ARCHIVO \"assembly/assembly_diff.txt\" CREADO CON EXITO\n"
    tput sgr0
    chmod 777 assembly/assembly_diff.txt
else
    tput setaf 1
    printf "\nERROR AL CREAR \"assembly/assembly_diff.txt\"\n"
    tput sgr0
fi

# compilar el primer archivo y generar el archivo ejecutable fichero1
ERRORS=$(gcc "$FILE1_PATH" -O0 -o executables/"${FILE1_NAME%.*}" 2>&1 >/dev/null)

if [ $? -eq 0 ]; then
    tput setaf 2
    printf "ARCHIVO \"%s\" COMPILADO CON EXITO\n" "$FILE1_NAME"
    tput sgr0
else
    tput setaf 1
    printf "\nERROR al compilar \"%s\":\n" "$FILE1_NAME"
    printf "%s\n\n" "$ERRORS"
    tput sgr0
    tput cnorm  # restaurar el cursor normal
    exit 1
fi

# compilar el segundo archivo y generar el archivo ejecutable fichero2
ERRORS=$(gcc "$FILE2_PATH" -O0 -o executables/"${FILE2_NAME%.*}" 2>&1 >/dev/null)

if [ $? -eq 0 ]; then
    tput setaf 2
    printf "ARCHIVO \"%s\" COMPILADO CON EXITO\n\n" "$FILE2_NAME"
    tput sgr0
else
    tput setaf 1
    printf "\nERROR al compilar \"%s\":\n" "$FILE2_NAME"
    printf "%s\n\n" "$ERRORS"
    tput sgr0
    tput cnorm  # restaurar el cursor normal
    exit 1
fi

# Comprueba si fichero1_out.txt existe
if [ -e "output/${FILE1_NAME%.*}_out.txt" ]; then
  # Si existe, vacía su contenido
  echo "" > "output/${FILE1_NAME%.*}_out.txt"
else
  # Si no existe, crea el archivo vacío
  touch "output/${FILE1_NAME%.*}_out.txt"
fi

# Comprueba si fichero2_out.txt existe
if [ -e "output/${FILE2_NAME%.*}_out.txt" ]; then
  # Si existe, vacía su contenido
  echo "" > "output/${FILE2_NAME%.*}_out.txt"
else
  # Si no existe, crea el archivo vacío
  touch "output/${FILE2_NAME%.*}_out.txt"
fi

# Comprueba si fichero1_data.txt existe
if [ -e "plot/${FILE1_NAME%.*}_data.txt" ]; then
  # Si existe, vacía su contenido
  echo "" > "plot/${FILE1_NAME%.*}_data.txt"
else
  # Si no existe, crea el archivo vacío
  touch "plot/${FILE1_NAME%.*}_data.txt"
fi

# Comprueba si fichero2_data.txt existe
if [ -e "plot/${FILE2_NAME%.*}_data.txt" ]; then
  # Si existe, vacía su contenido
  echo "" > "plot/${FILE2_NAME%.*}_data.txt"
else
  # Si no existe, crea el archivo vacío
  touch "plot/${FILE2_NAME%.*}_data.txt"
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
    ./executables/"${FILE1_NAME%.*}" "$ITER" "$N" "${FILE1_NAME%.*}" >> "output/${FILE2_NAME%.*}_out.txt"
    end1=$(date +%s.%N)
    runtime1=$(echo "$end1 - $start1" | bc)
    total_runtime1=$(echo "$total_runtime1 + $runtime1" | bc)
    avg_runtime1=$(echo "scale=6; $total_runtime1 / ($i + 1)" | bc)

    # ejecutar el segundo fichero con los valores actuales de ITER y N
    start2=$(date +%s.%N)
    ./executables/"${FILE2_NAME%.*}" "$ITER" "$N" "${FILE2_NAME%.*}" >> "output/${FILE2_NAME%.*}_out.txt"
    end2=$(date +%s.%N)
    runtime2=$(echo "$end2 - $start2" | bc)
    total_runtime2=$(echo "$total_runtime2 + $runtime2" | bc)
    avg_runtime2=$(echo "scale=6; $total_runtime2 / ($i + 1)" | bc)

    # actualizar los valores de ITER y N para la siguiente iteración
    ITER=$((ITER + 1))
    N=$((N - 1))
done

# Imprimimos el tiempo total y medio por iteración de archivo1
printf "\n\e[36mTiempo total de \"%s\":\e[0m $total_runtime1 segundos \033[0m\n" "$FILE1_NAME"
printf "\e[36mTiempo medio por iteración de \"%s\":\e[0m $avg_runtime1 segundos\n\n" "$FILE1_NAME"

# Imprimimos el tiempo total y medio por iteración de archivo2
printf "\e[36mTiempo total de \"%s\":\e[0m $total_runtime2 segundos\n" "$FILE2_NAME"
printf "\e[36mTiempo medio por iteración de \"%s\":\e[0m $avg_runtime2 segundos\n\n" "$FILE2_NAME"

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
    printf "\nEL ARCHIVO \"%s\" ES %.6f SEGUNDOS MÁS RÁPIDO.\n\n" "$FILE1_NAME" $(echo "$speed_difference" | bc)
    tput sgr0
else
    tput setaf 2
    printf "\nEL ARCHIVO \"%s\" ES %.6f SEGUNDOS MÁS RÁPIDO.\n\n" "$FILE2_NAME" $(echo "scale=6; -1 * $speed_difference" | bc)
    tput sgr0
fi

# Compara los dos archivos .s en el directorio "output" y guarda el resultado en un archivo llamado "output_diff.txt"
diff output/"${FILE1_NAME%.*}"_out.txt output/"${FILE2_NAME%.*}"_out.txt > output/output_diff.txt 2>&1
if [ $? -ge 0 ]; then
    tput setaf 2
    printf "ARCHIVO \"output/output_diff.txt\" CREADO CON EXITO\n\n"
    tput sgr0
    chmod 777 output/output_diff.txt
else
    tput setaf 1
    printf "\nERROR AL CREAR \"output/output_diff.txt\"\n"
    tput sgr0
fi

tput cnorm  # restaurar el cursor normal
# Preguntar al usuario si quiere generar gráficos con GNUplot
read -p "¿Desea generar gráficos con GNUplot? [Y/N]: " GENERAR_GRAFICOS
tput civis  # ocultar el cursor

if [[ "$GENERAR_GRAFICOS" == "Y" || "$GENERAR_GRAFICOS" == "y" ]]; then
  DOPLOT=1
else
  DOPLOT=0
fi

# Verificar si se está en un sistema Ubuntu o Debian
if [[ "$(uname)" == "Linux" && "$(lsb_release -si)" == "Ubuntu" || "$(lsb_release -si)" == "Debian" ]]; then
    # Verificar si GNUplot está instalado
    if ! command -v gnuplot &> /dev/null; then
        tput setaf 3
        echo "GNUplot no está instalado."
        tput sgr0
        tput cnorm  # restaurar el cursor normal
        # Preguntar al usuario si desea instalarlo
        read -p "¿Desea instalar GNUplot? [Y/N]: " INSTALAR_GNUPLOT
        tput civis  # ocultar el cursor
        if [[ "$INSTALAR_GNUPLOT" == "Y" || "$INSTALAR_GNUPLOT" == "y" ]]; then
            # Instalar GNUplot con sudo
            sudo apt-get update
            sudo apt-get install gnuplot -y
            tput setaf 2
            printf "\nGNUplot ha sido instalado.\n"
            tput sgr0
        else
            tput setaf 2
            printf "\nNo se ha instalado GNUplot.\n"
            tput sgr0
            tput cnorm  # restaurar el cursor normal
            exit 1
        fi
    fi
fi

# Verificar si se está en un sistema macOS
if [[ "$(uname)" == "Darwin" ]]; then
    # Verificar si brew está instalado
    if ! command -v brew &> /dev/null; then
        tput setaf 1
        echo "Homebrew no está instalado. Por favor, instale Homebrew para continuar."
        tput sgr0
        tput cnorm  # restaurar el cursor normal
        exit 1
    fi

    # Verificar si GNUplot está instalado
    if ! command -v gnuplot &> /dev/null; then
        tput setaf 3
        echo "GNUplot no está instalado."
        tput sgr0
        tput cnorm  # restaurar el cursor normal
        # Preguntar al usuario si desea instalarlo
        read -p "¿Desea instalar GNUplot? [Y/N]: " INSTALAR_GNUPLOT
        tput civis  # ocultar el cursor
        if [[ "$INSTALAR_GNUPLOT" == "Y" || "$INSTALAR_GNUPLOT" == "y" ]]; then
            # Instalar GNUplot con brew
            brew install gnuplot
            tput setaf 2
            echo "GNUplot ha sido instalado."
            tput sgr0
        else
            tput setaf 1
            echo "No se ha instalado GNUplot."
            tput sgr0
            exit 1
            tput cnorm  # restaurar el cursor normal
        fi
    fi
fi

# Continuar con el script si se desea generar gráficos
if [[ $DOPLOT -eq 1 ]]; then
    # ... código para generar gráficos con GNUplot
    tput setaf 2
    echo -e "\nSe generaron los gráficos con GNUplot."
    tput sgr0
fi


tput cnorm  # restaurar el cursor normal