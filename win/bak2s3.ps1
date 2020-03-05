Param (
[string]$f,
[string]$run
)

function tos3() {
    Write-Output "Copy or move on S3"

    $Opt = ConvertFrom-Json -InputObject $options

    $ni = 0

    ForEach ($item in $Opt){

        $ni = $ni + 1
        #  Получаем значения переменных из JSON
        $ACTION=$item.ACTION
        $SOURCE_FOLDER= $item.SOURCE_FOLDER
        #$FILTER=$item.FILTER
        $DEST_FOLDER=$item.DEST_FOLDER
        #$MAX_RK=$item.MAX_RK

        if ($ACTION.Contains("COPY")) {
            Write-Output "[$ni]  processing SOURCE_FOLDER=$SOURCE_FOLDER"
        } else {
            continue
        }

        if ($SOURCE_FOLDER -eq "" ) {
           Write-Output "Dont set source folder. Option missed."
           continue
        }

        # if set config path use it 
        $CNF=""
        if ($CONFIG -ne "") { 
            $CNF="--config $CONFIG"
        }
        
         # Copy on  S3 
        if ($TESTMODE -eq "") { 
			Write-Output "RUN> $RCLONE_EXE $RCLONE_FLAGS_COPY $CNF $RCLONE_COMMAND_RK $SOURCE_FOLDER $S3/$DEST_FOLDER"
            Invoke-Expression -Command  "$RCLONE_EXE $RCLONE_FLAGS_COPY $CNF $RCLONE_COMMAND_RK $SOURCE_FOLDER $S3/$DEST_FOLDER"
        } else {
            Write-Output "TESTMODE> $RCLONE_EXE $RCLONE_FLAGS_COPY $CNF $RCLONE_COMMAND_RK $SOURCE_FOLDER $S3/$DEST_FOLDER"
        }
    }

}

function dels3() {

    Write-Output " Operation: Delete from S3"

    $Opt = ConvertFrom-Json -InputObject $options

    $ni = 0
    
    ForEach ($item in $Opt){

        $ni = $ni + 1
         # Получаем значения переменных из JSON 
        $ACTION=$item.ACTION
        $SOURCE_FOLDER= $item.SOURCE_FOLDER
        $FILTER=$item.FILTER
        $DEST_FOLDER=$item.DEST_FOLDER
        $MAX_RK=$item.MAX_RK
         
        if ($ACTION.Contains("DELETE")) {
            Write-Output "[$ni] processing DEST_FOLDER=$DEST_FOLDER, FILTER=$FILTER, MAX_RK=$MAX_RK"
        } else {
            continue
        }

         # Если задан путь к конфигу rclone то используем его 
        $CNF=""
        if ($CONFIG -ne "") { 
            $CNF="--config $CONFIG"
        }

         # Получим список файлов с S3 согласно настройкам 
        Invoke-Expression -Command "$RCLONE_EXE $RCLONE_FLAGS_DELETE $CNF lsjson $S3/$DEST_FOLDER" | Out-String -OutVariable resp
        
        $files = ConvertFrom-Json -InputObject $resp[0] 

        $files = $files | Sort-Object -Property ModTime

        $files = $files | Where-Object { $_.Name -match $FILTER }
        
        $count_file = 0
        ForEach ($file in $files) { 
                $count_file = $count_file + 1
        }

        Write-Output "All $count_file, need $MAX_RK"

        if ($count_file -gt $MAX_RK) {
            $n_for_del = $count_file - $MAX_RK
            Write-Output "For delete $n_for_del"

            for($i=0;$i -lt $n_for_del;$i++){
                $FILE_FOR_DELETE = $files[$i].Name
                Write-Output "Delete - $S3/$DEST_FOLDER/$FILE_FOR_DELETE"   
                
                 # Удаляем на S3 
                if ($TESTMODE -eq "") { 
                    Invoke-Expression -Command  "$RCLONE_EXE $RCLONE_FLAGS_DELETE $CNF deletefile $S3/$DEST_FOLDER/$FILE_FOR_DELETE"
                } else {
                    Write-Output "TESTMODE> $RCLONE_EXE $RCLONE_FLAGS_DELETE $CNF deletefile $S3/$DEST_FOLDER/$FILE_FOR_DELETE"
                } 
           
            } 
        } 
    }
}

if ($f -ne "") {

    . $f

    $TESTMODE="T"
    if ($run -eq "--run") {
        $TESTMODE=""    
    }

    if ($TESTMODE -ne "") {
        Write-Output "Set TEST mode"
        Write-Output ""
    }

    if ($RCLONE_COMMAND_RK -eq "") {
        RCLONE_COMMAND_RK="copy"
    }       
    
    if (($RCLONE_COMMAND_RK -ne "copy") -and ($RCLONE_COMMAND_RK -ne "move")) {     
        Write-Output " The value of parameter RCLONE_COMMAND_RK must be copy or move" 
        exit 1
    }
	

    # Копирование на S3 
    tos3

     # Удаление с S3 
    dels3
} else {
    Write-Output "Dont set configuration file"
}
