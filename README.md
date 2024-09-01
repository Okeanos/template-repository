# Readme

Create a new repository using this repository as a template then:

- [ ] update the `LICENSE`. See [choosealicense.com](https://choosealicense.com) for alternatives
- [ ] check all the linter configs (and `.github/workflows/verify.yml`)

How to manage repository settings?

You could create a central `admin` or `settings` repository and manage ALL repositories that way. This
way you wouldn't have to set up authentication and authorization multiple times.

This repository could then also use Terraform/OpenTofu for definitions (see the `settings`-branch).

Why use OpenTofu/Terraform? Mainly because the other options:

- [settings app](https://github.com/repository-settings/app) (individually managed repositories)
- [safe settings repo](https://github.com/github/safe-settings) (centrally managed repositories)
- [allstar](https://github.com/ossf/allstar) (centrally managed repositories)
- custom shell scripting with the [GitHub ClI](https://cli.github.com) and [REST API](https://docs.github.com/en/rest)
- …

Are either even more fragile, cannot be run locally (for verification or application), require additional/convoluted
setup or are otherwise not easily migrated.
