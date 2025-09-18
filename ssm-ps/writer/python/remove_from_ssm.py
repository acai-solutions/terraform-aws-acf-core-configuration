#!/usr/bin/env python3
"""
ACAI Cloud Foundation (ACF)
Copyright (C) 2025 ACAI GmbH
Licensed under AGPL v3

This file is part of ACAI ACF.
Visit https://www.acai.gmbh or https://docs.acai.gmbh for more information.

For full license text, see LICENSE file in repository root.
For commercial licensing, contact: contact@acai.gmbh
"""

import argparse
import os
import sys

import boto3
from botocore.config import Config
from botocore.exceptions import ClientError

CLUSTER_ID_TAG = "module_parameter_cluster_id"


def assume_role(role_arn, region=None):
    sts = boto3.client("sts", region_name=region)
    resp = sts.assume_role(RoleArn=role_arn, RoleSessionName="TerraformSSMSession")
    creds = resp["Credentials"]
    return dict(
        aws_access_key_id=creds["AccessKeyId"],
        aws_secret_access_key=creds["SecretAccessKey"],
        aws_session_token=creds["SessionToken"],
    )


def get_ssm_client(role_arn: str, region: str):
    creds = assume_role(role_arn, region)
    boto_config = Config(
        region_name=region, retries={"max_attempts": 5, "mode": "standard"}
    )
    return boto3.client("ssm", region_name=region, config=boto_config, **creds)


def find_parameters_to_delete(ssm, prefix: str, cluster_id: str) -> list[str]:
    print(
        f"Searching for SSM parameters with tag {CLUSTER_ID_TAG}={cluster_id} and prefix {prefix}..."
    )

    paginator = ssm.get_paginator("describe_parameters")
    pages = paginator.paginate(
        ParameterFilters=[
            {
                "Key": "Name",
                "Option": "BeginsWith",
                "Values": [prefix],
            }
        ]
    )

    to_delete = []
    for page in pages:
        for param in page["Parameters"]:
            param_name = param["Name"]
            if has_matching_cluster_tag(ssm, param_name, cluster_id):
                to_delete.append(param_name)
                print(f"Found parameter to delete: {param_name}")
    return to_delete


def has_matching_cluster_tag(ssm, param_name: str, cluster_id: str) -> bool:
    try:
        tags_response = ssm.list_tags_for_resource(
            ResourceType="Parameter", ResourceId=param_name
        )
        tags = {tag["Key"]: tag["Value"] for tag in tags_response.get("TagList", [])}
        return tags.get(CLUSTER_ID_TAG) == cluster_id
    except ClientError as e:
        if e.response["Error"]["Code"] == "ParameterNotFound":
            return False
        print(f"Error checking tags for {param_name}: {e}")
        return False


def delete_parameters(ssm, parameters: list[str]) -> None:
    print(f"Deleting {len(parameters)} parameters...")
    for i in range(0, len(parameters), 10):
        batch = parameters[i : i + 10]
        try:
            ssm.delete_parameters(Names=batch)
            print(f"Successfully deleted parameters: {batch}")
        except Exception as e:
            print(f"Error deleting batch {batch}: {e}")
            continue
    print(f"Cleanup completed. Processed {len(parameters)} parameters.")


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--parameter_name_prefix", required=True)
    parser.add_argument("--role-arn", required=True)
    parser.add_argument("--cluster-id", required=True)
    return parser.parse_args()


def main():
    args = parse_args()
    region = os.environ.get("AWS_DEFAULT_REGION")

    if not region:
        print("Error: AWS_DEFAULT_REGION environment variable not set")
        sys.exit(1)

    try:
        ssm = get_ssm_client(args.role_arn, region)
        parameters = find_parameters_to_delete(
            ssm, args.parameter_name_prefix, args.cluster_id
        )

        if not parameters:
            print("No parameters found to delete.")
            return

        delete_parameters(ssm, parameters)

    except Exception as e:
        print(f"Error during cleanup process: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
