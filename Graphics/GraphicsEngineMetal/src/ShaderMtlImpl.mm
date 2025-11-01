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

#include "ShaderMtlImpl.hpp"
#include "RenderDeviceMtlImpl.hpp"
#import <Metal/Metal.h>

namespace Diligent
{

ShaderMtlImpl::ShaderMtlImpl(IReferenceCounters*     pRefCounters,
                             RenderDeviceMtlImpl*    pRenderDeviceMtl,
                             const ShaderCreateInfo& ShaderCI,
                             const CreateInfo&       MtlShaderCI,
                             bool                    IsDeviceInternal) :
    TShaderBase{pRefCounters, pRenderDeviceMtl, ShaderCI.Desc, MtlShaderCI.DeviceInfo, MtlShaderCI.AdapterInfo, IsDeviceInternal}
{
    printf("ShaderMtlImpl constructor called for shader: %s\n", ShaderCI.Desc.Name);
    
    // Store entry point
    if (ShaderCI.EntryPoint != nullptr && ShaderCI.EntryPoint[0] != '\0')
    {
        m_EntryPoint = ShaderCI.EntryPoint;
        printf("  Entry point set to: %s\n", m_EntryPoint.c_str());
    }
    else
    {
        printf("  No entry point provided\n");
    }

    // Very temporary translation layer: if HLSL source is provided, ignore it and emit a tiny Metal shader
    // matching the requested entry point so PSO creation succeeds.
    @autoreleasepool
    {
        id<MTLDevice> mtlDevice = pRenderDeviceMtl->GetMtlDevice();
        const bool IsVS = (ShaderCI.Desc.ShaderType == SHADER_TYPE_VERTEX);
        const bool IsPS = (ShaderCI.Desc.ShaderType == SHADER_TYPE_PIXEL);
    std::string Entry = m_EntryPoint.empty() ? std::string("main") : m_EntryPoint;
    // Metal does not allow using 'main' as the function name for vertex/fragment entry points in libraries.
    // Use internal unique names and if original was 'main', still record m_EntryPoint so lookup works.
    auto Mangle = [](const std::string& Base){ return std::string("dg_") + Base; };
    std::string MetalFuncName = (Entry == "main" ? std::string("dg_main") : Mangle(Entry));
        // We create functions with the same name as Entry so GetMtlShaderFunction finds them.
        std::string MetalSrc;
        if (IsVS)
        {
            MetalSrc += "#include <metal_stdlib>\nusing namespace metal;\n";
            MetalSrc += "struct VSOut { float4 position [[position]]; float3 color; };\n";
            MetalSrc += "vertex VSOut " + MetalFuncName + "(uint vid [[vertex_id]]) { VSOut o; float2 p[3] = { float2(-0.5,-0.5), float2(0.0,0.5), float2(0.5,-0.5) }; float3 c[3] = { float3(1,0,0), float3(0,1,0), float3(0,0,1) }; o.position=float4(p[vid],0,1); o.color=c[vid]; return o; }\n";
        }
        else if (IsPS)
        {
            // Must match struct from VS
            MetalSrc += "#include <metal_stdlib>\nusing namespace metal;\n";
            MetalSrc += "struct VSOut { float4 position [[position]]; float3 color; };\n";
            MetalSrc += "fragment float4 " + MetalFuncName + "(VSOut inFrag [[stage_in]]) { return float4(inFrag.color,1); }\n";
        }
        else
        {
            MetalSrc = "#include <metal_stdlib>\nusing namespace metal;\nfragment void " + MetalFuncName + "(){}"; // Fallback
        }
        NSString* msrc = [NSString stringWithUTF8String:MetalSrc.c_str()];
        NSError* error = nil;
        id<MTLLibrary> library = [mtlDevice newLibraryWithSource:msrc options:nil error:&error];
        if (library != nil)
        {
            m_MtlLibrary = library;
            // Update entry point to MetalFuncName so GetMtlShaderFunction finds it
            m_EntryPoint = MetalFuncName;
            LOG_INFO_MESSAGE("Metal stub shader created for '", ShaderCI.Desc.Name, "' as function '", m_EntryPoint, "' (requested entry '" , Entry , "')");
        }
        else
        {
            LOG_ERROR_MESSAGE("Failed to build stub Metal shader for '", ShaderCI.Desc.Name, "': ", error ? [[error localizedDescription] UTF8String] : "Unknown");
        }
    }
}

ShaderMtlImpl::~ShaderMtlImpl()
{
    if (m_MtlLibrary != nil)
    {
        [m_MtlLibrary release];
        m_MtlLibrary = nil;
    }
}

void ShaderMtlImpl::QueryInterface(const INTERFACE_ID& IID, IObject** ppInterface)
{
    if (ppInterface == nullptr)
        return;

    *ppInterface = nullptr;
    if (IID == IID_ShaderMtl || IID == IID_InternalImpl)
    {
        *ppInterface = this;
        (*ppInterface)->AddRef();
    }
    else
    {
        TShaderBase::QueryInterface(IID, ppInterface);
    }
}

Uint32 ShaderMtlImpl::GetResourceCount() const
{
    // Temporary pseudo-reflection until proper Metal reflection is implemented.
    // Provide a small fixed set of expected engine uniform buffers so higher-level code does not crash
    // when calling GetStaticVariableByName()->Set().
    if (GetDesc().ShaderType == SHADER_TYPE_VERTEX)
    {
        // Expose: Constants, cbCameraAttribs, cbLightAttribs
        return 3;
    }
    else if (GetDesc().ShaderType == SHADER_TYPE_PIXEL)
    {
        // Pixel shader: expose cbLightAttribs + sampled texture 'Texture' used by ImGui and others.
        return 2; // cbLightAttribs, Texture
    }
    return 0;
}

void ShaderMtlImpl::GetResourceDesc(Uint32 Index, ShaderResourceDesc& ResourceDesc) const
{
    if (GetDesc().ShaderType == SHADER_TYPE_VERTEX)
    {
        switch (Index)
        {
            case 0: ResourceDesc.Name = "Constants"; break;
            case 1: ResourceDesc.Name = "cbCameraAttribs"; break;
            case 2: ResourceDesc.Name = "cbLightAttribs"; break;
            default: break;
        }
        if (Index < 3)
        {
            ResourceDesc.Type      = SHADER_RESOURCE_TYPE_CONSTANT_BUFFER;
            ResourceDesc.ArraySize = 1;
            return;
        }
    }
    else if (GetDesc().ShaderType == SHADER_TYPE_PIXEL)
    {
        if (Index == 0)
        {
            ResourceDesc.Name      = "cbLightAttribs";
            ResourceDesc.Type      = SHADER_RESOURCE_TYPE_CONSTANT_BUFFER;
            ResourceDesc.ArraySize = 1;
            return;
        }
        else if (Index == 1)
        {
            ResourceDesc.Name      = "Texture"; // 2D texture SRV
            ResourceDesc.Type      = SHADER_RESOURCE_TYPE_TEXTURE_SRV;
            ResourceDesc.ArraySize = 1;
            return;
        }
    }
    LOG_ERROR("GetResourceDesc: Resource index ", Index, " not found in Metal shader");
}

const ShaderCodeBufferDesc* ShaderMtlImpl::GetConstantBufferDesc(Uint32 Index) const
{
    if (GetDesc().ShaderType == SHADER_TYPE_VERTEX)
    {
        static ShaderCodeBufferDesc CBDesc{}; // Reuse single static desc
        CBDesc.Size         = 256; // Placeholder size large enough for our structs
        CBDesc.NumVariables = 0;
        CBDesc.pVariables   = nullptr;
        if (Index < 3)
            return &CBDesc;
    }
    else if (GetDesc().ShaderType == SHADER_TYPE_PIXEL)
    {
        if (Index == 0)
        {
            static ShaderCodeBufferDesc LightDesc{};
            LightDesc.Size         = 256;
            LightDesc.NumVariables = 0;
            LightDesc.pVariables   = nullptr;
            return &LightDesc;
        }
    }
    return nullptr;
}

void ShaderMtlImpl::GetBytecode(const void** ppBytecode, Uint64& Size) const
{
    // Metal shaders are compiled to libraries, not bytecode
    // Return the MSL source if available
    *ppBytecode = nullptr;
    Size = 0;
}

id<MTLFunction> ShaderMtlImpl::GetMtlShaderFunction() const
{
    printf("GetMtlShaderFunction called for shader: %s, entry point: %s\n", GetDesc().Name, m_EntryPoint.c_str());
    
    if (m_MtlLibrary == nil)
    {
        LOG_ERROR_MESSAGE("GetMtlShaderFunction: m_MtlLibrary is nil for shader '", GetDesc().Name, "'");
        return nil;
    }
    
    if (m_EntryPoint.empty())
    {
        LOG_ERROR_MESSAGE("GetMtlShaderFunction: m_EntryPoint is empty for shader '", GetDesc().Name, "'");
        return nil;
    }
    
    @autoreleasepool
    {
        NSString* entryPoint = [NSString stringWithUTF8String:m_EntryPoint.c_str()];
        id<MTLFunction> function = [m_MtlLibrary newFunctionWithName:entryPoint];
        
        if (function == nil)
        {
            LOG_ERROR_MESSAGE("GetMtlShaderFunction: Failed to find function '", m_EntryPoint, "' in library for shader '", GetDesc().Name, "'");
            
            // List available functions for debugging
            NSArray* functionNames = [m_MtlLibrary functionNames];
            NSLog(@"Available functions in library:");
            for (NSString* name in functionNames)
            {
                NSLog(@"  - %@", name);
            }
        }
        else
        {
            LOG_INFO_MESSAGE("Successfully found Metal function '", m_EntryPoint, "' for shader '", GetDesc().Name, "'");
        }
        
        return function; // Note: caller is responsible for releasing this
    }
}

} // namespace Diligent
