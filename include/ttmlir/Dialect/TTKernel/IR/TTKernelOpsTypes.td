// SPDX-FileCopyrightText: (c) 2024 Tenstorrent AI ULC
//
// SPDX-License-Identifier: Apache-2.0

#ifndef TTMLIR_TTMLIR_DIALECT_TTKERNEL_TTKERNELOPSTYPES_TD
#define TTMLIR_TTMLIR_DIALECT_TTKERNEL_TTKERNELOPSTYPES_TD

include "ttmlir/Dialect/TTKernel/IR/TTKernelBase.td"
include "ttmlir/Dialect/TTKernel/IR/TTKernelOpsEnums.td"
include "ttmlir/Dialect/TTKernel/IR/TTKernelAttrInterfaces.td"

//===----------------------------------------------------------------------===//
// TTKernel type definitions
//===----------------------------------------------------------------------===//

class TTKernel_Type<string name, string typeMnemonic, list<Trait> traits = []>
    : TypeDef<TTKernel_Dialect, name, traits> {
  let mnemonic = typeMnemonic;
}

class TTKernel_Attr<string name, string attrMnemonic, list<Trait> traits = [],
                   string baseCppClass = "::mlir::Attribute">
    : AttrDef<TTKernel_Dialect, name, traits, baseCppClass> {
  let mnemonic = attrMnemonic;
  let attrName = "ttkernel." # attrMnemonic;
}

def TTKernel_TensixConfigAttr: TTKernel_Attr<"TensixConfig", "tensix_config", [TTKernel_KernelConfigInterface]> {
  let summary = "TT TensixConfig attribute";
  let description = [{
    TT compute_desc attribute
  }];
  let parameters = (ins "MathFidelity":$math_fidelity,
                        "bool":$fp32_dest_acc_en,
                        "bool":$preserve_fp32_precision,
                        "bool":$math_approx_mode);
  let assemblyFormat =  "`<` $math_fidelity`,` $fp32_dest_acc_en`,` $preserve_fp32_precision`,` $math_approx_mode `>`";

  let extraClassDeclaration = [{
    static TensixConfigAttr get(::mlir::MLIRContext *context){
      return TensixConfigAttr::get(context, MathFidelity::HiFi4, false, false, false);
    };

    ThreadType getThreadType() const { return ThreadType::Tensix; }
  }];
}

def TTKernel_NocConfigAttr: TTKernel_Attr<"NocConfig", "noc_config", [TTKernel_KernelConfigInterface]> {
  let summary = "TT NocConfig attribute";
  let description = [{
    TT noc_config attribute
  }];
  let parameters = (ins "NocIndex":$noc_index);
  let assemblyFormat = "`<` $noc_index `>`";
  let extraClassDeclaration = [{
    ThreadType getThreadType() const { return ThreadType::Noc; }
  }];
}

def TTKernel_EthernetConfigAttr: TTKernel_Attr<"EthernetConfig", "ethernet_config", [TTKernel_KernelConfigInterface]> {
  let summary = "TT EthernetConfig attribute";
  let description = [{
    TT ethernet_config attribute
  }];
  let parameters = (ins "EthType":$eth_type,
                        "NocIndex":$noc_index);
  let assemblyFormat = "`<` $eth_type`,` $noc_index `>`";
  let extraClassDeclaration = [{
    ThreadType getThreadType() const { return ThreadType::Ethernet; }
  }];
}

def TTKernel_KernelConfigAttr : AnyAttrOf<[TTKernel_TensixConfigAttr, TTKernel_NocConfigAttr, TTKernel_EthernetConfigAttr]>;

def TTKernel_KernelConfigArrayAttr : TypedArrayAttrBase<TTKernel_KernelConfigAttr, "">;

def TTKernel_CB : TTKernel_Type<"CB", "cb"> {
    let summary = "TTKernel cb";
    let description = "Circular buffer type in TTKernel dialect";
    let parameters = (ins "CBPort":$port,
                          "uint64_t":$address,
                          "MemRefType":$memref,
                          "uint64_t":$page_size,
                          "uint64_t":$num_buffers);
    let assemblyFormat = "`<` $port`,` $address`,` $memref`,` $page_size`,` $num_buffers `>`";

    let extraClassDeclaration = [{
        static CBType get(::mlir::MLIRContext *context,
                              CBPort port,
                              uint64_t address,
                              MemRefType memref) {
          uint64_t numBuffers = 1;
          uint64_t pageSize = 0;
          if (::mlir::isa<::mlir::tt::TileType>(memref.getElementType())) {
            pageSize = ::mlir::cast<::mlir::tt::TileType>(memref.getElementType()).getSizeBytes();
          } else {
            pageSize = memref.getShape().back() * (memref.getElementType().getIntOrFloatBitWidth() / 8);
          }
          return CBType::get(context, port, address, memref, pageSize, numBuffers);
        }

        ::llvm::ArrayRef<int64_t> getShape() const {
          return getMemref().getShape();
        }
    }];
}

def TTKernel_NocAddr : TTKernel_Type<"NocAddr", "noc_addr"> {
    let summary = "TTKernel noc address";
    let description = "Noc address type in TTKernel dialect";
}

def TTKernel_ThreadTypeAttr : EnumAttr<TTKernel_Dialect, TTKernel_ThreadType, "thread"> {
  let assemblyFormat = "`<` $value `>`";
}

def TTKernel_ThreadTypeArrayAttr : TypedArrayAttrBase<TTKernel_ThreadTypeAttr, "">;

#endif
