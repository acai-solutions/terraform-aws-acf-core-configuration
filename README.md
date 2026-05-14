# terraform-aws-acf-core-configuration

<!-- LOGO -->
<a href="https://acai.gmbh">    
  <img src="https://github.com/acai-solutions/acai.public/raw/main/logo/logo_github_readme.png" alt="acai logo" title="ACAI" align="right" height="75" />
</a>

<!-- SHIELDS -->
[![Maintained by acai.gmbh][acai-shield]][acai-url]
[![documentation][acai-docs-shield]][acai-docs-url]  
![module-version-shield]
![terraform-version-shield]  
![trivy-shield]
![checkov-shield]

<!-- DESCRIPTION -->
This [Terraform][terraform-url] module allows you to share Configuration Items (Terraform HCL map) over multiple Terraform pipelines.

For persistence [AWS Systems Manager Parameter Store](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-parameter-store.html) is used.
Later persistence via Amazon DynamoDB or Amazon S3 will be added.

<!-- ARCHITECTURE -->
## Architecture

![architecture][architecture-png]

> **Note:** This module is pure HCL. No Python or other external runtime is required on the Terraform / OpenTofu agent.
>
> **Compatibility:** Tested on Terraform `1.5.7` (the last MPL-licensed release) and OpenTofu `>= 1.6`. The `required_version` floor is `>= 1.5.0` with no upper cap, so callers can stay on the pre-BSL Terraform line *or* move to OpenTofu without forking the module.

<!-- FEATURES -->
## Features

* Select one AWS Account for hosting the Core Configuration -> Foundation Configuration Account.
* Provision writer- and reader-principals (IAM Roles) in the Foundation Configuration Account.
* Terraform pipelines can write to the Core Configuration via assuming the writer-prinicpal.
* Terraform pipelines can read from the Core Configuration via assuming the reader-prinicpal.
* Arbitrarily nested HCL maps are flattened into hierarchical SSM parameter names (and unflattened on read).
* Optional KMS encryption (`SecureString`) for parameters.
* Optional persistence of writer-/reader-role ARNs as SSM parameters for downstream discovery.

<!-- SUBMODULES -->
## Submodules

The repository is split into three submodules. They are intended to be consumed independently from different pipelines.

| Submodule | Path | Purpose | Provider alias |
|---|---|---|---|
| IAM Roles | [`ssm-ps/iam-roles`](./ssm-ps/iam-roles) | Provisions the `configuration_writer` and `configuration_reader` IAM roles in the Foundation Configuration Account. Run **once** by the foundation pipeline. | default `aws` |
| Writer | [`ssm-ps/writer`](./ssm-ps/writer) | Flattens a nested HCL map and writes each leaf as an `aws_ssm_parameter`. Assumes the writer role via `aws.configuration_writer`. | `aws.configuration_writer` |
| Reader | [`ssm-ps/reader`](./ssm-ps/reader) | Reads all parameters under `parameter_name_prefix` and unflattens them back into a nested HCL map. Assumes the reader role via `aws.configuration_reader`. | `aws.configuration_reader` |

Internal helpers in [`shared/`](./shared) implement the flatten / unflatten transformation in pure HCL via an N-pass iterative reduction. There is no `data "external"` and no Python dependency.

<!-- USAGE -->
## Usage

### 1. Provision the IAM roles (one-time, in the Foundation Configuration Account)

```hcl
module "core_configuration_iam_roles" {
  source = "github.com/acai-consulting/terraform-aws-acf-core-configuration//ssm-ps/iam-roles"

  trusted_account_ids   = ["*"]            # any principal in the org; restrict if needed
  parameter_name_prefix = "/foundation"
  iam_roles = {
    store_role_arns = true                  # publish role ARNs as SSM params for discovery
  }
}
```

### 2. Write configuration from a pipeline

```hcl
provider "aws" {
  alias = "configuration_writer"
  assume_role { role_arn = "arn:aws:iam::<core-acct>:role/core-configuration-writer-role" }
}

module "core_configuration_writer" {
  source = "github.com/acai-consulting/terraform-aws-acf-core-configuration//ssm-ps/writer"
  providers = { aws.configuration_writer = aws.configuration_writer }

  parameter_name_prefix = "/foundation"
  parameter_overwrite   = false             # true => actively reconcile values & tags
  list_strategy         = "json"            # "json" (default) preserves lists across the round-trip;
                                            # "indexed" stores list elements as separate SSM parameters
  configuration_add_on  = {
    network = {
      vpc_id     = "vpc-0123456789abcdef0"
      cidr_block = "10.0.0.0/16"
    }
  }
}
```

### 3. Read configuration from any pipeline in the org

```hcl
provider "aws" {
  alias = "configuration_reader"
  assume_role { role_arn = "arn:aws:iam::<core-acct>:role/core-configuration-reader-role" }
}

module "core_configuration_reader" {
  source = "github.com/acai-consulting/terraform-aws-acf-core-configuration//ssm-ps/reader"
  providers = { aws.configuration_reader = aws.configuration_reader }

  parameter_name_prefix = "/foundation"
}

# nested map equivalent to what was written
locals {
  vpc_id = module.core_configuration_reader.unflattened_configuration.network.vpc_id
}
```

<!-- EXAMPLES -->
## Examples

