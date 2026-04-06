# Sanitized Local Comparison Summary

This note explains the intent of the sanitized local changes published on branch `codex/sanitized-local-comparison`.

The published diff is not a random snapshot of the whole local workspace. It is a focused subset of the local changes that were needed to validate the Tencent static route and the related Kubernetes and image preparation path without exposing private environment details.

## Scope

The published branch covers four change groups:

1. Reuse an existing SSH key instead of always generating `ssh_access.key`
2. Pass that key through terraform, packer, ansible, and runtime inventory generation
3. Adjust Kubernetes image sources for an environment where default upstream registries were not reliable
4. Keep a small WordPress compatibility fix that existed in the local working copy

## File-by-file intent

### SSH key reuse and propagation

- `script/terraform/script/start.sh`
  - Adds support for `WSF_SSH_PRIVATE_KEY_FILE` and `WSF_SSH_PUBLIC_KEY_FILE`
  - Reuses a provided key pair when present instead of always generating a throwaway key
  - Keeps the old behavior as the fallback when no key is provided

- `script/terraform/script/packer.sh`
  - Makes the packer stage reuse the provided SSH private key
  - Derives the public key from the private key when only the private key is provided
  - Avoids later stages silently drifting away from the reused key material

- `script/terraform/shell.sh`
  - Forwards `WSF_SSH_PRIVATE_KEY_FILE` and `WSF_SSH_PUBLIC_KEY_FILE` into the terraform container
  - Normalizes host paths so keys under the current user home can still be mounted correctly inside the container

- `script/terraform/script/create-cluster.py`
  - Detects the normalized `ssh_access.key` inside the workspace
  - Injects `ansible_private_key_file` and `ansible_ssh_private_key_file` into generated inventory entries for SSH-based hosts
  - Ensures ansible uses the reused key instead of depending on implicit SSH defaults

- `script/terraform/template/packer/static/generic/build.pkr.hcl`
  - Passes the local private key path into the packer-generated inventory template

- `script/terraform/template/packer/static/generic/template/inventory.yaml.tpl`
  - Emits `ansible_private_key_file` and `ansible_ssh_private_key_file`
  - Keeps the packer ansible run aligned with the reused key path

### Kubernetes image source adjustments

- `script/terraform/template/ansible/common/roles/containerd/defaults/main.yaml`
  - Changes the pause image registry to an alternative mirror

- `script/terraform/template/ansible/common/roles/containerd/tasks/main.yaml`
  - Broadens the sandbox image replacement rule so it works against more than one containerd config spelling
  - Keeps the configured pause image registry effective after installation or reset

- `script/terraform/template/ansible/kubernetes/roles/cni-flannel/defaults/main.yaml`
  - Switches the flannel image repo from `docker.io/flannel` to `quay.io/flannel`

- `script/terraform/template/ansible/kubernetes/roles/kubeadm/defaults/main.yaml`
  - Adds an explicit `k8s_image_repository`

- `script/terraform/template/ansible/kubernetes/roles/kubeadm/tasks/init.yaml`
  - Writes `imageRepository` into kubeadm cluster configuration
  - Makes control-plane image pulls use the configured mirror instead of hardcoded defaults

### WordPress local compatibility

- `workload/WordPress/Dockerfile.4.mariadb_wp67php83`
  - Removes overly strict package version pinning for `gosu` and `rsync`
  - Keeps the image build from failing when exact package revisions are no longer available

- `workload/WordPress/cmake/ROME.cmake`
  - Adds the missing Rome platform cmake include file so the local WordPress matrix is complete

### Reproduction note

- `doc/user-guide/preparing-infrastructure/setup-terraform-tencentstatic.md`
  - Documents the Tencent static route used during local validation
  - Explains the SSH key reuse behavior
  - Was sanitized before publication: host addresses were replaced with placeholders

## What was intentionally excluded

The published branch does not include:

- local credentials
- private key files
- personal repo references
- real cloud host IPs
- temporary Dockerfiles and other scratch artifacts
- unrelated dirty files from the local workspace

## Reading the diff

If you are reviewing the branch in GitHub, read it in this order:

1. `start.sh`
2. `shell.sh`
3. `packer.sh`
4. `create-cluster.py`
5. the two packer template files
6. the Kubernetes ansible defaults and init changes
7. the WordPress files
8. the Tencent static setup note

That order matches the actual flow of the SSH and provisioning fix: environment input, container forwarding, key normalization, inventory generation, packer ansible use, then cluster/image pull behavior.
