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
/// Declaration of Diligent::BufferViewMtlImpl class

#include "EngineMtlImplTraits.hpp"
#include "BufferViewBase.hpp"

#import <Metal/Metal.h>

namespace Diligent
{

/// Buffer view implementation in Metal backend.
class BufferViewMtlImpl final : public BufferViewBase<EngineMtlImplTraits>
{
public:
    using TBufferViewBase = BufferViewBase<EngineMtlImplTraits>;

    BufferViewMtlImpl(IReferenceCounters*   pRefCounters,
                      RenderDeviceMtlImpl*  pDevice,
                      const BufferViewDesc& ViewDesc,
                      IBuffer*              pBuffer,
                      bool                  bIsDefaultView);
    ~BufferViewMtlImpl();

    IMPLEMENT_QUERY_INTERFACE_IN_PLACE(IID_BufferViewMtl, TBufferViewBase)

    /// Implementation of IBufferViewMtl::GetMtlTextureView().
    virtual id<MTLTexture> DILIGENT_CALL_TYPE GetMtlTextureView() const override final;

protected:
    id<MTLTexture> m_MtlTextureView = nil;
};

} // namespace Diligent
