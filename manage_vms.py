import subprocess
import os
import json
import time

# Terraform working directory
TERRAFORM_DIR = "."

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

def switch_non_default_to_azure():
    for vm in VM_CLOUD_MAP:
        if vm not in ["self-healing-defaultaws", "self-healing-defaultazure"]:
            VM_CLOUD_MAP[vm] = "azure"

    print(f"🔄 Switching all non-default VMs to Azure...")
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

def ping_and_recover(vm_name):
    fqdn = f"{vm_name}.dev-machine.link"
    cloud = VM_CLOUD_MAP.get(vm_name)

    if not cloud:
        print(f"❌ Unknown VM: {vm_name}")
        return

    print(f"📡 Pinging {fqdn}...")

    success = False
    for attempt in range(1, 4):
        if is_pingable(fqdn):
            print(f"✅ {fqdn} responded on attempt {attempt}")
            success = True
            break
        else:
            print(f"⚠️ Attempt {attempt} failed. Retrying in 10 seconds...")
            time.sleep(10)

    if not success:
        print(f"🚨 {fqdn} is unresponsive. Recreating...")
        recreate_vm(cloud, vm_name)

def ping_all_and_recover():
    print("📡 Starting health check for all VMs...")

    for vm_name in VM_CLOUD_MAP:
        fqdn = f"{vm_name}.dev-machine.link"
        print(f"\n🔎 Checking {fqdn}...")
        success = False

        for attempt in range(1, 4):
            if is_pingable(fqdn):
                print(f"✅ {fqdn} responded on attempt {attempt}")
                success = True
                break
            else:
                print(f"⚠️ {fqdn} did not respond (attempt {attempt}). Waiting 10 seconds...")
                time.sleep(10)

        if not success:
            print(f"🚨 {fqdn} is unresponsive. Recreating VM...")
            cloud = VM_CLOUD_MAP.get(vm_name)
            if cloud:
                recreate_vm(cloud, vm_name)
            else:
                print(f"❌ Unknown cloud mapping for {vm_name}, skipping...")
        
        time.sleep(1)

if __name__ == "__main__":
    input("Action: Init All VMs. Press Enter to continue...")
    apply_all()

    input("Action: Check all VMs for ping response. Press Enter to continue...")
    ping_all_and_recover()

    input("Action: Switch All AWS VMs to Azure. Press Enter to continue...")
    switch_non_default_to_azure()

    input("Action: Destroy all VMs. Press Enter to continue...")
    destroy_all()