End-to-end scenarios live under [`examples/`](./examples) -- see the [examples README](./examples/README.md) for the full breakdown. Each example is self-contained (own `backend.tf`, `provider.tf`, `variables.tf`, `main.tf`, `core_configuration_roles.tf`, `outputs.tf`) and is exercised by a matching test in [`tests/terratest`](./tests/terratest).

| Example | Scenario |
|---|---|
| [`ssm-ps-1`](./examples/ssm-ps-1) | Mixed scalars + simple lists + nested object (smoke test). |
| [`ssm-ps-2`](./examples/ssm-ps-2) | Combined: `configuration_add_on` AND `configuration_add_on_list` under the same prefix. |
| [`ssm-ps-3`](./examples/ssm-ps-3) | Realistic configuration tree with database connections + service lists (`list_strategy = "json"`). |
| [`ssm-ps-4`](./examples/ssm-ps-4) | 15-level deep nesting -- exercises every pass of the flatten/unflatten ladders. |

<!-- TESTS -->
## Tests & CI

Tests live under [`tests/terratest`](./tests/terratest) and follow the [ACAI Terratest convention](https://github.com/acai-solutions/github-workflows/blob/main/docs/terratest.md):

* `helpers_test.go` provides `loadBackendConfig`, `getHclBinary`, `outputClean`, and the shared `runRoundTripExample` driver. The HCL binary (`terraform` vs `tofu`) is selected at runtime via the `TERRATEST_TERRAFORM_BINARY` env var.
* One `ssm-ps-N_test.go` per example, each delegating to `runRoundTripExample(t, "ssm-ps-N")`. The driver runs a two-stage init/apply (IAM roles first, then full stack) and asserts `test_success == "true"`.
* Backend configuration is injected at runtime from `tests/terratest/backend.json` (written by the workflow from `<TEST_BED>_TESTBED_BACKEND_JSON`); `*.tfvar` inputs come from `<TEST_BED>_TESTBED_TFVARS`.

The GitHub workflow [`.github/workflows/acai-terraform-module.yml`](./.github/workflows/acai-terraform-module.yml) calls the reusable `acai-solutions/github-workflows/.github/workflows/checks-py-hcl-module.yml` and runs the suite against both the **AWS** and **AWS_ESC** test beds, on both Terraform and OpenTofu, via the matrix configs `aws/matrix_tf1x5x7_aws6x0x0.json` and `aws/matrix_ofu1x6x0_aws6x0x0.json`.

Each example's `test_success` output asserts a full round-trip: the reader's unflattened map equals the original HCL configuration.

<!-- LIMITATIONS -->
## Known Limitations

### `for_each` keys must be known at plan time

The writer creates one `aws_ssm_parameter` per leaf via

```hcl
for_each = local.flattened_configuration_add_on
```

The flattener (`shared/complex_map_to_simple_map`) is pure HCL, so Terraform can compute the **key set** at plan time even when individual leaf **values** are still unknown. Plans therefore succeed for the common case where only resource attributes (ARNs, IDs) are unknown but the structure of `configuration_add_on` is fixed.

If the **structure itself** (which keys exist) depends on apply-time values, Terraform will still abort with:

```
The "for_each" map includes keys derived from resource attributes that
cannot be determined until apply, ...
```

Remedies for that case, in order of preference:

1. **Keep the key set static in the caller.** Pass a map whose attribute names are HCL literals; only values may reference resource attributes.
2. **Split the apply.** Provision the resources whose attributes shape the key set in a first run (or with `-target`), then run the writer in a second invocation.
3. **Two writer modules.** Write the static portion in one `module "writer"` call and the apply-time-shaped portion in another, sized so each call's keys are known.

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

No providers.

## Modules

No modules.

## Resources

No resources.

## Inputs

No inputs.

## Outputs

No outputs.
<!-- END_TF_DOCS -->


<!-- AUTHORS -->
## Authors

This module is maintained by [ACAI GmbH][acai-url].

<!-- LICENSE -->
## License

See [LICENSE][license-url] for full details.

<!-- COPYRIGHT -->
<br />
<p align="center">Copyright &copy; 2024, 2025 ACAI GmbH</p>

<!-- MARKDOWN LINKS & IMAGES -->
[acai-shield]: https://img.shields.io/badge/maintained_by-acai.gmbh-CB224B?style=flat
[acai-docs-shield]: https://img.shields.io/badge/documentation-docs.acai.gmbh-CB224B?style=flat
[acai-url]: https://acai.gmbh
[acai-docs-url]: https://docs.acai.gmbh
[module-version-shield]: https://img.shields.io/badge/module_version-1.4.2-CB224B?style=flat
[terraform-version-shield]: https://img.shields.io/badge/tf-%3E%3D1.5.0-blue.svg?style=flat&color=blueviolet
[trivy-shield]: https://img.shields.io/badge/trivy-passed-green
[checkov-shield]: https://img.shields.io/badge/checkov-passed-green
[release-shield]: https://img.shields.io/github/v/release/acai-solutions/terraform-aws-acf-core-configuration?style=flat&color=success
[release-url]: ./releases
[architecture-png]: ./docs/terraform-aws-acf-core-configuration.png
[license-url]: ./LICENSE.md
[terraform-url]: https://www.terraform.io

