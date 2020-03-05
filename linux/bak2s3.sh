

#####################
# Копирование на S3 #
#####################
function toS3() {

    ni=0 # счетчик
    echo "Операция: Копирование на S3"

    echo $OPTIONS | jq -c '.[]' | while read i; do
    
        ni=$(($ni+1))

        # Получаем значения переменных из JSON
        ACTION=$(echo $i | jq -r '.ACTION')
        SOURCE_FOLDER=$(echo $i | jq -r '.SOURCE_FOLDER')
        FILTER=$(echo $i | jq -r '.FILTER')
        DEST_FOLDER=$(echo $i | jq -r '.DEST_FOLDER') 
        MAX_RK=$(echo $i | jq -r '.MAX_RK')  

        if [[ $ACTION =~ "COPY" ]]; then
            echo "[$ni] Отрабатываем SOURCE_FOLDER=$SOURCE_FOLDER"
        else
            continue
        fi

        if [[ -z "$SOURCE_FOLDER" ]]; then 
           echo "Не задан каталог источник. Настройка пропущена."
           continue
        fi

        # Если задан путь к конфигу rclone то используем его
        CNF=""
        if [[ ! -z "$CONFIG" ]]; then 
            CNF="--config $CONFIG"
        fi
        
        # Копируем на S3
        if [[ -z "$TESTMODE" ]]; then 
            rclone $RCLONE_FLAGS_COPY $CNF $RCLONE_COMMAND_RK $SOURCE_FOLDER $S3/$DEST_FOLDER
        else
            echo "TESTMODE> rclone $RCLONE_FLAGS_COPY $CNF $RCLONE_COMMAND_RK $SOURCE_FOLDER $S3/$DEST_FOLDER"
        fi

    done

}


##############################################
# Удаляем ненужные файлы согласно настройкам #
##############################################
function delS3() {

    ni=0 # счетчик
    echo ""
    echo "Операция: Удаление с S3"

    echo $OPTIONS | jq -c '.[]' | while read i; do
    
        ni=$(($ni+1))

        # Получаем значения переменных из JSON
        ACTION=$(echo $i | jq -r '.ACTION')
        SOURCE_FOLDER=$(echo $i | jq -r '.SOURCE_FOLDER')
        FILTER=$(echo $i | jq -r '.FILTER')
        DEST_FOLDER=$(echo $i | jq -r '.DEST_FOLDER') 
        MAX_RK=$(echo $i | jq -r '.MAX_RK') 

        if [[ $ACTION =~ "DELETE" ]]; then
            echo "[$ni] Отрабатываем DEST_FOLDER=$DEST_FOLDER, FILTER=$FILTER, MAX_RK=$MAX_RK"
        else
            continue
        fi

        # Если задан путь к конфигу rclone то используем его
        CNF=""
        if [[ ! -z "$CONFIG" ]]; then 
            CNF="--config $CONFIG"
        fi

        # Получим список файлов с S3 согласно настройкам
        resp=$(rclone $RCLONE_FLAGS_DELETE $CNF lsjson $S3/$DEST_FOLDER | jq -c --arg v "$FILTER" '[ .[] | select( .Name | test($v)) ] | sort_by(.ModTime)')

        # Получим количество файлов из результата
        n=$(echo $resp | jq '. | length')

        echo "Всего $n, надо $MAX_RK"

        # Если колтчество файлов больше чем MAX_RK, то удаляем старые 
        if [[ $n -gt $MAX_RK ]]; then
            
            # Вычисляем количество файлов для удаления
            let "n_for_del = n - MAX_RK" 
            echo "К удалению $n_for_del"
            
            # Удаляем в цикле
            for (( n = 0; n < $n_for_del; n++ ))
            do            
                file_for_del=$(echo $resp | jq -r ".[$n].Name")
                echo Delete - $S3/$DEST_FOLDER/$file_for_del
                
                # Удаляем файл
                
                if [[ -z "$TESTMODE" ]]; then 
                    rclone $RCLONE_FLAGS_DELETE $CNF deletefile $S3/$DEST_FOLDER/$file_for_del
                else 
                    echo "TESTMODE> rclone $RCLONE_FLAGS_DELETE $CNF deletefile $S3/$DEST_FOLDER/$file_for_del"
                fi
            done
        else
            echo "К удалению 0"   
        fi
    done  
}

TESTMODE="T"
CONF_FILE=""

while [ -n "$1" ]
do
case "$1" in
--run) TESTMODE="";;
-f) CONF_FILE="$2"
shift ;;
--) shift
break ;;
*) echo "$1 is not an option";;
esac
shift
done

 #echo [$TESTMODE]
 #echo [$CONF_FILE]

if [[ ! -z "$CONF_FILE" ]]; then 

    if [[ ! -f "$CONF_FILE" ]]; then
         echo "Не найден конфигурационный файл $CONF_FILE" 
         exit 1
    fi
    source $CONF_FILE

    if [[ ! -z "$TESTMODE" ]]; then
        echo "Включен режим ТЕСТИРОВАНИЯ"
        echo ""
    fi

    if [[ -z "$RCLONE_COMMAND_RK" ]]; then
        RCLONE_COMMAND_RK="copy"   
    elif [ $RCLONE_COMMAND_RK != "copy" ] && [ $RCLONE_COMMAND_RK != "move" ]; then     
        echo "Параметр  RCLONE_COMMAND_RK должен быть или copy или move" 
        exit 1
    fi

    # Копирование на S3
    toS3
    # Удаление с S3
    delS3
else
    echo "Не задан конфигурационный файл"    
fi
