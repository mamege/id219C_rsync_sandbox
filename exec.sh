#--- 毎回 変数設定 start ---#
WORK_DIR=/tmp/workdir
TMP_INTERNAL=${WORK_DIR:?"undefined"}/src
TMP_PUBLIC=${WORK_DIR:?"undefined"}/dest
set | (grep TMP_ || echo "Error: $TMP_* is Undefined") # TMP_を含む一時変数が定義されていることを確認

TARGET=test.txt
#--- 毎回 変数設定 end ---#

function init() {
    echo "-- initialize --"
    #--- 1回目のみ 初期設定 start ---#
    mkdir -p ${TMP_INTERNAL:?"undefined"}/ ${TMP_PUBLIC:?"undefined"}/
    echo "origin" > $TMP_PUBLIC/$TARGET
    chgrp HPCS-WEB $TMP_PUBLIC/* && ls $_ -l --full-time
    sleep 1
    echo "1st edit" > $TMP_INTERNAL/$TARGET
    echo "same file" > $TMP_INTERNAL/same_contents_file.txt

    # 余計なdirctory
    mkdir -p $TMP_INTERNAL/deleteme && echo "deleteme" > $TMP_INTERNAL/deleteme/deleteme.txt
}

function del() {
    rm -rf ${TMP_INTERNAL:?"undefined"} ${TMP_PUBLIC:?"undefined"} 
}

del && init 

# -r: --links 指定パスのみならず、配下にあるファイルおよびディレクトリをcopy
# -l: --recursive シンボリックリンクをシンボリックリンクのままコピー
# -v: --verbose 詳細情報を表示
# -h: ?? 読みやすくする
echo "rsync <option> src/ dst/"
rsync -rlth \
 ${TMP_INTERNAL:?"undefined"}/ ${TMP_PUBLIC:?"undefined"}/

echo $TMP_PUBLIC
ls -l --full-time $TMP_PUBLIC/ && cat $TMP_PUBLIC/$TARGET


del && init  

echo "rsync <option> src/ dst/"
rsync -rlth \
  --exclude='.*' --exclude='*/' --include='*.*'\
 ${TMP_INTERNAL:?"undefined"}/ ${TMP_PUBLIC:?"undefined"}/

echo $TMP_PUBLIC
ls -l --full-time $TMP_PUBLIC/ && cat $TMP_PUBLIC/$TARGET


del 