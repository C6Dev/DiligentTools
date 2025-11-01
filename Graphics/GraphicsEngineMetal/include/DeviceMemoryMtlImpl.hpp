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
/// Declaration of Diligent::DeviceMemoryMtlImpl class

#include "EngineMtlImplTraits.hpp"
#include "DeviceMemoryBase.hpp"

namespace Diligent
{

/// Device memory object implementation in Metal backend.
class DeviceMemoryMtlImpl final : public DeviceMemoryBase<EngineMtlImplTraits>
{
public:
    using TDeviceMemoryBase = DeviceMemoryBase<EngineMtlImplTraits>;

    static constexpr INTERFACE_ID IID_InternalImpl =
        {0x8b2c6f8a, 0x4c5d, 0x4e8f, {0x9b, 0x1a, 0x2c, 0x3d, 0x5e, 0x7f, 0x8a, 0x1c}};

    DeviceMemoryMtlImpl(IReferenceCounters*           pRefCounters,
                        RenderDeviceMtlImpl*          pDevice,
                        const DeviceMemoryCreateInfo& MemCI);

    ~DeviceMemoryMtlImpl();

    virtual void DILIGENT_CALL_TYPE QueryInterface(const INTERFACE_ID& IID, IObject** ppInterface) override final;

    /// Implementation of IDeviceMemory::Resize().
    virtual Bool DILIGENT_CALL_TYPE Resize(Uint64 NewSize) override final;

    /// Implementation of IDeviceMemory::GetCapacity().
    virtual Uint64 DILIGENT_CALL_TYPE GetCapacity() const override final;

    /// Implementation of IDeviceMemory::IsCompatible().
    virtual Bool DILIGENT_CALL_TYPE IsCompatible(IDeviceObject* pResource) const override final;

    /// Implementation of IDeviceMemoryMtl::GetMtlResource().
    virtual id<MTLHeap> DILIGENT_CALL_TYPE GetMtlResource() const override final;

private:
    id<MTLHeap> m_MtlHeap = nullptr;
};

} // namespace Diligent