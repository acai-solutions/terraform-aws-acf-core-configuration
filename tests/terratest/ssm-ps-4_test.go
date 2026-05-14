package test

import (
	"testing"
)

// TestSsmPs4 -- 15-level deep nesting; exercises every pass of the flatten/unflatten ladders.
func TestSsmPs4(t *testing.T) {
	runRoundTripExample(t, "ssm-ps-4")
}
