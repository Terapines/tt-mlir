// SPDX-FileCopyrightText: (c) 2024 Tenstorrent AI ULC
//
// SPDX-License-Identifier: Apache-2.0

#ifndef TTMLIR_TTMLIR_TTOPSTYPES_TD
#define TTMLIR_TTMLIR_TTOPSTYPES_TD

include "mlir/IR/AttrTypeBase.td"
include "mlir/IR/EnumAttr.td"
include "mlir/IR/BuiltinTypeInterfaces.td"
include "mlir/IR/CommonTypeConstraints.td"
include "ttmlir/Dialect/TT/IR/TTBase.td"
include "ttmlir/Dialect/TT/IR/TTOpsEnums.td"

//===----------------------------------------------------------------------===//
// TT attr definitions
//===----------------------------------------------------------------------===//
// Should Attr be a separate file?

class TT_Attr<string name, string attrMnemonic, list<Trait> traits = [],
                   string baseCppClass = "::mlir::Attribute">
    : AttrDef<TT_Dialect, name, traits, baseCppClass> {
  let mnemonic = attrMnemonic;
  let attrName = "tt." # attrMnemonic;
}

def TT_GridAttr : TT_Attr<"Grid", "grid"> {
  let summary = "TT grid attribute";
  let description = [{
    TT grid attribute
  }];

  let parameters = (ins ArrayRefParameter<"int64_t">:$shape,
                        DefaultValuedParameter<
                          "AffineMap",
                          "$_builder.getEmptyAffineMap()">:$mapping);
  let assemblyFormat = "`<` custom<DimensionList>($shape) (`,` $mapping^)? `>`";

  let extraClassDeclaration = [{
      static GridAttr get(::mlir::MLIRContext *context) {
        return GridAttr::get(context, {1, 1});
      }

      static GridAttr get(::mlir::MLIRContext *context, ArrayRef<int64_t> shape) {
        return GridAttr::get(context, shape, AffineMap::get(context));
      }

      static GridAttr get(::mlir::MLIRContext *context, std::int64_t rank) {
        return GridAttr::get(context, SmallVector<std::int64_t>(rank, 1));
      }
  }];
}

def TT_ArchAttr : EnumAttr<TT_Dialect, TT_Arch, "arch"> {
  let assemblyFormat = "`<` $value `>`";
}

def TT_DataTypeAttr : EnumAttr<TT_Dialect, TT_DataType, "supportedDataTypes"> {
  let assemblyFormat = "`<` $value `>`";
}

def TT_CoreCoordAttr : TT_Attr<"CoreCoord", "core_coord"> {
  let summary = "TT core_coord attribute";
  let description = [{
    TT core_coord attribute containing a single physical core coordinate.
  }];

  let parameters = (ins "int64_t":$y, "int64_t":$x);
  let assemblyFormat = "custom<VargDimensionList>($y, $x)";
}

def TT_TileSizeAttr : TT_Attr<"TileSize", "tile_size"> {
  let summary = "TT tile_size attribute";
  let description = [{
    TT tile_size attribute containing a supported Tensix tile shape.
  }];

  let parameters = (ins "int64_t":$y, "int64_t":$x);
  let assemblyFormat = "custom<VargDimensionList>($y, $x)";
}


def TT_ChipPhysicalCoresAttr : TT_Attr<"ChipPhysicalCores", "chip_physical_cores"> {
  let summary = "TT chip_physical_cores attribute";
  let description = [{
    TT chip_physical_cores attribute containing arrays of physical cores by core type in order of logical cores.
  }];

  let parameters = (ins ArrayRefParameter<"CoreCoordAttr">:$worker, ArrayRefParameter<"CoreCoordAttr">:$dram, OptionalArrayRefParameter<"CoreCoordAttr">:$eth, OptionalArrayRefParameter<"CoreCoordAttr">:$eth_inactive);
  let assemblyFormat = "`{` `worker` `=` `[` $worker `]` `dram` `=` `[` $dram `]` (`eth` `=` `[` $eth^ `]`)? (`eth_inactive` `=` `[` $eth_inactive^ `]`)? `}`";
}

