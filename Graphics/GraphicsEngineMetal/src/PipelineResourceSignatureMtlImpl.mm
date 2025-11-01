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

#include "PipelineResourceSignatureMtlImpl.hpp"
#include "RenderDeviceMtlImpl.hpp"

namespace Diligent
{

PipelineResourceSignatureMtlImpl::PipelineResourceSignatureMtlImpl(IReferenceCounters*                  pRefCounters,
                                                                   RenderDeviceMtlImpl*                 pRenderDeviceMtl,
                                                                   const PipelineResourceSignatureDesc& Desc,
                                                                   SHADER_TYPE                          ShaderStages,
                                                                   bool                                 IsDeviceInternal) :
    TPRSBase{pRefCounters, pRenderDeviceMtl, Desc, ShaderStages, IsDeviceInternal}
{
    // Initialize base signature infrastructure (static variable managers, resource attribs, etc.).
    try
    {
        Initialize(
            GetRawAllocator(), Desc,
            /*CreateImmutableSamplers=*/true,
            // InitResourceLayout - no additional backend-specific work for Metal yet.
            [this]() {},
            // GetRequiredResourceCacheMemorySize - Metal SRB cache sizing minimal for now.
            []() -> size_t { return 0; } // No descriptor sets; binding is direct at draw time.
        );
    }
    catch (...)
    {
        Destruct();
        throw;
    }
}

PipelineResourceSignatureMtlImpl::~PipelineResourceSignatureMtlImpl()
{
    Destruct();
}

void PipelineResourceSignatureMtlImpl::Destruct()
{
    // No Metal-specific GPU objects yet; just invoke base cleanup so that
    // ~PipelineResourceSignatureBase() assertion is satisfied.
    TPRSBase::Destruct();
}

void PipelineResourceSignatureMtlImpl::InitSRBResourceCache(ShaderResourceCacheMtl& ResourceCache)
{
    // Stub implementation - Metal handles resource binding differently
    // No explicit descriptor sets like Vulkan
}

void PipelineResourceSignatureMtlImpl::CopyStaticResources(ShaderResourceCacheMtl& DstResourceCache) const
{
    // Stub implementation - Metal handles static resources through shader reflection
    // No explicit copying needed like in D3D12/Vulkan descriptor sets
}

} // namespace Diligent
