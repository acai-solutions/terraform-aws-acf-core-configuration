package test

import (
    "testing"
    "github.com/gruntwork-io/terratest/modules/terraform"
)

func TestExample9(t *testing.T) {
    t.Log("Starting 'negative' tests")

    terraformDir := "../../examples/ssm-ps-9"

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
        Targets: []string{
            "module.core_configuration_roles",
            "aws_iam_role.example", // Add this to ensure the IAM role is created
        },
    }
    terraform.InitAndApply(t, terraformCoreConfigurationRoles)

    // Write Configuration - Apply writer1 (should succeed)
    terraformWriteConfiguration1 := &terraform.Options{
        TerraformDir: terraformDir,
        NoColor:      false,
        Lock:         true,
        Targets: []string{
            "module.core_configuration_writer1",
        },
    }
    terraform.InitAndApply(t, terraformWriteConfiguration1)

    // Write Configuration - Apply writer2 (should fail, and we expect this)
    terraformWriteConfiguration2 := &terraform.Options{
        TerraformDir: terraformDir,
        NoColor:      false,
        Lock:         true,
        Targets: []string{
            "module.core_configuration_writer2",
        },
    }
    
    _, err1 := terraform.InitAndApplyE(t, terraformWriteConfiguration2)
    if err1 != nil {
        t.Logf("Expected failure occurred in writer2: %v", err1)
        // Test passes because writer2 failed as expected
        t.Log("Test PASSED: writer2 failed as expected with when trying to overwrite already existing parameters")
        
        // Continue to test writer3 instead of returning
        // Write Configuration - Apply writer3 (should fail, and we expect this)
        terraformWriteConfiguration3 := &terraform.Options{
            TerraformDir: terraformDir,
            NoColor:      false,
            Lock:         true,
            Targets: []string{
                "module.core_configuration_writer3",
            },
        }

        _, err2 := terraform.InitAndApplyE(t, terraformWriteConfiguration3)
        if err2 != nil {
            t.Logf("Expected failure occurred in writer3: %v", err2)
            // Test passes because writer3 failed as expected
            t.Log("Test PASSED: writer3 failed as expected when trying to save invalid value with control characters")
        } else {
            t.Fatal("Writer3 unexpectedly succeeded")
        }
    } else {
        t.Fatal("Writer2 unexpectedly succeeded")
    }
}