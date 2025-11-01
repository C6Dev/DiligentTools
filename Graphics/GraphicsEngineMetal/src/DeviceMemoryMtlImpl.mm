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

#include "DeviceMemoryMtlImpl.hpp"
#include "RenderDeviceMtlImpl.hpp"

namespace Diligent
{

DeviceMemoryMtlImpl::DeviceMemoryMtlImpl(IReferenceCounters*           pRefCounters,
                                         RenderDeviceMtlImpl*          pDevice,
                                         const DeviceMemoryCreateInfo& MemCI) :
    TDeviceMemoryBase{pRefCounters, pDevice, MemCI}
{
    // Metal has limited support for sparse resources compared to Vulkan/D3D12
    // This is a stub implementation
    LOG_WARNING_MESSAGE("DeviceMemoryMtlImpl is not fully implemented. Metal has limited sparse resource support.");
}

DeviceMemoryMtlImpl::~DeviceMemoryMtlImpl()
{
    if (m_MtlHeap != nil)
    {
        [m_MtlHeap release];
        m_MtlHeap = nil;
    }
}

void DeviceMemoryMtlImpl::QueryInterface(const INTERFACE_ID& IID, IObject** ppInterface)
{
    if (ppInterface == nullptr)
        return;

    *ppInterface = nullptr;
    if (IID == IID_DeviceMemoryMtl || IID == IID_InternalImpl)
    {
        *ppInterface = this;
        (*ppInterface)->AddRef();
    }
    else
    {
        TDeviceMemoryBase::QueryInterface(IID, ppInterface);
    }
}

Bool DeviceMemoryMtlImpl::Resize(Uint64 NewSize)
{
    // Metal sparse resources are not resizable like Vulkan
    LOG_ERROR_MESSAGE("Resize is not supported for Metal device memory");
    return false;
}

Uint64 DeviceMemoryMtlImpl::GetCapacity() const
{
    // Return 0 as Metal sparse resources are not fully supported
    return 0;
}

Bool DeviceMemoryMtlImpl::IsCompatible(IDeviceObject* pResource) const
{
    // Metal has limited sparse resource support
    return false;
}

id<MTLHeap> DeviceMemoryMtlImpl::GetMtlResource() const
{
    return m_MtlHeap;
}

} // namespace Diligent