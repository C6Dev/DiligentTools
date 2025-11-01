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

/// \file
/// Routines that initialize Metal-based engine implementation

#include "EngineFactoryMtl.h"
#include "EngineFactoryBase.hpp"
#include "RenderDeviceMtlImpl.hpp"
#include "DeviceContextMtlImpl.hpp"
#include "CommandQueueMtlStub.hpp"
#include "SwapChainMtlImpl.hpp"
#include "EngineMemory.h"
#include "../../../Primitives/interface/Errors.hpp"
#include <cstring> // for strcpy

#import <Metal/Metal.h>

namespace Diligent
{

/// Engine factory for Metal implementation
class EngineFactoryMtlImpl final : public EngineFactoryBase<IEngineFactoryMtl>
{
public:
    using TBase = EngineFactoryBase<IEngineFactoryMtl>;

    EngineFactoryMtlImpl() :
        TBase{IID_EngineFactoryMtl}
    {}

    ~EngineFactoryMtlImpl() = default;

    /// Implementation of IEngineFactory::EnumerateAdapters()
    virtual void DILIGENT_CALL_TYPE EnumerateAdapters(Version              MinVersion,
                                                      Uint32&              NumAdapters,
                                                      GraphicsAdapterInfo* Adapters) const override final
    {
        UNSUPPORTED("Metal backend does not support adapter enumeration");
    }

    /// Implementation of IEngineFactory::CreateDearchiver()
    virtual void DILIGENT_CALL_TYPE CreateDearchiver(const DearchiverCreateInfo& CreateInfo,
                                                     IDearchiver**               ppDearchiver) const override final
    {
        UNSUPPORTED("Metal backend does not support dearchiving");
    }

    /// Implementation of IEngineFactoryMtl::CreateDeviceAndContextsMtl()
    virtual void DILIGENT_CALL_TYPE CreateDeviceAndContextsMtl(const EngineMtlCreateInfo& EngineCI,
                                                               IRenderDevice**            ppDevice,
                                                               IDeviceContext**           ppContexts) override final
    {
        if (EngineCI.EngineAPIVersion != DILIGENT_API_VERSION)
        {
            LOG_ERROR_MESSAGE("Diligent Engine runtime (", DILIGENT_API_VERSION, ") is not compatible with the client API version (", EngineCI.EngineAPIVersion, ")");
            return;
        }

        VERIFY(ppDevice && ppContexts, "Null pointer provided");
        if (!ppDevice || !ppContexts)
            return;

        *ppDevice = nullptr;
        memset(ppContexts, 0, sizeof(*ppContexts) * (size_t{std::max(1u, EngineCI.NumImmediateContexts)} + size_t{EngineCI.NumDeferredContexts}));

        try
        {
            LOG_INFO_MESSAGE("Metal backend: Creating Metal device and contexts");
            
            // Check that Metal is available on this system
            id<MTLDevice> mtlDevice = MTLCreateSystemDefaultDevice();
            if (!mtlDevice)
            {
                LOG_ERROR_MESSAGE("Metal is not available on this system");
                return;
            }

            LOG_INFO_MESSAGE("Metal device found: ", [mtlDevice.name UTF8String]);
            
            // Create adapter info for the Metal device
            GraphicsAdapterInfo AdapterInfo;
            strcpy(AdapterInfo.Description, [mtlDevice.name UTF8String]);
            AdapterInfo.Type = ADAPTER_TYPE_DISCRETE; // Metal devices are typically discrete
            AdapterInfo.Vendor = ADAPTER_VENDOR_APPLE;
            AdapterInfo.VendorId = 0x106b; // Apple vendor ID
            AdapterInfo.DeviceId = 0; // Not applicable for Metal
            
            // Set memory size from Metal device (this is an approximation)
            if (@available(macOS 10.15, iOS 13.0, *)) {
                AdapterInfo.Memory.LocalMemory = mtlDevice.recommendedMaxWorkingSetSize;
                AdapterInfo.Memory.HostVisibleMemory = mtlDevice.maxBufferLength;
                AdapterInfo.Memory.UnifiedMemory = mtlDevice.hasUnifiedMemory ? AdapterInfo.Memory.LocalMemory : 0;
            }
            
            // Create the Metal device
            // Note: Metal manages command queues through device contexts, not at device level
            // We create a stub command queue to satisfy the base class requirements
            auto* pStubQueue = NEW_RC_OBJ(GetRawAllocator(), "CommandQueueMtlStub instance", CommandQueueMtlStub)();
            ICommandQueueMtl* pCmdQueue = pStubQueue;
            RenderDeviceMtlImpl* pRenderDeviceMtl = NEW_RC_OBJ(GetRawAllocator(), "RenderDeviceMtlImpl instance", RenderDeviceMtlImpl)(
                GetRawAllocator(), this, EngineCI, AdapterInfo, size_t{1}, &pCmdQueue);
            
            pRenderDeviceMtl->QueryInterface(IID_RenderDevice, reinterpret_cast<IObject**>(ppDevice));
            
            LOG_INFO_MESSAGE("Metal backend: Device created successfully");
            
            // Create device contexts
            Uint32 NumImmediateContexts = std::max(1u, EngineCI.NumImmediateContexts);
            for (Uint32 CtxInd = 0; CtxInd < NumImmediateContexts; ++CtxInd)
            {
                DeviceContextDesc CtxDesc;
                CtxDesc.Name        = "Immediate context";
                CtxDesc.QueueType   = COMMAND_QUEUE_TYPE_GRAPHICS;
                CtxDesc.IsDeferred  = False;
                
                auto* pContext = NEW_RC_OBJ(GetRawAllocator(), "DeviceContextMtlImpl instance", DeviceContextMtlImpl)(
                    pRenderDeviceMtl, EngineCI, CtxDesc);
                pContext->QueryInterface(IID_DeviceContext, reinterpret_cast<IObject**>(ppContexts + CtxInd));
            }
            
            // Create deferred contexts if requested
            for (Uint32 CtxInd = 0; CtxInd < EngineCI.NumDeferredContexts; ++CtxInd)
            {
                DeviceContextDesc CtxDesc;
                CtxDesc.Name        = "Deferred context";
                CtxDesc.QueueType   = COMMAND_QUEUE_TYPE_GRAPHICS;
                CtxDesc.IsDeferred  = True;
                
                auto* pDeferredCtx = NEW_RC_OBJ(GetRawAllocator(), "DeviceContextMtlImpl instance", DeviceContextMtlImpl)(
                    pRenderDeviceMtl, EngineCI, CtxDesc);
                pDeferredCtx->QueryInterface(IID_DeviceContext, reinterpret_cast<IObject**>(ppContexts + NumImmediateContexts + CtxInd));
            }
            
            LOG_INFO_MESSAGE("Metal backend: Created device and ", NumImmediateContexts, " immediate and ", EngineCI.NumDeferredContexts, " deferred contexts successfully");
        }
        catch (const std::runtime_error& err)
        {
            LOG_ERROR("Failed to create Metal device and contexts: ", err.what());
            if (*ppDevice)
            {
                (*ppDevice)->Release();
                *ppDevice = nullptr;
            }
        }
    }

