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
/// Declaration of Diligent::PipelineStateMtlImpl class

#include "EngineMtlImplTraits.hpp"
#include "PipelineResourceSignatureMtlImpl.hpp" // Required by PipelineStateBase
#include "PipelineStateBase.hpp"

namespace Diligent
{

/// Implementation of a pipeline state object in Metal backend.
class PipelineStateMtlImpl final : public PipelineStateBase<EngineMtlImplTraits>
{
public:
    using TPipelineStateBase = PipelineStateBase<EngineMtlImplTraits>;
    
    struct ShaderStageInfo
    {
        SHADER_TYPE Type = SHADER_TYPE_UNKNOWN;
        const ShaderMtlImpl* pShader = nullptr;
        ShaderStageInfo() = default;
        explicit ShaderStageInfo(const RefCntAutoPtr<ShaderMtlImpl>& Shader)
        {
            pShader = Shader;
            if (pShader)
                Type = pShader->GetDesc().ShaderType;
        }
        
        friend SHADER_TYPE GetShaderStageType(const ShaderStageInfo& Stage) { return Stage.Type; }
        friend std::vector<const ShaderMtlImpl*> GetStageShaders(const ShaderStageInfo& Stage) { return {Stage.pShader}; }
    };
    using TShaderStages = std::vector<ShaderStageInfo>;

    static constexpr INTERFACE_ID IID_InternalImpl =
        {0x8b2c6f8a, 0x4c5d, 0x4e8f, {0x9b, 0x1a, 0x2c, 0x3d, 0x5e, 0x7f, 0x8a, 0x1b}};

    PipelineStateMtlImpl(IReferenceCounters*                    pRefCounters,
                         RenderDeviceMtlImpl*                   pRenderDeviceMtl,
                         const GraphicsPipelineStateCreateInfo& CreateInfo,
                         bool                                   IsDeviceInternal = false);

    PipelineStateMtlImpl(IReferenceCounters*                   pRefCounters,
                         RenderDeviceMtlImpl*                  pRenderDeviceMtl,
                         const ComputePipelineStateCreateInfo& CreateInfo,
                         bool                                  IsDeviceInternal = false);

    PipelineStateMtlImpl(IReferenceCounters*                         pRefCounters,
                         RenderDeviceMtlImpl*                        pRenderDeviceMtl,
                         const RayTracingPipelineStateCreateInfo&    CreateInfo,
                         bool                                        IsDeviceInternal = false);

    ~PipelineStateMtlImpl();

    IMPLEMENT_QUERY_INTERFACE2_IN_PLACE(IID_PipelineStateMtl, IID_InternalImpl, TPipelineStateBase)

    /// Implementation of IPipelineStateMtl::GetMtlRenderPipeline().
    virtual id<MTLRenderPipelineState> DILIGENT_CALL_TYPE GetMtlRenderPipeline() const override final;

    /// Implementation of IPipelineStateMtl::GetMtlComputePipeline().
    virtual id<MTLComputePipelineState> DILIGENT_CALL_TYPE GetMtlComputePipeline() const override final;

    /// Implementation of IPipelineStateMtl::GetMtlDepthStencilState().
    virtual id<MTLDepthStencilState> DILIGENT_CALL_TYPE GetMtlDepthStencilState() const override final;

    static PipelineResourceSignatureDescWrapper GetDefaultResourceSignatureDesc(
        const TShaderStages&              ShaderStages,
        const char*                       PSOName,
        const PipelineResourceLayoutDesc& ResourceLayout,
        Uint32                            SRBAllocationGranularity);

    // TPipelineStateBase::Construct needs access to InitializePipeline
    friend TPipelineStateBase;

private:
    // Required initialization methods called by base class Construct() - not used in our simple approach
    void InitializePipeline(const GraphicsPipelineStateCreateInfo& CreateInfo);
    void InitializePipeline(const ComputePipelineStateCreateInfo& CreateInfo);
    void InitializePipeline(const RayTracingPipelineStateCreateInfo& CreateInfo);

    // Releases Metal-specific objects then calls base class Destruct().
    void Destruct();
    
    // Helper methods for Metal pipeline creation
    void CreateMetalGraphicsPipeline(const GraphicsPipelineStateCreateInfo& CreateInfo);
    void CreateMetalComputePipeline(const ComputePipelineStateCreateInfo& CreateInfo);
    
    id<MTLRenderPipelineState>  m_MtlRenderPipeline  = nil;
    id<MTLComputePipelineState> m_MtlComputePipeline = nil;
    id<MTLDepthStencilState>    m_MtlDepthStencilState = nil;
};

} // namespace Diligent
