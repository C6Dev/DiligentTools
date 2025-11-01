/*
 *  Copyright 2019-2025 Diligent Graphics LLC
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *
 *  In no event and under no legal theory, whether in tort (including negligence),
 *  contract, or otherwise, unless required by applicable law (such as deliberate
 *  and grossly negligent acts) or agreed to in writing, shall any Contributor be
 *  liable for any damages, including any direct, indirect, special, incidental,
 *  or consequential damages of any character arising as a result of this License or
 *  out of the use or inability to use the software (including but not limited to damages
 *  for loss of goodwill, work stoppage, computer failure or malfunction, or any and
 *  all other commercial damages or losses), even if such Contributor has been advised
 *  of the possibility of such damages.
 */

#pragma once

/// \file
/// Declaration of Diligent::EngineMtlImplTraits struct

#include "RenderDeviceMtl.h"
#include "PipelineStateMtl.h"
#include "ShaderResourceBindingMtl.h"
#include "BufferMtl.h"
#include "BufferViewMtl.h"
#include "TextureMtl.h"
#include "TextureViewMtl.h"
#include "ShaderMtl.h"
#include "SamplerMtl.h"
#include "FenceMtl.h"
#include "QueryMtl.h"
#include "BottomLevelASMtl.h"
#include "TopLevelASMtl.h"
#include "PipelineResourceSignature.h"
#include "DeviceMemoryMtl.h"
#include "PipelineStateCacheMtl.h"
#include "CommandQueueMtl.h"
#include "DeviceContextMtl.h"
#include "Framebuffer.h"
#include "ShaderBindingTable.h"
#include "PipelineResourceAttribsMtl.hpp"
#include "ImmutableSamplerAttribsMtl.hpp"

namespace Diligent
{

class ShaderResourceCacheMtl;
class ShaderResourceBindingMtlImpl;
class ShaderVariableManagerMtl;
class RenderDeviceMtlImpl;
class DeviceContextMtlImpl;
class PipelineStateMtlImpl;
class BufferMtlImpl;
class BufferViewMtlImpl;
class TextureMtlImpl;
class TextureViewMtlImpl;
class ShaderMtlImpl;
class SamplerMtlImpl;
class FenceMtlImpl;
class QueryMtlImpl;
class RenderPassMtlImpl;
class FramebufferMtlImpl;
class BottomLevelASMtlImpl;
class TopLevelASMtlImpl;
class ShaderBindingTableMtlImpl;
class PipelineResourceSignatureMtlImpl;
class DeviceMemoryMtlImpl;
class PipelineStateCacheMtlImpl;

class FixedBlockMemoryAllocator;

struct ImmutableSamplerAttribsMtl;

struct PipelineResourceSignatureInternalDataMtl;

struct EngineMtlImplTraits
{
    static constexpr RENDER_DEVICE_TYPE DeviceType = RENDER_DEVICE_TYPE_METAL;

    using RenderDeviceInterface              = IRenderDeviceMtl;
    using DeviceContextInterface             = IDeviceContextMtl;
    using PipelineStateInterface             = IPipelineStateMtl;
    using ShaderResourceBindingInterface     = IShaderResourceBindingMtl;
    using BufferInterface                    = IBufferMtl;
    using BufferViewInterface                = IBufferViewMtl;
    using TextureInterface                   = ITextureMtl;
    using TextureViewInterface               = ITextureViewMtl;
    using ShaderInterface                    = IShaderMtl;
    using SamplerInterface                   = ISamplerMtl;
    using FenceInterface                     = IFenceMtl;
    using QueryInterface                     = IQueryMtl;
    using FramebufferInterface               = IFramebuffer;
    using BottomLevelASInterface             = IBottomLevelASMtl;
    using TopLevelASInterface                = ITopLevelASMtl;
    using ShaderBindingTableInterface        = IShaderBindingTable;
    using PipelineResourceSignatureInterface = IPipelineResourceSignature;
    using CommandQueueInterface              = ICommandQueueMtl;
    using DeviceMemoryInterface              = IDeviceMemoryMtl;
    using PipelineStateCacheInterface        = IPipelineStateCacheMtl;

