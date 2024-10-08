// SPDX-FileCopyrightText: (c) 2024 Tenstorrent AI ULC
//
// SPDX-License-Identifier: Apache-2.0

#ifndef TTMLIR_TTMLIR_DIALECT_TTIR_TTIROPS_TD
#define TTMLIR_TTMLIR_DIALECT_TTIR_TTIROPS_TD

include "ttmlir/Dialect/TT/IR/TTOpsTypes.td"
include "ttmlir/Dialect/TTIR/IR/TTIRBase.td"
include "ttmlir/Dialect/TTIR/IR/TTIROpsInterfaces.td"
include "mlir/Dialect/Linalg/IR/LinalgBase.td"
include "mlir/Interfaces/InferTypeOpInterface.td"
include "mlir/Interfaces/DestinationStyleOpInterface.td"
include "mlir/Interfaces/ControlFlowInterfaces.td"
include "mlir/Interfaces/SideEffectInterfaces.td"
include "mlir/IR/CommonTypeConstraints.td"
include "mlir/IR/CommonAttrConstraints.td"
include "mlir/IR/OpBase.td"

class TTIR_DPSOp<string mnemonic, list<Trait> traits = []> :
    TTIR_Op<mnemonic, !listconcat(traits, [TTIROpInterface, DestinationStyleOpInterface])> {
    let extraClassDeclaration = [{
      MutableOperandRange getDpsInitsMutable() { return getOutputsMutable(); }
    }];
}

//===----------------------------------------------------------------------===//
// TTIR top level ops
//===----------------------------------------------------------------------===//

def TTIR_GenericOp : TTIR_DPSOp<"generic", [AttrSizedOperandSegments]> {
    let summary = "Generically dispatch work to a grid of cores.";
    let description = [{
      This generic op carries a region that represents the work each core does. The region is
      expected to have the same signature as the op itself. The op is expected to be lowered
      to a backend specific form by a consuming backend. This op is heavily inspired by the
      linalg.generic op so it can be useful to refer to linalg.generic documentation for more
      details.

      ```llvm
      %5 = "ttir.generic"(%1, %3, %4) <{
        grid = #tt.grid<1x1>,                     // The grid range of cores to dispatch work to.
        indexing_maps = [#map, #map, #map],       // Affine maps for indexing into the input/output tensors. See linalg.generic
        iterator_types = [#parallel, #parallel],  // Iterator types for the input/output tensors. See linalg.generic
        operandSegmentSizes = array<i32: 2, 1>,   // Sizes of the operand segments, i.e. 2 inputs and 1 output.
      ({
      ^bb0(%arg2: memref<64x128xf32, #l1_>, %arg3: memref<64x128xf32, #l1_>, %arg4: memref<64x128xf32, #l1_>):
          // Region body, would contain some computation that represents the work each core does.
      }) : (tensor<64x128xf32, #layout1>, tensor<64x128xf32, #layout1>, tensor<64x128xf32, #layout1>) -> tensor<64x128xf32, #layout1>
      ```
    }];

    let arguments = (ins Variadic<AnyRankedTensor>:$inputs,
                         Variadic<AnyRankedTensor>:$outputs,
                         TT_GridAttr:$grid,
                         AffineMapArrayAttr:$indexing_maps,
                         TT_IteratorTypeArrayAttr:$iterator_types,
                         TT_OperandConstraintArrayAttr:$operand_constraints);
    let results = (outs Variadic<AnyRankedTensor>:$results);
    let regions = (region AnyRegion:$region);
    let hasVerifier = 1;
}

