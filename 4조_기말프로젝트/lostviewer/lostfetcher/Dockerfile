FROM ubuntu:20.04 
#베이스 이미지로 Ubuntu 20.04를 사용
RUN apt update && \
    apt install -y curl libxml2-utils cron && \
    mkdir -p /data
#패키지 목록을 업데이트한 뒤, 필요한 패키지들을 설치
#/data 디렉토리를 만들어서 HTML 파일 저장소로 사용할 준비를 함
WORKDIR /app 
COPY update.sh .
COPY entrypoint.sh .
# 이후의 작업 디렉토리를 /app으로 설정
# update.sh, entrypoint.sh 두 스크립트 파일을 컨테이너의 /app 디렉토리에 복사
RUN chmod +x update.sh entrypoint.sh
# 복사한 두 스크립트 파일에 실행 권한을 부여
CMD ["/app/entrypoint.sh"]
# 컨테이너 실행 시 기본으로 entrypoint.sh 스크립트를 실행
# 이 스크립트에서 cron 설정 및 초기 데이터 생성, cron 데몬 실행까지 모두 담당함