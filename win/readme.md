# bak2s3 (windows)
Перенос файлов на s3 совместимые хранилища

## Использование скрипта

```
bak2s3.ps1 -f path_to_conf [--run] 
```

`path_to_conf` - путь к конфигурационному файлу
`--run` - без данного ключа действия выполняются в тестовом режиме, т.е. не происходит реального копирования на s3 и удаления старых копий на s3.  Без данного ключа скрипт используется для тестирования настроек.

## Формат конфигурационного файла

Пример конфигурационного файла
```
S3="bak:"
CONFIG="./rclone.conf"
$RCLONE_EXE="C:\Backup\rclone\rclone.exe"
RCLONE_COMMAND_RK="copy" # copy or move, default copy
RCLONE_FLAGS_COPY="--no-check-certificate -P"
RCLONE_FLAGS_DELETE="--no-check-certificate -P"
OPTIONS='
    [   
        {
            "ACTION": "COPY,DELETE",
            "SOURCE_FOLDER": "/data",
            "FILTER": "bk_data",
            "DEST_FOLDER": "d1",
            "MAX_RK": 10
        },
        {
            "ACTION": "DELETE",
            "FILTER": "bk_data",
            "DEST_FOLDER": "d2",
            "MAX_RK": 7
        } 
    ]
'
```

Описание примера настроек:
`OPTIONS[0]`:
1. Копирование содержимого каталога `/data` на s3 в каталог `d1`. 
2. Проверка на s3 в каталоге `DEST_FOLDER` количества файлов по маске `FILTER` и удаление старых файлов при превышении количества `MAX_RK` 

Описание параметров:
| Parameter |Description |
| --- | --- |
| `S3` |  Имя настройки в файле настроек для rclone|
| `CONFIG` | Путь к конфигурационному файлу для rclone |
| `RCLONE_EXE` | Путь к программе rclone.exe |
| `RCLONE_COMMAND_RK` |  Команда выподняемая rclone при копировании на s3 (`copy,move`)|
| `RCLONE_FLAGS_COPY` | Дополнительные флаги запуска rclone для команды `COPY`|
| `RCLONE_FLAGS_DELETE` | Дополнительные флаги запуска rclone для команды `DELETE`|
| `OPTIONS` |  Настройки копирования и удаления|

Настройки (параметр `OPTIONS` файла настроек)
| Parameter |Description |
| --- | --- |
| `ACTION` | Задает действия производимые для данной строки настроек Возможные варианты: `COPY,DELETE`.
| `SOURCE_FOLDER` | Каталог источник |
| `DEST_FOLDER` | Каталог приемник на s3 |
| `FILTER` | Фильтр для поиска однотипных файлов на s3 в каталоге `DEST_FOLDER` для определения необходимости удаления старых копий. Может быть указано регулярное выражение |
| `MAX_RK` | Поддерживаемое количество копий файлов на s3 согдасно маски `FILTER` |