def TTIR_ToLayoutOp : TTIR_Op<"to_layout", [DestinationStyleOpInterface, TTIROpInterface]> {
    let summary = "Layout op.";
    let description = [{
      ToLayout operation, transition tensors from one layout to another.  Some examples include:
        - Transitioning between different memory spaces, e.g. DRAM to L1.
        - Transitioning between different data types, e.g. f32 to f16.
        - Transitioning between different tile sizes, e.g. 1x16 to 32x32
        - Transitioning between different tensor sharding
        - Some combination of the above

      ```llvm
      #layout = #tt.layout<8192x128x1, undef, <1x1>, memref<64x128xf32, #system>>
      #layout1 = #tt.layout<8192x128x1, undef, <1x1>, memref<64x128xf32, #l1_>>
      %1 = "ttir.to_layout"(%arg0, %0) : (tensor<64x128xf32, #layout>, tensor<64x128xf32, #layout1>) -> tensor<64x128xf32, #layout1>
      ```
    }];

    let arguments = (ins AnyRankedTensor:$input,
                         AnyRankedTensor:$output);
    let results = (outs AnyRankedTensor:$result);

    let extraClassDeclaration = [{
      MutableOperandRange getDpsInitsMutable() { return getOutputMutable(); }
      ArrayAttr getOperandConstraints() {
        return nullptr;
        // TODO return below, but we need a way to properly create an ArrayAttr:
        // return {OperandConstraint::Any, OperandConstraint::Any};
      }

      struct CompoundComponents {
        bool isLayoutChange;
        bool isGridChange;
        bool isFormatChange;
        bool isMemorySpaceChange;
        bool isMemoryLayoutChange;
      };

      // Returns booleans indicating if the op changes layout, grid, format, memory space or memory layout.
      CompoundComponents compoundComponents();
    }];

    let hasVerifier = 1;
}

def TTIR_AllocOp : TTIR_Op<"alloc"> {
    let summary = "Alloc op.";
    let description = [{
      Tensor Alloc operation
    }];

    let arguments = (ins I64Attr:$address, I64Attr:$size, TT_MemorySpaceAttr:$memory_space);
    let results = (outs AnyRankedTensor:$result);

    let hasVerifier = 1;
}

def TTIR_DeallocOp : TTIR_Op<"dealloc"> {
    let summary = "Dealloc op.";
    let description = [{
      Tensor Dealloc operation
    }];

    let arguments = (ins AnyRankedTensor:$result);
}

//===----------------------------------------------------------------------===//
// TTIR top level named ops
//===----------------------------------------------------------------------===//

class TTIR_ElementwiseOp<string mnemonic, list<Trait> traits = []> :
    TTIR_DPSOp<mnemonic, !listconcat(traits, [AttrSizedOperandSegments, TTIR_ElementwiseOpInterface])> {

    let description = [{
      Base class for elementwise operations. Elementwise operations can take inputs with different shape,
      as long as the input tensors are broadcastable to the same shape.
    }];

    let arguments = (ins Variadic<AnyRankedTensor>:$inputs,
                         Variadic<AnyRankedTensor>:$outputs,
                         TT_OperandConstraintArrayAttr:$operand_constraints);
    let results = (outs Variadic<AnyRankedTensor>:$results);
}

class TTIR_ElementwiseUnaryOp<string mnemonic, list<Trait> traits = []> :
    TTIR_ElementwiseOp<mnemonic, traits> {
    let summary = "Eltwise unary op.";
    let description = [{
      Eltwise unary op.
    }];

    let builders =
    [
      OpBuilder<(ins "Value": $in, "Value": $out, "ArrayAttr": $operand_constraints),
      [{
        build($_builder, $_state, {out.getType()}, in, out, operand_constraints);
      }]>
    ];
}

def TTIR_AbsOp: TTIR_ElementwiseUnaryOp<"abs"> {
    let summary = "Eltwise absolute op.";
    let description = [{
      Eltwise absolute operation.
    }];
}

def TTIR_TypecastOp: TTIR_ElementwiseUnaryOp<"typecast"> {
    let summary = "Eltwise cast op.";
    let description = [{
      Eltwise cast operation.
    }];
}

def TTIR_SqrtOp : TTIR_ElementwiseUnaryOp<"sqrt"> {
    let summary = "Eltwise square root.";
    let description = [{
      Eltwise square root operation.
    }];
}

