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
# ¦ PURE-HCL FLATTEN
# ---------------------------------------------------------------------------------------------------------------------
# Bounded iterative flatten. Each pass rewrites one level of nesting:
#   { k = <map> }                                       -> { "k/childkey" => child_value }
#   { k = <list> }  (only when list_strategy="indexed") -> { "k/<idx>"   => element       }
# After 10 passes every value is a leaf (assuming the input does not nest deeper than 10).
#
# Keys come from the caller's HCL literals, so they remain plan-time-known even when leaf VALUES are unknown
# (e.g. attributes of resources not yet created). This is what makes for_each on the result safe.
#
# Implementation note: we cannot use a chained ternary to choose between "expand a map", "expand a list",
# and "keep a leaf" because Terraform infers each branch as an object with literal attribute names (when
# the input keys are statically known) and rejects the unification. Instead each pass is built as
# merge(<map-children>, <list-children>, <leaves>) where each part is computed by an independent filtered
# for-expression -- merge() is variadic and accepts heterogeneous objects.
# ---------------------------------------------------------------------------------------------------------------------

locals {
  sep         = var.separator
  expand_list = var.list_strategy == "indexed"

  seed = {
    for k, v in var.configuration_add_on :
    (var.prefix == "" ? k : "${trimsuffix(var.prefix, local.sep)}${local.sep}${k}") => v
  }
}

# ----- pass 1 -----
locals {
  p1_map_children = merge([
    for k, v in local.seed : { for ck, cv in v : "${k}${local.sep}${ck}" => cv }
    if can(keys(v))
  ]...)
  p1_list_children = merge([
    for k, v in local.seed : { for i, cv in tolist(v) : "${k}${local.sep}${i}" => cv }
    if local.expand_list && !can(keys(v)) && can(tolist(v))
  ]...)
  p1_leaves = {
    for k, v in local.seed : k => v
    if !can(keys(v)) && !(local.expand_list && can(tolist(v)))
  }
  p1 = merge(local.p1_map_children, local.p1_list_children, local.p1_leaves)
}

# ----- pass 2 -----
locals {
  p2_map_children  = merge([for k, v in local.p1 : { for ck, cv in v : "${k}${local.sep}${ck}" => cv } if can(keys(v))]...)
  p2_list_children = merge([for k, v in local.p1 : { for i, cv in tolist(v) : "${k}${local.sep}${i}" => cv } if local.expand_list && !can(keys(v)) && can(tolist(v))]...)
  p2_leaves        = { for k, v in local.p1 : k => v if !can(keys(v)) && !(local.expand_list && can(tolist(v))) }
  p2               = merge(local.p2_map_children, local.p2_list_children, local.p2_leaves)
}

# ----- pass 3 -----
locals {
  p3_map_children  = merge([for k, v in local.p2 : { for ck, cv in v : "${k}${local.sep}${ck}" => cv } if can(keys(v))]...)
  p3_list_children = merge([for k, v in local.p2 : { for i, cv in tolist(v) : "${k}${local.sep}${i}" => cv } if local.expand_list && !can(keys(v)) && can(tolist(v))]...)
  p3_leaves        = { for k, v in local.p2 : k => v if !can(keys(v)) && !(local.expand_list && can(tolist(v))) }
  p3               = merge(local.p3_map_children, local.p3_list_children, local.p3_leaves)
}

# ----- pass 4 -----
locals {
  p4_map_children  = merge([for k, v in local.p3 : { for ck, cv in v : "${k}${local.sep}${ck}" => cv } if can(keys(v))]...)
  p4_list_children = merge([for k, v in local.p3 : { for i, cv in tolist(v) : "${k}${local.sep}${i}" => cv } if local.expand_list && !can(keys(v)) && can(tolist(v))]...)
  p4_leaves        = { for k, v in local.p3 : k => v if !can(keys(v)) && !(local.expand_list && can(tolist(v))) }
  p4               = merge(local.p4_map_children, local.p4_list_children, local.p4_leaves)
}

