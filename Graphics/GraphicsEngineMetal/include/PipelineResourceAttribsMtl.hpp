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
/// Declaration of Diligent::PipelineResourceAttribsMtl struct

#include "BasicTypes.h"
#include "ShaderResourceCacheCommon.hpp"
#include "PrivateConstants.h"
#include "DebugUtilities.hpp"
#include "HashUtils.hpp"

namespace Diligent
{

// sizeof(PipelineResourceAttribsMtl) == 16, x64
struct PipelineResourceAttribsMtl
{
private:
    static constexpr Uint32 _BindingIndexBits    = 16;
    static constexpr Uint32 _SamplerIndBits      = 16;
    static constexpr Uint32 _ArraySizeBits       = 24;
    static constexpr Uint32 _ResourceTypeBits    = 5;
    static constexpr Uint32 _SamplerAssignedBits = 1;
    static constexpr Uint32 _PaddingBits         = 2;

    static_assert((_BindingIndexBits + _ArraySizeBits + _SamplerIndBits + _ResourceTypeBits + _SamplerAssignedBits + _PaddingBits) % 32 == 0, "Bits are not optimally packed");

public:
    static constexpr Uint32 InvalidSamplerInd = (1u << _SamplerIndBits) - 1;

    // clang-format off
    const Uint32  BindingIndex         : _BindingIndexBits;    // Binding in the argument buffer
    const Uint32  SamplerInd           : _SamplerIndBits;      // Index of the assigned sampler in m_Desc.Resources and m_pPipelineResourceAttribsMtl
    const Uint32  ArraySize            : _ArraySizeBits;       // Array size
    const Uint32  ResourceType         : _ResourceTypeBits;    // Resource type (SHADER_RESOURCE_TYPE)
    const Uint32  ImtblSamplerAssigned : _SamplerAssignedBits; // Immutable sampler flag
    const Uint32  Padding              : _PaddingBits;          // Padding for alignment

    const Uint32  SRBCacheOffset;                              // Offset in the SRB resource cache
    const Uint32  StaticCacheOffset;                           // Offset in the static resource cache
    // clang-format on

    PipelineResourceAttribsMtl(Uint32                _BindingIndex,
                               Uint32                _SamplerInd,
                               Uint32                _ArraySize,
                               SHADER_RESOURCE_TYPE  _ResourceType,
                               bool                  _ImtblSamplerAssigned,
                               Uint32                _SRBCacheOffset,
                               Uint32                _StaticCacheOffset) noexcept :
        // clang-format off
        BindingIndex         {_BindingIndex                      },
        SamplerInd           {_SamplerInd                        },
        ArraySize            {_ArraySize                         },
        ResourceType         {static_cast<Uint32>(_ResourceType)},
        ImtblSamplerAssigned {_ImtblSamplerAssigned ? 1u : 0u   },
        Padding              {0                                  },
        SRBCacheOffset       {_SRBCacheOffset                    },
        StaticCacheOffset    {_StaticCacheOffset                 }
    // clang-format on
    {
        // clang-format off
        VERIFY(BindingIndex        == _BindingIndex, "Binding index (", _BindingIndex, ") exceeds maximum representable value");
        VERIFY(ArraySize           == _ArraySize,    "Array size (", _ArraySize, ") exceeds maximum representable value");
        VERIFY(SamplerInd          == _SamplerInd,   "Sampler index (", _SamplerInd, ") exceeds maximum representable value");
        VERIFY(GetResourceType()   == _ResourceType, "Resource type (", static_cast<Uint32>(_ResourceType), ") exceeds maximum representable value");
        // clang-format on
    }

    // Only for serialization
    PipelineResourceAttribsMtl() noexcept :
        PipelineResourceAttribsMtl{0, 0, 0, SHADER_RESOURCE_TYPE_UNKNOWN, false, 0, 0}
    {}

    Uint32 CacheOffset(ResourceCacheContentType CacheType) const
    {
        return CacheType == ResourceCacheContentType::SRB ? SRBCacheOffset : StaticCacheOffset;
    }

    SHADER_RESOURCE_TYPE GetResourceType() const
    {
        return static_cast<SHADER_RESOURCE_TYPE>(ResourceType);
    }

    bool IsImmutableSamplerAssigned() const
    {
        return ImtblSamplerAssigned != 0;
    }

    bool IsCombinedWithSampler() const
    {
        return SamplerInd != InvalidSamplerInd;
    }

    bool IsCompatibleWith(const PipelineResourceAttribsMtl& rhs) const
    {
        // Ignore sampler index and cache offsets.
        // clang-format off
        return BindingIndex         == rhs.BindingIndex &&
               ArraySize            == rhs.ArraySize    &&
               ResourceType         == rhs.ResourceType &&
               ImtblSamplerAssigned == rhs.ImtblSamplerAssigned;
        // clang-format on
    }

    size_t GetHash() const
    {
        return ComputeHash(BindingIndex, ArraySize, ResourceType, ImtblSamplerAssigned);
    }
};
ASSERT_SIZEOF(PipelineResourceAttribsMtl, 16, "The struct is used in serialization and must be tightly packed");

} // namespace Diligent