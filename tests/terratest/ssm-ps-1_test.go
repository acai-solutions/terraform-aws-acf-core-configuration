package test

import (
	"testing"
)

// TestSsmPs1 -- mixed scalars + simple lists + nested object (smoke test).
func TestSsmPs1(t *testing.T) {
	runRoundTripExample(t, "ssm-ps-1")
}
