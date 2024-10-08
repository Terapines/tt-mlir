// SPDX-FileCopyrightText: (c) 2024 Tenstorrent AI ULC
//
// SPDX-License-Identifier: Apache-2.0

#ifndef TTNN_RUNTIME_FROM_DEVICE_H
#define TTNN_RUNTIME_FROM_DEVICE_H

#include "tt/runtime/ttnn/types.h"
#include "ttmlir/Target/TTNN/program_generated.h"

namespace tt::runtime::ttnn::operations::layout {
void run(const ::tt::target::ttnn::FromDeviceOp *op, ProgramContext &context);
} // namespace tt::runtime::ttnn::operations::layout

#endif // TTNN_RUNTIME_FROM_DEVICE_H
