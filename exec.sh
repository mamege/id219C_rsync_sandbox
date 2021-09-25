#--- 毎回 変数設定 start ---#
WORK_DIR=/tmp/workdir
TMP_INTERNAL=${WORK_DIR:?"undefined"}/src
TMP_PUBLIC=${WORK_DIR:?"undefined"}/dest
# set | (grep TMP_ || echo "Error: $TMP_* is Undefined") # TMP_を含む一時変数が定義されていることを確認

TARGET=test.txt
#--- 毎回 変数設定 end ---#

function init() {
    echo "-- initialize --"
    #--- 1回目のみ 初期設定 start ---#
    mkdir -p ${TMP_INTERNAL:?"undefined"}/ ${TMP_PUBLIC:?"undefined"}/
    echo "origin" > $TMP_PUBLIC/$TARGET
    chgrp HPCS-WEB $TMP_PUBLIC/*

    echo "1st edit" > $TMP_INTERNAL/$TARGET
    echo "same file" > $TMP_INTERNAL/same_contents_file.txt

    # 余計なdirctory
    mkdir -p $TMP_INTERNAL/deleteme && echo "deleteme" > $TMP_INTERNAL/deleteme/deleteme.txt
}

function del() {
    rm -rf ${TMP_INTERNAL:?"undefined"} ${TMP_PUBLIC:?"undefined"} 
}

function backup() {
    BACKUP_TARGET=${1:-$TMP_PUBLIC} #変数展開を利用して外部から引数を取得、与えられない場合は:-以降が代入される。
    BASEDIR="${BACKUP_TARGET}/backup" #各バックアップディレクトリを格納する親ディレクトリ

    # 親ディレクトリが存在しない場合(1回目の実行)は、新規作成する。
    # 存在する場合(2回目以降の実行)は、直近のバックアップディレクトリをLATEST_BACKUPに格納
    if [ ! -d "${BASEDIR}" ]; then
        mkdir ${BASEDIR}
    else
        LATEST_BACKUP=$(ls ${BASEDIR} | grep backup- | tail -n 1) #直近のディレクトリ / The -1 (that's a one) says one file per line https://stackoverflow.com/questions/15691359/how-can-i-list-ls-the-5-last-modified-files-in-a-directory
    fi

    # LATEST_BACKUP変数に値が格納されていない場合(直近のバックアップなし)は、backup-baseという名前のバックアップを作成
    # 格納されている場合は、LATEST_BACKUPを起点に増分バックアップを行う
    NEW_BACKUP=${BASEDIR}/backup-$(date +%m%d-%H%M%S)
    echo "Save backup of ${BACKUP_TARGET}{ (time:$(date +%F-%H:%M:%S)) to ${NEW_BACKUP}"
    if [ -z "${LATEST_BACKUP}" ]; then
        rsync -a --exclude='.*' --exclude='*/' --include='*.*'\
         ${BACKUP_TARGET}/ ${NEW_BACKUP}/
    else
        echo LATEST_BACKUP=$LATEST_BACKUP
        rsync -a --exclude='.*' --exclude='*/' --include='*.*'\
         --link-dest=${BASEDIR}/${LATEST_BACKUP}\
         ${BACKUP_TARGET}/ ${NEW_BACKUP}/
    fi
}

del && init 

# -r: --links 指定パスのみならず、配下にあるファイルおよびディレクトリをcopy
# -l: --recursive シンボリックリンクをシンボリックリンクのままコピー
# -v: --verbose 詳細情報を表示
# -h: --human-readable

backup $TMP_PUBLIC ;sleep 1

rsync -rlth \
  --exclude='.*' --exclude='*/' --include='*.*'\
 ${TMP_INTERNAL:?"undefined"}/ ${TMP_PUBLIC:?"undefined"}/

backup $TMP_PUBLIC ;sleep 1

echo "2nd edit" > $TMP_INTERNAL/$TARGET
rsync -rlth \
  --exclude='.*' --exclude='*/' --include='*.*'\
 ${TMP_INTERNAL:?"undefined"}/ ${TMP_PUBLIC:?"undefined"}/

backup $TMP_PUBLIC ;sleep 1

echo $TMP_PUBLIC
ls -l --full-time $TMP_PUBLIC/
find $TMP_PUBLIC/backup/ -type f | grep $TARGET | xargs -L 1 -t cat