    /// Implementation of IEngineFactoryMtl::CreateSwapChainMtl()
    virtual void DILIGENT_CALL_TYPE CreateSwapChainMtl(IRenderDevice*       pDevice,
                                                       IDeviceContext*      pImmediateContext,
                                                       const SwapChainDesc& SCDesc,
                                                       const NativeWindow&  Window,
                                                       ISwapChain**         ppSwapChain) override final
    {
        VERIFY(ppSwapChain, "Null pointer provided");
        if (!ppSwapChain)
            return;

        *ppSwapChain = nullptr;

        try
        {
            LOG_INFO_MESSAGE("Metal backend: Creating Metal swap chain");

            if (!pDevice)
            {
                LOG_ERROR_MESSAGE("Render device is null");
                return;
            }

            if (!pImmediateContext)
            {
                LOG_ERROR_MESSAGE("Immediate context is null");
                return;
            }

            // Get the Metal device implementation
            auto* pRenderDeviceMtl = static_cast<RenderDeviceMtlImpl*>(pDevice);
            
            // Get the native macOS window
            if (!Window.pNSView)
            {
                LOG_ERROR_MESSAGE("Native macOS NSView is null");
                return;
            }

            LOG_INFO_MESSAGE("Metal backend: Creating functional Metal swap chain");

            auto* pImmediateCtxMtl = static_cast<DeviceContextMtlImpl*>(pImmediateContext);
            NSView* pView = Window.pNSView;
            if (!pView)
            {
                LOG_ERROR_MESSAGE("Metal swap chain creation failed: NSView is null");
                return;
            }

            auto* pSwapChain = NEW_RC_OBJ(GetRawAllocator(), "SwapChainMtlImpl instance", SwapChainMtlImpl)(
                pRenderDeviceMtl, pImmediateCtxMtl, SCDesc, pView);
            pSwapChain->QueryInterface(IID_SwapChain, reinterpret_cast<IObject**>(ppSwapChain));
            LOG_INFO_MESSAGE("Metal backend: Swap chain created (", SCDesc.Width, "x", SCDesc.Height, ")");
        }
        catch (const std::runtime_error& err)
        {
            LOG_ERROR("Failed to create Metal swap chain: ", err.what());
            if (*ppSwapChain)
            {
                (*ppSwapChain)->Release();
                *ppSwapChain = nullptr;
            }
        }
    }

    /// Implementation of IEngineFactoryMtl::CreateCommandQueueMtl()
    virtual void DILIGENT_CALL_TYPE CreateCommandQueueMtl(void*                     pMtlNativeQueue,
                                                          struct IMemoryAllocator*  pRawAllocator,
                                                          struct ICommandQueueMtl** ppCommandQueue) override final
    {
        UNSUPPORTED("Metal backend is not fully implemented");
    }

    /// Implementation of IEngineFactoryMtl::AttachToMtlDevice()
    virtual void DILIGENT_CALL_TYPE AttachToMtlDevice(void*                      pMtlNativeDevice,
                                                      Uint32                     CommandQueueCount,
                                                      struct ICommandQueueMtl** ppCommandQueues,
                                                      const EngineMtlCreateInfo& EngineCI,
                                                      IRenderDevice**            ppDevice,
                                                      IDeviceContext**           ppContexts) override final
    {
        UNSUPPORTED("Metal backend is not fully implemented");
    }

    static EngineFactoryMtlImpl* GetInstance()
    {
        static EngineFactoryMtlImpl TheFactory;
        return &TheFactory;
    }
};

API_QUALIFIER
IEngineFactoryMtl* GetEngineFactoryMtl()
{
    return EngineFactoryMtlImpl::GetInstance();
}

} // namespace Diligent

extern "C"
{
    API_QUALIFIER
    Diligent::IEngineFactoryMtl* Diligent_GetEngineFactoryMtl()
    {
        return Diligent::GetEngineFactoryMtl();
    }
}