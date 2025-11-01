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

#include "SamplerMtlImpl.hpp"
#include "RenderDeviceMtlImpl.hpp"
#import <Metal/Metal.h>

namespace Diligent
{

static MTLSamplerMinMagFilter GetMtlFilter(FILTER_TYPE Filter)
{
    switch (Filter)
    {
        case FILTER_TYPE_POINT:
        case FILTER_TYPE_COMPARISON_POINT:
            return MTLSamplerMinMagFilterNearest;
        case FILTER_TYPE_LINEAR:
        case FILTER_TYPE_COMPARISON_LINEAR:
        case FILTER_TYPE_ANISOTROPIC:
        case FILTER_TYPE_COMPARISON_ANISOTROPIC:
            return MTLSamplerMinMagFilterLinear;
        default:
            return MTLSamplerMinMagFilterLinear;
    }
}

static MTLSamplerAddressMode GetMtlAddressMode(TEXTURE_ADDRESS_MODE Mode)
{
    switch (Mode)
    {
        case TEXTURE_ADDRESS_WRAP:
            return MTLSamplerAddressModeRepeat;
        case TEXTURE_ADDRESS_MIRROR:
            return MTLSamplerAddressModeMirrorRepeat;
        case TEXTURE_ADDRESS_CLAMP:
            return MTLSamplerAddressModeClampToEdge;
        case TEXTURE_ADDRESS_BORDER:
            return MTLSamplerAddressModeClampToBorderColor;
        default:
            return MTLSamplerAddressModeClampToEdge;
    }
}

SamplerMtlImpl::SamplerMtlImpl(IReferenceCounters*  pRefCounters,
                               RenderDeviceMtlImpl* pDeviceMtl,
                               const SamplerDesc&   SamplerDesc) :
    TSamplerBase{pRefCounters, pDeviceMtl, SamplerDesc}
{
    @autoreleasepool
    {
        id<MTLDevice> mtlDevice = pDeviceMtl->GetMtlDevice();
        
        MTLSamplerDescriptor* samplerDesc = [[MTLSamplerDescriptor alloc] init];
        
        samplerDesc.minFilter = GetMtlFilter(SamplerDesc.MinFilter);
        samplerDesc.magFilter = GetMtlFilter(SamplerDesc.MagFilter);
        samplerDesc.mipFilter = (SamplerDesc.MipFilter == FILTER_TYPE_POINT) ? 
                                MTLSamplerMipFilterNearest : MTLSamplerMipFilterLinear;
        
        samplerDesc.sAddressMode = GetMtlAddressMode(SamplerDesc.AddressU);
        samplerDesc.tAddressMode = GetMtlAddressMode(SamplerDesc.AddressV);
        samplerDesc.rAddressMode = GetMtlAddressMode(SamplerDesc.AddressW);
        
        samplerDesc.maxAnisotropy = SamplerDesc.MaxAnisotropy;
        samplerDesc.lodMinClamp = SamplerDesc.MinLOD;
        samplerDesc.lodMaxClamp = SamplerDesc.MaxLOD;
        
        m_MtlSampler = [mtlDevice newSamplerStateWithDescriptor:samplerDesc];
        [samplerDesc release];
        
        if (m_MtlSampler == nil)
        {
            LOG_ERROR_AND_THROW("Failed to create Metal sampler state");
        }
    }
}

SamplerMtlImpl::~SamplerMtlImpl()
{
    if (m_MtlSampler != nil)
    {
        [m_MtlSampler release];
        m_MtlSampler = nil;
    }
}

id<MTLSamplerState> SamplerMtlImpl::GetMtlSampler()
{
    return m_MtlSampler;
}

} // namespace Diligent
