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
/// Declaration of Diligent::ShaderMtlImpl class

#include "EngineMtlImplTraits.hpp"
#include "ShaderBase.hpp"
#include <functional>

namespace Diligent
{

class SerializedShaderImpl;

class SerializedShaderImpl;

/// Implementation of a shader object in Metal backend.
class ShaderMtlImpl : public ShaderBase<EngineMtlImplTraits>
{
public:
    using TShaderBase = ShaderBase<EngineMtlImplTraits>;

    static constexpr INTERFACE_ID IID_InternalImpl =
        {0x9a8b00f1, 0x673, 0x4a39, {0xaf, 0x28, 0xa4, 0xa5, 0xd6, 0x3e, 0x84, 0xa2}};

    struct CreateInfo
    {
        const RenderDeviceInfo&                   DeviceInfo;
        const GraphicsAdapterInfo&                AdapterInfo;
        IDataBlob**                               ppCompilerOutput;
        class IAsyncShaderCompilationTaskProcessor* pAsyncTaskProcessor;
        std::function<void(std::string&)>         PreprocessMslSource;

        CreateInfo(const RenderDeviceInfo&                  _DeviceInfo,
                   const GraphicsAdapterInfo&                _AdapterInfo,
                   IDataBlob**                               _ppCompilerOutput,
                   IAsyncShaderCompilationTaskProcessor*     _pAsyncTaskProcessor,
                   std::function<void(std::string&)>         _PreprocessMslSource) :
            DeviceInfo{_DeviceInfo},
            AdapterInfo{_AdapterInfo},
            ppCompilerOutput{_ppCompilerOutput},
            pAsyncTaskProcessor{_pAsyncTaskProcessor},
            PreprocessMslSource{std::move(_PreprocessMslSource)}
        {}
    };

    ShaderMtlImpl(IReferenceCounters*     pRefCounters,
                  RenderDeviceMtlImpl*    pRenderDeviceMtl,
                  const ShaderCreateInfo& ShaderCI,
                  const CreateInfo&       MtlShaderCI,
                  bool                    IsDeviceInternal = false);

    ~ShaderMtlImpl();

    virtual void DILIGENT_CALL_TYPE QueryInterface(const INTERFACE_ID& IID, IObject** ppInterface) override final;

    /// Implementation of IShader::GetResourceCount() in Metal backend.
    virtual Uint32 DILIGENT_CALL_TYPE GetResourceCount() const override final;

    /// Implementation of IShader::GetResourceDesc() in Metal backend.
    virtual void DILIGENT_CALL_TYPE GetResourceDesc(Uint32 Index, ShaderResourceDesc& ResourceDesc) const override final;

    /// Implementation of IShader::GetConstantBufferDesc() in Metal backend.
    virtual const ShaderCodeBufferDesc* DILIGENT_CALL_TYPE GetConstantBufferDesc(Uint32 Index) const override final;

    /// Implementation of IShader::GetBytecode() in Metal backend.
    virtual void DILIGENT_CALL_TYPE GetBytecode(const void** ppBytecode, Uint64& Size) const override final;

    /// Implementation of IShaderMtl::GetMtlShaderFunction().
    virtual id<MTLFunction> DILIGENT_CALL_TYPE GetMtlShaderFunction() const override final;

    /// Get the Metal library object
    id<MTLLibrary> GetMtlLibrary() const { return m_MtlLibrary; }

    /// Get the entry point name
    const String& GetEntryPoint() const { return m_EntryPoint; }

private:
    String m_EntryPoint;
    id<MTLLibrary> m_MtlLibrary = nil;
};

} // namespace Diligent