# ----- pass 5 -----
locals {
  p5_map_children  = merge([for k, v in local.p4 : { for ck, cv in v : "${k}${local.sep}${ck}" => cv } if can(keys(v))]...)
  p5_list_children = merge([for k, v in local.p4 : { for i, cv in tolist(v) : "${k}${local.sep}${i}" => cv } if local.expand_list && !can(keys(v)) && can(tolist(v))]...)
  p5_leaves        = { for k, v in local.p4 : k => v if !can(keys(v)) && !(local.expand_list && can(tolist(v))) }
  p5               = merge(local.p5_map_children, local.p5_list_children, local.p5_leaves)
}

# ----- pass 6 -----
locals {
  p6_map_children  = merge([for k, v in local.p5 : { for ck, cv in v : "${k}${local.sep}${ck}" => cv } if can(keys(v))]...)
  p6_list_children = merge([for k, v in local.p5 : { for i, cv in tolist(v) : "${k}${local.sep}${i}" => cv } if local.expand_list && !can(keys(v)) && can(tolist(v))]...)
  p6_leaves        = { for k, v in local.p5 : k => v if !can(keys(v)) && !(local.expand_list && can(tolist(v))) }
  p6               = merge(local.p6_map_children, local.p6_list_children, local.p6_leaves)
}

# ----- pass 7 -----
locals {
  p7_map_children  = merge([for k, v in local.p6 : { for ck, cv in v : "${k}${local.sep}${ck}" => cv } if can(keys(v))]...)
  p7_list_children = merge([for k, v in local.p6 : { for i, cv in tolist(v) : "${k}${local.sep}${i}" => cv } if local.expand_list && !can(keys(v)) && can(tolist(v))]...)
  p7_leaves        = { for k, v in local.p6 : k => v if !can(keys(v)) && !(local.expand_list && can(tolist(v))) }
  p7               = merge(local.p7_map_children, local.p7_list_children, local.p7_leaves)
}

# ----- pass 8 -----
locals {
  p8_map_children  = merge([for k, v in local.p7 : { for ck, cv in v : "${k}${local.sep}${ck}" => cv } if can(keys(v))]...)
  p8_list_children = merge([for k, v in local.p7 : { for i, cv in tolist(v) : "${k}${local.sep}${i}" => cv } if local.expand_list && !can(keys(v)) && can(tolist(v))]...)
  p8_leaves        = { for k, v in local.p7 : k => v if !can(keys(v)) && !(local.expand_list && can(tolist(v))) }
  p8               = merge(local.p8_map_children, local.p8_list_children, local.p8_leaves)
}

# ----- pass 9 -----
locals {
  p9_map_children  = merge([for k, v in local.p8 : { for ck, cv in v : "${k}${local.sep}${ck}" => cv } if can(keys(v))]...)
  p9_list_children = merge([for k, v in local.p8 : { for i, cv in tolist(v) : "${k}${local.sep}${i}" => cv } if local.expand_list && !can(keys(v)) && can(tolist(v))]...)
  p9_leaves        = { for k, v in local.p8 : k => v if !can(keys(v)) && !(local.expand_list && can(tolist(v))) }
  p9               = merge(local.p9_map_children, local.p9_list_children, local.p9_leaves)
}

# ----- pass 10 -----
locals {
  p10_map_children  = merge([for k, v in local.p9 : { for ck, cv in v : "${k}${local.sep}${ck}" => cv } if can(keys(v))]...)
  p10_list_children = merge([for k, v in local.p9 : { for i, cv in tolist(v) : "${k}${local.sep}${i}" => cv } if local.expand_list && !can(keys(v)) && can(tolist(v))]...)
  p10_leaves        = { for k, v in local.p9 : k => v if !can(keys(v)) && !(local.expand_list && can(tolist(v))) }
  p10               = merge(local.p10_map_children, local.p10_list_children, local.p10_leaves)
}

