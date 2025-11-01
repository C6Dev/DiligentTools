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

#include "ShaderVariableManagerMtl.hpp"
#include "PipelineResourceSignatureMtlImpl.hpp"
#include "BufferMtlImpl.hpp"

#include <cstring> // for strcmp

namespace Diligent
{

size_t ShaderVariableManagerMtl::GetRequiredMemorySize(const PipelineResourceSignatureMtlImpl& Signature,
                                                       const SHADER_RESOURCE_VARIABLE_TYPE*    AllowedVarTypes,
                                                       Uint32                                 NumAllowedTypes,
                                                       SHADER_TYPE                            ShaderStages,
                                                       Uint32*                                pNumVariables)
{
    Uint32 Count = 0;
    const auto& Desc = Signature.GetDesc();
    for (Uint32 i = 0; i < Desc.NumResources; ++i)
    {
        const PipelineResourceDesc& Res = Desc.Resources[i];
        if ((Res.ShaderStages & ShaderStages) != 0 && Res.VarType == SHADER_RESOURCE_VARIABLE_TYPE_STATIC)
            ++Count;
    }
    if (pNumVariables)
        *pNumVariables = Count;
    return size_t{Count} * sizeof(ShaderVariableMtlImpl);
}

void ShaderVariableManagerMtl::Initialize(const PipelineResourceSignatureMtlImpl& Signature,
                                          IMemoryAllocator&                       Allocator,
                                          const SHADER_RESOURCE_VARIABLE_TYPE*    AllowedVarTypes,
                                          Uint32                                  NumAllowedTypes,
                                          SHADER_TYPE                             ShaderType)
{
    Uint32 NumVars = 0;
    const size_t MemSize = GetRequiredMemorySize(Signature, AllowedVarTypes, NumAllowedTypes, ShaderType, &NumVars);
    if (NumVars == 0)
    {
        LOG_INFO_MESSAGE("MtlVarMgr: Initialize -> no variables for ShaderType=0x", std::hex, ShaderType, std::dec);
        m_NumVariables = 0;
        return;
    }
    m_NumVariables = NumVars;
    TBase::Initialize(Signature, Allocator, MemSize);
    LOG_INFO_MESSAGE("MtlVarMgr: Allocating ", NumVars, " static variables (ShaderType=0x", std::hex, ShaderType, std::dec, ") mem=", MemSize, " bytes");
    Uint32 VarIdx = 0;
    const auto& Desc = Signature.GetDesc();
    for (Uint32 i = 0; i < Desc.NumResources; ++i)
    {
        const PipelineResourceDesc& Res = Desc.Resources[i];
        if ((Res.ShaderStages & ShaderType) != 0 && Res.VarType == SHADER_RESOURCE_VARIABLE_TYPE_STATIC)
        {
            ::new (m_pVariables + VarIdx) ShaderVariableMtlImpl(*this, i);
            LOG_INFO_MESSAGE("MtlVarMgr: Constructed variable #", VarIdx, " -> ResIndex=", i, " Name=", (Res.Name ? Res.Name : "<null>"));
            ++VarIdx;
        }
    }
}

void ShaderVariableManagerMtl::Destroy(IMemoryAllocator& Allocator)
{
    for (Uint32 v = 0; v < m_NumVariables; ++v)
        m_pVariables[v].~ShaderVariableMtlImpl();
    m_NumVariables = 0;
    TBase::Destroy(Allocator);
}

ShaderVariableMtlImpl* ShaderVariableManagerMtl::GetVariable(const Char* Name) const
{
    LOG_INFO_MESSAGE("MtlVarMgr: GetVariableByName('", (Name ? Name : "<null>"), "') count=", m_NumVariables);
    for (Uint32 v = 0; v < m_NumVariables; ++v)
    {
        auto& Var = m_pVariables[v];
        if (strcmp(Var.GetDesc().Name, Name) == 0)
        {
            LOG_INFO_MESSAGE("MtlVarMgr: Found variable index ", v);
            return &Var;
        }
    }
    LOG_INFO_MESSAGE("MtlVarMgr: Variable not found: ", (Name ? Name : "<null>"));
    return nullptr;
}

ShaderVariableMtlImpl* ShaderVariableManagerMtl::GetVariable(Uint32 Index) const
{
    return (Index < m_NumVariables) ? (m_pVariables + Index) : nullptr;
}

void ShaderVariableManagerMtl::BindResource(Uint32 ResIndex, const BindResourceInfo& BindInfo)
{
    // For now: only constant buffer semantics validation
    const auto& ResDesc = GetResourceDesc(ResIndex);
    if (ResDesc.ResourceType == SHADER_RESOURCE_TYPE_CONSTANT_BUFFER)
    {
        // No cache integration yet; rely on higher level binding later.
        (void)BindInfo;
    }
}

void ShaderVariableManagerMtl::SetBufferDynamicOffset(Uint32 ResIndex, Uint32 ArrayIndex, Uint32 BufferDynamicOffset)
{
    (void)ResIndex; (void)ArrayIndex; (void)BufferDynamicOffset;
}

IDeviceObject* ShaderVariableManagerMtl::Get(Uint32 ArrayIndex, Uint32 ResIndex) const
{
    (void)ArrayIndex; (void)ResIndex; return nullptr;
}

void ShaderVariableManagerMtl::BindResources(IResourceMapping* pResourceMapping, BIND_SHADER_RESOURCES_FLAGS Flags)
{
    TBase::BindResources(pResourceMapping, Flags);
}

void ShaderVariableManagerMtl::CheckResources(IResourceMapping*                    pResourceMapping,
                                              BIND_SHADER_RESOURCES_FLAGS          Flags,
                                              SHADER_RESOURCE_VARIABLE_TYPE_FLAGS& StaleVarTypes) const
{
    TBase::CheckResources(pResourceMapping, Flags, StaleVarTypes);
}

Uint32 ShaderVariableManagerMtl::GetVariableIndex(const ShaderVariableMtlImpl& Variable)
{
    const ptrdiff_t Offset = reinterpret_cast<const Uint8*>(&Variable) - reinterpret_cast<const Uint8*>(m_pVariables);
    if (Offset % sizeof(ShaderVariableMtlImpl) == 0)
    {
        Uint32 Index = static_cast<Uint32>(Offset / sizeof(ShaderVariableMtlImpl));
        return Index < m_NumVariables ? Index : ~0u;
    }
    return ~0u;
}

const PipelineResourceDesc& ShaderVariableManagerMtl::GetResourceDesc(Uint32 Index) const
{
    return m_pSignature->GetResourceDesc(Index);
}

const PipelineResourceAttribsMtl& ShaderVariableManagerMtl::GetResourceAttribs(Uint32 Index) const
{
    return m_pSignature->GetResourceAttribs(Index);
}

} // namespace Diligent
