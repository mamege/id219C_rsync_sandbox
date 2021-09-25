#--- 毎回 変数設定 start ---#
INTERNAL=/home/www/new/https/internal/bachelor
PUBLIC=/home/www/new/https/bachelor

WORK_DIR=/tmp/workdir
TMP_INTERNAL=${WORK_DIR:?"undefined"}/internal_bachelor
TMP_PUBLIC=${WORK_DIR:?"undefined"}/public_bachelor
BACKUP_DIR=${TMP_PUBLIC}/$(date +%Y)

TARGET=arcteam.md
# set | (grep TMP_ || echo "Error: $TMP_* is Undefined") # TMP_を含む一時変数が定義されていることを確認
#--- 毎回 変数設定 end ---#

function init() {
    echo "-- initialize --"
    #--- 1回目のみ 初期設定 start ---#
    mkdir -p ${TMP_INTERNAL:?"undefined"}/ ${TMP_PUBLIC:?"undefined"}/
    cp -r ${PUBLIC:?"undefined"}/* $TMP_PUBLIC/ 2>/dev/null
    cp -r ${INTERNAL:?"undefined"}/* $TMP_INTERNAL/

}

function del() {
    rm -rf ${TMP_INTERNAL:?"undefined"} ${TMP_PUBLIC:?"undefined"} 
}

function backup() {
    BACKUP_TARGET=${1:?"Usage: backup [target] [backup_dir]"} #変数展開を利用して外部から引数を取得、与えられない場合は:-以降が代入される
    BASEDIR=${2:?"Usage: backup [target] [backup_dir]"} #各バックアップディレクトリを格納する親ディレクトリ

    # 親ディレクトリが存在しない場合(1回目の実行)は、新規作成する。
    # 存在する場合(2回目以降の実行)は、直近のバックアップディレクトリをLATEST_BACKUPに格納
    if [ ! -d "${BASEDIR}" ]; then
        mkdir -m 774 ${BASEDIR}
        chgrp HPCS-WEB ${BASEDIR}
    else
        LATEST_BACKUP=$(ls ${BASEDIR} | grep backup- | tail -n 1) #直近のディレクトリ / The -1 (that's a one) says one file per line https://stackoverflow.com/questions/15691359/how-can-i-list-ls-the-5-last-modified-files-in-a-directory
    fi

    # LATEST_BACKUP変数に値が格納されていない場合(直近のバックアップなし)は、backup-baseという名前のバックアップを作成
    # 格納されている場合は、LATEST_BACKUPを起点に増分バックアップを行う
    NEW_BACKUP=${BASEDIR}/backup-$(date +%m%d-%H%M%S)
    echo "Save backup of ${BACKUP_TARGET} (time:$(date +%F-%H:%M:%S)) to ${NEW_BACKUP}"
    if [ -z "${LATEST_BACKUP}" ]; then
        rsync -av --exclude='*/' --include='*.*'\
         ${BACKUP_TARGET}/ ${NEW_BACKUP}
    else
        echo LATEST_BACKUP=$LATEST_BACKUP
        rsync -av --exclude='*/' --include='*.*'\
         --link-dest=${BASEDIR}/${LATEST_BACKUP}\
         ${BACKUP_TARGET}/ ${NEW_BACKUP}
    fi
}

del && init 

# -r: --links 指定パスのみならず、配下にあるファイルおよびディレクトリをcopy
# -l: --recursive シンボリックリンクをシンボリックリンクのままコピー
# -v: --verbose 詳細情報を表示
# -h: --human-readable

echo "origin" >> $TMP_PUBLIC/$TARGET
backup $TMP_PUBLIC "$BACKUP_DIR";sleep 1

echo "1st@internal" >> $TMP_INTERNAL/$TARGET
rsync -rltvh \
  --exclude='.*' --exclude='*/' --include='*.*'\
 ${TMP_INTERNAL:?"undefined"}/ ${TMP_PUBLIC:?"undefined"}/

backup $TMP_PUBLIC "$BACKUP_DIR";sleep 1
echo "2st@internal" >> $TMP_INTERNAL/$TARGET
rsync -rltvh \
  --exclude='.*' --exclude='*/' --include='*.*'\
 ${TMP_INTERNAL:?"undefined"}/ ${TMP_PUBLIC:?"undefined"}/

backup $TMP_PUBLIC "$BACKUP_DIR";sleep 1
echo "3rd@internal" >> $TMP_INTERNAL/$TARGET
rsync -rltvh \
  --exclude='.*' --exclude='*/' --include='*.*'\
 ${TMP_INTERNAL:?"undefined"}/ ${TMP_PUBLIC:?"undefined"}/


echo $BACKUP_DIR 

find $TMP_PUBLIC/ -maxdepth 1 -type f | xargs chgrp HPCS-WEB
find $TMP_PUBLIC/ -maxdepth 1 -type f | xargs chmod 664

ls -l --full-time $BACKUP_DIR/ | grep -v -E "md|jpg|png|txt|html|pdf"
find $TMP_PUBLIC/ -type f | grep $TARGET | xargs -L 1 -t tail -n 2