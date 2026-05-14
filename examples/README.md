# Examples

End-to-end round-trip examples for `terraform-aws-acf-core-configuration`. Each example writes a
`configuration_add_on` to SSM Parameter Store via the **writer** submodule and reads it back via the
**reader** submodule, asserting equality through `output "test_success"`.

All examples share the same scaffolding ([backend.tf](ssm-ps-1/backend.tf), [provider.tf](ssm-ps-1/provider.tf),
[variables.tf](ssm-ps-1/variables.tf)) and the [IAM-roles bootstrap](ssm-ps-1/core_configuration_roles.tf) —
only the `configuration_add_on` input shape differs. The Terratest suite under [tests/terratest/](../tests/terratest/)
drives every example through a two-stage apply (roles first, then writer + reader) on both `terraform` (1.5.7, last MPL) and `tofu` (>= 1.6).

## Scenarios at a glance

Ordered from simplest to most demanding.

| # | Focus | Input shape | Notes |
|---|-------|-------------|-------|
| [ssm-ps-1](ssm-ps-1/main.tf) | Smoke test | Scalars + simple list + small nested object | Smallest example; fast sanity check. |
| [ssm-ps-2](ssm-ps-2/main.tf) | Combined inputs | Both `configuration_add_on` *and* `configuration_add_on_list` | Verifies single + list inputs merge correctly under one prefix. |
| [ssm-ps-3](ssm-ps-3/main.tf) | Realistic tree | Nested map with lists of objects + string lists | Mirrors a production-shaped configuration; both list flavours round-trip via the default `list_strategy = "json"`. |
| [ssm-ps-4](ssm-ps-4/main.tf) | Max-depth stress | 15 levels of nesting with siblings at every level | Exercises every pass of the 15-pass flatten/unflatten ladders. Includes a `max_depth_reached` output. |

## Running locally

Each example expects backend + tfvars wiring identical to the Terratest harness. The simplest path is to
run the matching test:

```powershell
cd tests\terratest
$env:TERRATEST_TERRAFORM_BINARY = "terraform"   # or "tofu"
go test -run TestSsmPs4 -v -timeout 30m
```

For a static check without AWS credentials:

```powershell
cd examples\ssm-ps-4
terraform init -backend=false
terraform validate
```