def TTIR_RsqrtOp : TTIR_ElementwiseUnaryOp<"rsqrt"> {
    let summary = "Eltwise reciprocal square root.";
    let description = [{
      Eltwise reciprocal square root operation.
    }];
}

def TTIR_NegOp: TTIR_ElementwiseUnaryOp<"neg"> {
    let summary = "Eltwise negate op.";
    let description = [{
      Eltwise negate operation.
    }];
}

def TTIR_ReciprocalOp : TTIR_ElementwiseUnaryOp<"reciprocal"> {
    let summary = "Eltwise reciprocal.";
    let description = [{
      Eltwise reciprocal operation.
    }];
}

def TTIR_ReluOp : TTIR_ElementwiseUnaryOp<"relu"> {
    let summary = "Eltwise ReLU.";
    let description = [{
      Eltwise ReLU operation.
    }];
}

def TTIR_SigmoidOp: TTIR_ElementwiseUnaryOp<"sigmoid"> {
    let summary = "Eltwise sigmoid.";
    let description = [{
      Eltwise sigmoid operation.
    }];
}

class TTIR_ElementwiseBinaryOp<string mnemonic, list<Trait> traits = []> :
    TTIR_ElementwiseOp<mnemonic, traits> {
    let summary = "Eltwise binary op.";
    let description = [{
      Eltwise binary op.
    }];

    let builders =
    [
      OpBuilder<(ins "Value": $lhs, "Value": $rhs, "Value": $out, "ArrayAttr": $operand_constraints),
      [{
        build($_builder, $_state, {out.getType()}, {lhs, rhs}, out, operand_constraints);
      }]>
    ];
}

def TTIR_SubtractOp : TTIR_ElementwiseBinaryOp<"subtract"> {
    let summary = "Eltwise subtract.";
    let description = [{
      Eltwise subtract operation.
    }];
}

def TTIR_EqualOp : TTIR_ElementwiseBinaryOp<"eq"> {
    let summary = "Eltwise equal to.";
    let description = [{
      Eltwise equal to operation.
    }];
}

def TTIR_NotEqualOp : TTIR_ElementwiseBinaryOp<"ne"> {
    let summary = "Eltwise not equal to.";
    let description = [{
      Eltwise not equal to operation.
    }];
}

def TTIR_GreaterEqualOp : TTIR_ElementwiseBinaryOp<"ge"> {
    let summary = "Eltwise greater than or equal to.";
    let description = [{
      Eltwise greater than or equal to operation.
    }];
}

def TTIR_GreaterThanOp : TTIR_ElementwiseBinaryOp<"gt"> {
    let summary = "Eltwise greater than.";
    let description = [{
      Eltwise greater than operation.
    }];
}

def TTIR_LessEqualOp : TTIR_ElementwiseBinaryOp<"le"> {
    let summary = "Eltwise less than or equal to.";
    let description = [{
      Eltwise less than or equal to operation.
    }];
}

def TTIR_LessThanOp : TTIR_ElementwiseBinaryOp<"lt"> {
    let summary = "Eltwise less than.";
    let description = [{
      Eltwise less than operation.
    }];
}

def TTIR_MaximumOp :  TTIR_ElementwiseBinaryOp<"maximum"> {
    let summary = "Eltwise maximum OP.";
    let description = [{
      Calculates maximum of input tensors' values element-wise and stores result in output tensor.

      Example:
        %lhs: [[3, 2, 7], [1, 4, 4]]
        %rhs: [[1, 4, 2], [1, 2, 3]]
        "ttir.maximum"(%lhs, %rhs, %out) -> %out: [[3, 4, 7], [1, 4, 4]]
    }];
}

class TTIR_ReductionOp<string mnemonic, list<Trait> traits = []> : TTIR_DPSOp<mnemonic, traits> {
    let summary = "Reduction op.";
    let description = [{
      Reduction op.
    }];

    let arguments = (ins AnyRankedTensor:$input,
                         AnyRankedTensor:$output,
                         BoolAttr:$keep_dim,
                         OptionalAttr<I32ArrayAttr>:$dim_arg,
                         TT_OperandConstraintArrayAttr:$operand_constraints);

