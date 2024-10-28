#!/bin/bash

# Function to run command and save output
run_command() {
    command="$1"
    filename="$(echo "$command" | tr ' ' '_')"
    datetime="$(date +"%Y%m%d_%H%M%S")"
    output_file="${filename}_${datetime}.txt"
    
    echo "Running: $command"
    eval "$command" > "$output_file" 2>&1
    echo "Output saved to: $output_file"
    echo
}

# Run Terraform commands
run_command "terraform graph"
run_command "terraform show"
run_command "terraform state list"
run_command "terraform plan -out=tfplan"
run_command "terraform show -json tfplan"
run_command "terraform providers"
run_command "terraform providers schema -json"
run_command "terraform validate"
run_command "terraform refresh"
run_command "terraform output"
run_command "terraform get"

# Commands that require additional processing

# terraform state show for each resource
echo "Running terraform state show for each resource"
terraform state list | while IFS= read -r resource; do
    run_command "terraform state show \"$resource\""
done

# terraform console commands
echo "Running terraform console commands"
console_commands=(
    "terraform.workspace"
    "path.module"
    "path.root"
    "path.cwd"
    "null_resource.example"
    "var.example_variable"
)

for cmd in "${console_commands[@]}"; do
    run_command "echo '$cmd' | terraform console"
done

# Clean up
rm tfplan

echo "All commands executed. Check the generated output files for details."