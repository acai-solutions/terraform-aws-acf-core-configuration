package test

import (
	"encoding/json"
	"fmt"
	"os"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// runRoundTripExample is the shared driver for all ssm-ps-N tests. It deploys the named example in
// three stages -- IAM roles (their ARNs feed the writer / reader provider blocks), then the writer
// (so the SSM parameters exist before the reader plans), then the full stack -- and asserts the
// example's `test_success` output evaluates to "true", which signals the writer -> SSM -> reader
// round-trip reproduced the original HCL configuration.
//
// The intermediate writer-only stage is required because the reader's
// `data.aws_ssm_parameters_by_path` returns names that are unknown at plan time until the writer's
// `aws_ssm_parameter` resources actually exist in the parameter store.
func runRoundTripExample(t *testing.T, exampleName string) {
	t.Helper()
	t.Logf("Starting Terratest for examples/%s", exampleName)

	terraformDir := "../../examples/" + exampleName
	stateKey := "terratest/terraform-aws-acf-core-configuration-" + exampleName + ".tfstate"
	backendConfig := loadBackendConfig(t, stateKey)

	common := func(targets ...string) *terraform.Options {
		o := &terraform.Options{
			TerraformBinary: getHclBinary(),
			TerraformDir:    terraformDir,
			NoColor:         false,
			Lock:            true,
			BackendConfig:   backendConfig,
			Reconfigure:     true,
		}
		if len(targets) > 0 {
			o.Targets = targets
		}
		return o
	}

	roles := common("module.core_configuration_roles")
	defer terraform.Destroy(t, roles)
	terraform.InitAndApply(t, roles)

	writer := common("module.core_configuration_roles", "module.core_configuration_writer")
	terraform.InitAndApply(t, writer)

	full := common()
	defer terraform.Destroy(t, full)
	terraform.InitAndApply(t, full)

	got := outputClean(t, full, "test_success")
	t.Logf("test_success: %s", got)
	assert.Equal(t, "true", got, "round-trip mismatch for %s", exampleName)
}

// loadBackendConfig reads backend.json (written by the workflow from the
// <TEST_BED>_TESTBED_BACKEND_JSON variable) and overrides its "key" with
// the per-test state key. Returns nil for local state when the file is
// not present.
func loadBackendConfig(t *testing.T, stateKey string) map[string]interface{} {
	backendConfig := map[string]interface{}{}
	data, err := os.ReadFile("backend.json")
	if err != nil {
		t.Logf("No backend.json found, using local state: %v", err)
		return nil
	}
	if err := json.Unmarshal(data, &backendConfig); err != nil {
		t.Fatalf("Failed to parse backend.json: %v", err)
	}
	if stateKey != "" {
		backendConfig["key"] = stateKey
	}
	return backendConfig
}

// getHclBinary returns the HCL CLI binary to invoke. The GitHub workflow
// sets TERRATEST_TERRAFORM_BINARY to "tofu" for OpenTofu matrix entries
// and "terraform" otherwise.
func getHclBinary() string {
	if bin := os.Getenv("TERRATEST_TERRAFORM_BINARY"); bin != "" {
		return bin
	}
	return "terraform"
}

// outputClean runs `terraform output -json <key>` and strips any trailing
// Terraform/OpenTofu warnings (e.g. deprecated-backend-parameter) before
// JSON-unmarshalling the result into a string.
func outputClean(t *testing.T, options *terraform.Options, key string) string {
	t.Helper()
	stdout := rawOutput(t, options, key)
	var value string
	if err := json.Unmarshal([]byte(stdout), &value); err != nil {
		t.Fatalf("Failed to parse terraform output %q: %v\nRaw output: %s", key, err, stdout)
	}
	return value
}

// outputMapClean runs `terraform output -json <key>` and strips trailing
// warnings before unmarshalling into map[string]string.
func outputMapClean(t *testing.T, options *terraform.Options, key string) map[string]string {
	t.Helper()
	stdout := rawOutput(t, options, key)
	var value map[string]string
	if err := json.Unmarshal([]byte(stdout), &value); err != nil {
		t.Fatalf("Failed to parse terraform output map %q: %v\nRaw output: %s", key, err, stdout)
	}
	return value
}

// outputRawClean runs `terraform output -json <key>` and strips trailing
// warnings, returning the trimmed raw JSON string for manual inspection.
func outputRawClean(t *testing.T, options *terraform.Options, key string) string {
	t.Helper()
	return rawOutput(t, options, key)
}

func rawOutput(t *testing.T, options *terraform.Options, key string) string {
	t.Helper()
	args := []string{"output", "-no-color", "-json", key}
	stdout, err := terraform.RunTerraformCommandAndGetStdoutE(t, options, args...)
	if err != nil {
		t.Fatal(fmt.Errorf("terraform output %q: %w", key, err))
	}
	if idx := strings.Index(stdout, "\nWarning:"); idx != -1 {
		stdout = stdout[:idx]
	}
	return strings.TrimSpace(stdout)
}
