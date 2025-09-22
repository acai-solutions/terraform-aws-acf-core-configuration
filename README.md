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

> **Note:** Python must be installed at the agent.

<!-- FEATURES -->
## Features

* Select one AWS Account for hosting the Core Configuration -> Foundation Configuration Account.
* Provision writer- and reader-principals (IAM Roles) in the Foundation Configuration Account.
* Terraform pipelines can write to the Core Configuration via assuming the writer-prinicpal.
* Terraform pipelines can read from the Core Configuration via assuming the reader-prinicpal.

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
[module-version-shield]: https://img.shields.io/badge/module_version-1.4.1-CB224B?style=flat
[terraform-version-shield]: https://img.shields.io/badge/tf-%3E%3D1.3.10-blue.svg?style=flat&color=blueviolet
[trivy-shield]: https://img.shields.io/badge/trivy-passed-green
[checkov-shield]: https://img.shields.io/badge/checkov-passed-green
[release-shield]: https://img.shields.io/github/v/release/acai-solutions/terraform-aws-acf-core-configuration?style=flat&color=success
[release-url]: ./releases
[architecture-png]: ./docs/terraform-aws-acf-core-configuration.png
[license-url]: ./LICENSE.md
[terraform-url]: https://www.terraform.io

