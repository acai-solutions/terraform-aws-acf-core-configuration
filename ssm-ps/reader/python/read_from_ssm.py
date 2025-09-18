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

import json
import sys

import boto3
from botocore.config import Config
from botocore.exceptions import ClientError


def assume_role(role_arn, region):
    sts = boto3.client("sts", region_name=region)
    resp = sts.assume_role(RoleArn=role_arn, RoleSessionName="TerraformSSMReadSession")
    creds = resp["Credentials"]
    return dict(
        aws_access_key_id=creds["AccessKeyId"],
        aws_secret_access_key=creds["SecretAccessKey"],
        aws_session_token=creds["SessionToken"],
    )


def main():
    # Read query from stdin (external data source format)
    try:
        query = json.loads(sys.stdin.read())
    except json.JSONDecodeError:
        print("Error: Invalid JSON received on stdin.", file=sys.stderr)
        sys.exit(1)

    parameter_name_prefix = query.get("parameter_name_prefix")
    role_arn = query.get("role_arn")
    aws_region = query.get("aws_region")

    if not all([parameter_name_prefix, role_arn, aws_region]):
        print(
            "Error: Missing required key in JSON input (parameter_name_prefix, role_arn, aws_region).",
            file=sys.stderr,
        )
        sys.exit(1)

    try:
        creds = assume_role(role_arn, aws_region)
        boto_config = Config(
            region_name=aws_region, retries={"max_attempts": 5, "mode": "standard"}
        )
        ssm = boto3.client("ssm", config=boto_config, **creds)

        # Get all parameters under the specified path
        paginator = ssm.get_paginator("get_parameters_by_path")
        pages = paginator.paginate(
            Path=parameter_name_prefix, Recursive=True, WithDecryption=True
        )

        flat_configuration = {}
        for page in pages:
            for param in page["Parameters"]:
                flat_configuration[param["Name"]] = param["Value"]

        # Output result in external data source format (JSON to stdout)
        print(json.dumps(flat_configuration))

    except Exception as e:
        print(f"Error reading from SSM: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