    let results = (outs AnyRankedTensor:$result);

    let extraClassDeclaration = [{
      MutableOperandRange getDpsInitsMutable() { return getOutputMutable(); }
    }];
}

def TTIR_SumOp : TTIR_ReductionOp<"sum"> {
    let summary = "Sum reduction op.";
    let description = [{
      Sum reduction op.
    }];
}

def TTIR_MeanOp : TTIR_ReductionOp<"mean"> {
  let summary = "Mean reduction op.";
  let description = [{
    Mean reduction op.
  }];
}

def TTIR_MaxOp : TTIR_ReductionOp<"max"> {
  let summary = "Max reduction op.";
  let description = [{
    Max reduction op.
  }];
}

def TTIR_EmbeddingOp : TTIR_DPSOp<"embedding"> {
    let summary = "Embedding op.";
    let description = [{
      Embedding operation.
    }];

    let arguments = (ins AnyRankedTensor:$input,
                         AnyRankedTensor:$weight,
                         AnyRankedTensor:$output,
                         TT_OperandConstraintArrayAttr:$operand_constraints);

    let results = (outs AnyRankedTensor:$result);

    let extraClassDeclaration = [{
      MutableOperandRange getDpsInitsMutable() { return getOutputMutable(); }
    }];

    let hasVerifier = 1;
}

def TTIR_SoftmaxOp : TTIR_DPSOp<"softmax"> {
    let summary = "Softmax operation.";
    let description = [{
      Softmax operation.
    }];

    let arguments = (ins AnyRankedTensor:$input,
                         AnyRankedTensor:$output,
                         SI32Attr:$dimension,
                         TT_OperandConstraintArrayAttr:$operand_constraints);

    let results = (outs AnyRankedTensor:$result);

    let extraClassDeclaration = [{
      MutableOperandRange getDpsInitsMutable() { return getOutputMutable(); }
    }];

    let hasVerifier = 1;
}

def TTIR_TransposeOp : TTIR_DPSOp<"transpose"> {
    let summary = "Transpose op.";
    let description = [{
      Transpose tensor along two given dimensions.
    }];

    let arguments = (ins AnyRankedTensor:$input,
                         AnyRankedTensor:$output,
                         SI32Attr:$dim0,
                         SI32Attr:$dim1,
                         TT_OperandConstraintArrayAttr:$operand_constraints);

    let results = (outs AnyRankedTensor:$result);

    let extraClassDeclaration = [{
      MutableOperandRange getDpsInitsMutable() { return getOutputMutable(); }
    }];

    let hasVerifier = 1;
}

def TTIR_ConcatOp : TTIR_DPSOp<"concat"> {
    let summary = "Concat op.";
    let description = [{
      Concat tensors along a given dimension.
    }];

    let arguments = (ins Variadic<AnyRankedTensor>:$inputs,
                         AnyRankedTensor:$output,
                         SI32Attr:$dim,

    TT_OperandConstraintArrayAttr:$operand_constraints);

    let results = (outs AnyRankedTensor:$result);

    let extraClassDeclaration = [{
      MutableOperandRange getDpsInitsMutable() { return getOutputMutable(); }
    }];

    let hasVerifier = 1;
}

def TTIR_BroadcastOp : TTIR_DPSOp<"broadcast"> {
    let summary = "Broadcast operation.";
    let description = [{
      Broadcast op.
    }];

    let arguments = (ins AnyRankedTensor:$input,
                         AnyRankedTensor:$output,
                         I64ArrayAttr:$dimension,
                         TT_OperandConstraintArrayAttr:$operand_constraints);

    let results = (outs AnyRankedTensor:$result);

    let extraClassDeclaration = [{
      MutableOperandRange getDpsInitsMutable() { return getOutputMutable(); }
    }];
}

