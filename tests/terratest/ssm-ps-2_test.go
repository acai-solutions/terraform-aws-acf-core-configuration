package test

import (
	"testing"
)

// TestSsmPs2 -- combined: configuration_add_on AND configuration_add_on_list under the same prefix.
func TestSsmPs2(t *testing.T) {
	runRoundTripExample(t, "ssm-ps-2")
}