    using RenderDeviceImplType              = RenderDeviceMtlImpl;
    using DeviceContextImplType             = DeviceContextMtlImpl;
    using PipelineStateImplType             = PipelineStateMtlImpl;
    using ShaderResourceBindingImplType     = ShaderResourceBindingMtlImpl;
    using BufferImplType                    = BufferMtlImpl;
    using BufferViewImplType                = BufferViewMtlImpl;
    using TextureImplType                   = TextureMtlImpl;
    using TextureViewImplType               = TextureViewMtlImpl;
    using ShaderImplType                    = ShaderMtlImpl;
    using SamplerImplType                   = SamplerMtlImpl;
    using FenceImplType                     = FenceMtlImpl;
    using QueryImplType                     = QueryMtlImpl;
    using RenderPassImplType                = RenderPassMtlImpl;
    using FramebufferImplType               = FramebufferMtlImpl;
    using BottomLevelASImplType             = BottomLevelASMtlImpl;
    using TopLevelASImplType                = TopLevelASMtlImpl;
    using ShaderBindingTableImplType        = ShaderBindingTableMtlImpl;
    using PipelineResourceSignatureImplType = PipelineResourceSignatureMtlImpl;
    using DeviceMemoryImplType              = DeviceMemoryMtlImpl;
    using PipelineStateCacheImplType        = PipelineStateCacheMtlImpl;
    using ShaderResourceCacheImplType       = ShaderResourceCacheMtl;
    using ShaderVariableManagerImplType     = ShaderVariableManagerMtl;

    using PipelineResourceAttribsType               = PipelineResourceAttribsMtl;
    using ImmutableSamplerAttribsType               = ImmutableSamplerAttribsMtl;
    using PipelineResourceSignatureInternalDataType = PipelineResourceSignatureInternalDataMtl;

    using BuffViewObjAllocatorType = FixedBlockMemoryAllocator;
    using TexViewObjAllocatorType  = FixedBlockMemoryAllocator;
};

} // namespace Diligent

#include "PipelineResourceSignatureBase.hpp"

namespace Diligent
{

struct PipelineResourceSignatureInternalDataMtl : PipelineResourceSignatureInternalData<PipelineResourceAttribsMtl, ImmutableSamplerAttribsMtl>
{
    PipelineResourceSignatureInternalDataMtl() noexcept
    {}

    explicit PipelineResourceSignatureInternalDataMtl(const PipelineResourceSignatureInternalData& InternalData) noexcept :
        PipelineResourceSignatureInternalData{InternalData}
    {}
};

} // namespace Diligent

#include "RenderDeviceMtlImpl.hpp"
#include "DeviceContextMtlImpl.hpp"
#include "PipelineResourceSignatureMtlImpl.hpp"
#include "PipelineStateCacheMtlImpl.hpp"
#include "BufferMtlImpl.hpp"
#include "BufferViewMtlImpl.hpp"
#include "TextureMtlImpl.hpp"
#include "TextureViewMtlImpl.hpp"
#include "ShaderMtlImpl.hpp"
#include "SamplerMtlImpl.hpp"
#include "FenceMtlImpl.hpp"
#include "QueryMtlImpl.hpp"
#include "RenderPassMtlImpl.hpp"
#include "FramebufferMtlImpl.hpp"
#include "BottomLevelASMtlImpl.hpp"
#include "TopLevelASMtlImpl.hpp"
#include "ShaderBindingTableMtlImpl.hpp"
#include "ShaderResourceCacheMtl.hpp"
#include "ShaderVariableManagerMtl.hpp"
#include "ShaderResourceBindingMtlImpl.hpp"
