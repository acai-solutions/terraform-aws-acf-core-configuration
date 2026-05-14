terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ PURE-HCL UNFLATTEN
# ---------------------------------------------------------------------------------------------------------------------
# Inverse of shared/complex_map_to_simple_map_hcl. Turns a flat map<string,string> -- e.g. the result of
# `aws_ssm_parameters_by_path` -- back into the original nested HCL object.
#
# Strategy (mirror of the flatten side):
#   * State is held as map<string,string> the whole time so we never run into the type-unification trap
#     described in shared/complex_map_to_simple_map_hcl/main.tf. Every value is JSON-encoded.
#   * One pass: take the keys at the CURRENT maximum depth (only when that depth is >= 2), group them by
#     parent path, and collapse each group into a single entry whose value is
#     `jsonencode({child_name = decoded_child_value, ...})`. When max depth is already 1 the pass is a
#     no-op so we don't accumulate spurious empty-key wrappings.
#   * After 10 passes every key is at depth 1; we jsondecode each value to restore the original nested HCL.
# ---------------------------------------------------------------------------------------------------------------------

locals {
  sep = var.separator

  s0 = {
    for k, v in var.flat_configuration :
    trimprefix(trimprefix(k, var.prefix), local.sep) => jsonencode(v)
  }
}

# ----- pass 1 -----
locals {
  s1_max_depth = max(concat([0], [for k in keys(local.s0) : length(split(local.sep, k))])...)
  s1_collapse  = local.s1_max_depth >= 2
  s1_deepest   = local.s1_collapse ? [for k in keys(local.s0) : k if length(split(local.sep, k)) == local.s1_max_depth] : []
  s1_shallow   = local.s1_collapse ? { for k, v in local.s0 : k => v if length(split(local.sep, k)) < local.s1_max_depth } : local.s0
  s1_parents   = distinct([for k in local.s1_deepest : join(local.sep, slice(split(local.sep, k), 0, length(split(local.sep, k)) - 1))])
  s1_collapsed = { for p in local.s1_parents : p => jsonencode({ for k in local.s1_deepest : element(split(local.sep, k), length(split(local.sep, k)) - 1) => jsondecode(local.s0[k]) if join(local.sep, slice(split(local.sep, k), 0, length(split(local.sep, k)) - 1)) == p }) }
  s1           = merge(local.s1_shallow, local.s1_collapsed)
}

# ----- pass 2 -----
locals {
  s2_max_depth = max(concat([0], [for k in keys(local.s1) : length(split(local.sep, k))])...)
  s2_collapse  = local.s2_max_depth >= 2
  s2_deepest   = local.s2_collapse ? [for k in keys(local.s1) : k if length(split(local.sep, k)) == local.s2_max_depth] : []
  s2_shallow   = local.s2_collapse ? { for k, v in local.s1 : k => v if length(split(local.sep, k)) < local.s2_max_depth } : local.s1
  s2_parents   = distinct([for k in local.s2_deepest : join(local.sep, slice(split(local.sep, k), 0, length(split(local.sep, k)) - 1))])
  s2_collapsed = { for p in local.s2_parents : p => jsonencode({ for k in local.s2_deepest : element(split(local.sep, k), length(split(local.sep, k)) - 1) => jsondecode(local.s1[k]) if join(local.sep, slice(split(local.sep, k), 0, length(split(local.sep, k)) - 1)) == p }) }
  s2           = merge(local.s2_shallow, local.s2_collapsed)
}

# ----- pass 3 -----
locals {
  s3_max_depth = max(concat([0], [for k in keys(local.s2) : length(split(local.sep, k))])...)
  s3_collapse  = local.s3_max_depth >= 2
  s3_deepest   = local.s3_collapse ? [for k in keys(local.s2) : k if length(split(local.sep, k)) == local.s3_max_depth] : []
  s3_shallow   = local.s3_collapse ? { for k, v in local.s2 : k => v if length(split(local.sep, k)) < local.s3_max_depth } : local.s2
  s3_parents   = distinct([for k in local.s3_deepest : join(local.sep, slice(split(local.sep, k), 0, length(split(local.sep, k)) - 1))])
  s3_collapsed = { for p in local.s3_parents : p => jsonencode({ for k in local.s3_deepest : element(split(local.sep, k), length(split(local.sep, k)) - 1) => jsondecode(local.s2[k]) if join(local.sep, slice(split(local.sep, k), 0, length(split(local.sep, k)) - 1)) == p }) }
  s3           = merge(local.s3_shallow, local.s3_collapsed)
}

