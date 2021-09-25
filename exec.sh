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

function backup_tmp_public() {
    BASEDIR="${TMP_PUBLIC}/backup/" #各バックアップディレクトリを格納する親ディレクトリ

    # 親ディレクトリが存在しない場合(1回目の実行)は、新規作成する。
    # 存在する場合(2回目以降の実行)は、直近のバックアップディレクトリをLATESTBKUPに格納
    if [ ! -d "${BASEDIR}" ]; then
        mkdir ${BASEDIR}
    else
        LATESTBKUP=$(ls -1t ${BASEDIR} | head -1) #直近のディレクトリ / The -1 (that's a one) says one file per line https://stackoverflow.com/questions/15691359/how-can-i-list-ls-the-5-last-modified-files-in-a-directory
    fi

    # LATESTBKUP変数に値が格納されていない場合(直近のバックアップなし)は、backup-baseという名前のバックアップを作成
    # 格納されている場合は、LATESTBKUPを起点に増分バックアップを行う
    if [ -z "${LATESTBKUP}" ]; then
        rsync -a --exclude='.*' --exclude='*/' --include='*.*'\
            ${TMP_PUBLIC}/ ${BASEDIR}/backup-base
    else
        rsync -a --exclude='.*' --exclude='*/' --include='*.*'\
         --link-dest=${BASEDIR}/${LATESTBKUP} ${TMP_PUBLIC}/ ${BASEDIR}/backup-$(date +%Y-%m-%d)
    fi
}

del && init 

# -r: --links 指定パスのみならず、配下にあるファイルおよびディレクトリをcopy
# -l: --recursive シンボリックリンクをシンボリックリンクのままコピー
# -v: --verbose 詳細情報を表示
# -h: --human-readable

backup_tmp_public

rsync -rlth \
  --exclude='.*' --exclude='*/' --include='*.*'\
 ${TMP_INTERNAL:?"undefined"}/ ${TMP_PUBLIC:?"undefined"}/

backup_tmp_public

echo $TMP_PUBLIC
ls -l --full-time $TMP_PUBLIC/
find $TMP_PUBLIC/backup/ -type f | grep $TARGET | xargs -L 1 -t cat