import json
import boto3
import os
import random
import string
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

secretsmanager = boto3.client('secretsmanager')
rds = boto3.client('rds')

def lambda_handler(event, context):
    arn = event['SecretId']
    token = event['ClientRequestToken']
    step = event['Step']
    metadata = secretsmanager.describe_secret(SecretId=arn)
    if 'RotationEnabled' in metadata and not metadata['RotationEnabled']:
        raise ValueError(f"Secret {arn} is not enabled for rotation")
    if step == "createSecret":
        create_secret(arn, token)
    elif step == "setSecret":
        set_secret(arn, token)
    elif step == "testSecret":
        test_secret(arn, token)
    elif step == "finishSecret":
        finish_secret(arn, token)
    else:
        raise ValueError(f"Invalid step: {step}")

def create_secret(arn, token):
    new_password = ''.join(random.choice(string.ascii_letters + string.digits) for _ in range(32))
    current = secretsmanager.get_secret_value(SecretId=arn, VersionStage='AWSCURRENT')
    secret_dict = json.loads(current['SecretString'])
    secret_dict['password'] = new_password
    secretsmanager.put_secret_value(
        SecretId=arn,
        ClientRequestToken=token,
        SecretString=json.dumps(secret_dict),
        VersionStages=['AWSPENDING']
    )
    logger.info("New secret version created as AWSPENDING")

def set_secret(arn, token):
    pending = secretsmanager.get_secret_value(SecretId=arn, VersionId=token, VersionStage='AWSPENDING')
    secret = json.loads(pending['SecretString'])
    db_id = secret['host'].split('.')[0]
    rds.modify_db_instance(DBInstanceIdentifier=db_id, MasterUserPassword=secret['password'])
    logger.info(f"RDS master password updated for {db_id}")

def test_secret(arn, token):
    secretsmanager.get_secret_value(SecretId=arn, VersionId=token, VersionStage='AWSPENDING')
    logger.info("Test secret passed")

def finish_secret(arn, token):
    current = secretsmanager.get_secret_value(SecretId=arn, VersionStage='AWSCURRENT')
    current_version = current['VersionId']
    secretsmanager.update_secret_version_stage(
        SecretId=arn,
        VersionStage='AWSCURRENT',
        MoveToVersionId=token,
        RemoveFromVersionId=current_version
    )
    logger.info("Rotation complete: AWSCURRENT updated")