# ----- pass 4 -----
locals {
  s4_max_depth = max(concat([0], [for k in keys(local.s3) : length(split(local.sep, k))])...)
  s4_collapse  = local.s4_max_depth >= 2
  s4_deepest   = local.s4_collapse ? [for k in keys(local.s3) : k if length(split(local.sep, k)) == local.s4_max_depth] : []
  s4_shallow   = local.s4_collapse ? { for k, v in local.s3 : k => v if length(split(local.sep, k)) < local.s4_max_depth } : local.s3
  s4_parents   = distinct([for k in local.s4_deepest : join(local.sep, slice(split(local.sep, k), 0, length(split(local.sep, k)) - 1))])
  s4_collapsed = { for p in local.s4_parents : p => jsonencode({ for k in local.s4_deepest : element(split(local.sep, k), length(split(local.sep, k)) - 1) => jsondecode(local.s3[k]) if join(local.sep, slice(split(local.sep, k), 0, length(split(local.sep, k)) - 1)) == p }) }
  s4           = merge(local.s4_shallow, local.s4_collapsed)
}

# ----- pass 5 -----
locals {
  s5_max_depth = max(concat([0], [for k in keys(local.s4) : length(split(local.sep, k))])...)
  s5_collapse  = local.s5_max_depth >= 2
  s5_deepest   = local.s5_collapse ? [for k in keys(local.s4) : k if length(split(local.sep, k)) == local.s5_max_depth] : []
  s5_shallow   = local.s5_collapse ? { for k, v in local.s4 : k => v if length(split(local.sep, k)) < local.s5_max_depth } : local.s4
  s5_parents   = distinct([for k in local.s5_deepest : join(local.sep, slice(split(local.sep, k), 0, length(split(local.sep, k)) - 1))])
  s5_collapsed = { for p in local.s5_parents : p => jsonencode({ for k in local.s5_deepest : element(split(local.sep, k), length(split(local.sep, k)) - 1) => jsondecode(local.s4[k]) if join(local.sep, slice(split(local.sep, k), 0, length(split(local.sep, k)) - 1)) == p }) }
  s5           = merge(local.s5_shallow, local.s5_collapsed)
}

# ----- pass 6 -----
locals {
  s6_max_depth = max(concat([0], [for k in keys(local.s5) : length(split(local.sep, k))])...)
  s6_collapse  = local.s6_max_depth >= 2
  s6_deepest   = local.s6_collapse ? [for k in keys(local.s5) : k if length(split(local.sep, k)) == local.s6_max_depth] : []
  s6_shallow   = local.s6_collapse ? { for k, v in local.s5 : k => v if length(split(local.sep, k)) < local.s6_max_depth } : local.s5
  s6_parents   = distinct([for k in local.s6_deepest : join(local.sep, slice(split(local.sep, k), 0, length(split(local.sep, k)) - 1))])
  s6_collapsed = { for p in local.s6_parents : p => jsonencode({ for k in local.s6_deepest : element(split(local.sep, k), length(split(local.sep, k)) - 1) => jsondecode(local.s5[k]) if join(local.sep, slice(split(local.sep, k), 0, length(split(local.sep, k)) - 1)) == p }) }
  s6           = merge(local.s6_shallow, local.s6_collapsed)
}

# ----- pass 7 -----
locals {
  s7_max_depth = max(concat([0], [for k in keys(local.s6) : length(split(local.sep, k))])...)
  s7_collapse  = local.s7_max_depth >= 2
  s7_deepest   = local.s7_collapse ? [for k in keys(local.s6) : k if length(split(local.sep, k)) == local.s7_max_depth] : []
  s7_shallow   = local.s7_collapse ? { for k, v in local.s6 : k => v if length(split(local.sep, k)) < local.s7_max_depth } : local.s6
  s7_parents   = distinct([for k in local.s7_deepest : join(local.sep, slice(split(local.sep, k), 0, length(split(local.sep, k)) - 1))])
  s7_collapsed = { for p in local.s7_parents : p => jsonencode({ for k in local.s7_deepest : element(split(local.sep, k), length(split(local.sep, k)) - 1) => jsondecode(local.s6[k]) if join(local.sep, slice(split(local.sep, k), 0, length(split(local.sep, k)) - 1)) == p }) }
  s7           = merge(local.s7_shallow, local.s7_collapsed)
}