# ----- pass 11 -----
locals {
  p11_map_children  = merge([for k, v in local.p10 : { for ck, cv in v : "${k}${local.sep}${ck}" => cv } if can(keys(v))]...)
  p11_list_children = merge([for k, v in local.p10 : { for i, cv in tolist(v) : "${k}${local.sep}${i}" => cv } if local.expand_list && !can(keys(v)) && can(tolist(v))]...)
  p11_leaves        = { for k, v in local.p10 : k => v if !can(keys(v)) && !(local.expand_list && can(tolist(v))) }
  p11               = merge(local.p11_map_children, local.p11_list_children, local.p11_leaves)
}

# ----- pass 12 -----
locals {
  p12_map_children  = merge([for k, v in local.p11 : { for ck, cv in v : "${k}${local.sep}${ck}" => cv } if can(keys(v))]...)
  p12_list_children = merge([for k, v in local.p11 : { for i, cv in tolist(v) : "${k}${local.sep}${i}" => cv } if local.expand_list && !can(keys(v)) && can(tolist(v))]...)
  p12_leaves        = { for k, v in local.p11 : k => v if !can(keys(v)) && !(local.expand_list && can(tolist(v))) }
  p12               = merge(local.p12_map_children, local.p12_list_children, local.p12_leaves)
}

# ----- pass 13 -----
locals {
  p13_map_children  = merge([for k, v in local.p12 : { for ck, cv in v : "${k}${local.sep}${ck}" => cv } if can(keys(v))]...)
  p13_list_children = merge([for k, v in local.p12 : { for i, cv in tolist(v) : "${k}${local.sep}${i}" => cv } if local.expand_list && !can(keys(v)) && can(tolist(v))]...)
  p13_leaves        = { for k, v in local.p12 : k => v if !can(keys(v)) && !(local.expand_list && can(tolist(v))) }
  p13               = merge(local.p13_map_children, local.p13_list_children, local.p13_leaves)
}

# ----- pass 14 -----
locals {
  p14_map_children  = merge([for k, v in local.p13 : { for ck, cv in v : "${k}${local.sep}${ck}" => cv } if can(keys(v))]...)
  p14_list_children = merge([for k, v in local.p13 : { for i, cv in tolist(v) : "${k}${local.sep}${i}" => cv } if local.expand_list && !can(keys(v)) && can(tolist(v))]...)
  p14_leaves        = { for k, v in local.p13 : k => v if !can(keys(v)) && !(local.expand_list && can(tolist(v))) }
  p14               = merge(local.p14_map_children, local.p14_list_children, local.p14_leaves)
}

# ----- pass 15 -----
locals {
  p15_map_children  = merge([for k, v in local.p14 : { for ck, cv in v : "${k}${local.sep}${ck}" => cv } if can(keys(v))]...)
  p15_list_children = merge([for k, v in local.p14 : { for i, cv in tolist(v) : "${k}${local.sep}${i}" => cv } if local.expand_list && !can(keys(v)) && can(tolist(v))]...)
  p15_leaves        = { for k, v in local.p14 : k => v if !can(keys(v)) && !(local.expand_list && can(tolist(v))) }
  p15               = merge(local.p15_map_children, local.p15_list_children, local.p15_leaves)
}

# ----- final stringification -----
# SSM Parameter Store stores strings only. Lists/maps that survived (json strategy, or list values when
# expand_list = false) are JSON-encoded; primitives are coerced to string.
locals {
  flattened_configuration_add_on = {
    for k, v in local.p15 :
    k => (can(keys(v)) || can(tolist(v))) ? jsonencode(v) : tostring(v)
  }
}

# Fail loudly if the input nests deeper than the ladder above can handle.
check "max_depth_not_exceeded" {
  assert {
    condition = alltrue([
      for v in values(local.p15) :
      !can(keys(v)) && (!local.expand_list || !can(tolist(v)))
    ])
    error_message = "configuration_add_on nests deeper than the supported max depth (15). Extend the pN ladder in shared/complex_map_to_simple_map/main.tf."
  }
}
