# ACAI Cloud Foundation (ACF)
# Copyright (C) 2025 ACAI GmbH
# Licensed under AGPL v3
#
# This file is part of ACAI ACF.
# Visit https://www.acai.gmbh or https://docs.acai.gmbh for more information.
#
# For full license text, see LICENSE file in repository root.
# For commercial licensing, contact: contact@acai.gmbh


# ---------------------------------------------------------------------------------------------------------------------
# ¦ BACKEND
# ---------------------------------------------------------------------------------------------------------------------
# Partial S3 backend. Concrete values (bucket / region / dynamodb_table) are injected at runtime via
# -backend-config from <terratest_path>/backend.json, written by the workflow from
# <TEST_BED>_TESTBED_BACKEND_JSON. The per-test state `key` is set in Go via loadBackendConfig(t, stateKey).
terraform {
  backend "s3" {}
}
