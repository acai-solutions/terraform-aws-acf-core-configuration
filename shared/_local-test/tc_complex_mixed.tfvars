# ACAI Cloud Foundation (ACF)
# Copyright (C) 2025 ACAI GmbH
# Licensed under AGPL v3
#
# This file is part of ACAI ACF.
# Visit https://www.acai.gmbh or https://docs.acai.gmbh for more information.
# 
# For full license text, see LICENSE file in repository root.
# For commercial licensing, contact: contact@acai.gmbh


configuration_add_on = {
  database = {
    connections = [
      {
        name = "primary"
        host = "db1.example.com"
        port = "5432"
        settings = {
          max_connections = "100"
          timeout         = "30"
        }
        tags = ["production", "primary"]
      },
      {
        name = "secondary"
        host = "db2.example.com"
        port = "5432"
        settings = {
          max_connections = "50"
          timeout         = "15"
          backup_enabled  = "true"
        }
        tags = ["production", "backup"]
      }
    ]
  }
  application = {
    services = ["api", "worker", "scheduler"]
    environments = [
      {
        name     = "prod"
        replicas = "3"
        resources = {
          cpu    = "2"
          memory = "4Gi"
        }
      },
      {
        name     = "staging"
        replicas = "1"
        resources = {
          cpu    = "1"
          memory = "2Gi"
        }
      }
    ]
  }
}
prefix = "/test"