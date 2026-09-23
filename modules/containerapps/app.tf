# The app itself. One container, pulled from ACR with the user-assigned
# identity, so there is no registry password anywhere.
#
# min_replicas is 0, so with no traffic the app scales to zero and costs
# nothing. The first request after a quiet spell waits for a replica to start.

resource "azurerm_container_app" "api" {
  name                         = "ca-${var.name_prefix}-api"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"
  workload_profile_name        = "Consumption"

  identity {
    type         = "UserAssigned"
    identity_ids = [var.identity_id]
  }

  registry {
    server   = var.acr_login_server
    identity = var.identity_id
  }

  # A reference to the Key Vault secret, fetched with the app's identity. The
  # value itself never appears in the app's configuration.
  secret {
    name                = "app-message"
    key_vault_secret_id = var.app_message_secret
    identity            = var.identity_id
  }

  ingress {
    external_enabled = true
    target_port      = var.app_port

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  template {
    min_replicas = 0
    max_replicas = 2

    container {
      name   = "api"
      image  = "${var.acr_login_server}/azure-lab-api:${var.image_tag}"
      cpu    = 0.25
      memory = "0.5Gi"

      env {
        name        = "APP_MESSAGE"
        secret_name = "app-message"
      }

      liveness_probe {
        transport = "HTTP"
        port      = var.app_port
        path      = "/health"
      }

      readiness_probe {
        transport = "HTTP"
        port      = var.app_port
        path      = "/health"
      }
    }
  }

  tags = var.tags
}