def TTIR_Conv2dOp : TTIR_DPSOp<"conv2d"> {
    let summary = "Conv2d operation.";
    let description = [{
     Applies a 2D convolution over an input image composed of several input planes.
    }];

    let arguments = (ins AnyRankedTensor:$input,
                         AnyRankedTensor:$weight,
                         Optional<AnyRankedTensor>:$bias,
                         AnyRankedTensor:$output,
                         SI32Attr:$stride_height,
                         SI32Attr:$stride_width,
                         SI32Attr:$dilation_height,
                         SI32Attr:$dilation_width,
                         SI32Attr:$groups,
                         SI32Attr:$padding_left,
                         SI32Attr:$padding_right,
                         SI32Attr:$padding_top,
                         SI32Attr:$padding_bottom,
                         TT_OperandConstraintArrayAttr:$operand_constraints);

    let results = (outs AnyRankedTensor:$result);

    let extraClassDeclaration = [{
      MutableOperandRange getDpsInitsMutable() { return getOutputMutable(); }
    }];

    let hasVerifier = 1;
}

def TTIR_MaxPool2dOp : TTIR_DPSOp<"max_pool2d"> {
    let summary = "Applies a 2D max pooling over an input signal composed of several input planes.";
    let description = [{
      Applies a 2D max pooling over an input signal composed of several input planes.
    }];

    let arguments = (ins AnyRankedTensor:$input,
                         AnyRankedTensor:$output,
                         SI32Attr:$kernel_height,
                         SI32Attr:$kernel_width,
                         SI32Attr:$stride_height,
                         SI32Attr:$stride_width,
                         SI32Attr:$dilation_height,
                         SI32Attr:$dilation_width,
                         BoolAttr:$ceil_mode,
                         SI32Attr:$padding_left,
                         SI32Attr:$padding_right,
                         SI32Attr:$padding_top,
                         SI32Attr:$padding_bottom,
                         TT_OperandConstraintArrayAttr:$operand_constraints,
                         OptionalAttr<SI32Attr>:$original_height,
                         OptionalAttr<SI32Attr>:$original_width);

    let results = (outs AnyRankedTensor:$result);

    let extraClassDeclaration = [{
      MutableOperandRange getDpsInitsMutable() { return getOutputMutable(); }
    }];

    let hasVerifier = 1;
}

def TTIR_ReshapeOp: TTIR_DPSOp<"reshape"> {
    let summary = "Reshape op.";
    let description = [{
      Reshape tensor.
    }];

    let arguments = (ins AnyRankedTensor:$input,
                         AnyRankedTensor:$output,
                         I32ArrayAttr:$shape,
                         TT_OperandConstraintArrayAttr:$operand_constraints);

    let results = (outs AnyRankedTensor:$result);

    let extraClassDeclaration = [{
      MutableOperandRange getDpsInitsMutable() { return getOutputMutable(); }
    }];

    let hasVerifier = 1;
}

def TTIR_SqueezeOp : TTIR_DPSOp<"squeeze"> {
    let summary = "Squeeze op.";
    let description = [{
      Squeeze tensor.
    }];

    let arguments = (ins AnyRankedTensor:$input,
                         AnyRankedTensor:$output,
                         SI32Attr:$dim,
                         TT_OperandConstraintArrayAttr:$operand_constraints);

    let results = (outs AnyRankedTensor:$result);

    let extraClassDeclaration = [{
      MutableOperandRange getDpsInitsMutable() { return getOutputMutable(); }
    }];

    let hasVerifier = 1;
}

def TTIR_UnsqueezeOp : TTIR_DPSOp<"unsqueeze"> {
    let summary = "Unsqueeze op.";
    let description = [{
      Unsqueeze tensor.
    }];

    let arguments = (ins AnyRankedTensor:$input,
                         AnyRankedTensor:$output,
                         SI32Attr:$dim,
                         TT_OperandConstraintArrayAttr:$operand_constraints);

    let results = (outs AnyRankedTensor:$result);

    let extraClassDeclaration = [{
      MutableOperandRange getDpsInitsMutable() { return getOutputMutable(); }
    }];

    let hasVerifier = 1;
}

