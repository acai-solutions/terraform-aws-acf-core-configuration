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
import base64
import json
import sys

import boto3
from botocore.config import Config
from botocore.exceptions import ClientError

CLUSTER_ID_TAG = "module_parameter_cluster_id"


def assume_role(role_arn):
    sts = boto3.client("sts")
    resp = sts.assume_role(RoleArn=role_arn, RoleSessionName="TerraformSSMSession")
    creds = resp["Credentials"]
    return dict(
        aws_access_key_id=creds["AccessKeyId"],
        aws_secret_access_key=creds["SecretAccessKey"],
        aws_session_token=creds["SessionToken"],
    )


def parse_base64_or_json(raw: str, base64_encoded: str | None) -> dict:
    try:
        if base64_encoded:
            return json.loads(base64.b64decode(base64_encoded).decode("utf-8"))
        return json.loads(raw)
    except (json.JSONDecodeError, base64.binascii.Error) as e:
        print(f"Error parsing input: {e}")
        sys.exit(1)


def get_parameter_details(ssm, name):
    try:
        response = ssm.get_parameter(Name=name, WithDecryption=False)
        try:
            tags_response = ssm.list_tags_for_resource(
                ResourceType="Parameter", ResourceId=name
            )
            tags = {
                tag["Key"]: tag["Value"] for tag in tags_response.get("TagList", [])
            }
        except ClientError as e:
            print(f"Warning: Could not retrieve tags for parameter {name}: {e}")
            tags = {}
        return response["Parameter"], tags
    except ClientError as e:
        if e.response["Error"]["Code"] == "ParameterNotFound":
            return None, {}
        raise


def write_or_update_parameters(ssm, param_map, tags, overwrite, cluster_id, kms_key_id):
    for name, value in param_map.items():
        try:
            parameter, existing_tags = get_parameter_details(ssm, name)
            existing_cluster_id = existing_tags.get(CLUSTER_ID_TAG)

            if (
                not overwrite
                and existing_cluster_id
                and existing_cluster_id != cluster_id
            ):
                print(
                    f"Error: Parameter {name} exists and is managed by cluster {existing_cluster_id}, not {cluster_id}."
                )
                sys.exit(1)

            kwargs = {
                "Name": name,
                "Value": value,
                "Type": "SecureString" if kms_key_id else "String",
                "Overwrite": overwrite,
            }
            if kms_key_id:
                kwargs["KeyId"] = kms_key_id

            if not parameter:
                kwargs["Tags"] = tags
                ssm.put_parameter(**kwargs)
                print(f"Created {name} with tags.")
            else:
                ssm.put_parameter(**kwargs)
                print(f"Updated {name} value.")
                if tags:
                    # Remove old tags first
                    old_keys = list(existing_tags.keys())
                    if old_keys:
                        ssm.remove_tags_from_resource(
                            ResourceType="Parameter", ResourceId=name, TagKeys=old_keys
                        )
                    ssm.add_tags_to_resource(
                        ResourceType="Parameter", ResourceId=name, Tags=tags
                    )
                    print(f"Replaced tags for {name}.")
        except Exception as e:
            print(f"Error processing parameter {name}: {e}")
            sys.exit(1)


def _get_parameters_by_prefix(ssm, prefix):
    paginator = ssm.get_paginator("describe_parameters")
    return paginator.paginate(
        ParameterFilters=[{"Key": "Name", "Option": "BeginsWith", "Values": [prefix]}]
    )


def _get_cluster_managed_parameters(ssm, pages, cluster_id):
    managed = set()
    for page in pages:
        for param in page["Parameters"]:
            name = param["Name"]
            try:
                tags_response = ssm.list_tags_for_resource(
                    ResourceType="Parameter", ResourceId=name
                )
                tags = {
                    tag["Key"]: tag["Value"] for tag in tags_response.get("TagList", [])
                }
                if tags.get(CLUSTER_ID_TAG) == cluster_id:
                    managed.add(name)
                    print(f"Found parameter managed by this cluster: {name}")
            except ClientError as e:
                if e.response["Error"]["Code"] == "ParameterNotFound":
                    print(
                        f"Parameter {name} was deleted during processing, skipping..."
                    )
                else:
                    print(f"Error checking tags for {name}: {e}")
            except Exception as e:
                print(f"Unexpected error checking tags for {name}: {e}")
    return managed


def _delete_parameters_in_batches(ssm, obsolete):
    for i in range(0, len(obsolete), 10):
        batch = list(obsolete)[i : i + 10]
        try:
            ssm.delete_parameters(Names=batch)
            print(f"Successfully deleted batch: {batch}")
        except Exception as e:
            print(f"Error deleting batch {batch}: {e}")


def cleanup_obsolete_parameters(ssm, cluster_id, prefix, current_keys):
    print(
        f"\nSearching for obsolete parameters with cluster ID: {cluster_id} and prefix: {prefix}"
    )
    try:
        pages = _get_parameters_by_prefix(ssm, prefix)
        managed_by_cluster = _get_cluster_managed_parameters(ssm, pages, cluster_id)
        obsolete = managed_by_cluster - set(current_keys)

        if not obsolete:
            print("No obsolete parameters found.")
            return

        print(f"Found {len(obsolete)} obsolete parameters to delete: {obsolete}")
        _delete_parameters_in_batches(ssm, obsolete)

    except Exception as e:
        print(f"Error during cleanup of obsolete parameters: {e}")
        sys.exit(1)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--parameter_name_prefix", required=True)
    parser.add_argument("--map", required=False)
    parser.add_argument("--map-base64", required=False)
    parser.add_argument("--tags", required=False, default="{}")
    parser.add_argument("--tags-base64", required=False)
    parser.add_argument("--parameter_overwrite", required=False, default="false")
    parser.add_argument("--role-arn", required=True)
    parser.add_argument("--cluster-id", required=True)
    parser.add_argument("--kms-key-id", required=False)
    args = parser.parse_args()

    if bool(args.map) == bool(args.map_base64):
        print("Error: Provide either --map or --map-base64 (not both or neither).")
        sys.exit(1)

    param_map = parse_base64_or_json(args.map, args.map_base64)
    raw_tags = parse_base64_or_json(args.tags, args.tags_base64)
    tags = [{"Key": k, "Value": v} for k, v in raw_tags.items()]
    overwrite = args.parameter_overwrite.lower() == "true"

    creds = assume_role(args.role_arn)
    boto_config = Config(retries={"max_attempts": 5, "mode": "standard"})
    ssm = boto3.client("ssm", config=boto_config, **creds)

    write_or_update_parameters(
        ssm, param_map, tags, overwrite, args.cluster_id, args.kms_key_id
    )
    cleanup_obsolete_parameters(
        ssm, args.cluster_id, args.parameter_name_prefix, param_map.keys()
    )


if __name__ == "__main__":
    main()
