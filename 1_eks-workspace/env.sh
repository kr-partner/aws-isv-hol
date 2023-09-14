#!/bin/sh
cat <<EOF
{
  "aws_access_key": "$AWS_ACCESS_KEY_ID",
  "aws_secret_key": "$AWS_SECRET_ACCESS_KEY",
  "aws_token": "$AWS_SESSION_TOKEN"
}
EOF
# Windows System에서 동작불가