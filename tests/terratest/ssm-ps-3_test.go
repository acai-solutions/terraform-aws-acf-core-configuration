package test

import (
	"testing"
)

// TestSsmPs3 -- realistic configuration tree with database connections + service lists.
func TestSsmPs3(t *testing.T) {
	runRoundTripExample(t, "ssm-ps-3")
}