def TTIR_ConstantOp : TTIR_Op<"constant", [ConstantLike,
                                           AllShapesMatch<["value", "result"]>]> {
    let summary = "Constant op.";
    let description = [{
      Produces tensor filled with given constant value.

      Examples:
        %0 = "ttir.constant"() {value = dense<0> : tensor<2x3xi32>} : () -> tensor<2x3xi32>
        // %0: [[0, 0, 0], [0, 0, 0]]
        %1 = "ttir.constant"() {value = dense<[0.2, 1.3]> : tensor<2xf32>} : () -> tensor<2xf32>
        // %1: [0.2, 1.3]
    }];

    let arguments = (ins ElementsAttr:$value);

    let results = (outs AnyRankedTensor:$result);

    let hasFolder = 1;
}

def TTIR_FillOp : TTIR_DPSOp<"fill", [AllShapesMatch<["value", "result"]>]> {
    let summary = "Fill operation.";
    let description = [{
      Produces tensor filled with given fill value.

      Examples:
        %0 = tensor.empty() : () -> tensor<2x3xi32>
        %1 = "ttir.fill"(%0) {value = dense<0> : tensor<2x3xi32>} : () -> tensor<2x3xi32>
        %2 = tensor.empty() : () -> tensor<2xf32>
        %3 = "ttir.fill"(%2) {value = dense<[0.2, 1.3]> : tensor<2xf32>} : () -> tensor<2xf32>
    }];

    let arguments = (ins AnyRankedTensor:$output,
                         ElementsAttr:$value,
                         TT_OperandConstraintArrayAttr:$operand_constraints);

    let results = (outs AnyRankedTensor:$result);

    let extraClassDeclaration = [{
      MutableOperandRange getDpsInitsMutable() { return getOutputMutable(); }
    }];
}

// ANCHOR: adding_an_op_matmul_ttir
def TTIR_MatmulOp : TTIR_DPSOp<"matmul"> {
    let summary = "Matrix multiply operation.";
    let description = [{
      Matrix multiply operation.
    }];

    let arguments = (ins AnyRankedTensor:$a,
                         AnyRankedTensor:$b,
                         AnyRankedTensor:$output,
                         TT_OperandConstraintArrayAttr:$operand_constraints);

    let results = (outs AnyRankedTensor:$result);

    let extraClassDeclaration = [{
      MutableOperandRange getDpsInitsMutable() { return getOutputMutable(); }
    }];

    let hasVerifier = 1;
}
// ANCHOR_END: adding_an_op_matmul_ttir

//===----------------------------------------------------------------------===//
// TTIR top level generic ops
//===----------------------------------------------------------------------===//

class TTIR_GenericElementwiseUnaryOp<string mnemonic, list<Trait> traits = []> :
    TTIR_ElementwiseUnaryOp<mnemonic, !listconcat(traits, [TTIR_GenericRegionOpInterface])> {

    let extraClassDeclaration = [{
      MutableOperandRange getDpsInitsMutable() { return getOutputsMutable(); }

      void buildGenericRegion(::mlir::OpBuilder &opBuilder, ::mlir::Block* block);

      std::pair<::mlir::ArrayAttr, ::mlir::ArrayAttr> getIndexingMaps(Builder &builder) {
        assert(getNumOperands() == 2 && "Input and output operand must have the same rank");
        assert(sameRank(getOperands()) &&
               "Elementwise unary op must have only one input and one output operand.");

        auto rank = mlir::cast<RankedTensorType>(getOperand(0).getType()).getRank();

        SmallVector<AffineMap> indexingMaps(2, builder.getMultiDimIdentityMap(rank));
        SmallVector<Attribute> iteratorTypes(
            rank, builder.getAttr<IteratorTypeAttr>(IteratorType::Parallel));

        return {builder.getAffineMapArrayAttr(indexingMaps),
                builder.getArrayAttr(iteratorTypes)};
      }

      static bool sameRank(mlir::OperandRange operands) {
        if (operands.empty()) {
          return true;
        }
        auto rank = mlir::cast<RankedTensorType>(operands[0].getType()).getRank();
        for (auto operand : operands) {
          if (mlir::cast<RankedTensorType>(operand.getType()).getRank() != rank) {
            return false;
          }
        }
        return true;
      }
    }];
}