# ----- pass 8 -----
locals {
  s8_max_depth = max(concat([0], [for k in keys(local.s7) : length(split(local.sep, k))])...)
  s8_collapse  = local.s8_max_depth >= 2
  s8_deepest   = local.s8_collapse ? [for k in keys(local.s7) : k if length(split(local.sep, k)) == local.s8_max_depth] : []
  s8_shallow   = local.s8_collapse ? { for k, v in local.s7 : k => v if length(split(local.sep, k)) < local.s8_max_depth } : local.s7
  s8_parents   = distinct([for k in local.s8_deepest : join(local.sep, slice(split(local.sep, k), 0, length(split(local.sep, k)) - 1))])
  s8_collapsed = { for p in local.s8_parents : p => jsonencode({ for k in local.s8_deepest : element(split(local.sep, k), length(split(local.sep, k)) - 1) => jsondecode(local.s7[k]) if join(local.sep, slice(split(local.sep, k), 0, length(split(local.sep, k)) - 1)) == p }) }
  s8           = merge(local.s8_shallow, local.s8_collapsed)
}

# ----- pass 9 -----
locals {
  s9_max_depth = max(concat([0], [for k in keys(local.s8) : length(split(local.sep, k))])...)
  s9_collapse  = local.s9_max_depth >= 2
  s9_deepest   = local.s9_collapse ? [for k in keys(local.s8) : k if length(split(local.sep, k)) == local.s9_max_depth] : []
  s9_shallow   = local.s9_collapse ? { for k, v in local.s8 : k => v if length(split(local.sep, k)) < local.s9_max_depth } : local.s8
  s9_parents   = distinct([for k in local.s9_deepest : join(local.sep, slice(split(local.sep, k), 0, length(split(local.sep, k)) - 1))])
  s9_collapsed = { for p in local.s9_parents : p => jsonencode({ for k in local.s9_deepest : element(split(local.sep, k), length(split(local.sep, k)) - 1) => jsondecode(local.s8[k]) if join(local.sep, slice(split(local.sep, k), 0, length(split(local.sep, k)) - 1)) == p }) }
  s9           = merge(local.s9_shallow, local.s9_collapsed)
}

# ----- pass 10 -----
locals {
  s10_max_depth = max(concat([0], [for k in keys(local.s9) : length(split(local.sep, k))])...)
  s10_collapse  = local.s10_max_depth >= 2
  s10_deepest   = local.s10_collapse ? [for k in keys(local.s9) : k if length(split(local.sep, k)) == local.s10_max_depth] : []
  s10_shallow   = local.s10_collapse ? { for k, v in local.s9 : k => v if length(split(local.sep, k)) < local.s10_max_depth } : local.s9
  s10_parents   = distinct([for k in local.s10_deepest : join(local.sep, slice(split(local.sep, k), 0, length(split(local.sep, k)) - 1))])
  s10_collapsed = { for p in local.s10_parents : p => jsonencode({ for k in local.s10_deepest : element(split(local.sep, k), length(split(local.sep, k)) - 1) => jsondecode(local.s9[k]) if join(local.sep, slice(split(local.sep, k), 0, length(split(local.sep, k)) - 1)) == p }) }
  s10           = merge(local.s10_shallow, local.s10_collapsed)
}

# ----- pass 11 -----
locals {
  s11_max_depth = max(concat([0], [for k in keys(local.s10) : length(split(local.sep, k))])...)
  s11_collapse  = local.s11_max_depth >= 2
  s11_deepest   = local.s11_collapse ? [for k in keys(local.s10) : k if length(split(local.sep, k)) == local.s11_max_depth] : []
  s11_shallow   = local.s11_collapse ? { for k, v in local.s10 : k => v if length(split(local.sep, k)) < local.s11_max_depth } : local.s10
  s11_parents   = distinct([for k in local.s11_deepest : join(local.sep, slice(split(local.sep, k), 0, length(split(local.sep, k)) - 1))])
  s11_collapsed = { for p in local.s11_parents : p => jsonencode({ for k in local.s11_deepest : element(split(local.sep, k), length(split(local.sep, k)) - 1) => jsondecode(local.s10[k]) if join(local.sep, slice(split(local.sep, k), 0, length(split(local.sep, k)) - 1)) == p }) }
  s11           = merge(local.s11_shallow, local.s11_collapsed)
}

