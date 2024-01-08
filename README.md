# Generate and deploy PKGBUILD from Cargo.toml

[![GitHub Super-Linter](https://github.com/SergioRibera/cargo-pkgbuild-action/actions/workflows/linter.yml/badge.svg)](https://github.com/super-linter/super-linter)
![CI](https://github.com/SergioRibera/cargo-pkgbuild-action/actions/workflows/ci.yml/badge.svg)

This action allows you to generate the PKGBUILD file and
publish it in the AUR repository from your Cargo.toml metadata.

> [!NOTE]
> This uses [cargo-aur](https://github.com/SergioRibera/cargo-pkgbuild/tree/dev) to make all this possible

## Usage

Here's an example of how to use this action in a workflow file:

```yaml
name: Example

on:
  push:
    tags:
      - "*" # Run on any tag

jobs:
    aur-publish:
        runs-on: ubuntu-latest
        steps:
        - uses: actions/checkout@v4

        - name: Publish AUR package
          uses: SergioRibera/cargo-pkgbuild-action@v1
          with:
            github_token: ${{ secrets.GITHUB_TOKEN }}
            ssh_private_key: ${{ secrets.AUR_SSH_PRIVATE_KEY }}
            proyect_path: 'test_proyect' # The project path to generate PKGBUILD
```

## Inputs

| Input             | Default                               | Description                                                        |
|-------------------|---------------------------------------|--------------------------------------------------------------------|
| `proyect_path`    | `.`                                   | The project path to generate PKGBUILD                              |
| `musl`            | `false`                               | Build the binary as musl                                           |
| `file`            | ``                                    | The path to the .tar.gz file to use                                |
| `output`          | `out/`                                | Defines the folder from which the PKGBUILD file will be generated. |
| `package_name`    | `${{ github.event.repository.name }}` | The name in AUR of the package to release                          |
| `git_username`    | `AUR Release Action`                  | The username to use for the git commit                             |
| `git_email`       | `github-action-bot@no-reply.com`      | The email to use for the git commit                                |
| `ssh_private_key` | `true`                                | The private key to use for the git commit                          |
| `publish`         | `true`                                | To publish or not to publish the package                           |
| `test_pkgbuild`   | `true`                                | Whether to try building and installing the package or not          |
| `github_token`    | `true`                                | The GitHub token to use for the release                            |
| `commit_message`  | `Bump %FILENAME% to %VERSION%`        | The commit message to use for the git commit                       |

## Outputs

| Output     | Description                             |
|------------|-----------------------------------------|
| `file`     | The path to the generated .tar.gz file  |
| `pkgbuild` | The path to the generated PKGBUILD file |
