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

#include "BufferViewMtlImpl.hpp"
#include "RenderDeviceMtlImpl.hpp"
#include "BufferMtlImpl.hpp"
#include "Cast.hpp"
#import <Metal/Metal.h>

namespace Diligent
{

BufferViewMtlImpl::BufferViewMtlImpl(IReferenceCounters*   pRefCounters,
                                     RenderDeviceMtlImpl*  pDevice,
                                     const BufferViewDesc& ViewDesc,
                                     IBuffer*              pBuffer,
                                     bool                  bIsDefaultView) :
    TBufferViewBase{pRefCounters, pDevice, ViewDesc, pBuffer, bIsDefaultView}
{
    // For formatted buffer views, create MTLTexture view
    if (ViewDesc.Format.ValueType != VT_UNDEFINED)
    {
        @autoreleasepool
        {
            auto* pBufferMtl = ClassPtrCast<BufferMtlImpl>(pBuffer);
            id<MTLBuffer> mtlBuffer = pBufferMtl->GetMtlResource();
            (void)mtlBuffer; // Suppress unused warning - will be used when texture buffer views are implemented
            
            // Create texture view for formatted buffer
            // Note: Metal texture buffers are created differently than Vulkan
            // For now, we store nil and will implement when needed
            m_MtlTextureView = nil;
        }
    }
}

BufferViewMtlImpl::~BufferViewMtlImpl()
{
    if (m_MtlTextureView != nil)
    {
        [m_MtlTextureView release];
        m_MtlTextureView = nil;
    }
}

id<MTLTexture> BufferViewMtlImpl::GetMtlTextureView() const
{
    return m_MtlTextureView;
}

} // namespace Diligent
