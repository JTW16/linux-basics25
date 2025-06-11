#!/bin/bash

echo "*/10 * * * * /app/update.sh" > /etc/cron.d/lost-cron
#cron 스케줄을 파일에 등록
#*/10 * * * * 은 10분마다를 의미하며, /app/update.sh 스크립트를 실행
#해당 내용을 /etc/cron.d/lost-cron 파일에 저장

chmod 0644 /etc/cron.d/lost-cron
#cron 파일의 권한을 일반적인 읽기 권한(0644)로 설정

crontab /etc/cron.d/lost-cron
#위에 만든 cron 설정 파일을 실제 crontab에 등록

/app/update.sh
# 1회 실행해서 index.html 바로 만들기

cron -f # cron 데몬 실행
#일반적으로 Docker 컨테이너 안에서는 백그라운드 데몬이 없기 때문에 포그라운드로 띄워야 컨테이너가 종료되지 않음
