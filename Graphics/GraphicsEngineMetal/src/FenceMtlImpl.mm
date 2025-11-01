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

#include "FenceMtlImpl.hpp"
#include "RenderDeviceMtlImpl.hpp"
#import <Metal/Metal.h>
#include <thread>

namespace Diligent
{

FenceMtlImpl::FenceMtlImpl(IReferenceCounters*  pRefCounters,
                           RenderDeviceMtlImpl* pDeviceMtl,
                           const FenceDesc&     Desc) :
    TFenceBase{pRefCounters, pDeviceMtl, Desc}
{
    if (@available(macOS 10.14, iOS 12.0, tvOS 12.0, *))
    {
        @autoreleasepool
        {
            id<MTLDevice> mtlDevice = pDeviceMtl->GetMtlDevice();
            m_MtlSharedEvent = [mtlDevice newSharedEvent];
            
            if (m_MtlSharedEvent == nil)
            {
                LOG_ERROR_AND_THROW("Failed to create Metal shared event");
            }
            
            m_MtlSharedEvent.signaledValue = 0;
        }
    }
    else
    {
        LOG_ERROR_AND_THROW("Metal shared events require macOS 10.14, iOS 12.0, or tvOS 12.0 or later");
    }
}

FenceMtlImpl::~FenceMtlImpl()
{
    if (@available(macOS 10.14, iOS 12.0, tvOS 12.0, *))
    {
        if (m_MtlSharedEvent != nil)
        {
            [m_MtlSharedEvent release];
            m_MtlSharedEvent = nil;
        }
    }
}

Uint64 FenceMtlImpl::GetCompletedValue()
{
    if (@available(macOS 10.14, iOS 12.0, tvOS 12.0, *))
    {
        return m_MtlSharedEvent != nil ? m_MtlSharedEvent.signaledValue : 0;
    }
    return 0;
}

void FenceMtlImpl::Signal(Uint64 Value)
{
    if (@available(macOS 10.14, iOS 12.0, tvOS 12.0, *))
    {
        if (m_MtlSharedEvent != nil)
        {
            m_MtlSharedEvent.signaledValue = Value;
        }
    }
}

void FenceMtlImpl::Wait(Uint64 Value)
{
    if (@available(macOS 10.14, iOS 12.0, tvOS 12.0, *))
    {
        if (m_MtlSharedEvent != nil)
        {
            // Busy wait until the event reaches the specified value
            while (m_MtlSharedEvent.signaledValue < Value)
            {
                // Yield CPU to avoid busy-waiting
                std::this_thread::yield();
            }
        }
    }
}

id<MTLSharedEvent> FenceMtlImpl::GetMtlSharedEvent() const
{
    if (@available(macOS 10.14, iOS 12.0, tvOS 12.0, *))
    {
        return m_MtlSharedEvent;
    }
    return nil;
}

} // namespace Diligent
