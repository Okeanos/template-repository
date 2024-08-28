# Readme

Create a new repository using this repository as a template (include all branches) then:

- [ ] check the OpenTofu/Terraform definitions and ensure they as expected (`.github/settings/*`)
- [ ] run `.github/settings/init.sh` to apply the settings once, manually.

  This will also disable the `Settings` workflow that is supposed to sync the repository settings when pushing to the
  `settings` branch, however, unless authentication with a fine-granular token or a properly authorized GitHub App is
  supplied, this will fail (at the planning step already).

- [ ] update the `LICENSE`. See [choosealicense.com](https://choosealicense.com) for alternatives
- [ ] check all the linter configs (and `.github/workflows/verify.yml`)

Until proper authentication for the settings workflow is set up, you'll have to manually sync the repo settings by
invoking `tofu apply` from within the `.github/settings` folder.

Alternatively, you could create a central `admin` or `settings` repository and manage ALL repositories that way. This
way you wouldn't have to set up authentication and authorization multiple times.

Why use OpenTofu/Terraform? Mainly because the other options:

- [settings app](https://github.com/repository-settings/app) (individually managed repositories)
- [safe settings repo](https://github.com/github/safe-settings) (centrally managed repositories)
- custom shell scripting with the [GitHub ClI](https://cli.github.com) and [REST API](https://docs.github.com/en/rest)
- …

Are either even more fragile, cannot be run locally (for verification or application), require additional/convoluted
setup or are otherwise not easily migrated.
