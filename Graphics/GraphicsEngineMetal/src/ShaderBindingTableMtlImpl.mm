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

#include "ShaderBindingTableMtlImpl.hpp"
#include "RenderDeviceMtlImpl.hpp"
#include "../../../Primitives/interface/Errors.hpp"
#include <atomic>

namespace Diligent
{

static std::atomic<Int32> g_NextUniqueID{1};

ShaderBindingTableMtlImpl::ShaderBindingTableMtlImpl(IReferenceCounters*           pRefCounters,
                                                     RenderDeviceMtlImpl*          pDevice,
                                                     const ShaderBindingTableDesc& Desc,
                                                     bool                          bIsDeviceInternal) :
    TBase{pRefCounters},
    m_Desc{Desc},
    m_UniqueID{g_NextUniqueID.fetch_add(1)}
{
    DEV_ERROR("Shader binding tables are not supported in Metal backend");
}

ShaderBindingTableMtlImpl::~ShaderBindingTableMtlImpl()
{
}

const ShaderBindingTableDesc& ShaderBindingTableMtlImpl::GetDesc() const
{
    return m_Desc;
}

Bool ShaderBindingTableMtlImpl::Verify(VERIFY_SBT_FLAGS Flags) const
{
    UNSUPPORTED("Shader binding tables are not supported in Metal backend");
    return false;
}

void ShaderBindingTableMtlImpl::Reset(IPipelineState* pPSO)
{
    UNSUPPORTED("Shader binding tables are not supported in Metal backend");
}

void ShaderBindingTableMtlImpl::ResetHitGroups()
{
    UNSUPPORTED("Shader binding tables are not supported in Metal backend");
}

void ShaderBindingTableMtlImpl::BindRayGenShader(const Char* pShaderGroupName,
                                                 const void* pData,
                                                 Uint32      DataSize)
{
    UNSUPPORTED("Shader binding tables are not supported in Metal backend");
}

void ShaderBindingTableMtlImpl::BindMissShader(const Char* pShaderGroupName,
                                               Uint32      MissIndex,
                                               const void* pData,
                                               Uint32      DataSize)
{
    UNSUPPORTED("Shader binding tables are not supported in Metal backend");
}

void ShaderBindingTableMtlImpl::BindHitGroupForGeometry(ITopLevelAS* pTLAS,
                                                        const Char*  pInstanceName,
                                                        const Char*  pGeometryName,
                                                        Uint32       RayOffsetInHitGroupIndex,
                                                        const Char*  pShaderGroupName,
                                                        const void*  pData,
                                                        Uint32       DataSize)
{
    UNSUPPORTED("Shader binding tables are not supported in Metal backend");
}

void ShaderBindingTableMtlImpl::BindHitGroupByIndex(Uint32      BindingIndex,
                                                    const Char* pShaderGroupName,
                                                    const void* pData,
                                                    Uint32      DataSize)
{
    UNSUPPORTED("Shader binding tables are not supported in Metal backend");
}

void ShaderBindingTableMtlImpl::BindHitGroupForInstance(ITopLevelAS* pTLAS,
                                                        const Char*  pInstanceName,
                                                        Uint32       RayOffsetInHitGroupIndex,
                                                        const Char*  pShaderGroupName,
                                                        const void*  pData,
                                                        Uint32       DataSize)
{
    UNSUPPORTED("Shader binding tables are not supported in Metal backend");
}

void ShaderBindingTableMtlImpl::BindHitGroupForTLAS(ITopLevelAS* pTLAS,
                                                    Uint32       RayOffsetInHitGroupIndex,
                                                    const Char*  pShaderGroupName,
                                                    const void*  pData,
                                                    Uint32       DataSize)
{
    UNSUPPORTED("Shader binding tables are not supported in Metal backend");
}

void ShaderBindingTableMtlImpl::BindCallableShader(const Char* pShaderGroupName,
                                                   Uint32      CallableIndex,
                                                   const void* pData,
                                                   Uint32      DataSize)
{
    UNSUPPORTED("Shader binding tables are not supported in Metal backend");
}

} // namespace Diligent
