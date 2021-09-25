#--- 毎回 変数設定 start ---#
INTERNAL=/home/www/new/https/internal/bachelor
PUBLIC=/home/www/new/https/bachelor

# 権限の関係で/home/www/new/https/bachelor/2020/が取得できない-> --excludeで対応
tar --exclude $PUBLIC/2020 -zcf  $HOME/home-www-new_https-bachelor_backup-$(date +%Y%m%d-%H%M).tar.gz $PUBLIC/
# 解凍: $ tar xf *.tar.gz #-> home/が生成される。