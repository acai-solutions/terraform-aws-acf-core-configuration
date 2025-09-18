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
import json
import boto3
import sys
import base64
from botocore.config import Config
from botocore.exceptions import ClientError

CLUSTER_ID_TAG = 'module_parameter_cluster_id'

def assume_role(role_arn):
    sts = boto3.client('sts')
    resp = sts.assume_role(RoleArn=role_arn, RoleSessionName="TerraformSSMSession")
    creds = resp['Credentials']
    return dict(
        aws_access_key_id=creds['AccessKeyId'],
        aws_secret_access_key=creds['SecretAccessKey'],
        aws_session_token=creds['SessionToken'],
    )

def get_parameter_details(ssm, name):
    try:
        response = ssm.get_parameter(Name=name, WithDecryption=False)
        # Only try to get tags if parameter exists
        try:
            tags_response = ssm.list_tags_for_resource(ResourceType='Parameter', ResourceId=name)
            tags = {tag['Key']: tag['Value'] for tag in tags_response.get('TagList', [])}
        except ClientError as tag_error:
            # If we can't get tags, return empty dict
            print(f"Warning: Could not retrieve tags for parameter {name}: {tag_error}")
            tags = {}
        return response['Parameter'], tags
    except ClientError as e:
        if e.response['Error']['Code'] == 'ParameterNotFound':
            return None, {}
        raise

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--parameter_name_prefix', required=True)
    
    # Support both regular and base64-encoded JSON
    parser.add_argument('--map', required=False)
    parser.add_argument('--map-base64', required=False)
    parser.add_argument('--tags', required=False, default='{}')
    parser.add_argument('--tags-base64', required=False)
    
    parser.add_argument('--parameter_overwrite', required=False, default='false')
    parser.add_argument('--role-arn', required=True)
    parser.add_argument('--cluster-id', required=True)
    parser.add_argument('--kms-key-id', required=False)
    args = parser.parse_args()

    # Validate that either --map or --map-base64 is provided
    if not args.map and not args.map_base64:
        print("Error: Either --map or --map-base64 must be provided")
        sys.exit(1)
    
    if args.map and args.map_base64:
        print("Error: Cannot provide both --map and --map-base64")
        sys.exit(1)

    creds = assume_role(args.role_arn)
    boto_config = Config(
        retries = {
            'max_attempts': 5,
            'mode': 'standard'
        }
    )
    ssm = boto3.client('ssm', config=boto_config, **creds)

    # Parse map parameter (base64 or regular)
    try:
        if args.map_base64:
            param_map = json.loads(base64.b64decode(args.map_base64).decode('utf-8'))
        else:
            param_map = json.loads(args.map)
    except (json.JSONDecodeError, base64.binascii.Error) as e:
        print(f"Error parsing map parameter: {e}")
        sys.exit(1)

    # Parse tags parameter (base64 or regular)
    try:
        if args.tags_base64:
            tags_dict = json.loads(base64.b64decode(args.tags_base64).decode('utf-8'))
        else:
            tags_dict = json.loads(args.tags)
        tags = [{'Key': k, 'Value': v} for k, v in tags_dict.items()]
    except (json.JSONDecodeError, base64.binascii.Error) as e:
        print(f"Error parsing tags parameter: {e}")
        sys.exit(1)

    overwrite = args.parameter_overwrite.lower() == "true"
    cluster_id = args.cluster_id

    # --- Step 1: Write/Update parameters from the map ---
    for k, v in param_map.items():
        try:
            parameter, existing_tags = get_parameter_details(ssm, k)
            
            existing_cluster_id = existing_tags.get(CLUSTER_ID_TAG)
            if not overwrite and existing_cluster_id and existing_cluster_id != cluster_id:
                print(f"Error: Parameter {k} exists but is managed by a different cluster ID ({existing_cluster_id}). Current cluster ID is {cluster_id}.")
                sys.exit(1)

            kwargs = {
                'Name': k,
                'Value': v,
                'Type': 'SecureString' if args.kms_key_id else 'String',
            }
            if args.kms_key_id:
                kwargs['KeyId'] = args.kms_key_id

            try:
                if not parameter:
                    # Parameter does not exist: create with tags
                    kwargs['Tags'] = tags
                    kwargs['Overwrite'] = False
                    ssm.put_parameter(**kwargs)
                    print(f"Created {k} with tags.")
                else:
                    # Parameter exists: update value and tags
                    kwargs['Overwrite'] = overwrite
                    ssm.put_parameter(**kwargs)
                    print(f"Updated {k} value.")
                    if tags:
                        # Remove old tags first to ensure clean state
                        old_tag_keys = [tag_key for tag_key in existing_tags.keys()]
                        if old_tag_keys:
                            ssm.remove_tags_from_resource(ResourceType='Parameter', ResourceId=k, TagKeys=old_tag_keys)
                        
                        ssm.add_tags_to_resource(
                            ResourceType='Parameter',
                            ResourceId=k,
                            Tags=tags
                        )
                        print(f"Replaced tags for {k}.")
            except Exception as e:
                print(f"Error storing {k}: {e}")
                sys.exit(1)
        except Exception as e:
            print(f"Error processing parameter {k}: {e}")
            sys.exit(1)

    # --- Step 2: Find and delete obsolete parameters managed by this cluster ---
    print(f"\nSearching for obsolete parameters with cluster ID: {cluster_id} and prefix: {args.parameter_name_prefix}")
    try:
        paginator = ssm.get_paginator('describe_parameters')
        pages = paginator.paginate(
            ParameterFilters=[
                {
                    'Key': 'Name',
                    'Option': 'BeginsWith',
                    'Values': [args.parameter_name_prefix]
                }
            ]
        )
        ssm_params_with_tag = set()
        for page in pages:
            for param in page['Parameters']:
                param_name = param['Name']
                try:
                    # Always check tags for each parameter, regardless of 'Tags' in describe_parameters response
                    tags_response = ssm.list_tags_for_resource(ResourceType='Parameter', ResourceId=param_name)
                    tags = {tag['Key']: tag['Value'] for tag in tags_response.get('TagList', [])}
                    if CLUSTER_ID_TAG in tags and tags[CLUSTER_ID_TAG] == cluster_id:
                        # This parameter is managed by this cluster
                        ssm_params_with_tag.add(param_name)
                        print(f"Found parameter managed by this cluster: {param_name}")
                except ClientError as e:
                    if e.response['Error']['Code'] == 'ParameterNotFound':
                        # Parameter was deleted between describe and list_tags calls
                        print(f"Parameter {param_name} was deleted during processing, skipping...")
                        continue
                    else:
                        print(f"Error checking tags for {param_name}: {e}")
                        continue
                except Exception as e:
                    print(f"Unexpected error checking tags for {param_name}: {e}")
                    continue

        obsolete_params = ssm_params_with_tag - set(param_map.keys())

        if not obsolete_params:
            print("No obsolete parameters found.")
        else:
            print(f"Found {len(obsolete_params)} obsolete parameters to delete: {obsolete_params}")
            # AWS API only allows deleting 10 at a time
            obsolete_list = list(obsolete_params)
            for i in range(0, len(obsolete_list), 10):
                batch = obsolete_list[i:i+10]
                try:
                    ssm.delete_parameters(Names=batch)
                    print(f"Successfully deleted batch: {batch}")
                except Exception as e:
                    print(f"Error deleting batch {batch}: {e}")
                    # Continue with next batch instead of failing completely
                    continue

    except Exception as e:
        print(f"Error during cleanup of obsolete parameters: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()