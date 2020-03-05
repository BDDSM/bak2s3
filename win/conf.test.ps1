$S3="bak:"
$CONFIG="C:\Backup\rclone\rclone.conf"
$RCLONE_EXE="C:\Backup\rclone\rclone.exe"
$RCLONE_COMMAND_RK="copy" # copy or move, default copy
$RCLONE_FLAGS_COPY="--no-check-certificate -P --max-age 48h"
$RCLONE_FLAGS_DELETE="--no-check-certificate"
$OPTIONS='
    [   
        {
            "ACTION": "COPY,DELETE",
			"SOURCE_FOLDER": "C:/Backup/Test",
            "FILTER": "data",
            "DEST_FOLDER": "test/bak2s3",
            "MAX_RK": 5
        }
    ]
'     