def TTIR_ExpOp: TTIR_GenericElementwiseUnaryOp<"exp"> {
    let summary = "Eltwise exponential op.";
    let description = [{
      Eltwise exponential operation. Calculates e^x for all elements x in input tensor.
    }];
}

class TTIR_GenericElementwiseBinaryOp<string mnemonic, list<Trait> traits = []> :
    TTIR_ElementwiseBinaryOp<mnemonic, !listconcat(traits, [TTIR_GenericRegionOpInterface])> {

    let extraClassDeclaration = [{
      MutableOperandRange getDpsInitsMutable() { return getOutputsMutable(); }

      void buildGenericRegion(::mlir::OpBuilder &opBuilder, ::mlir::Block* block);

      std::pair<::mlir::ArrayAttr, ::mlir::ArrayAttr> getIndexingMaps(Builder &builder) {
        assert(sameRank(getOperands()) &&
               "For now all operands must have the same rank");
        auto rank = mlir::cast<RankedTensorType>(getOperand(0).getType()).getRank();
        SmallVector<AffineMap> indexingMaps(getNumOperands(),
                                            builder.getMultiDimIdentityMap(rank));
        SmallVector<Attribute> iteratorTypes(
            rank, builder.getAttr<IteratorTypeAttr>(IteratorType::Parallel));
        return {builder.getAffineMapArrayAttr(indexingMaps),
                builder.getArrayAttr(iteratorTypes)};
      }

      static bool sameRank(mlir::OperandRange operands) {
        if (operands.empty()) {
          return true;
        }
        auto rank = mlir::cast<RankedTensorType>(operands[0].getType()).getRank();
        for (auto operand : operands) {
          if (mlir::cast<RankedTensorType>(operand.getType()).getRank() != rank) {
            return false;
          }
        }
        return true;
      }
    }];
}

def TTIR_AddOp : TTIR_GenericElementwiseBinaryOp<"add"> {
    let summary = "Eltwise add.";
    let description = [{
      Eltwise add operation.
    }];
}

def TTIR_MultiplyOp : TTIR_GenericElementwiseBinaryOp<"multiply"> {
    let summary = "Eltwise multiply.";
    let description = [{
      Eltwise multiply operation.
    }];
}

def TTIR_DivOp : TTIR_GenericElementwiseBinaryOp<"div"> {
    let summary = "Eltwise divide.";
    let description = [{
      Eltwise divide operation.
    }];
}

//===----------------------------------------------------------------------===//
// TTIR region ops (ops that may appear inside of ttir.generic region)
//===----------------------------------------------------------------------===//

def AnyRankedTensorOrMemRef: AnyTypeOf<[AnyRankedTensor, AnyNon0RankedMemRef]>;

def TTIR_KernelOp : TTIR_DPSOp<"kernel", [AttrSizedOperandSegments]> {
    let summary = "Kernel call.";
    let description = [{
      A generic kernel call operation. This operation is used to pattern match by some consuming backend.
    }];

    let arguments = (ins FlatSymbolRefAttr:$op,
                         FlatSymbolRefAttr:$kind,
                         Variadic<AnyRankedTensorOrMemRef>:$inputs,
                         Variadic<AnyRankedTensorOrMemRef>:$outputs,
                         TT_OperandConstraintArrayAttr:$operand_constraints);
    let results = (outs Variadic<AnyRankedTensorOrMemRef>:$results);
}

def TTIR_YieldOp : TTIR_Op<"yield", [Pure, ReturnLike, Terminator]> {
    let summary = "Yield op.";
    let description = [{
      Yield operation, this is required by MLIR to mark the end of a dispatch region.
    }];

    let arguments = (ins Variadic<AnyRankedTensorOrMemRef>:$values);
}

#endif
