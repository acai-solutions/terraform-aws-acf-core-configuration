"""
ACAI Cloud Foundation (ACF)
Copyright (C) 2025 ACAI GmbH
Licensed under AGPL v3
#
This file is part of ACAI ACF.
Visit https://www.acai.gmbh or https://docs.acai.gmbh for more information.

For full license text, see LICENSE file in repository root.
For commercial licensing, contact: contact@acai.gmbh


"""

import argparse
import boto3
import sys
import os
from botocore.config import Config
from botocore.exceptions import ClientError

CLUSTER_ID_TAG = "module_parameter_cluster_id"


def assume_role(role_arn, region=None):
    # Use region if provided, otherwise use environment or default
    sts = boto3.client("sts", region_name=region)
    resp = sts.assume_role(RoleArn=role_arn, RoleSessionName="TerraformSSMSession")
    creds = resp["Credentials"]
    return dict(
        aws_access_key_id=creds["AccessKeyId"],
        aws_secret_access_key=creds["SecretAccessKey"],
        aws_session_token=creds["SessionToken"],
    )


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--parameter_name_prefix", required=True)
    parser.add_argument("--role-arn", required=True)
    parser.add_argument("--cluster-id", required=True)
    args = parser.parse_args()

    # Get AWS region from environment variable (set by Terraform)
    region = os.environ.get("AWS_DEFAULT_REGION")
    if not region:
        print("Error: AWS_DEFAULT_REGION environment variable not set")
        sys.exit(1)

    try:
        creds = assume_role(args.role_arn, region)
        boto_config = Config(
            region_name=region, retries={"max_attempts": 5, "mode": "standard"}
        )
        ssm = boto3.client("ssm", region_name=region, config=boto_config, **creds)

        cluster_id = args.cluster_id

        print(
            f"Searching for SSM parameters with tag {CLUSTER_ID_TAG}={cluster_id} and prefix {args.parameter_name_prefix}..."
        )

        # Use describe_parameters with filters instead of tag-based pagination
        # because tag filters in describe_parameters can be unreliable
        paginator = ssm.get_paginator("describe_parameters")
        pages = paginator.paginate(
            ParameterFilters=[
                {
                    "Key": "Name",
                    "Option": "BeginsWith",
                    "Values": [args.parameter_name_prefix],
                }
            ]
        )

        to_delete = []
        for page in pages:
            for param in page["Parameters"]:
                param_name = param["Name"]
                try:
                    # Check if this parameter has the correct cluster ID tag
                    tags_response = ssm.list_tags_for_resource(
                        ResourceType="Parameter", ResourceId=param_name
                    )
                    tags = {
                        tag["Key"]: tag["Value"]
                        for tag in tags_response.get("TagList", [])
                    }

                    if CLUSTER_ID_TAG in tags and tags[CLUSTER_ID_TAG] == cluster_id:
                        to_delete.append(param_name)
                        print(f"Found parameter to delete: {param_name}")
                except ClientError as e:
                    if e.response["Error"]["Code"] == "ParameterNotFound":
                        # Parameter was deleted between describe and list_tags calls
                        continue
                    else:
                        print(f"Error checking tags for {param_name}: {e}")
                        continue

        if not to_delete:
            print("No parameters found to delete.")
            return

        print(f"Deleting {len(to_delete)} parameters...")
        # AWS API only allows deleting 10 parameters at a time
        for i in range(0, len(to_delete), 10):
            batch = to_delete[i : i + 10]
            try:
                ssm.delete_parameters(Names=batch)
                print(f"Successfully deleted parameters: {batch}")
            except Exception as e:
                print(f"Error deleting batch {batch}: {e}")
                # Continue with next batch instead of failing completely
                continue

        print(f"Cleanup completed. Processed {len(to_delete)} parameters.")

    except Exception as e:
        print(f"Error during cleanup process: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
