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

#include "TopLevelASMtlImpl.hpp"
#include "RenderDeviceMtlImpl.hpp"
#include "Cast.hpp"
#import <Metal/Metal.h>

namespace Diligent
{

TopLevelASMtlImpl::TopLevelASMtlImpl(IReferenceCounters*   pRefCounters,
                                     RenderDeviceMtlImpl*  pDeviceMtl,
                                     const TopLevelASDesc& Desc,
                                     bool                  IsDeviceInternal) :
    TTopLevelASBase{pRefCounters, pDeviceMtl, Desc, IsDeviceInternal}
{
    if (@available(macOS 11.0, iOS 14.0, *))
    {
        @autoreleasepool
        {
            id<MTLDevice> mtlDevice = pDeviceMtl->GetMtlDevice();
            
            // Create instance acceleration structure descriptor
            MTLInstanceAccelerationStructureDescriptor* asDesc = 
                [MTLInstanceAccelerationStructureDescriptor descriptor];
            
            asDesc.instanceCount = Desc.MaxInstanceCount;
            
            // Calculate sizes
            MTLAccelerationStructureSizes sizes = 
                [mtlDevice accelerationStructureSizesWithDescriptor:asDesc];
            
            // Create acceleration structure
            m_MtlAccelStruct = [mtlDevice newAccelerationStructureWithSize:sizes.accelerationStructureSize];
            
            if (m_MtlAccelStruct == nil)
            {
                LOG_ERROR_AND_THROW("Failed to create Metal top-level acceleration structure");
            }
        }
    }
    else
    {
        LOG_ERROR_AND_THROW("Metal ray tracing requires macOS 11.0, iOS 14.0 or later");
    }
}

TopLevelASMtlImpl::~TopLevelASMtlImpl()
{
    if (@available(macOS 11.0, iOS 14.0, *))
    {
        if (m_MtlAccelStruct != nil)
        {
            [m_MtlAccelStruct release];
            m_MtlAccelStruct = nil;
        }
    }
}

id<MTLAccelerationStructure> TopLevelASMtlImpl::GetMtlAccelerationStructure() const
{
    if (@available(macOS 11.0, iOS 14.0, *))
    {
        return m_MtlAccelStruct;
    }
    return nil;
}

Uint64 TopLevelASMtlImpl::GetNativeHandle()
{
    if (@available(macOS 11.0, iOS 14.0, *))
    {
        return BitCast<Uint64>(m_MtlAccelStruct);
    }
    return 0;
}

} // namespace Diligent
