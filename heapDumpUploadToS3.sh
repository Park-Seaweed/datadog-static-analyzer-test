#!/bin/bash

### Slack 토큰과 채널 ID를 아규먼트로 받는다.
SLACK_TOKEN=$1
CHANNEL_ID=$2

### 작업 경로: 기본값은 /usr/app, 전달된 파라미터가 있는 경우 덮어쓴다.
WORKDIR=${3:-/usr/app}

### taskId: ECS의 경우 METADATA 정보를 취득하여 task id 정보를 경로에 포함시킨다.
TARGET_FOLDER=localhost
if [ -n "$4" ]; then
    TARGET_FOLDER=$4
elif [ -n "$ECS_CONTAINER_METADATA_URI_V4" ]; then
    TARGET_FOLDER=$(curl -s $ECS_CONTAINER_METADATA_URI_V4 | jq -r '.Labels["com.amazonaws.ecs.task-arn"]' | rev | cut -f 1 -d '/' | rev)
fi

SERVICE_NAME=$(curl $ECS_CONTAINER_METADATA_URI_V4 | jq -r '.Name')
### 저장된 힙덤프 파일을 s3로 업로드.
aws s3 cp $WORKDIR/*.hprof s3://timf-ecs-log/heapDump/$TARGET_FOLDER/

### 업로드된 덤프 파일의 목록 추출.
FILE_LIST=$(ls $WORKDIR/*.hprof)

for _file in ${FILE_LIST[@]}; do
    FILE=$(echo $_file | rev | cut -f 1 -d '/' | rev)
    TARGET_URL+=https://timf-ecs-log.s3.ap-northeast-2.amazonaws.com/heapDump/$TARGET_FOLDER/$FILE\\n
done

### 슬랙으로 정보 취합하여 전달한다.
function sendSlackMSG() {
    curl -X POST https://slack.com/api/chat.postMessage \
    -H "Authorization: Bearer $SLACK_TOKEN" \
    -H "Content-Type: application/json; charset=utf-8" \
    --data-raw "$1"
}

MSG="{
      \"channel\":\"$CHANNEL_ID\",
      \"text\":\"OOME occur. taskId :: [$TARGET_FOLDER]\nService-name :: [$SERVICE_NAME]\",
      \"attachments\": [{\"text\":\"$TARGET_URL\", \"color\":\"#ff0000\"}]
}"


sendSlackMSG "$MSG"