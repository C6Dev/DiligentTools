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
/// Declaration of Diligent::BottomLevelASMtlImpl class

#include "EngineMtlImplTraits.hpp"
#include "BottomLevelASBase.hpp"

#import <Metal/Metal.h>

namespace Diligent
{

/// Bottom-level acceleration structure implementation in Metal backend.
class BottomLevelASMtlImpl final : public BottomLevelASBase<EngineMtlImplTraits>
{
public:
    using TBottomLevelASBase = BottomLevelASBase<EngineMtlImplTraits>;

    BottomLevelASMtlImpl(IReferenceCounters*        pRefCounters,
                         RenderDeviceMtlImpl*       pDeviceMtl,
                         const BottomLevelASDesc&   Desc,
                         bool                       IsDeviceInternal = false);
    ~BottomLevelASMtlImpl();

    IMPLEMENT_QUERY_INTERFACE_IN_PLACE(IID_BottomLevelASMtl, TBottomLevelASBase)

    /// Implementation of IBottomLevelASMtl::GetMtlAccelerationStructure().
    virtual id<MTLAccelerationStructure> DILIGENT_CALL_TYPE GetMtlAccelerationStructure() const API_AVAILABLE(ios(14), macosx(11.0)) API_UNAVAILABLE(tvos) override final;

    /// Implementation of IBottomLevelAS::GetNativeHandle().
    virtual Uint64 DILIGENT_CALL_TYPE GetNativeHandle() override final;

private:
    id<MTLAccelerationStructure> m_MtlAccelStruct API_AVAILABLE(ios(14), macosx(11.0)) API_UNAVAILABLE(tvos) = nil;
};

} // namespace Diligent