# ----- pass 12 -----
locals {
  s12_max_depth = max(concat([0], [for k in keys(local.s11) : length(split(local.sep, k))])...)
  s12_collapse  = local.s12_max_depth >= 2
  s12_deepest   = local.s12_collapse ? [for k in keys(local.s11) : k if length(split(local.sep, k)) == local.s12_max_depth] : []
  s12_shallow   = local.s12_collapse ? { for k, v in local.s11 : k => v if length(split(local.sep, k)) < local.s12_max_depth } : local.s11
  s12_parents   = distinct([for k in local.s12_deepest : join(local.sep, slice(split(local.sep, k), 0, length(split(local.sep, k)) - 1))])
  s12_collapsed = { for p in local.s12_parents : p => jsonencode({ for k in local.s12_deepest : element(split(local.sep, k), length(split(local.sep, k)) - 1) => jsondecode(local.s11[k]) if join(local.sep, slice(split(local.sep, k), 0, length(split(local.sep, k)) - 1)) == p }) }
  s12           = merge(local.s12_shallow, local.s12_collapsed)
}

# ----- pass 13 -----
locals {
  s13_max_depth = max(concat([0], [for k in keys(local.s12) : length(split(local.sep, k))])...)
  s13_collapse  = local.s13_max_depth >= 2
  s13_deepest   = local.s13_collapse ? [for k in keys(local.s12) : k if length(split(local.sep, k)) == local.s13_max_depth] : []
  s13_shallow   = local.s13_collapse ? { for k, v in local.s12 : k => v if length(split(local.sep, k)) < local.s13_max_depth } : local.s12
  s13_parents   = distinct([for k in local.s13_deepest : join(local.sep, slice(split(local.sep, k), 0, length(split(local.sep, k)) - 1))])
  s13_collapsed = { for p in local.s13_parents : p => jsonencode({ for k in local.s13_deepest : element(split(local.sep, k), length(split(local.sep, k)) - 1) => jsondecode(local.s12[k]) if join(local.sep, slice(split(local.sep, k), 0, length(split(local.sep, k)) - 1)) == p }) }
  s13           = merge(local.s13_shallow, local.s13_collapsed)
}

# ----- pass 14 -----
locals {
  s14_max_depth = max(concat([0], [for k in keys(local.s13) : length(split(local.sep, k))])...)
  s14_collapse  = local.s14_max_depth >= 2
  s14_deepest   = local.s14_collapse ? [for k in keys(local.s13) : k if length(split(local.sep, k)) == local.s14_max_depth] : []
  s14_shallow   = local.s14_collapse ? { for k, v in local.s13 : k => v if length(split(local.sep, k)) < local.s14_max_depth } : local.s13
  s14_parents   = distinct([for k in local.s14_deepest : join(local.sep, slice(split(local.sep, k), 0, length(split(local.sep, k)) - 1))])
  s14_collapsed = { for p in local.s14_parents : p => jsonencode({ for k in local.s14_deepest : element(split(local.sep, k), length(split(local.sep, k)) - 1) => jsondecode(local.s13[k]) if join(local.sep, slice(split(local.sep, k), 0, length(split(local.sep, k)) - 1)) == p }) }
  s14           = merge(local.s14_shallow, local.s14_collapsed)
}

# ----- pass 15 -----
locals {
  s15_max_depth = max(concat([0], [for k in keys(local.s14) : length(split(local.sep, k))])...)
  s15_collapse  = local.s15_max_depth >= 2
  s15_deepest   = local.s15_collapse ? [for k in keys(local.s14) : k if length(split(local.sep, k)) == local.s15_max_depth] : []
  s15_shallow   = local.s15_collapse ? { for k, v in local.s14 : k => v if length(split(local.sep, k)) < local.s15_max_depth } : local.s14
  s15_parents   = distinct([for k in local.s15_deepest : join(local.sep, slice(split(local.sep, k), 0, length(split(local.sep, k)) - 1))])
  s15_collapsed = { for p in local.s15_parents : p => jsonencode({ for k in local.s15_deepest : element(split(local.sep, k), length(split(local.sep, k)) - 1) => jsondecode(local.s14[k]) if join(local.sep, slice(split(local.sep, k), 0, length(split(local.sep, k)) - 1)) == p }) }
  s15           = merge(local.s15_shallow, local.s15_collapsed)
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ FINAL ASSEMBLY
# ---------------------------------------------------------------------------------------------------------------------
locals {
  unflattened_configuration = { for k, v in local.s15 : k => jsondecode(v) }
}

# Loud failure if the input nested deeper than the ladder above can handle (any pass 15 key still has depth > 1).
check "max_depth_not_exceeded" {
  assert {
    condition     = local.s15_max_depth <= 1
    error_message = "flat_configuration nests deeper than the supported max depth (15). Extend the sN ladder in shared/simple_map_to_complex_map/main.tf."
  }
}
