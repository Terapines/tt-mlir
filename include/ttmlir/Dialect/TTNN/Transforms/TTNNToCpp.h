// SPDX-FileCopyrightText: © 2024 Tenstorrent Inc.
//
// SPDX-License-Identifier: Apache-2.0

#ifndef TTMLIR_TTMLIR_DIALECT_TTNN_TRANSFORMS_KERNELSTOCPP_H
#define TTMLIR_TTMLIR_DIALECT_TTNN_TRANSFORMS_KERNELSTOCPP_H

#include "mlir/Support/LogicalResult.h"

#include "ttmlir/Dialect/TTNN/IR/TTNNOps.h"

namespace mlir::tt::ttnn {
LogicalResult emitTTNNModuleAsCpp(ModuleOp module, llvm::raw_ostream &os);
} // namespace mlir::tt::ttnn
#endif