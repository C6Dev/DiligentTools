/*
 *  Copyright 2019-2024 Diligent Graphics LLC
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

#include "ArchiverImpl.hpp"
#include "Archiver_Inc.hpp"

#include "../../GraphicsEngineMetal/include/PipelineResourceSignatureMtlImpl.hpp"

namespace Diligent
{

template <>
struct SerializedResourceSignatureImpl::SignatureTraits<PipelineResourceSignatureMtlImpl>
{
    static constexpr DeviceType Type = DeviceType::Metal_MacOS;

    template <SerializerMode Mode>
    using PRSSerializerType = PRSSerializer<Mode>; // Use base PRSSerializer since Metal-specific one is not implemented
};

template <typename CreateInfoType>
void SerializedPipelineStateImpl::PatchShadersMtl(const CreateInfoType& CreateInfo, DeviceType DevType, const std::string& DumpDir) noexcept(false)
{
    // Metal backend does not support archiving
    UNSUPPORTED("Metal backend does not support archiving");
}

INSTANTIATE_PATCH_SHADER_METHODS(PatchShadersMtl, DeviceType DevType, const std::string& DumpDir)
// Metal backend does not support archiving - remove device signature instantiation
// INSTANTIATE_DEVICE_SIGNATURE_METHODS(PipelineResourceSignatureMtlImpl)

void SerializedShaderImpl::CreateShaderMtl(IReferenceCounters*     pRefCounters,
                                           const ShaderCreateInfo& ShaderCI,
                                           DeviceType              Type,
                                           IDataBlob**             ppCompilerOutput) noexcept(false)
{
    // Metal backend does not support archiving
    UNSUPPORTED("Metal backend does not support archiving");
}

void SerializationDeviceImpl::GetPipelineResourceBindingsMtl(const PipelineResourceBindingAttribs& Info,
                                                             std::vector<PipelineResourceBinding>& ResourceBindings,
                                                             const Uint32                          MaxBufferArgs)
{
    // Metal backend does not support archiving
    UNSUPPORTED("Metal backend does not support archiving");
    ResourceBindings.clear();
}

} // namespace Diligent
