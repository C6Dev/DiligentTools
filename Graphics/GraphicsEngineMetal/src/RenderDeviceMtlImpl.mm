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

#include "RenderDeviceMtlImpl.hpp"
#include "ShaderMtlImpl.hpp"
#include "PipelineStateMtlImpl.hpp"
#include "BufferMtlImpl.hpp"
#include "TextureMtlImpl.hpp"
#include "SamplerMtlImpl.hpp"
#include "FenceMtlImpl.hpp"
#include "DebugUtilities.hpp"

#import <Metal/Metal.h>

namespace Diligent
{

RenderDeviceMtlImpl::RenderDeviceMtlImpl(IReferenceCounters*        pRefCounters,
                                         IMemoryAllocator&          RawMemAllocator,
                                         IEngineFactory*            pEngineFactory,
                                         const EngineCreateInfo&    EngineCI,
                                         const GraphicsAdapterInfo& AdapterInfo,
                                         size_t                     CommandQueueCount,
                                         ICommandQueueMtl**         ppCmdQueues) noexcept(false) :
    TRenderDeviceBase{pRefCounters, RawMemAllocator, pEngineFactory, CommandQueueCount, ppCmdQueues, EngineCI, AdapterInfo}
{
    m_DeviceInfo.Type = RENDER_DEVICE_TYPE_METAL;
    m_MtlDevice = MTLCreateSystemDefaultDevice();
}

RenderDeviceMtlImpl::~RenderDeviceMtlImpl()
{
    if (m_MtlDevice != nil)
    {
        [m_MtlDevice release];
        m_MtlDevice = nil;
    }
}

void RenderDeviceMtlImpl::CreateGraphicsPipelineState(const GraphicsPipelineStateCreateInfo& PSOCreateInfo,
                                                      IPipelineState**                       ppPipelineState)
{
    printf("Metal: CreateGraphicsPipelineState called for PSO: %s\n", PSOCreateInfo.PSODesc.Name ? PSOCreateInfo.PSODesc.Name : "unnamed");
    CreatePipelineStateImpl(ppPipelineState, PSOCreateInfo);
}

void RenderDeviceMtlImpl::CreateComputePipelineState(const ComputePipelineStateCreateInfo& PSOCreateInfo,
                                                     IPipelineState**                      ppPipelineState)
{
    CreatePipelineStateImpl(ppPipelineState, PSOCreateInfo);
}

void RenderDeviceMtlImpl::CreateBuffer(const BufferDesc& BuffDesc,
                                       const BufferData* pBuffData,
                                       IBuffer**         ppBuffer)
{
    CreateBufferImpl(ppBuffer, BuffDesc, pBuffData);
}

void RenderDeviceMtlImpl::CreateShader(const ShaderCreateInfo& ShaderCreateInfo,
                                       IShader**               ppShader,
                                       IDataBlob**             ppCompilerOutput)
{
    printf("RenderDeviceMtlImpl::CreateShader called for: %s\n", ShaderCreateInfo.Desc.Name);
    printf("  Source: %p, Length: %zu\n", ShaderCreateInfo.Source, ShaderCreateInfo.SourceLength);
    printf("  EntryPoint: %s\n", ShaderCreateInfo.EntryPoint ? ShaderCreateInfo.EntryPoint : "null");
    
    const ShaderMtlImpl::CreateInfo MtlShaderCI{
        GetDeviceInfo(),
        GetAdapterInfo(),
        ppCompilerOutput,
        nullptr, // pAsyncTaskProcessor
        nullptr  // PreprocessMslSource
    };
    CreateShaderImpl(ppShader, ShaderCreateInfo, MtlShaderCI);
}

void RenderDeviceMtlImpl::CreateTexture(const TextureDesc& TexDesc,
                                        const TextureData* pData,
                                        ITexture**         ppTexture)
{
    CreateTextureImpl(ppTexture, TexDesc, pData);
}

void RenderDeviceMtlImpl::CreateSampler(const SamplerDesc& SamplerDesc,
                                        ISampler**         ppSampler)
{
    CreateSamplerImpl(ppSampler, SamplerDesc);
}

void RenderDeviceMtlImpl::CreateFence(const FenceDesc& Desc,
                                      IFence**         ppFence)
{
    CreateFenceImpl(ppFence, Desc);
}

void RenderDeviceMtlImpl::CreateQuery(const QueryDesc& Desc,
                                      IQuery**         ppQuery)
{
    CreateQueryImpl(ppQuery, Desc);
}

id<MTLDevice> RenderDeviceMtlImpl::GetMtlDevice() const
{
    return m_MtlDevice;
}

void RenderDeviceMtlImpl::CreateTextureFromMtlResource(id<MTLTexture> mtlTexture,
                                                       RESOURCE_STATE InitialState,
                                                       ITexture**     ppTexture)
{
    // Build a proper TextureDesc from the supplied Metal texture so validation succeeds.
    TextureDesc TexDesc{};
    TexDesc.Name = "Texture from Metal resource";

    if (mtlTexture == nil)
    {
        LOG_ERROR_MESSAGE("CreateTextureFromMtlResource called with nil mtlTexture");
        *ppTexture = nullptr;
        return;
    }

    // Map Metal texture type to Diligent resource dimension.
    switch ([mtlTexture textureType])
    {
        case MTLTextureType2D:
        case MTLTextureType2DMultisample:
            TexDesc.Type = RESOURCE_DIM_TEX_2D; break;
        case MTLTextureTypeCube:
            TexDesc.Type = RESOURCE_DIM_TEX_CUBE; break;
        case MTLTextureType3D:
            TexDesc.Type = RESOURCE_DIM_TEX_3D; break;
        case MTLTextureType2DArray:
        case MTLTextureTypeCubeArray:
            TexDesc.Type = RESOURCE_DIM_TEX_2D; break; // treat arrays as 2D for now; ArraySize will reflect elements
        default:
            TexDesc.Type = RESOURCE_DIM_TEX_2D; break;
    }

    TexDesc.Width      = static_cast<Uint32>([mtlTexture width]);
    TexDesc.Height     = static_cast<Uint32>([mtlTexture height]);
    TexDesc.Depth      = static_cast<Uint32>([mtlTexture depth]);
    TexDesc.ArraySize  = static_cast<Uint32>([mtlTexture arrayLength]);
    TexDesc.MipLevels  = static_cast<Uint32>([mtlTexture mipmapLevelCount]);
    TexDesc.SampleCount= static_cast<Uint8>([mtlTexture sampleCount]);

    // Reverse map pixel format (subset of common formats used by swap chain/back buffers).
    auto MapFormat = [](MTLPixelFormat fmt) -> TEXTURE_FORMAT {
        switch (fmt)
        {
            case MTLPixelFormatBGRA8Unorm:         return TEX_FORMAT_BGRA8_UNORM;
            case MTLPixelFormatBGRA8Unorm_sRGB:    return TEX_FORMAT_BGRA8_UNORM_SRGB;
            case MTLPixelFormatRGBA8Unorm:         return TEX_FORMAT_RGBA8_UNORM;
            case MTLPixelFormatRGBA8Unorm_sRGB:    return TEX_FORMAT_RGBA8_UNORM_SRGB;
            case MTLPixelFormatDepth32Float:       return TEX_FORMAT_D32_FLOAT;
            case MTLPixelFormatDepth24Unorm_Stencil8: return TEX_FORMAT_D24_UNORM_S8_UINT;
            case MTLPixelFormatDepth32Float_Stencil8: return TEX_FORMAT_D32_FLOAT_S8X24_UINT;
            default: return TEX_FORMAT_UNKNOWN;
        }
    };
    TexDesc.Format = MapFormat([mtlTexture pixelFormat]);

    // Derive bind flags. Back buffers are render targets; if depth format, mark depth-stencil.
    if (TexDesc.Format == TEX_FORMAT_D32_FLOAT || TexDesc.Format == TEX_FORMAT_D24_UNORM_S8_UINT || TexDesc.Format == TEX_FORMAT_D32_FLOAT_S8X24_UINT)
        TexDesc.BindFlags = BIND_DEPTH_STENCIL;
    else
        TexDesc.BindFlags = BIND_RENDER_TARGET;
    // Also allow shader resource usage for potential sampling of resolve/capture.
    if (TexDesc.Format != TEX_FORMAT_UNKNOWN)
        TexDesc.BindFlags |= BIND_SHADER_RESOURCE;

    TexDesc.Usage = USAGE_DEFAULT;
    TexDesc.ClearValue.Format = TexDesc.Format; // set format for possible clear validation

    if (TexDesc.Format == TEX_FORMAT_UNKNOWN)
    {
        LOG_WARNING_MESSAGE("CreateTextureFromMtlResource: Unmapped MTLPixelFormat=", static_cast<int>([mtlTexture pixelFormat]), 
                            ", defaulting to BGRA8_UNORM");
        TexDesc.Format    = TEX_FORMAT_BGRA8_UNORM;
        TexDesc.BindFlags = BIND_RENDER_TARGET | BIND_SHADER_RESOURCE;
    }

    // Sanity fallback: Depth must be at least 1 for 2D.
    if (TexDesc.Type == RESOURCE_DIM_TEX_2D && TexDesc.Depth == 0)
        TexDesc.Depth = 1;
    if (TexDesc.ArraySize == 0)
        TexDesc.ArraySize = 1;
    if (TexDesc.MipLevels == 0)
        TexDesc.MipLevels = 1;

    CreateTextureImpl(ppTexture, TexDesc, InitialState, mtlTexture);
}

void RenderDeviceMtlImpl::CreateBufferFromMtlResource(id<MTLBuffer>     mtlBuffer,
                                                      const BufferDesc& BuffDesc,
                                                      RESOURCE_STATE    InitialState,
                                                      IBuffer**         ppBuffer)
{
    CreateBufferImpl(ppBuffer, BuffDesc, InitialState, mtlBuffer);
}

void RenderDeviceMtlImpl::CreateSparseTexture(const TextureDesc& TexDesc,
                                              IDeviceMemory*     pMemory,
                                              ITexture**         ppTexture)
{
    // Sparse textures not yet implemented for Metal backend
    LOG_ERROR_MESSAGE("CreateSparseTexture is not yet implemented for Metal backend");
    *ppTexture = nullptr;
}

void RenderDeviceMtlImpl::CreateRayTracingPipelineState(const RayTracingPipelineStateCreateInfo& PSOCreateInfo,
                                                        IPipelineState**                         ppPipelineState)
{
    UNSUPPORTED("Ray tracing is not yet implemented for Metal backend");
    *ppPipelineState = nullptr;
}

void RenderDeviceMtlImpl::CreateRenderPass(const RenderPassDesc& Desc,
                                           IRenderPass**         ppRenderPass)
{
    CreateRenderPassImpl(ppRenderPass, Desc);
}

void RenderDeviceMtlImpl::CreateFramebuffer(const FramebufferDesc& Desc,
                                            IFramebuffer**         ppFramebuffer)
{
    CreateFramebufferImpl(ppFramebuffer, Desc);
}

void RenderDeviceMtlImpl::CreateBLAS(const BottomLevelASDesc& Desc,
                                     IBottomLevelAS**         ppBLAS)
{
    UNSUPPORTED("CreateBLAS is not yet implemented for Metal backend");
    *ppBLAS = nullptr;
}

void RenderDeviceMtlImpl::CreateTLAS(const TopLevelASDesc& Desc,
                                     ITopLevelAS**         ppTLAS)
{
    UNSUPPORTED("CreateTLAS is not yet implemented for Metal backend");
    *ppTLAS = nullptr;
}

void RenderDeviceMtlImpl::CreateSBT(const ShaderBindingTableDesc& Desc,
                                    IShaderBindingTable**         ppSBT)
{
    UNSUPPORTED("CreateSBT is not yet implemented for Metal backend");
    *ppSBT = nullptr;
}

void RenderDeviceMtlImpl::CreatePipelineResourceSignature(const PipelineResourceSignatureDesc& Desc,
                                                          IPipelineResourceSignature**         ppSignature)
{
    CreatePipelineResourceSignatureImpl(ppSignature, Desc, SHADER_TYPE_UNKNOWN, false);
}

void RenderDeviceMtlImpl::CreatePipelineResourceSignature(const PipelineResourceSignatureDesc& Desc,
                                                          IPipelineResourceSignature**         ppSignature,
                                                          SHADER_TYPE                          ShaderStages,
                                                          bool                                 IsDeviceInternal)
{
    CreatePipelineResourceSignatureImpl(ppSignature, Desc, ShaderStages, IsDeviceInternal);
}

void RenderDeviceMtlImpl::CreateDeviceMemory(const DeviceMemoryCreateInfo& CreateInfo,
                                             IDeviceMemory**               ppMemory)
{
    CreateDeviceMemoryImpl(ppMemory, CreateInfo);
}

void RenderDeviceMtlImpl::CreatePipelineStateCache(const PipelineStateCacheCreateInfo& CreateInfo,
                                                   IPipelineStateCache**               ppPSOCache)
{
    // Pipeline state cache not yet implemented for Metal backend
    *ppPSOCache = nullptr;
}

void RenderDeviceMtlImpl::CreateDeferredContext(IDeviceContext** ppContext)
{
    UNSUPPORTED("Deferred contexts are not supported in Metal backend");
    *ppContext = nullptr;
}

SparseTextureFormatInfo RenderDeviceMtlImpl::GetSparseTextureFormatInfo(TEXTURE_FORMAT     TexFormat,
                                                                        RESOURCE_DIMENSION Dimension,
                                                                        Uint32             SampleCount) const
{
    // Sparse textures not yet supported in Metal backend - return empty info
    SparseTextureFormatInfo SparseTexInfo{};
    return SparseTexInfo;
}

void RenderDeviceMtlImpl::ReleaseStaleResources(bool ForceRelease)
{
    // Metal resource management is handled by ARC
    // Stub implementation for now
}

void RenderDeviceMtlImpl::IdleGPU()
{
    // Wait for all GPU operations to complete
    // Stub implementation for now
}

void RenderDeviceMtlImpl::CreateBLASFromMtlResource(id<MTLAccelerationStructure> mtlBLAS,
                                                    const BottomLevelASDesc&     Desc,
                                                    RESOURCE_STATE               InitialState,
                                                    IBottomLevelAS**             ppBLAS)
{
    UNSUPPORTED("CreateBLASFromMtlResource is not yet implemented for Metal backend");
    *ppBLAS = nullptr;
}

void RenderDeviceMtlImpl::CreateTLASFromMtlResource(id<MTLAccelerationStructure> mtlTLAS,
                                                    const TopLevelASDesc&        Desc,
                                                    RESOURCE_STATE               InitialState,
                                                    ITopLevelAS**                ppTLAS)
{
    UNSUPPORTED("CreateTLASFromMtlResource is not yet implemented for Metal backend");
    *ppTLAS = nullptr;
}

void RenderDeviceMtlImpl::CreateRasterizationRateMapFromMtlResource(id<MTLRasterizationRateMap> mtlRRM,
                                                                    IRasterizationRateMapMtl**  ppRRM)
{
    UNSUPPORTED("CreateRasterizationRateMapFromMtlResource is not yet implemented for Metal backend");
    *ppRRM = nullptr;
}

void RenderDeviceMtlImpl::CreateRasterizationRateMap(const RasterizationRateMapCreateInfo& CreateInfo,
                                                     IRasterizationRateMapMtl**            ppRRM)
{
    UNSUPPORTED("CreateRasterizationRateMap is not yet implemented for Metal backend");
    *ppRRM = nullptr;
}

void RenderDeviceMtlImpl::TestTextureFormat(TEXTURE_FORMAT TexFormat)
{
    // Texture format testing for Metal backend
    // Stub implementation for now
}

} // namespace Diligent
