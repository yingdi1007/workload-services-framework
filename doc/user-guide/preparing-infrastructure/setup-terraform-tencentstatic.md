# Setup Terraform for an Existing Tencent Cloud Host

This setup reuses an already running Tencent Cloud VM through the terraform `static` backend instead of asking WSF to create new cloud instances.

## Included config

Use [`script/terraform/terraform-config.tencentstatic.tf`](../../../script/terraform/terraform-config.tencentstatic.tf).

It is prefilled for an example host:

- user: `ubuntu`
- public IP: `<public-ip>`
- private IP: `<private-ip>`
- ssh port: `22`

The same host is currently mapped as `worker-0`, `client-0`, and `controller-0` to keep the first validation path minimal.

## Configure and enumerate tests

```bash
cd ~/workload-services-framework
mkdir -p build-tencentstatic
cd build-tencentstatic
cmake -DTERRAFORM_SUT=tencentstatic -DBENCHMARK=workload/Iperf ..
cd workload/Iperf
ctest -N
```

Expected result: the `Iperf` terraform testcases are listed instead of `Total Tests: 0`.

## Reuse an existing PEM

For a non-local `static` host, WSF normally generates `ssh_access.key`. It now also supports reusing an existing private key by exporting `WSF_SSH_PRIVATE_KEY_FILE` before execution.

Example:

```bash
export WSF_SSH_PRIVATE_KEY_FILE=/path/to/tencent.pem
./ctest.sh -N
```

If `WSF_SSH_PUBLIC_KEY_FILE` is also provided, WSF reuses that public key too. Otherwise it derives `ssh_access.key.pub` from the private key automatically.

WSF still normalizes the key into the terraform workspace as `ssh_access.key` / `ssh_access.key.pub`, so later terraform, packer, ansible, and runtime SSH paths continue to work without additional patches.

If you do not provide `WSF_SSH_PRIVATE_KEY_FILE`, WSF falls back to generating a fresh `ssh_access.key`.

## Remaining prerequisites before running Iperf

- The target host still needs the relevant SUT preparation for the chosen workload type.
- `Iperf` in WSF uses the Kubernetes deployment path, so the host must be prepared accordingly.
- Single-host mapping is useful for first validation, but some scenarios may still require more than one real host to be meaningful.
