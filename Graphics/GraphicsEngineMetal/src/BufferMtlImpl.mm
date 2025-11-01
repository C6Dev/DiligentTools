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

#include "BufferMtlImpl.hpp"
#include "BufferViewMtlImpl.hpp"
#include "RenderDeviceMtlImpl.hpp"
#include "Cast.hpp"
#import <Metal/Metal.h>

namespace Diligent
{

BufferMtlImpl::BufferMtlImpl(IReferenceCounters*        pRefCounters,
                             FixedBlockMemoryAllocator& BuffViewObjMemAllocator,
                             RenderDeviceMtlImpl*       pDeviceMtl,
                             const BufferDesc&          BuffDesc,
                             const BufferData*          pBuffData) :
    TBufferBase{pRefCounters, BuffViewObjMemAllocator, pDeviceMtl, BuffDesc, false}
{
    @autoreleasepool
    {
        id<MTLDevice> mtlDevice = pDeviceMtl->GetMtlDevice();
        
        if (pBuffData != nullptr && pBuffData->pData != nullptr && BuffDesc.Size > 0)
        {
            // Create buffer with initial data - use shared storage for data upload
            m_MtlBuffer = [mtlDevice newBufferWithBytes:pBuffData->pData
                                                 length:BuffDesc.Size
                                                options:MTLResourceStorageModeShared];
        }
        else if (BuffDesc.Size > 0)
        {
            // Create empty buffer - can use private storage for GPU-only buffers
            MTLResourceOptions options = MTLResourceStorageModeShared;
            if (BuffDesc.Usage == USAGE_DEFAULT || BuffDesc.Usage == USAGE_IMMUTABLE)
            {
                options = MTLResourceStorageModePrivate;
            }
            
            m_MtlBuffer = [mtlDevice newBufferWithLength:BuffDesc.Size
                                                  options:options];
        }
        else
        {
            LOG_ERROR_AND_THROW("Cannot create buffer with zero size");
        }
        
        if (m_MtlBuffer == nil)
        {
            LOG_ERROR_AND_THROW("Failed to create Metal buffer");
        }
    }
}

BufferMtlImpl::BufferMtlImpl(IReferenceCounters*        pRefCounters,
                             FixedBlockMemoryAllocator& BuffViewObjMemAllocator,
                             RenderDeviceMtlImpl*       pDeviceMtl,
                             const BufferDesc&          BuffDesc,
                             RESOURCE_STATE             InitialState,
                             id<MTLBuffer>              mtlBuffer) :
    TBufferBase{pRefCounters, BuffViewObjMemAllocator, pDeviceMtl, BuffDesc, false},
    m_MtlBuffer{mtlBuffer}
{
    if (m_MtlBuffer != nil)
    {
        [m_MtlBuffer retain];
    }
}

BufferMtlImpl::~BufferMtlImpl()
{
    if (m_MtlBuffer != nil)
    {
        [m_MtlBuffer release];
        m_MtlBuffer = nil;
    }
}

id<MTLBuffer> BufferMtlImpl::GetMtlResource() const
{
    return m_MtlBuffer;
}

Uint64 BufferMtlImpl::GetNativeHandle()
{
    return BitCast<Uint64>(m_MtlBuffer);
}

SparseBufferProperties BufferMtlImpl::GetSparseProperties() const
{
    DEV_ERROR("IBuffer::GetSparseProperties() is not yet supported in Metal backend");
    return {};
}

void BufferMtlImpl::CreateViewInternal(const BufferViewDesc& ViewDesc, IBufferView** ppView, bool bIsDefaultView)
{
    VERIFY(ppView != nullptr, "Null pointer provided");
    if (!ppView) return;
    VERIFY(*ppView == nullptr, "Overwriting reference to existing object may cause memory leaks");

    *ppView = nullptr;

    try
    {
        auto* pDeviceMtl = GetDevice();
        auto& BuffViewAllocator = pDeviceMtl->GetBuffViewObjAllocator();
        VERIFY(&BuffViewAllocator == &m_dbgBuffViewAllocator, "Buff view allocator does not match allocator provided during buffer initialization");

        BufferViewMtlImpl* pViewMtl = NEW_RC_OBJ(BuffViewAllocator, "BufferViewMtlImpl instance", BufferViewMtlImpl)
                                      (GetDevice(), ViewDesc, this, bIsDefaultView);
        pViewMtl->QueryInterface(IID_BufferView, reinterpret_cast<IObject**>(ppView));
    }
    catch (const std::runtime_error&)
    {
        const auto* ViewTypeName = GetBufferViewTypeLiteralName(ViewDesc.ViewType);
        LOG_ERROR("Failed to create view \"", ViewDesc.Name ? ViewDesc.Name : "", "\" (", ViewTypeName, ") for buffer \"", m_Desc.Name, "\"");
    }
}

} // namespace Diligent
