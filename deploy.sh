#!/bin/sh

## Setlist Sherlock - Apple Music Token Server
## Builds and deploys the Lambda code as an ECR image

readonly DEPLOY_AWS_ACCT_ID=$1
readonly DEPLOY_AWS_REGION_ID="${2:-"us-east-1"}"
readonly DEPLOY_LAMBDA_NAME="setlist-sherlock-token-gen" # This is also in the test:* commands, if you change them here, then change them there!
readonly DEPLOY_ECR_NAME="$DEPLOY_LAMBDA_NAME-lambda"
readonly DEPLOY_AWS_ECR_REPO_URL="$DEPLOY_AWS_ACCT_ID.dkr.ecr.$DEPLOY_AWS_REGION_ID.amazonaws.com"
readonly DEPLOY_ORIGIN_URL="https://setlist-sherlock.dylmye.me"

## Step 0: Check AWS account ID is provided
if [ -z "$DEPLOY_AWS_ACCT_ID" ];
then
  echo ERROR: You need to provide a numeric AWS account ID. 1>&2
  exit 1
fi

## Step 1: Check AWS user is authenticated
echo "Checking AWS login status...\n"
aws sts get-caller-identity --region $DEPLOY_AWS_REGION_ID >/dev/null || {
  echo ERROR: You need to log in with AWS, use aws configure. If you have, ensure you have access to the region you requested. 1>&2
  exit 1
}
echo "Logged in to AWS!\n"

## Step 2: Log in to ECR Docker repo using AWS CLI
echo "Logging in to ECR repo...\n"
aws ecr get-login-password --region $DEPLOY_AWS_REGION_ID | docker login --username AWS --password-stdin $DEPLOY_AWS_ECR_REPO_URL
echo "Logged in to ECR!\n"

## Step 3: Install dependencies, build and create Docker image
echo "Creating Docker image...\n"
yarn install --frozen-lockfile --silent
yarn build
yarn test:build || {
  exit 1
}
echo "Created!\n"

## Step 4: Create ECR repository if needed
echo "Finding ECR repository...\n"
aws ecr describe-repositories --region $DEPLOY_AWS_REGION_ID --repository-names $DEPLOY_ECR_NAME >/dev/null || {
  echo "Creating ECR repository as it doesn't exist...\n"
  aws ecr create-repository --repository-name $DEPLOY_ECR_NAME --region $DEPLOY_AWS_REGION_ID --image-scanning-configuration scanOnPush=true --image-tag-mutability MUTABLE
}
echo "ECR repository found!\n"

## Step 5: Tag on ECR repo and push the tag
echo "Pushing new build to ECR...\n"
docker tag $DEPLOY_LAMBDA_NAME:test $DEPLOY_AWS_ECR_REPO_URL/$DEPLOY_ECR_NAME:latest
docker push $DEPLOY_AWS_ECR_REPO_URL/$DEPLOY_ECR_NAME:latest -q
echo "Pushed!\n"

DEPLOY_SHOULD_UPDATE_FUNCTION=true
readonly AWS_DEPLOY_ENV_VARS="$(cat .env | tr '\n' ',' | tr -d '\r')"
## Step 6: Create Lambda function if it doesn't exist already
aws lambda get-function --region $DEPLOY_AWS_REGION_ID --function-name $DEPLOY_LAMBDA_NAME >/dev/null || {
  DEPLOY_SHOULD_UPDATE_FUNCTION=false
  echo "Lambda function doesn't exist already, creating with execution role...\n"

  aws iam get-role --role-name $DEPLOY_LAMBDA_NAME-executor >/dev/null || {
    aws iam create-role --role-name $DEPLOY_LAMBDA_NAME-executor --assume-role-policy-document '{"Version": "2012-10-17","Statement": [{ "Effect": "Allow", "Principal": {"Service": "lambda.amazonaws.com"}, "Action": "sts:AssumeRole"}]}'
    aws iam attach-role-policy --role-name $DEPLOY_LAMBDA_NAME-executor --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
    sleep 15
  }
  
  # for some reason on the first time this fails with "(InvalidParameterValueException) when calling the CreateFunction operation: The role defined for the function cannot be assumed by Lambda."
  # running it again seems to work
  aws lambda create-function --region $DEPLOY_AWS_REGION_ID --function-name $DEPLOY_LAMBDA_NAME --package-type Image --code ImageUri=$DEPLOY_AWS_ECR_REPO_URL/$DEPLOY_ECR_NAME:latest --role arn:aws:iam::$DEPLOY_AWS_ACCT_ID:role/$DEPLOY_LAMBDA_NAME-executor --environment "Variables={$AWS_DEPLOY_ENV_VARS}"

  # attach function url to the function so it's directly callable
  aws lambda create-function-url-config --region $DEPLOY_AWS_REGION_ID --function-name $DEPLOY_LAMBDA_NAME --auth-type NONE --cors AllowMethods=GET,AllowOrigins=$DEPLOY_ORIGIN_URL

  echo "Created!\n"
}

if [ "$DEPLOY_SHOULD_UPDATE_FUNCTION" = true ];
then
  echo "Updating Lambda function...\n"
  aws lambda update-function-code --region $DEPLOY_AWS_REGION_ID --function-name $DEPLOY_LAMBDA_NAME --image-uri $DEPLOY_AWS_ECR_REPO_URL/$DEPLOY_ECR_NAME:latest --publish --output text >/dev/null
  sleep 15
  aws lambda update-function-configuration --region $DEPLOY_AWS_REGION_ID --function-name $DEPLOY_LAMBDA_NAME --environment "Variables={$AWS_DEPLOY_ENV_VARS}" --output text >/dev/null
  echo "Updated!\n"
fi

echo "All done!"
