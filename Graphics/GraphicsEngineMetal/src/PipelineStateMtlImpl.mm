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

#include "PipelineStateMtlImpl.hpp"
#include "RenderDeviceMtlImpl.hpp"
#include "ShaderMtlImpl.hpp"
#import <Metal/Metal.h>

namespace Diligent
{

// Graphics pipeline constructor
PipelineStateMtlImpl::PipelineStateMtlImpl(IReferenceCounters*                    pRefCounters,
                                           RenderDeviceMtlImpl*                   pRenderDeviceMtl,
                                           const GraphicsPipelineStateCreateInfo& CreateInfo,
                                           bool                                   IsDeviceInternal) :
    TPipelineStateBase{pRefCounters, pRenderDeviceMtl, CreateInfo, IsDeviceInternal}
{
    LOG_INFO_MESSAGE("Metal: PipelineStateMtlImpl (graphics) - starting Construct() path for PSO: ",
                     CreateInfo.PSODesc.Name ? CreateInfo.PSODesc.Name : "unnamed");

    try
    {
        this->template Construct<ShaderMtlImpl>(CreateInfo);
        LOG_INFO_MESSAGE("Metal: Graphics Construct() finished. Status=", static_cast<int>(m_Status.load()), ", SignatureCount=", static_cast<int>(m_SignatureCount));
    }
    catch (...)
    {
        LOG_ERROR_MESSAGE("Metal: Graphics pipeline Construct() failed");
        throw;
    }
}

// Compute pipeline constructor  
PipelineStateMtlImpl::PipelineStateMtlImpl(IReferenceCounters*                   pRefCounters,
                                           RenderDeviceMtlImpl*                  pRenderDeviceMtl,
                                           const ComputePipelineStateCreateInfo& CreateInfo,
                                           bool                                  IsDeviceInternal) :
    TPipelineStateBase{pRefCounters, pRenderDeviceMtl, CreateInfo, IsDeviceInternal}
{
    LOG_INFO_MESSAGE("Metal: PipelineStateMtlImpl (compute) - starting Construct() path for PSO: ",
                     CreateInfo.PSODesc.Name ? CreateInfo.PSODesc.Name : "unnamed");
    try
    {
        this->template Construct<ShaderMtlImpl>(CreateInfo);
        LOG_INFO_MESSAGE("Metal: Compute Construct() finished. Status=", static_cast<int>(m_Status.load()), ", SignatureCount=", static_cast<int>(m_SignatureCount));
    }
    catch (...)
    {
        LOG_ERROR_MESSAGE("Metal: Compute pipeline Construct() failed");
        throw;
    }
}

// Ray tracing pipeline constructor
PipelineStateMtlImpl::PipelineStateMtlImpl(IReferenceCounters*                       pRefCounters,
                                           RenderDeviceMtlImpl*                      pRenderDeviceMtl,
                                           const RayTracingPipelineStateCreateInfo&  CreateInfo,
                                           bool                                      IsDeviceInternal) :
    TPipelineStateBase{pRefCounters, pRenderDeviceMtl, CreateInfo, IsDeviceInternal}
{
    LOG_ERROR_AND_THROW("Ray tracing pipelines are not supported in Metal backend");
}

PipelineStateMtlImpl::~PipelineStateMtlImpl()
{
    // Make sure async initialization (if any) finished before tearing down objects.
    GetStatus(/*WaitForCompletion =*/true);
    Destruct();
}

void PipelineStateMtlImpl::Destruct()
{
    // Release native Metal pipeline objects first (they may still be referenced by command buffers).
    if (m_MtlRenderPipeline != nil)
    {
        [m_MtlRenderPipeline release];
        m_MtlRenderPipeline = nil;
    }
    if (m_MtlComputePipeline != nil)
    {
        [m_MtlComputePipeline release];
        m_MtlComputePipeline = nil;
    }
    if (m_MtlDepthStencilState != nil)
    {
        [m_MtlDepthStencilState release];
        m_MtlDepthStencilState = nil;
    }

    // Now destroy base class allocations (signatures, pipeline data, etc.).
    TPipelineStateBase::Destruct();
}

// Helper method to create Metal graphics pipeline
void PipelineStateMtlImpl::CreateMetalGraphicsPipeline(const GraphicsPipelineStateCreateInfo& CreateInfo)
{
    RenderDeviceMtlImpl* pRenderDeviceMtl = static_cast<RenderDeviceMtlImpl*>(this->GetDevice());
    id<MTLDevice> mtlDevice = pRenderDeviceMtl->GetMtlDevice();
    
    @autoreleasepool
    {
        MTLRenderPipelineDescriptor* pipelineDesc = [[MTLRenderPipelineDescriptor alloc] init];

        // Map Diligent texture format to MTLPixelFormat (subset for swap chain / depth usage)
        auto ToMtlFormat = [](TEXTURE_FORMAT fmt) -> MTLPixelFormat {
            switch (fmt)
            {
                case TEX_FORMAT_BGRA8_UNORM: return MTLPixelFormatBGRA8Unorm;
                case TEX_FORMAT_BGRA8_UNORM_SRGB: return MTLPixelFormatBGRA8Unorm_sRGB;
                case TEX_FORMAT_RGBA8_UNORM: return MTLPixelFormatRGBA8Unorm;
                case TEX_FORMAT_RGBA8_UNORM_SRGB: return MTLPixelFormatRGBA8Unorm_sRGB;
                case TEX_FORMAT_D32_FLOAT: return MTLPixelFormatDepth32Float;
                case TEX_FORMAT_D24_UNORM_S8_UINT: return MTLPixelFormatDepth24Unorm_Stencil8;
                case TEX_FORMAT_D32_FLOAT_S8X24_UINT: return MTLPixelFormatDepth32Float_Stencil8;
                default: return MTLPixelFormatInvalid;
            }
        };
        // Assign color attachment formats expected by Metal pipeline so validation doesn't silently drop output.
        for (Uint32 i = 0; i < CreateInfo.GraphicsPipeline.NumRenderTargets; ++i)
        {
            auto fmt = CreateInfo.GraphicsPipeline.RTVFormats[i];
            if (fmt != TEX_FORMAT_UNKNOWN)
            {
                MTLPixelFormat mfmt = ToMtlFormat(fmt);
                if (mfmt != MTLPixelFormatInvalid)
                    pipelineDesc.colorAttachments[i].pixelFormat = mfmt;
            }
        }
        if (CreateInfo.GraphicsPipeline.DSVFormat != TEX_FORMAT_UNKNOWN)
        {
            MTLPixelFormat dfmt = ToMtlFormat(CreateInfo.GraphicsPipeline.DSVFormat);
            if (dfmt == MTLPixelFormatDepth24Unorm_Stencil8 || dfmt == MTLPixelFormatDepth32Float_Stencil8)
                pipelineDesc.depthAttachmentPixelFormat = dfmt, pipelineDesc.stencilAttachmentPixelFormat = dfmt;
            else if (dfmt == MTLPixelFormatDepth32Float)
                pipelineDesc.depthAttachmentPixelFormat = dfmt;
        }
        
        // Set up vertex function
        if (CreateInfo.pVS != nullptr)
        {
            auto* pVS = static_cast<ShaderMtlImpl*>(CreateInfo.pVS);
            NSString* entryPoint = [NSString stringWithUTF8String:pVS->GetEntryPoint().c_str()];
            id<MTLFunction> vertexFunc = [pVS->GetMtlLibrary() newFunctionWithName:entryPoint];
            if (vertexFunc != nil)
            {
                pipelineDesc.vertexFunction = vertexFunc;
                [vertexFunc release];
                this->m_ActiveShaderStages |= SHADER_TYPE_VERTEX;
            }
        }
        
        // Set up fragment function
        if (CreateInfo.pPS != nullptr)
        {
            auto* pPS = static_cast<ShaderMtlImpl*>(CreateInfo.pPS);
            NSString* entryPoint = [NSString stringWithUTF8String:pPS->GetEntryPoint().c_str()];
            id<MTLFunction> fragmentFunc = [pPS->GetMtlLibrary() newFunctionWithName:entryPoint];
            if (fragmentFunc != nil)
            {
                pipelineDesc.fragmentFunction = fragmentFunc;
                [fragmentFunc release];
                this->m_ActiveShaderStages |= SHADER_TYPE_PIXEL;
            }
        }
        
        // Set up vertex descriptor for ImGui - this fixes "no vertex descriptor was set" error
        if (CreateInfo.GraphicsPipeline.InputLayout.NumElements > 0)
        {
            LOG_INFO_MESSAGE("Metal: Setting up vertex descriptor with ", CreateInfo.GraphicsPipeline.InputLayout.NumElements, " elements");
            MTLVertexDescriptor* vertexDesc = [[MTLVertexDescriptor alloc] init];
            
            for (Uint32 i = 0; i < CreateInfo.GraphicsPipeline.InputLayout.NumElements; ++i)
            {
                const auto& element = CreateInfo.GraphicsPipeline.InputLayout.LayoutElements[i];
                
                // Configure vertex attribute
                vertexDesc.attributes[element.InputIndex].bufferIndex = element.BufferSlot;
                vertexDesc.attributes[element.InputIndex].offset = element.RelativeOffset;
                
                // Convert DiligentEngine vertex type to Metal format
                switch (element.ValueType)
                {
                    case VT_FLOAT32:
                        if (element.NumComponents == 1) vertexDesc.attributes[element.InputIndex].format = MTLVertexFormatFloat;
                        else if (element.NumComponents == 2) vertexDesc.attributes[element.InputIndex].format = MTLVertexFormatFloat2;
                        else if (element.NumComponents == 3) vertexDesc.attributes[element.InputIndex].format = MTLVertexFormatFloat3;
                        else if (element.NumComponents == 4) vertexDesc.attributes[element.InputIndex].format = MTLVertexFormatFloat4;
                        break;
                    case VT_UINT8:
                        if (element.IsNormalized)
                        {
                            if (element.NumComponents == 4) vertexDesc.attributes[element.InputIndex].format = MTLVertexFormatUChar4Normalized;
                        }
                        else
                        {
                            if (element.NumComponents == 4) vertexDesc.attributes[element.InputIndex].format = MTLVertexFormatUChar4;
                        }
                        break;
                    default:
                        LOG_WARNING_MESSAGE("Metal: Unsupported vertex format: ValueType=", element.ValueType, 
                                          ", NumComponents=", element.NumComponents);
                        // Default to Float4 for unknown types
                        vertexDesc.attributes[element.InputIndex].format = MTLVertexFormatFloat4;
                        break;
                }
            }
            
            // Calculate and set vertex buffer stride
            Uint32 maxStride = 0;
            for (Uint32 i = 0; i < CreateInfo.GraphicsPipeline.InputLayout.NumElements; ++i)
            {
                const auto& element = CreateInfo.GraphicsPipeline.InputLayout.LayoutElements[i];
                Uint32 elementSize = 0;
                switch (element.ValueType)
                {
                    case VT_FLOAT32: elementSize = element.NumComponents * 4; break;
                    case VT_UINT8:   elementSize = element.NumComponents * 1; break;
                    default: elementSize = element.NumComponents * 4; break; // Default to 4 bytes
                }
                maxStride = std::max(maxStride, element.RelativeOffset + elementSize);
            }
            
            // Configure vertex buffer layout (assuming single interleaved buffer for now)
            vertexDesc.layouts[0].stride = maxStride;
            vertexDesc.layouts[0].stepFunction = MTLVertexStepFunctionPerVertex;
            vertexDesc.layouts[0].stepRate = 1;
            
            pipelineDesc.vertexDescriptor = vertexDesc;
            LOG_INFO_MESSAGE("Metal: Vertex descriptor configured with stride=", maxStride);
            [vertexDesc release];
        }
        
        NSError* error = nil;
        m_MtlRenderPipeline = [mtlDevice newRenderPipelineStateWithDescriptor:pipelineDesc error:&error];
        [pipelineDesc release];
        
        if (m_MtlRenderPipeline == nil || error != nil)
        {
            if (error != nil)
            {
                NSString* errorMsg = [error localizedDescription];
                LOG_ERROR_AND_THROW("Failed to create Metal render pipeline state: ", [errorMsg UTF8String]);
            }
            else
            {
                LOG_ERROR_AND_THROW("Failed to create Metal render pipeline state: unknown error");
            }
        }
        else
        {
            LOG_INFO_MESSAGE("Metal render pipeline state created successfully");
        }
    }
}

// Helper method to create Metal compute pipeline
void PipelineStateMtlImpl::CreateMetalComputePipeline(const ComputePipelineStateCreateInfo& CreateInfo)
{
    RenderDeviceMtlImpl* pRenderDeviceMtl = static_cast<RenderDeviceMtlImpl*>(this->GetDevice());
    id<MTLDevice> mtlDevice = pRenderDeviceMtl->GetMtlDevice();
    
    @autoreleasepool
    {
        if (CreateInfo.pCS != nullptr)
        {
            auto* pCS = static_cast<ShaderMtlImpl*>(CreateInfo.pCS);
            NSString* entryPoint = [NSString stringWithUTF8String:pCS->GetEntryPoint().c_str()];
            id<MTLFunction> computeFunc = [pCS->GetMtlLibrary() newFunctionWithName:entryPoint];
            
            if (computeFunc != nil)
            {
                NSError* error = nil;
                m_MtlComputePipeline = [mtlDevice newComputePipelineStateWithFunction:computeFunc error:&error];
                [computeFunc release];
                
                if (m_MtlComputePipeline == nil || error != nil)
                {
                    if (error != nil)
                    {
                        NSString* errorMsg = [error localizedDescription];
                        LOG_ERROR_AND_THROW("Failed to create Metal compute pipeline state: ", [errorMsg UTF8String]);
                    }
                    else
                    {
                        LOG_ERROR_AND_THROW("Failed to create Metal compute pipeline state: unknown error");
                    }
                }
                else
                {
                    LOG_INFO_MESSAGE("Metal compute pipeline state created successfully");
                    this->m_ActiveShaderStages |= SHADER_TYPE_COMPUTE;
                }
            }
        }
    }
}

// InitializePipeline implementations invoked by base class Construct() after
// resource signature memory has been reserved & copied. These methods finish
// implicit signature initialization (if using the implicit path) and then
// create the native Metal pipeline objects.
void PipelineStateMtlImpl::InitializePipeline(const GraphicsPipelineStateCreateInfo& CreateInfo)
{
    LOG_INFO_MESSAGE("Metal: InitializePipeline(Graphics) begin for PSO: ", CreateInfo.PSODesc.Name ? CreateInfo.PSODesc.Name : "unnamed");
    // Replicate other backends: reserve memory for pipeline desc & signatures, then init implicit signature (if any), then create native pipeline.
    FixedLinearAllocator MemPool{GetRawAllocator()};
    // Reserve space for graphics pipeline data (desc + layout + signatures).
    ReserveSpaceForPipelineDesc(CreateInfo, MemPool);
    MemPool.Reserve();
    InitializePipelineDesc(CreateInfo, MemPool);

    // Implicit signature creation (if requested) using shader list.
    if (m_UsingImplicitSignature && m_SignatureCount == 1 && m_Signatures[0] == nullptr)
    {
        TShaderStages ShaderStages;
        SHADER_TYPE   StagesMask = SHADER_TYPE_UNKNOWN;
        auto Add = [&](IShader* pShader) {
            if (!pShader) return;
            RefCntAutoPtr<ShaderMtlImpl> pShaderImpl{pShader, ShaderMtlImpl::IID_InternalImpl};
            if (!pShaderImpl) return;
            ShaderStageInfo S; S.pShader = pShaderImpl; S.Type = pShaderImpl->GetDesc().ShaderType; ShaderStages.push_back(S);
            StagesMask |= S.Type;
        };
        Add(CreateInfo.pVS); Add(CreateInfo.pPS); Add(CreateInfo.pGS); Add(CreateInfo.pHS); Add(CreateInfo.pDS); Add(CreateInfo.pAS); Add(CreateInfo.pMS);
        const auto SignDesc = GetDefaultResourceSignatureDesc(ShaderStages, m_Desc.Name, m_Desc.ResourceLayout, m_Desc.SRBAllocationGranularity);
        InitDefaultSignature(SignDesc, StagesMask, false);
        LOG_INFO_MESSAGE("Metal: Implicit resource signature initialized (graphics) with ", (m_Signatures[0] ? m_Signatures[0]->GetDesc().NumResources : 0), " resources");
    }

    CreateMetalGraphicsPipeline(CreateInfo);
    LOG_INFO_MESSAGE("Metal: InitializePipeline(Graphics) completed");
}

void PipelineStateMtlImpl::InitializePipeline(const ComputePipelineStateCreateInfo& CreateInfo)
{
    LOG_INFO_MESSAGE("Metal: InitializePipeline(Compute) begin for PSO: ", CreateInfo.PSODesc.Name ? CreateInfo.PSODesc.Name : "unnamed");
    FixedLinearAllocator MemPool{GetRawAllocator()};
    ReserveSpaceForPipelineDesc(CreateInfo, MemPool);
    MemPool.Reserve();
    InitializePipelineDesc(CreateInfo, MemPool);
    if (m_UsingImplicitSignature && m_SignatureCount == 1 && m_Signatures[0] == nullptr)
    {
        TShaderStages ShaderStages;
        SHADER_TYPE   StagesMask = SHADER_TYPE_UNKNOWN;
        if (CreateInfo.pCS)
        {
            RefCntAutoPtr<ShaderMtlImpl> pShaderImpl{CreateInfo.pCS, ShaderMtlImpl::IID_InternalImpl};
            if (pShaderImpl)
            {
                ShaderStageInfo S; S.pShader = pShaderImpl; S.Type = SHADER_TYPE_COMPUTE; ShaderStages.push_back(S); StagesMask |= SHADER_TYPE_COMPUTE;
            }
        }
        const auto SignDesc = GetDefaultResourceSignatureDesc(ShaderStages, m_Desc.Name, m_Desc.ResourceLayout, m_Desc.SRBAllocationGranularity);
        InitDefaultSignature(SignDesc, StagesMask, false);
        LOG_INFO_MESSAGE("Metal: Implicit resource signature initialized (compute) with ", (m_Signatures[0] ? m_Signatures[0]->GetDesc().NumResources : 0), " resources");
    }
    CreateMetalComputePipeline(CreateInfo);
    LOG_INFO_MESSAGE("Metal: InitializePipeline(Compute) completed");
}

void PipelineStateMtlImpl::InitializePipeline(const RayTracingPipelineStateCreateInfo& CreateInfo)
{
    LOG_ERROR_AND_THROW("Ray tracing pipelines are not supported in Metal backend");
}

id<MTLRenderPipelineState> PipelineStateMtlImpl::GetMtlRenderPipeline() const
{
    return m_MtlRenderPipeline;
}

id<MTLComputePipelineState> PipelineStateMtlImpl::GetMtlComputePipeline() const
{
    return m_MtlComputePipeline;
}

id<MTLDepthStencilState> PipelineStateMtlImpl::GetMtlDepthStencilState() const
{
    return m_MtlDepthStencilState;
}

PipelineResourceSignatureDescWrapper PipelineStateMtlImpl::GetDefaultResourceSignatureDesc(
    const TShaderStages&              ShaderStages,
    const char*                       PSOName,
    const PipelineResourceLayoutDesc& ResourceLayout,
    Uint32                            SRBAllocationGranularity)
{
    // For now, create a minimal resource signature with the given name and layout
    PipelineResourceSignatureDescWrapper SignDesc{PSOName, ResourceLayout, SRBAllocationGranularity};

    // Basic Metal pseudo-reflection: query each shader for declared resources via
    // ShaderMtlImpl::GetResourceCount / GetResourceDesc. This enables at least the
    // ImGui 'Constants' static constant buffer to appear so GetStaticVariableByName()
    // returns a valid handle instead of nullptr.
    for (const auto& Stage : ShaderStages)
    {
        if (Stage.pShader)
        {
            const Uint32 ResCount = Stage.pShader->GetResourceCount();
            for (Uint32 r = 0; r < ResCount; ++r)
            {
                ShaderResourceDesc ResDesc;
                Stage.pShader->GetResourceDesc(r, ResDesc);
                if (ResDesc.Type == SHADER_RESOURCE_TYPE_CONSTANT_BUFFER || ResDesc.Type == SHADER_RESOURCE_TYPE_TEXTURE_SRV)
                {
                    LOG_INFO_MESSAGE("Metal: Pseudo-reflection found resource name='", ResDesc.Name, "' type=", (int)ResDesc.Type, " stage=0x", std::hex, Stage.Type, std::dec);
                    bool Merged = false;
                    const auto& CurrDesc = SignDesc.Get();
                    for (Uint32 existing = 0; existing < CurrDesc.NumResources; ++existing)
                    {
                        auto& ExistingRes = const_cast<PipelineResourceDesc&>(CurrDesc.Resources[existing]);
                        if (ExistingRes.ResourceType == ResDesc.Type && strcmp(ExistingRes.Name, ResDesc.Name) == 0)
                        {
                            const auto OldStages = ExistingRes.ShaderStages;
                            ExistingRes.ShaderStages |= Stage.Type;
                            if (ExistingRes.ShaderStages != OldStages)
                            {
                                LOG_INFO_MESSAGE("Metal: Merged stage mask for resource '", ResDesc.Name, "' -> stages=0x", std::hex, ExistingRes.ShaderStages, std::dec);
                            }
                            Merged = true;
                            break;
                        }
                    }
                    if (!Merged)
                    {
                        // Interim policy (until real Metal reflection): treat constant buffers AND sampled textures as STATIC
                        // so code paths using GetStaticVariableByName (e.g. ImGui font texture) succeed. We can later
                        // reclassify textures as mutable/dynamic once proper SRB binding is implemented.
                        const bool IsCB  = (ResDesc.Type == SHADER_RESOURCE_TYPE_CONSTANT_BUFFER);
                        const bool IsTex = (ResDesc.Type == SHADER_RESOURCE_TYPE_TEXTURE_SRV);
                        const auto VarType = (IsCB || IsTex) ? SHADER_RESOURCE_VARIABLE_TYPE_STATIC : SHADER_RESOURCE_VARIABLE_TYPE_DYNAMIC;
                        if (IsCB)
                            SignDesc.AddResource(Stage.Type, ResDesc.Name, SHADER_RESOURCE_TYPE_CONSTANT_BUFFER, VarType);
                        else if (IsTex)
                            SignDesc.AddResource(Stage.Type, ResDesc.Name, 1, SHADER_RESOURCE_TYPE_TEXTURE_SRV, VarType);
                        else
                            SignDesc.AddResource(Stage.Type, ResDesc.Name, 1, SHADER_RESOURCE_TYPE_TEXTURE_SRV, VarType); // Fallback (unlikely here)
                        LOG_INFO_MESSAGE("Metal: Added new resource '", ResDesc.Name, "' type=", (int)ResDesc.Type, " stages=0x", std::hex, Stage.Type, std::dec, " VarType=", (VarType==SHADER_RESOURCE_VARIABLE_TYPE_STATIC?"STATIC":"DYNAMIC"));
                    }
                }
                // Additional resource kinds (samplers, UAVs, etc.) can be added later.
            }
        }
    }
    return SignDesc;
}

// (Removed legacy InitResourceSignatureIfNeeded() helper that was used during
// transitional refactor. All implicit signature initialization now happens in
// InitializePipeline() matching other backends.)

} // namespace Diligent