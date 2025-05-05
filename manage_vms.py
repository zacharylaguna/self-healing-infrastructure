import subprocess
import os
import json
import time

# Terraform working directory
TERRAFORM_DIR = "."

# Which cloud non-default VMs are currently on ("aws" or "azure")
ACTIVE_CLOUD = "aws"

# In-code mapping of VM name -> cloud ("aws" or "azure")
VM_CLOUD_MAP = {
    "self-healing-defaultaws": "aws",
    "self-healing-defaultazure": "azure",
    "self-healing-machine1": "aws",
    "self-healing-machine2": "aws",
    "self-healing-machine3": "aws",
    "self-healing-machine4": "aws",
    "self-healing-machine5": "aws",
    "self-healing-machine6": "aws",
    "self-healing-machine7": "aws",
    "self-healing-machine8": "aws",
    "self-healing-machine9": "aws",
    "self-healing-machine10": "aws"
}

def write_tfvars_file_from_map(vm_map):
    aws_list = [vm for vm, cloud in vm_map.items() if cloud == "aws"]
    azure_list = [vm for vm, cloud in vm_map.items() if cloud == "azure"]

    tfvars_path = os.path.join(TERRAFORM_DIR, "terraform.tfvars")
    tfvars_content = (
        f'aws_vm_names = {json.dumps(aws_list)}\n'
        f'azure_vm_names = {json.dumps(azure_list)}\n'
    )
    with open(tfvars_path, "w") as f:
        f.write(tfvars_content)
    print(f"✅ Wrote terraform.tfvars with {len(aws_list)} AWS VMs and {len(azure_list)} Azure VMs.")

def run_terraform_command(args):
    print(f"🔧 Running: terraform {' '.join(args)}")
    subprocess.run(["terraform"] + args, cwd=TERRAFORM_DIR, check=True)

def apply_all():
    write_tfvars_file_from_map(VM_CLOUD_MAP)
    run_terraform_command(["init", "-input=false"])
    run_terraform_command(["apply", "-auto-approve", "-var-file=terraform.tfvars"])

def recreate_vm(cloud, vm_name):
    write_tfvars_file_from_map(VM_CLOUD_MAP)

    if cloud == "aws":
        resource = f"module.aws_vms[\"{vm_name}\"].aws_instance.vm"
    elif cloud == "azure":
        resource = f"module.azure_vms[\"{vm_name}\"].azurerm_linux_virtual_machine.vm"
    else:
        raise ValueError("Invalid cloud: must be 'aws' or 'azure'")

    run_terraform_command(["init", "-input=false"])
    run_terraform_command(["taint", resource])
    run_terraform_command(["apply", "-auto-approve", "-var-file=terraform.tfvars"])

def switch_non_default_cloud():
    global ACTIVE_CLOUD
    target_cloud = "azure" if ACTIVE_CLOUD == "aws" else "aws"
    print(f"🔄 Switching all non-default VMs to {target_cloud.upper()}...")

    for vm in VM_CLOUD_MAP:
        if vm not in ["self-healing-defaultaws", "self-healing-defaultazure"]:
            VM_CLOUD_MAP[vm] = target_cloud

    ACTIVE_CLOUD = target_cloud
    write_tfvars_file_from_map(VM_CLOUD_MAP)
    run_terraform_command(["init", "-input=false"])
    run_terraform_command(["apply", "-auto-approve", "-var-file=terraform.tfvars"])

def destroy_all():
    write_tfvars_file_from_map(VM_CLOUD_MAP)
    run_terraform_command(["init", "-input=false"])
    run_terraform_command(["destroy", "-auto-approve"])

def is_pingable(host):
    try:
        result = subprocess.run(
            ["ping", "-c", "1", "-W", "5", host],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL
        )
        return result.returncode == 0
    except Exception:
        return False

def ping_all_and_recover():
    print("📡 Starting health check sweep of all VMs...")

    failed_vms = []
    max_attempts = 3
    delay_between_attempts = 10
    fail_count = {vm_name: 0 for vm_name in VM_CLOUD_MAP}

    for attempt in range(1, max_attempts + 1):
        print(f"\n🔁 Ping attempt {attempt}/{max_attempts}")
        for vm_name in VM_CLOUD_MAP:
            fqdn = f"{vm_name}.dev-machine.link"

            if fail_count[vm_name] >= attempt - 1:
                if is_pingable(fqdn):
                    print(f"✅ {fqdn} responded")
                    fail_count[vm_name] = 0
                else:
                    print(f"⚠️ {fqdn} failed ping attempt {attempt}")
                    fail_count[vm_name] += 1

        if attempt < max_attempts:
            print(f"\n⏱ Waiting {delay_between_attempts} seconds before next sweep...")
            time.sleep(delay_between_attempts)

    failed_vms = [vm for vm, count in fail_count.items() if count == max_attempts]

    if not failed_vms:
        print("\n✅ All VMs responded successfully.")
        return

    if len(failed_vms) == 1:
        vm = failed_vms[0]
        print(f"\n🚨 Only one VM failed: {vm}. Recreating it...")
        recreate_vm(VM_CLOUD_MAP[vm], vm)
    else:
        print(f"\n🚨 Multiple VMs failed: {failed_vms}. Switching clouds...")
        switch_non_default_cloud()

if __name__ == "__main__":
    input("Action: Init All VMs. Press Enter to continue...")
    apply_all()

    input("Action: Health check sweep. Press Enter to continue...")
    ping_all_and_recover()

    input("Action: Switch non-default VMs to the other cloud. Press Enter to continue...")
    switch_non_default_cloud()

    input("Action: Destroy all VMs. Press Enter to continue...")
    destroy_all()
