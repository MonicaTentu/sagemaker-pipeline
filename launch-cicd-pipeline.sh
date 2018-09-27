#!/bin/bash
Email=muwaheed@amazon.com
GitHub_User=MustafaWaheed91
GitHub_Repo=tf-gamesbiz
GitHub_Branch=master
GitHub_Token=3aae36e1e16704b826d0fb6ff9bd9437b2371f51
Python_Build_Version="aws/codebuild/python:3.6.5-1.3.2"
Template_Name=${GitHub_Repo}-sgmkr01-pipeline
AWS_DEFAULT_REGION=us-east-1

aws cloudformation create-stack \
  --region ${AWS_DEFAULT_REGION} \
  --stack-name $Template_Name \
  --template-body file://template/sagemaker-pipeline.yaml \
  --parameters \
    ParameterKey=Email,ParameterValue=$Email \
    ParameterKey=GitHubUser,ParameterValue=$GitHub_User \
    ParameterKey=GitHubRepo,ParameterValue=$GitHub_Repo \
  	ParameterKey=GitHubBranch,ParameterValue=$GitHub_Branch \
  	ParameterKey=GitHubToken,ParameterValue=$GitHub_Token \
    ParameterKey=PythonBuildVersion,ParameterValue=$Python_Build_Version \
  --capabilities CAPABILITY_NAMED_IAM
