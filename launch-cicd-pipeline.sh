#!/bin/bash
Email=<Enter your Email Address>
GitHub_User=<Enter Github Organization Name or Github Username>
GitHub_Repo=<Enter Name (Only) of Github Repository>
GitHub_Branch=<Enter branch name for source for pipeline stage>
GitHub_Token=<Enter Personal Access Token from Github>
Python_Build_Version="aws/codebuild/python:3.6.5-1.3.2"
Template_Name=${GitHub_Repo}-cicd-pipeline
AWS_DEFAULT_REGION=us-east-1

aws cloudformation create-stack \
  --region ${AWS_DEFAULT_REGION} \
  --stack-name $Template_Name \
  --template-body file://template/sagemaker-pipeline-v2.yaml \
  --parameters \
    ParameterKey=Email,ParameterValue=$Email \
    ParameterKey=GitHubUser,ParameterValue=$GitHub_User \
    ParameterKey=GitHubRepo,ParameterValue=$GitHub_Repo \
  	ParameterKey=GitHubBranch,ParameterValue=$GitHub_Branch \
  	ParameterKey=GitHubToken,ParameterValue=$GitHub_Token \
    ParameterKey=PythonBuildVersion,ParameterValue=$Python_Build_Version \
  --capabilities CAPABILITY_NAMED_IAM
