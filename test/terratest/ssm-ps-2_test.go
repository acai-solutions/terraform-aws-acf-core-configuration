package test

import (
	"testing"
	"github.com/stretchr/testify/assert"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestExample2Complete(t *testing.T) {
	// retryable errors in terraform testing.
	t.Log("Starting Sample Module test")

	terraformDir := "../../examples/ssm-ps-2"

    terraformCore := &terraform.Options{
        TerraformDir: terraformDir,
        NoColor:      false,
        Lock:         true,
    }
    defer func() {
        terraform.Destroy(t, terraformCore)
        terraform.Show(t, terraformCore)
    }()

	// Create IAM Roles
	terraformCoreConfigurationRoles := &terraform.Options{
		TerraformDir: terraformDir,
		NoColor:      false,
		Lock:         true,
		Targets: 	  []string {
			"module.core_configuration_roles", 
		},
	}
	terraform.InitAndApply(t, terraformCoreConfigurationRoles)

	// Write Configuration 1
	terraformWriteConfiguration1 := &terraform.Options{
		TerraformDir: terraformDir,
		NoColor:      false,
		Lock:         true,
		Targets: 	  []string {
			"module.core_configuration_writer.module.complex_map_to_simple_map",
			"module.core_configuration_writer",
		},
	}
	terraform.InitAndApply(t, terraformWriteConfiguration1)
		
	// Read Configuration
	terraformReadConfiguration := &terraform.Options{
		TerraformDir: terraformDir,
		NoColor:      false,
		Lock:         true,
		Targets: 	  []string {
			"module.core_configuration_reader",
		},
	}
	terraform.InitAndApply(t, terraformReadConfiguration)
	
	
	// Retrieve the 'test_success' output
	testSuccessOutput := terraform.Output(t, terraformReadConfiguration, "test_success")

	// Assert that 'test_success' equals "true"
	assert.Equal(t, "true", testSuccessOutput, "The test_success output is not true")
}