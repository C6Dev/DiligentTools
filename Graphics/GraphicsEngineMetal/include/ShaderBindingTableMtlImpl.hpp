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
/// Declaration of Diligent::ShaderBindingTableMtlImpl class

#include "EngineMtlImplTraits.hpp"
#include "../../../Primitives/interface/Object.h"
#include "ShaderBindingTable.h"

namespace Diligent
{

/// Shader binding table implementation in Metal backend.
class ShaderBindingTableMtlImpl final : public ObjectBase<IShaderBindingTable>
{
public:
    using TBase = ObjectBase<IShaderBindingTable>;

    ShaderBindingTableMtlImpl(IReferenceCounters*           pRefCounters,
                              RenderDeviceMtlImpl*          pDevice,
                              const ShaderBindingTableDesc& Desc,
                              bool                          bIsDeviceInternal = false);
    ~ShaderBindingTableMtlImpl();

    IMPLEMENT_QUERY_INTERFACE_IN_PLACE(IID_ShaderBindingTable, TBase)

    /// Implementation of IDeviceObject::GetUniqueID().
    virtual Int32 DILIGENT_CALL_TYPE GetUniqueID() const override final
    {
        return m_UniqueID;
    }

    /// Implementation of IDeviceObject::SetUserData().
    virtual void DILIGENT_CALL_TYPE SetUserData(IObject* pUserData) override final
    {
        m_pUserData = pUserData;
    }

    /// Implementation of IDeviceObject::GetUserData().
    virtual IObject* DILIGENT_CALL_TYPE GetUserData() const override final
    {
        return m_pUserData;
    }

    /// Implementation of IShaderBindingTable::GetDesc().
    virtual const ShaderBindingTableDesc& DILIGENT_CALL_TYPE GetDesc() const override final;

    /// Implementation of IShaderBindingTable::Verify().
    virtual Bool DILIGENT_CALL_TYPE Verify(VERIFY_SBT_FLAGS Flags) const override final;

    /// Implementation of IShaderBindingTable::Reset().
    virtual void DILIGENT_CALL_TYPE Reset(IPipelineState* pPSO) override final;

    /// Implementation of IShaderBindingTable::ResetHitGroups().
    virtual void DILIGENT_CALL_TYPE ResetHitGroups() override final;

    /// Implementation of IShaderBindingTable::BindRayGenShader().
    virtual void DILIGENT_CALL_TYPE BindRayGenShader(const Char* pShaderGroupName,
                                                     const void* pData,
                                                     Uint32      DataSize) override final;

    /// Implementation of IShaderBindingTable::BindMissShader().
    virtual void DILIGENT_CALL_TYPE BindMissShader(const Char* pShaderGroupName,
                                                   Uint32      MissIndex,
                                                   const void* pData,
                                                   Uint32      DataSize) override final;

    /// Implementation of IShaderBindingTable::BindHitGroupForGeometry().
    virtual void DILIGENT_CALL_TYPE BindHitGroupForGeometry(ITopLevelAS* pTLAS,
                                                            const Char*  pInstanceName,
                                                            const Char*  pGeometryName,
                                                            Uint32       RayOffsetInHitGroupIndex,
                                                            const Char*  pShaderGroupName,
                                                            const void*  pData,
                                                            Uint32       DataSize) override final;

    /// Implementation of IShaderBindingTable::BindHitGroupByIndex().
    virtual void DILIGENT_CALL_TYPE BindHitGroupByIndex(Uint32      BindingIndex,
                                                        const Char* pShaderGroupName,
                                                        const void* pData,
                                                        Uint32      DataSize) override final;

    /// Implementation of IShaderBindingTable::BindHitGroupForInstance().
    virtual void DILIGENT_CALL_TYPE BindHitGroupForInstance(ITopLevelAS* pTLAS,
                                                            const Char*  pInstanceName,
                                                            Uint32       RayOffsetInHitGroupIndex,
                                                            const Char*  pShaderGroupName,
                                                            const void*  pData,
                                                            Uint32       DataSize) override final;

    /// Implementation of IShaderBindingTable::BindHitGroupForTLAS().
    virtual void DILIGENT_CALL_TYPE BindHitGroupForTLAS(ITopLevelAS* pTLAS,
                                                        Uint32       RayOffsetInHitGroupIndex,
                                                        const Char*  pShaderGroupName,
                                                        const void*  pData,
                                                        Uint32       DataSize) override final;

    /// Implementation of IShaderBindingTable::BindCallableShader().
    virtual void DILIGENT_CALL_TYPE BindCallableShader(const Char* pShaderGroupName,
                                                       Uint32      CallableIndex,
                                                       const void* pData,
                                                       Uint32      DataSize) override final;

private:
    ShaderBindingTableDesc m_Desc;
    const Int32            m_UniqueID;
    RefCntAutoPtr<IObject> m_pUserData;
};

} // namespace Diligent
