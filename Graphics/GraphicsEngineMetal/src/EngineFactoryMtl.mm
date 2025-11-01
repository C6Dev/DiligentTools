/* Metal engine factory with real swap chain */
#include "EngineFactoryMtl.h"
#include "EngineFactoryBase.hpp"
#include "RenderDeviceMtlImpl.hpp"
#include "DeviceContextMtlImpl.hpp"
#include "CommandQueueMtlStub.hpp"
#include "SwapChainMtlImpl.hpp"
#include "EngineMemory.h"
#include "../../Primitives/interface/Errors.hpp"
#import <Metal/Metal.h>
#import <Cocoa/Cocoa.h>

namespace Diligent
{
class EngineFactoryMtlImpl final : public EngineFactoryBase<IEngineFactoryMtl>
{
public:
    using TBase = EngineFactoryBase<IEngineFactoryMtl>;
    EngineFactoryMtlImpl():TBase{IID_EngineFactoryMtl}{ }
    ~EngineFactoryMtlImpl() = default;

    virtual void DILIGENT_CALL_TYPE EnumerateAdapters(Version, Uint32& NumAdapters, GraphicsAdapterInfo* Adapters) const override final
    { UNSUPPORTED("Metal backend does not support adapter enumeration"); }
    virtual void DILIGENT_CALL_TYPE CreateDearchiver(const DearchiverCreateInfo&, IDearchiver**) const override final
    { UNSUPPORTED("Metal backend does not support dearchiving"); }

    virtual void DILIGENT_CALL_TYPE CreateDeviceAndContextsMtl(const EngineMtlCreateInfo& EngineCI,
                                                               IRenderDevice** ppDevice,
                                                               IDeviceContext** ppContexts) override final
    {
        if (EngineCI.EngineAPIVersion != DILIGENT_API_VERSION)
        { LOG_ERROR_MESSAGE("API version mismatch"); return; }
        if (!ppDevice || !ppContexts) return; *ppDevice = nullptr;
        memset(ppContexts, 0, sizeof(*ppContexts));
        try
        {
            id<MTLDevice> mtlDevice = MTLCreateSystemDefaultDevice();
            if (!mtlDevice){ LOG_ERROR_MESSAGE("No Metal device"); return; }
            GraphicsAdapterInfo AdapterInfo{}; strcpy(AdapterInfo.Description, [mtlDevice.name UTF8String]);
            auto* pStubQueue = NEW_RC_OBJ(GetRawAllocator(), "CommandQueueMtlStub instance", CommandQueueMtlStub)();
            ICommandQueueMtl* pCmdQueue = pStubQueue;
            auto* pRenderDeviceMtl = NEW_RC_OBJ(GetRawAllocator(), "RenderDeviceMtlImpl instance", RenderDeviceMtlImpl)(
                GetRawAllocator(), this, EngineCI, AdapterInfo, size_t{1}, &pCmdQueue);
            pRenderDeviceMtl->QueryInterface(IID_RenderDevice, reinterpret_cast<IObject**>(ppDevice));
            DeviceContextDesc CtxDesc; CtxDesc.Name="Immediate context"; CtxDesc.QueueType = COMMAND_QUEUE_TYPE_GRAPHICS; CtxDesc.IsDeferred = False;
            auto* pContext = NEW_RC_OBJ(GetRawAllocator(), "DeviceContextMtlImpl instance", DeviceContextMtlImpl)(pRenderDeviceMtl, EngineCI, CtxDesc);
            pContext->QueryInterface(IID_DeviceContext, reinterpret_cast<IObject**>(ppContexts));
        }
        catch(const std::runtime_error& err){ LOG_ERROR("Failed to create Metal device: ", err.what()); }
    }

    virtual void DILIGENT_CALL_TYPE CreateSwapChainMtl(IRenderDevice* pDevice,
                                                       IDeviceContext* pImmediateContext,
                                                       const SwapChainDesc& SCDesc,
                                                       const NativeWindow& Window,
                                                       ISwapChain** ppSwapChain) override final
    {
        if (!ppSwapChain) return; *ppSwapChain = nullptr;
        if (!pDevice || !pImmediateContext || !Window.pNSView){ LOG_ERROR_MESSAGE("SwapChainMtlImpl: invalid params"); return; }
        auto* pRenderDeviceMtl = static_cast<RenderDeviceMtlImpl*>(pDevice);
        auto* pImmediateCtxMtl = static_cast<DeviceContextMtlImpl*>(pImmediateContext);
        try
        {
            auto* pSwapChain = NEW_RC_OBJ(GetRawAllocator(), "SwapChainMtlImpl instance", SwapChainMtlImpl)(pRenderDeviceMtl, pImmediateCtxMtl, SCDesc, (NSView*)Window.pNSView);
            pSwapChain->QueryInterface(IID_SwapChain, reinterpret_cast<IObject**>(ppSwapChain));
        }
        catch(const std::runtime_error& err){ LOG_ERROR("Metal swap chain creation failed: ", err.what()); }
    }

    virtual void DILIGENT_CALL_TYPE CreateCommandQueueMtl(void*, struct IMemoryAllocator*, struct ICommandQueueMtl**) override final
    { UNSUPPORTED("Not implemented"); }
    virtual void DILIGENT_CALL_TYPE AttachToMtlDevice(void*, Uint32, struct ICommandQueueMtl**, const EngineMtlCreateInfo&, IRenderDevice**, IDeviceContext**) override final
    { UNSUPPORTED("Not implemented"); }

    static EngineFactoryMtlImpl* GetInstance(){ static EngineFactoryMtlImpl TheFactory; return &TheFactory; }
};

API_QUALIFIER IEngineFactoryMtl* GetEngineFactoryMtl(){ return EngineFactoryMtlImpl::GetInstance(); }
API_QUALIFIER IEngineFactoryMtl* LoadEngineFactoryMtl(){ return EngineFactoryMtlImpl::GetInstance(); }
} // namespace Diligent
