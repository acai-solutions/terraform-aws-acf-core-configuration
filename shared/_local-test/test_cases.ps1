Set-Location -Path $PSScriptRoot

terraform init

Write-Host "Testing Level 3 nested structures..."
terraform apply --auto-approve --var-file=tc_l3.tfvars
terraform output > tc_l3.txt

Write-Host "Testing Level 8 nested structures..."
terraform apply --auto-approve --var-file=tc_l8.tfvars
terraform output > tc_l8.txt

Write-Host "Testing basic list structures..."
terraform apply --auto-approve --var-file=tc_list.tfvars
terraform output > tc_list.txt

Write-Host "Testing list of strings..."
terraform apply --auto-approve --var-file=tc_list_string.tfvars
terraform output > tc_list_string.txt

Write-Host "Testing list of dictionaries..."
terraform apply --auto-approve --var-file=tc_list_dict.tfvars
terraform output > tc_list_dict.txt

Write-Host "Testing complex mixed structures..."
terraform apply --auto-approve --var-file=tc_complex_mixed.tfvars
terraform output > tc_complex_mixed.txt

# Clean up
rm terraform.tfstate
rm .terraform.lock.hcl

Write-Host "All tests completed. Check output files for results."