def TT_ChipDescAttr : TT_Attr<"ChipDesc", "chip_desc"> {
  let summary = "TT chip_desc attribute";
  let description = [{
    TT chip_desc attribute
  }];

  let parameters = (ins "ArchAttr":$arch,
                    ArrayRefParameter<"int64_t">:$grid,
                    "unsigned":$l1Size,
                    "unsigned":$numDramChannels,
                    "unsigned":$dramChannelSize,
                    "unsigned":$nocL1AddressAlignBytes,
                    "unsigned":$pcieAddressAlignBytes,
                    "unsigned":$nocDRAMAddressAlignBytes,
                    "unsigned":$l1UnreservedBase,
                    "unsigned":$eriscL1UnreservedBase,
                    "unsigned":$dramUnreservedBase,
                    "unsigned":$dramUnreservedEnd,
                    "ChipPhysicalCoresAttr":$chipPhysicalCores,
                    ArrayRefParameter<"DataTypeAttr">:$supportedDataTypes,
                    ArrayRefParameter<"TileSizeAttr">:$supportedTileSizes);
  let assemblyFormat = [{`{` `arch` `=` $arch `,`
                             `grid` `=` custom<DimensionList>($grid) `,`
                             `l1_size` `=` $l1Size `,`
                             `num_dram_channels` `=` $numDramChannels `,`
                             `dram_channel_size` `=` $dramChannelSize `,`
                             `noc_l1_address_align_bytes` `=` $nocL1AddressAlignBytes `,`
                             `pcie_address_align_bytes` `=` $pcieAddressAlignBytes `,`
                             `noc_dram_address_align_bytes` `=` $nocDRAMAddressAlignBytes  `,`
                             `l1_unreserved_base` `=` $l1UnreservedBase `,`
                             `erisc_l1_unreserved_base` `=` $eriscL1UnreservedBase `,`
                             `dram_unreserved_base` `=` $dramUnreservedBase `,`
                             `dram_unreserved_end` `=` $dramUnreservedEnd `,`
                             `physical_cores` `=` $chipPhysicalCores `,`
                             `supported_data_types` `=` `[` $supportedDataTypes `]` `,`
                             `supported_tile_sizes` `=` `[` $supportedTileSizes `]` `}`}];

  let extraClassDeclaration = [{
    unsigned getUsableL1Size() const { return getL1Size() - getL1UnreservedBase(); }
    unsigned getUsableDramChannelSize() const { return getDramUnreservedEnd() - getDramUnreservedBase(); }
  }];
}

def TT_ChipCoordAttr : TT_Attr<"ChipCoord", "chip_coord"> {
  let summary = "TT chip_coord attribute";
  let description = [{
    TT chip_coord attribute
  }];

  let parameters = (ins "unsigned":$rack, "unsigned":$shelf, "unsigned":$y, "unsigned":$x);
  let assemblyFormat = "custom<VargDimensionList>($rack, $shelf, $y, $x)";
}

def TT_ChipChannelAttr : TT_Attr<"ChipChannel", "chip_channel"> {
  let summary = "TT chip_channel attribute";
  let description = [{
    TT chip_channel attribute
  }];

  let parameters = (ins "unsigned":$deviceId0,
                        ArrayRefParameter<"int64_t">:$ethernetCoreCoord0,
                        "unsigned":$deviceId1,
                        ArrayRefParameter<"int64_t">:$ethernetCoreCoord1);
  let assemblyFormat = "`<` `[` $deviceId0 `,` $ethernetCoreCoord0 `]` `,` `[` $deviceId1 `,` $ethernetCoreCoord1 `]` `>`";
}

