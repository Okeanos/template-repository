locals {
  repository_name = "template-repository"
}

# The repo is usually created on GitHub first and has to be imported in order to be modified
import {
  id = local.repository_name
  to = github_repository.repo
}

# Define the current repository state
resource "github_repository" "repo" {
  # Base settings
  description = "This is a bare bones template repository for setting up new GitHub repositories with batteries included"
  name        = local.repository_name
  auto_init   = false # want to set up the repo cleanly

  # Additional attributes and information
  homepage_url = null
  topics       = ["renovate-me"]

  # Visibility settings; access via collaborators handled separately
  visibility = "private"

  # Repo Features
  has_discussions = false
  has_downloads   = true
  has_issues      = true
  has_projects    = false
  has_wiki        = false

  # PR settings
  allow_auto_merge    = false # we want merges to be an active decision
  allow_merge_commit  = true
  allow_rebase_merge  = true
  allow_squash_merge  = false # we want to keep the PR history intact after a merge
  allow_update_branch = true

  # Branch handling
  delete_branch_on_merge = true # enable automatic deletion of branches on merge

  # Security & Vulnerability Handling
  # TODO doesn't appear to work for workflows with just the vanilla workflow GITHUB_TOKEN despite this setting,
  #   hence the settings workflow is disabled by default via the init.sh script
  ignore_vulnerability_alerts_during_read = true # prevent issues with accessing repo data without admin permissions
  vulnerability_alerts                    = true # requires the owner to enable this as well

  # Archive this repository on terraform destroy execution instead of deleting it
  archive_on_destroy = true
}

# can only be activated if repo.vulnerability_alerts is true
resource "github_repository_dependabot_security_updates" "security_updates" {
  repository = github_repository.repo.id
  enabled    = github_repository.repo.vulnerability_alerts == true ? true : false
}

## Define Git setup, i.e. branches & branch protections
resource "github_branch" "default" {
  repository = github_repository.repo.name
  branch     = "main"
}

resource "github_branch" "settings" {
  repository = github_repository.repo.name
  branch     = "settings"
}

resource "github_branch_default" "default" {
  repository = github_repository.repo.name
  branch     = github_branch.default.branch
}

resource "github_repository_ruleset" "default" {
  repository  = github_repository.repo.name
  name        = github_branch.default.branch
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      exclude = []
      include = ["~DEFAULT_BRANCH"]
    }
  }

  bypass_actors {
    actor_id    = 1
    actor_type  = "OrganizationAdmin"
    bypass_mode = "always"
  }

  bypass_actors {
    actor_id    = 5 # admin
    actor_type  = "RepositoryRole"
    bypass_mode = "always"
  }

  bypass_actors {
    actor_id    = 2 # maintain
    actor_type  = "RepositoryRole"
    bypass_mode = "always"
  }

  rules {
    creation         = true
    deletion         = true
    update           = false
    non_fast_forward = true

    # This makes PRs required unless a bypass works
    # Intention would be to make PRs optional, but if they exist they need to follow these rules.
    # To achieve a similar result the the repository role bypass for maintainers is used.
    pull_request {
      dismiss_stale_reviews_on_push     = true
      require_code_owner_review         = true
      required_review_thread_resolution = true
    }
  }
}

# TODO add a rule preventing updates to the settings workflow without PRs
# See:
# - https://github.com/integrations/terraform-provider-github/issues/2371
# - https://github.com/github/ruleset-recipes/blob/main/push-rulesets/keep-it-secret-keep-it-safe.json
# This rule targets the settings workflow file and ensures it is not touched to
# prevent unintended/unapproved changes to the repository settings.
# resource "github_repository_ruleset" "settings-workflow" {
#   repository  = github_repository.repo.name
#   name        = "${github_branch.default.branch}-settings-workflow"
#   target      = "push"
#   enforcement = "active"
#
#   conditions {}
#
#   bypass_actors {
#     actor_id    = 1
#     actor_type  = "OrganizationAdmin"
#     bypass_mode = "always"
#   }
#
#   bypass_actors {
#     actor_id    = 5
#     actor_type  = "RepositoryRole"
#     bypass_mode = "always"
#   }
#
#   rules {}
# }

resource "github_repository_ruleset" "settings" {
  repository  = github_repository.repo.name
  name        = github_branch.settings.branch
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      exclude = []
      include = ["refs/heads/${github_branch.settings.branch}"]
    }
  }

  bypass_actors {
    actor_id    = 5
    actor_type  = "RepositoryRole"
    bypass_mode = "always"
  }

  bypass_actors {
    actor_id    = 1
    actor_type  = "OrganizationAdmin"
    bypass_mode = "always"
  }

  rules {
    creation            = true
    deletion            = true
    update              = false
    non_fast_forward    = true
    required_signatures = true

    pull_request {
      dismiss_stale_reviews_on_push     = true
      require_code_owner_review         = true
      required_review_thread_resolution = true
      required_approving_review_count   = 1
    }
  }
}

resource "github_repository_environment" "settings" {
  environment         = "settings"
  repository          = github_repository.repo.name
  prevent_self_review = false

  # https://docs.github.com/en/actions/managing-workflow-runs-and-deployments/managing-deployments/managing-environments-for-deployment
  # wait timers and reviewers require a public repository

  deployment_branch_policy {
    protected_branches     = false
    custom_branch_policies = true
  }
}

# https://github.com/integrations/terraform-provider-github/issues/1997
resource "github_repository_environment_deployment_policy" "settings" {
  repository     = github_repository.repo.name
  environment    = github_repository_environment.settings.environment
  branch_pattern = "settings"
}
