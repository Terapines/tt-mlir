// RUN: ttmlir-opt --ttir-load-system-desc --ttir-implicit-device --ttir-layout --ttnn-open-device --convert-ttir-to-ttnn %s  > %t.mlir
// RUN: FileCheck %s --input-file=%t.mlir
// RUN: ttmlir-translate --ttnn-to-flatbuffer %t.mlir > %t.ttnn

#any_device = #tt.operand_constraint<dram|l1|scalar|tile|any_device|any_device_tile>

func.func @subtract(%arg0: tensor<64x128xf32>, %arg1: tensor<64x128xf32>) -> tensor<64x128xf32> {
  // CHECK: %[[C:.*]] = "ttnn.open_device"[[C:.*]]
  // CHECK: %[[C:.*]] = "ttnn.full"[[C:.*]]
  %0 = tensor.empty() : tensor<64x128xf32>
  // CHECK: %[[C:.*]] = "ttnn.to_memory_config"[[C:.*]]
  // CHECK: %[[C:.*]] = "ttnn.subtract"[[C:.*]]
  %1 = "ttir.subtract"(%arg0, %arg1, %0) <{operandSegmentSizes = array<i32: 2, 1>, operand_constraints = [#any_device, #any_device, #any_device]}> : (tensor<64x128xf32>, tensor<64x128xf32>, tensor<64x128xf32>) -> tensor<64x128xf32>
  // CHECK: %[[C:.*]] = "ttnn.to_memory_config"[[C:.*]]
  // CHECK: "ttnn.close_device"[[C:.*]]
  return %1 : tensor<64x128xf32>
}

func.func @multiply(%arg0: tensor<64x128xf32>, %arg1: tensor<64x128xf32>) -> tensor<64x128xf32> {
  // CHECK: %[[C:.*]] = "ttnn.open_device"[[C:.*]]
  // CHECK: %[[C:.*]] = "ttnn.full"[[C:.*]]
  %0 = tensor.empty() : tensor<64x128xf32>
  // CHECK: %[[C:.*]] = "ttnn.to_memory_config"[[C:.*]]
  // CHECK: %[[C:.*]] = "ttnn.multiply"[[C:.*]]
  %1 = "ttir.multiply"(%arg0, %arg1, %0) <{operandSegmentSizes = array<i32: 2, 1>, operand_constraints = [#any_device, #any_device, #any_device]}> : (tensor<64x128xf32>, tensor<64x128xf32>, tensor<64x128xf32>) -> tensor<64x128xf32>
  // CHECK: %[[C:.*]] = "ttnn.to_memory_config"[[C:.*]]
  // CHECK: "ttnn.close_device"[[C:.*]]
  return %1 : tensor<64x128xf32>
}

func.func @relu(%arg0: tensor<64x128xf32>) -> tensor<64x128xf32> {
  // CHECK: %[[C:.*]] = "ttnn.open_device"[[C:.*]]
  // CHECK: %[[C:.*]] = "ttnn.full"[[C:.*]]
  %0 = tensor.empty() : tensor<64x128xf32>
  // CHECK: %[[C:.*]] = "ttnn.to_memory_config"[[C:.*]]
  // CHECK: %[[C:.*]] = "ttnn.relu"[[C:.*]]
  %1 = "ttir.relu"(%arg0, %0) <{operandSegmentSizes = array<i32: 1, 1>, operand_constraints = [#any_device, #any_device]}> : (tensor<64x128xf32>, tensor<64x128xf32>) -> tensor<64x128xf32>
  // CHECK: %[[C:.*]] = "ttnn.to_memory_config"[[C:.*]]
  // CHECK: "ttnn.close_device"[[C:.*]]
  return %1 : tensor<64x128xf32>
}

func.func @ge(%arg0: tensor<64x128xf32>, %arg1: tensor<64x128xf32>) -> tensor<64x128xf32> {
  // CHECK: %[[C:.*]] = "ttnn.open_device"[[C:.*]]
  // CHECK: %[[C:.*]] = "ttnn.full"[[C:.*]]
  %0 = tensor.empty() : tensor<64x128xf32>
  // CHECK: %[[C:.*]] = "ttnn.to_memory_config"[[C:.*]]
  // CHECK: %[[C:.*]] = "ttnn.ge"[[C:.*]]
  %1 = "ttir.ge"(%arg0, %arg1, %0) <{operandSegmentSizes = array<i32: 2, 1>, operand_constraints = [#any_device, #any_device, #any_device]}> : (tensor<64x128xf32>, tensor<64x128xf32>, tensor<64x128xf32>) -> tensor<64x128xf32>
  // CHECK: %[[C:.*]] = "ttnn.to_memory_config"[[C:.*]]
  // CHECK: "ttnn.close_device"[[C:.*]]
  return %1 : tensor<64x128xf32>
}