def TT_SystemDescAttr : TT_Attr<"SystemDesc", "system_desc"> {
  let summary = "TT system_desc attribute";
  let description = [{
    TT system_desc attribute
  }];

  let parameters = (ins ArrayRefParameter<"ChipDescAttr">:$chipDescs,
                        ArrayRefParameter<"unsigned">:$chipDescIndices,
                        ArrayRefParameter<"ChipCapabilityAttr">:$chipCapabilities,
                        ArrayRefParameter<"ChipCoordAttr">:$chipCoords,
                        OptionalArrayRefParameter<"ChipChannelAttr">:$chipChannels);
  let assemblyFormat = "`<` `[` $chipDescs `]` `,` `[` $chipDescIndices `]` `,` `[` $chipCapabilities `]` `,` `[` $chipCoords `]` (`,` `[` $chipChannels^ `]`)? `>`";

  let extraClassDeclaration = [{
    static tt::SystemDescAttr getDefault(MLIRContext *context);
    static tt::SystemDescAttr getFromPath(MLIRContext *context, std::string& path);
    unsigned getAddressAlignBytes(unsigned chipIndex = 0) const;
    unsigned getAddressAlignBytes(MemorySpace memorySpace, unsigned chipIndex = 0) const;
    unsigned getNocL1AddressAlignBytes(unsigned chipIndex = 0) const;
    unsigned getNocDRAMAddressAlignBytes(unsigned chipIndex = 0) const;
    unsigned getPcieAddressAlignBytes(unsigned chipIndex = 0) const;
  }];
}

