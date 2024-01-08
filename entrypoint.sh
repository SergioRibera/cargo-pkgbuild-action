#!/bin/bash

set -o errexit -o pipefail -o nounset

source /utils.sh

NEW_RELEASE=${GITHUB_REF##*/v}
NEW_RELEASE=${NEW_RELEASE##*/}

export HOME=/home/builder

echo "::group::Generating PKGBUILD"
echo "Generating PKGBUILD"
CARGO_PKG_COMMAND="b"
if [[ -n "${INPUT_FILE}" ]]; then
  CARGO_PKG_COMMAND="generate ${INPUT_FILE}"
fi
if [[ "${INPUT_MUSL}" == "true" ]]; then
  CARGO_PKG_COMMAND="b --musl"
fi
/cargo-aur -o "$INPUT_OUTPUT" "$CARGO_PKG_COMMAND"
echo "file=$INPUT_OUTPUT/$(find "$INPUT_OUTPUT/*.tar.gz" | head -n1)">>"$GITHUB_OUTPUT"
echo "pkgbuild=$INPUT_OUTPUT/PKGBUILD">>"$GITHUB_OUTPUT"
echo "::endgroup::Generating PKGBUILD"

echo "::group::Setup"

echo "Creating release $NEW_RELEASE"

echo "Getting AUR SSH Public keys"
ssh-keyscan aur.archlinux.org >>$HOME/.ssh/known_hosts

echo "Writing SSH Private keys to file"
echo -e "${INPUT_SSH_PRIVATE_KEY//_/\\n}" >$HOME/.ssh/aur

chmod 600 $HOME/.ssh/aur*

echo "Setting up Git"
sudo git config --global user.name "$INPUT_GIT_USERNAME"
sudo git config --global user.email "$INPUT_GIT_EMAIL"

# Add github token to the git credential helper
sudo git config --global core.askPass /cred-helper.sh
sudo git config --global credential.helper cache

# Add the working directory as a save directory
sudo git config --global --add safe.directory /github/workspace

REPO_URL="ssh://aur@aur.archlinux.org/${INPUT_PACKAGE_NAME}.git"

# Make the working directory
mkdir -p $HOME/package

# Copy the PKGBUILD file into the working directory
cp "$INPUT_OUTPUT/PKGBUILD" $HOME/PKGBUILD

echo "Changing directory from $PWD to $HOME/package"
cd $HOME/package

echo "::endgroup::Setup"

echo "::group::Build"

echo "The new PKGBUILD is:"
cat PKGBUILD

echo "Make the .SRCINFO file"
makepkg --printsrcinfo >.SRCINFO
echo "The new .SRCINFO is:"
cat .SRCINFO

if [[ "${INPUT_TEST_PKGBUILD}" == "true" ]]; then
  echo "::group::Build::Install"
  echo "Try building the package"
  makepkg --syncdeps --noconfirm --cleanbuild --rmdeps --install
  echo "::endgroup::Build::Install"
fi

if [[ "$INPUT_PUBLISH" == "true" ]]; then
  echo "Clone the AUR repo [${REPO_URL}]"
  git clone "$REPO_URL"

  echo "Copy the new PKGBUILD and .SRCINFO files into the AUR repo"
  cp -f PKGBUILD .SRCINFO "$INPUT_PACKAGE_NAME/"

  echo "::endgroup::Build"
  echo "::group::Commit"

  cd "$INPUT_PACKAGE_NAME"

  echo "Push the new PKGBUILD and .SRCINFO files to the AUR repo"
  git add PKGBUILD .SRCINFO
  commit "$(generate_commit_message "" "$NEW_RELEASE")"
  git push
else
echo "::endgroup::Build"
echo "::group::Commit"
fi
