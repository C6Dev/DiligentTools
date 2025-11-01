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
/// Declaration of Diligent::BufferMtlImpl class

#include "EngineMtlImplTraits.hpp"
#include "BufferBase.hpp"

#import <Metal/Metal.h>

namespace Diligent
{

/// Buffer object implementation in Metal backend.
class BufferMtlImpl final : public BufferBase<EngineMtlImplTraits>
{
public:
    using TBufferBase = BufferBase<EngineMtlImplTraits>;

    BufferMtlImpl(IReferenceCounters*        pRefCounters,
                  FixedBlockMemoryAllocator& BuffViewObjMemAllocator,
                  RenderDeviceMtlImpl*       pDeviceMtl,
                  const BufferDesc&          BuffDesc,
                  const BufferData*          pBuffData = nullptr);

    BufferMtlImpl(IReferenceCounters*        pRefCounters,
                  FixedBlockMemoryAllocator& BuffViewObjMemAllocator,
                  RenderDeviceMtlImpl*       pDeviceMtl,
                  const BufferDesc&          BuffDesc,
                  RESOURCE_STATE             InitialState,
                  id<MTLBuffer>              mtlBuffer);

    ~BufferMtlImpl();

    IMPLEMENT_QUERY_INTERFACE_IN_PLACE(IID_BufferMtl, TBufferBase)

    /// Implementation of IBufferMtl::GetMtlResource().
    virtual id<MTLBuffer> DILIGENT_CALL_TYPE GetMtlResource() const override final;

    /// Implementation of IBuffer::GetNativeHandle() in Metal backend.
    virtual Uint64 DILIGENT_CALL_TYPE GetNativeHandle() override final;

    /// Implementation of IBuffer::GetSparseProperties().
    virtual SparseBufferProperties DILIGENT_CALL_TYPE GetSparseProperties() const override final;

protected:
    virtual void CreateViewInternal(const struct BufferViewDesc& ViewDesc, IBufferView** ppView, bool bIsDefaultView) override final;

private:
    id<MTLBuffer> m_MtlBuffer = nil;
};

} // namespace Diligent
