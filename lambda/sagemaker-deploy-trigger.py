import os
import json
import datetime
import boto3
import botocore
import tempfile
import logging
from boto3.session import Session

logger = logging.getLogger()
logger.setLevel(logging.INFO)

boto3.set_stream_logger(level=1)

codepipeline = boto3.client('codepipeline')
sagemaker = boto3.client('sagemaker')
dynamodb = boto3.client('dynamodb')


def main(event, context):
    job_id = event['CodePipeline.job']['id']
    job_data = event['CodePipeline.job']['data']
    try:
        input_artifact = job_data['inputArtifacts'][0]
        credentials = job_data['artifactCredentials']
        from_bucket = input_artifact['location']['s3Location']['bucketName']
        from_key = input_artifact['location']['s3Location']['objectKey']
        key_id = credentials['accessKeyId']
        key_secret = credentials['secretAccessKey']
        session_token = credentials['sessionToken']

        if "continuationToken" in job_data:
            print("Add Waiting Procedure for Sagemaker deploy")
        else:
            session = Session(aws_access_key_id=key_id, aws_secret_access_key=key_secret,
                              aws_session_token=session_token)
            s3 = session.client('s3', config=botocore.client.Config(signature_version='s3v4'))

            with tempfile.NamedTemporaryFile() as tmp:
                s3.download_file(from_bucket, from_key, tmp.name)
                with open(tmp.name) as f:
                    contents = f.readline()

                training_job_name = json.loads(contents)['training_job_name']

                res = sagemaker.list_training_jobs()

                for job in res['TrainingJobSummaries']:
                    if job['TrainingJobName'] == str(training_job_name):
                        job_status = str(job['TrainingJobStatus'])
                        print('job_status:' + job_status)
                        job_creation_time = str(job['CreationTime'])
                        print('creation_time:' + job_creation_time)
                        job_end_time = str(job['TrainingEndTime'])
                        print('job_end_time' + job_end_time)

                dynamodb.update_item(
                    TableName=str(os.environ['META_DATA_STORE']),
                    Key={'training_job_name': {'S': training_job_name}},
                    UpdateExpression="SET #job_creation_time= :val1, #job_end_time= :val2, #job_status= :val3",
                    ExpressionAttributeNames={'#job_creation_time': 'job_creation_time',
                                              '#job_end_time': 'job_end_time', '#job_status': 'job_status'},
                    ExpressionAttributeValues={':val1': {'S': job_creation_time}, ':val2': {'S': job_end_time},
                                               ':val3': {'S': job_status}
                                               }
                )

                inference_img_name = str(os.environ['FULL_NAME'])
                endpoint_name = str(os.environ["IMG"]) + '-' + str(datetime.datetime.today()).replace(' ', '-').replace(':', '-').rsplit('.')[0]
                model_name = 'model-' + str(endpoint_name)
                endpoint_config_name = 'endpoint-config-'+ str(endpoint_name)
                model_obj_key = "{}/output/model.tar.gz".format(training_job_name)
                model_data_url = 's3://{}/{}'.format(str(os.environ['DEST_BKT']), model_obj_key)


                codepipeline.put_job_success_result(jobId=job_id)
    except Exception as e:
        print(e)
        codepipeline.put_job_failure_result(jobId=job_id, failureDetails={'message': str(e), 'type': 'JobFailed'})