def TT_LayoutAttr : TT_Attr<"Layout", "layout"> {
  let summary = "Tensor layout attribute";
  let description = [{
    The tensor layout attribute captures how tensor data is sharded across a grid of devices, cores, and
    is laid out in memory.

    Some high level goals
      - **Logical shapes**: Keep the original tensor shape and rank intact and agnostic
        to underlying storage layout.
        Keeping the logical shapes not only makes some graph transformations vastly
        simpler, in particular convs, but it makes the lowered IR much easier to read
        and reason about.  The original tensor shapes leave breadcrumbs that make it
        much easier to map back to the input representation.
      - **Flexible sharding**: Enable flexibility in choosing grid shape, to get better
        parallelization and avoid resharding. This is particularly important in cases
        where tensor shapes are not clean powers of two and would otherwise force our
        hand in choosing non-optimal grid shapes.
      - **Logical-Physical Isomorphism**: Encode this information with just a few
        attributes to enable derived conversions from logical to physical layout and back.
      - **Explicit**: A single source of truth.
      - Enable a direct way to query padded regions.

    Please refer to the [Tensor Layout Spec](https://tenstorrent.github.io/tt-mlir/specs/tensor-layout.html) for more in depth documentation.

    Examples:
    ```mlir
    tensor<8x300xf32,
      #tt.layout<(d0, d1) -> (d0, d1),
        undef,
        <1x2>,
        memref<8x150xf32, #tt.memory_space<l1>>
      >
    >

    tensor<8x96x32xf32,
      #tt.layout<(d0, d1, d2) -> (d0 * 96 + d1, d2),
        undef,
        <2x1>,
        memref<384x32xf32, #tt.memory_space<l1>>
      >
    >

    tensor<8x96x32xf32,
      #tt.layout<(d0, d1, d2) -> (d0 * 96 + d1, d1, d2),
        undef,
        <2x1x2>,
        memref<384x96x16xf32, #tt.memory_space<l1>>
      >
    >

    tensor<5x3x2x2x7x32x32xf32,
      #tt.layout<
        (d0, d1, d2, d3, d4, d5, d6)
          -> (d0 * 2688 + d1 * 896 + d2 * 448 + d3 * 224 + d4 * 32 + d5, d4, d5, d6),
        undef,
        <3x2x2x2>,
        memref<4480x4x16x16xf32, #tt.memory_space<l1>>
      >
    >
    ```
  }];

  let parameters = (ins AttrParameter<"AffineMap", "An affine map that defines how the logical tensor dimensions map to a grid shape.">:$linear,
                        AttrParameter<"OOBVal", "A tracked out of bounds value that fills padding space.">:$oob_val,
                        AttrParameter<"GridAttr", "The grid shape that this tensor is divided onto.">:$grid,
                        AttrParameter<"MemRefType", "A memref that describes the physical footprint allocation of the shard. It must also have a shape with rank equal to grid.">:$memref,
                        DefaultValuedParameter<"TensorMemoryLayout", "TensorMemoryLayout::None", "The layout of the tensor in memory.">:$mem_layout);
  let assemblyFormat = "`<` $linear`,` $oob_val`,` $grid`,` $memref (`,` $mem_layout^)? `>`";

  let extraClassDeclaration = [{
      static LayoutAttr get(::mlir::MLIRContext *context,
                            ArrayRef<int64_t> tensorShape,
                            Type elementType,
                            MemorySpace memorySpace = MemorySpace::System,
                            GridAttr grid = {},
                            ArrayRef<std::pair<std::int64_t, std::int64_t>> collapseIntervals = {{0, -1}},
                            OOBVal oobVal = OOBVal::Undef,
                            TensorMemoryLayout memLayout = TensorMemoryLayout::None);
      static LayoutAttr get(::mlir::MLIRContext *context,
                            RankedTensorType ty,
                            MemorySpace memorySpace = MemorySpace::System,
                            GridAttr grid = {},
                            ArrayRef<std::pair<std::int64_t, std::int64_t>> collapseIntervals = {{0, -1}},
                            OOBVal oobVal = OOBVal::Undef,
                            TensorMemoryLayout memLayout = TensorMemoryLayout::None);
      static LayoutAttr get(::mlir::MLIRContext *context,
                            RankedTensorType ty,
                            MemorySpace memorySpace,
                            GridAttr grid,
                            Type elementType,
                            TensorMemoryLayout memLayout);
      LayoutAttr withGrid(::mlir::MLIRContext *context, ArrayRef<int64_t> tensorShape, GridAttr grid, ArrayRef<std::pair<std::int64_t, std::int64_t>> collapseIntervals = {{0, -1}});
      LayoutAttr withGrid(::mlir::MLIRContext *context,
                          RankedTensorType ty,
                          GridAttr grid,
                          ArrayRef<std::pair<std::int64_t, std::int64_t>> collapseIntervals = {{0, -1}});
      LayoutAttr withElementType(::mlir::MLIRContext *context, Type elementType);
      LayoutAttr withMemorySpace(::mlir::MLIRContext *context, MemorySpace memorySpace);
      LayoutAttr withMemoryLayout(::mlir::MLIRContext *context, TensorMemoryLayout memLayout);
      MemorySpace getMemorySpace() const;
      bool isSystemMemorySpace() const { return ::mlir::tt::isSystemMemorySpace(getMemorySpace()); }
      bool isDeviceMemorySpace() const { return ::mlir::tt::isDeviceMemorySpace(getMemorySpace()); }
      bool hasShardedTensorMemoryLayout() const;
      bool hasShardedL1TensorMemoryLayout() const;
      bool isTiled() const;
      Type getElementType() const;
      Type getScalarElementType() const;
      uint64_t getElementSizeBytes() const;
      llvm::SmallVector<int64_t> getStride(ArrayRef<int64_t> logicalShape) const;
      llvm::SmallVector<int64_t> getPhysicalShape(ArrayRef<int64_t> logicalShape) const;
      llvm::SmallVector<int64_t> getShardShape(bool convertTileToScalar = true) const;
      AffineMap replaceMemoryMapSymbolsWithShardShape(AffineMap physicalMemoryMap) const;
      AffineMap projectOnto(AffineMap linearMap, AffineMap physicalMemoryMap, ArrayRef<int64_t> logicalTensorShape) const;
      AffineMap getIdentityTileLinearMap() const;
      llvm::SmallVector<int64_t> getTiledShape(ArrayRef<int64_t> logicalTensorShape) const;
  }];
}

def TT_BufferAccessAttr : EnumAttr<TT_Dialect, TT_BufferAccess, "buffer_access"> {
  let assemblyFormat = "$value";
}

def TT_BufferAttr : TT_Attr<"Buffer", "buffer", []> {
  let summary = "Buffer attribute in TT dialect";
  let description = [{
    Describes the physical footprint and layout of a buffer in L1. Its memref must also have a shape with rank equal to DeviceAttr grid.
    It also carries a buffer access attribute which can be one of:
    - Alias: This buffer aliases a persistent Tensor L1 allocation directly. Implies that no datamovement occurs and the compute kernel
             just accesses the local allocation directly.
    - Stream: This buffer is a temporary destination as a means to get remote data for local computation.  Remote data is most likely a
              a tensor that is allocated in dram, but could also be data from a remote core.
  }];
  let parameters = (ins AttrParameter<"MemRefType", "A memref that describes the physical footprint and layout of the buffer. It must also have a shape with rank equal to DeviceAttr grid.">:$memref,
                        AttrParameter<"BufferAccess", "How data is accessed through this buffer, alias or stream.">:$buffer_access);
  let assemblyFormat = "`<` $memref `,` $buffer_access `>`";

  let extraClassDeclaration = [{
      ::mlir::Type getElementType() const;
      ::llvm::SmallVector<int64_t> getShape() const;
  }];
}

def TT_DeviceAttr : TT_Attr<"Device", "device", []> {
  let summary = "Device attribute in TT dialect.";
  let description = [{
    Describes the physical layout of a device in the system and is made up of a few components:
    - A grid attribute that describes the device's compute grid shape.  It not only describes the shape of the compute grid, but also
      carries an affine map that describes how the logical grid maps to the physical grid.
    - Two affine maps that describe how a tensor layout's linear attribute maps to the L1 and DRAM memory spaces.
    - A mesh shape that describes the virtual layout of the chips with respect to each other. Note that in a multi-chip system, this grid
      encapsulates the entire system's grid shape, e.g. 8x16 grid could be made up of a 1x2 mesh of chips side-by-side. The mesh
      attribute configures how the above grid/map attributes are created such that they implement this mesh topology.
    - An array of chip ids that this device is made up of. This array's length must match the volume of the mesh shape and should be
      interpreted in row-major order.
  }];
  let parameters = (ins TT_GridAttr:$workerGrid,
                        "AffineMap":$l1Map,
                        "AffineMap":$dramMap,
                        ArrayRefParameter<"int64_t">:$meshShape,
                        ArrayRefParameter<"unsigned">:$chipIds);
  let assemblyFormat = "`<` `workerGrid` `=` qualified($workerGrid) `,` `l1Map` `=` qualified($l1Map) `,` `dramMap` `=` qualified($dramMap) `,` `meshShape` `=` custom<DimensionList>($meshShape) `,` `chipIds` `=` `[` $chipIds `]` `>`";

  let extraClassDeclaration = [{
      static DeviceAttr get(::mlir::MLIRContext *context, SystemDescAttr systemDesc, ArrayRef<int64_t> meshShape, ArrayRef<unsigned> chipIds);
      static DeviceAttr get(::mlir::MLIRContext *context, SystemDescAttr systemDesc, ArrayRef<int64_t> meshShape = {});
      AffineMap getMapForMemorySpace(MemorySpace memorySpace) const {
        switch (memorySpace) {
        case MemorySpace::DeviceL1:
          return getL1Map();
        case MemorySpace::DeviceDRAM:
          return getDramMap();
        default:
          llvm_unreachable("Unsupported memory space");
        }
      }

      // Returns the footprint size in bytes of the tensor layout distributed across the given memory space.
      // The resulting size is a function of the memory space, roughly speaking this ends up being:
      // - DeviceL1: This ends up being exactly the shard size
      // - DeviceDRAM: Is more nuanced because the whole tensor size gets paged and interleaved between all dram channels,
      //   due to paging and rounding the footprint ends up being close to: the_whole_tensor / num_dram_channels
      uint64_t getLayoutSizeBytes(ArrayRef<int64_t> tensorShape, LayoutAttr layout, MemorySpace memorySpace) const;

      // Returns the footprint size in bytes of the tensor distributed across the given memory space.
      // Forwards to getLayoutSizeBytes, see comment there for more info.
      uint64_t getTensorSizeBytes(RankedTensorType tensorType, MemorySpace memorySpace) const;
  }];

  let genVerifyDecl = 1;
}

def TT_MemorySpaceAttr : EnumAttr<TT_Dialect, TT_MemorySpace, "memory_space"> {
  let assemblyFormat = "`<` $value `>`";
}

def TT_TensorMemoryLayoutAttr : EnumAttr<TT_Dialect, TT_TensorMemoryLayout, "tensor_memory_layout"> {
  let assemblyFormat = "`<` $value `>`";
}

def TT_OOBValAttr : EnumAttr<TT_Dialect, TT_OOBVal, "oob_val"> {
  let assemblyFormat = "`<` $value `>`";
}

def TT_IteratorTypeAttr : EnumAttr<TT_Dialect, TT_IteratorType, "iterator_type"> {
  let assemblyFormat = "`<` $value `>`";
}

def TT_IteratorTypeArrayAttr : TypedArrayAttrBase<TT_IteratorTypeAttr, "">;

def TT_OperandConstraintAttr : EnumAttr<TT_Dialect, TT_OperandConstraint, "operand_constraint"> {
  let assemblyFormat = "`<` $value `>`";
}

def TT_OperandConstraintArrayAttr : TypedArrayAttrBase<TT_OperandConstraintAttr, "">;

def TT_ArgumentAllocationAttr : TT_Attr<"ArgumentAllocation", "arg_alloc", []> {
  let summary = "Argument allocation attribute in TT dialect";
  let description = [{
    Holds the metadata for the allocation of an function argument i.e. for graph inputs.
  }];
  let parameters = (ins "uint64_t":$address, "uint64_t":$size, "MemorySpace":$memorySpace);
  let assemblyFormat = "`<` $address `,` $size `,` $memorySpace `>`";
}

//===----------------------------------------------------------------------===//
// TT type definitions
//===----------------------------------------------------------------------===//

class TT_Type<string name, string typeMnemonic, list<Trait> traits = []>
    : TypeDef<TT_Dialect, name, traits> {
  let mnemonic = typeMnemonic;
}

def TT_Tile : TT_Type<"Tile", "tile", [MemRefElementTypeInterface]> {
    let summary = "TT tile";
    let description = "Tile type in TT dialect";
    let parameters = (ins ArrayRefParameter<"int64_t">:$shape, "DataType":$dataType);
    let assemblyFormat = "`<` custom<DimensionList>($shape) `,` $dataType `>`";

    let extraClassDeclaration = [{
      static TileType get(::mlir::MLIRContext *context, Type elementType, ArrayRef<int64_t> shape = {32, 32});
      SmallVector<int64_t> getScalarShape(SmallVector<int64_t> tiledShape) const;
      SmallVector<int64_t> getTiledShape(SmallVector<int64_t> scalarShape) const;
      uint64_t getSizeBytes() const;
      int64_t getHeight() const { return getShape()[0]; }
      int64_t getWidth() const { return getShape()[1]; }
      // Returns the scalar element type of the tile, if compressed it returns
      // the corresponding uncompressed element type, i.e. bfp_bf8 -> bf16
      Type getElementType() const;
    }];

    let genVerifyDecl = 1;
}

def TT_Device : TT_Type<"Device", "device", []> {
    let summary = "TT device";
    let description = "Device type in TT dialect";
    let parameters = (ins TT_DeviceAttr:$desc);
    let assemblyFormat = "`<` $desc `>`";
}

#endif
