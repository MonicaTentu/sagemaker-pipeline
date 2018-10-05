#!/bin/bash
AWS_DEFAULT_REGION="<ENTER AWS REGION>"
Email="<ENTER EMAIL ADDRESS FOR PIPELINE NOTIFICATION>"

# Parameters to Configure Specific Github Repo
GitHub_User="<ENTER YOUR GITHUB USER NAME>"
GitHub_Repo="<ENTER NAME (ONLY) OF GITHUB REPOSITORY>"
GitHub_Branch="<ENTER NAME OF GIT BRANCH THAT WILL TRIGGER PIPELINE>"
GitHub_Token="<ENTER GITHUB PERSONAL ACCESS TOKEN>"

# CodeBuild Project Parameters
Python_Build_Version="aws/codebuild/python:3.6.5-1.3.2"
Build_Timeout_Mins=30

# SageMaker Training Job Parameters
Instance_Count=1
Instance_Type="ml.m4.4xlarge"
Max_Runtime_In_Seconds=86400
Vol_In_GB=30

Template_Name="${GitHub_Repo}-cicd-pipeline"
Lambdas_Bucket="${Template_Name}-lambdas-`date '+%Y-%m-%d-%H-%M-%S'`"
Lambdas_Key="SageMakerTrigger/LambdaFunction.zip"

cd lambda

chmod -R 755 .

zip -r ../LambdaFunction.zip .

cd ..

aws s3api create-bucket --bucket ${Lambdas_Bucket} \
 --region ${AWS_DEFAULT_REGION}

aws s3api put-object --bucket ${Lambdas_Bucket} \
  --key ${Lambdas_Key} \
  --body ./LambdaFunction.zip

aws cloudformation create-stack \
  --region ${AWS_DEFAULT_REGION} \
  --stack-name ${Template_Name} \
  --template-body file://template/sagemaker-pipeline.yaml \
  --parameters \
    ParameterKey=LambdasBucket,ParameterValue=${Lambdas_Bucket} \
    ParameterKey=LambdasKey,ParameterValue=${Lambdas_Key} \
    ParameterKey=Email,ParameterValue=${Email} \
    ParameterKey=GitHubUser,ParameterValue=${GitHub_User} \
    ParameterKey=GitHubRepo,ParameterValue=${GitHub_Repo} \
  	ParameterKey=GitHubBranch,ParameterValue=${GitHub_Branch} \
  	ParameterKey=GitHubToken,ParameterValue=${GitHub_Token} \
    ParameterKey=PythonBuildVersion,ParameterValue=${Python_Build_Version} \
    ParameterKey=BuildTimeoutMins,ParameterValue=${Build_Timeout_Mins} \
    ParameterKey=InstanceCount,ParameterValue=${Instance_Count} \
    ParameterKey=InstanceType,ParameterValue=${Instance_Type} \
    ParameterKey=MaxRuntimeInSeconds,ParameterValue=${Max_Runtime_In_Seconds} \
    ParameterKey=VolInGB,ParameterValue=${Vol_In_GB} \
  --capabilities CAPABILITY_NAMED_IAM

rm -rf ./LambdaFunction.zip