// Clean functional Metal swap chain declaration (implementation in SwapChainMtlImpl.mm)
#pragma once

#include "SwapChain.h"
#include "ObjectBase.hpp"
#include "RefCntAutoPtr.hpp"
#include "TextureView.h"

@class NSView; // Forward declare to avoid including Cocoa in headers that include this one
@class CAMetalLayer;
@protocol MTLDrawable;
@protocol CAMetalDrawable;

namespace Diligent
{

class RenderDeviceMtlImpl;
class DeviceContextMtlImpl;

class SwapChainMtlImpl final : public ObjectBase<ISwapChain>
{
public:
    using TBase = ObjectBase<ISwapChain>;

    SwapChainMtlImpl(IReferenceCounters*    pRefCounters,
                     RenderDeviceMtlImpl*   pDevice,
                     DeviceContextMtlImpl*  pImmediateCtx,
                     const SwapChainDesc&   SCDesc,
                     NSView*                pView);

    IMPLEMENT_QUERY_INTERFACE_IN_PLACE(IID_SwapChain, TBase)

    // ISwapChain interface
    virtual void                  DILIGENT_CALL_TYPE Present(Uint32 SyncInterval) override final;
    virtual void                  DILIGENT_CALL_TYPE Resize(Uint32 NewWidth, Uint32 NewHeight, SURFACE_TRANSFORM NewPreTransform) override final;
    virtual void                  DILIGENT_CALL_TYPE SetFullscreenMode(const DisplayModeAttribs& DisplayMode) override final {}
    virtual void                  DILIGENT_CALL_TYPE SetWindowedMode() override final {}
    virtual ITextureView*         DILIGENT_CALL_TYPE GetCurrentBackBufferRTV() override final;
    virtual ITextureView*         DILIGENT_CALL_TYPE GetDepthBufferDSV() override final { return m_pDSV; }
    virtual const SwapChainDesc&  DILIGENT_CALL_TYPE GetDesc() const override final { return m_Desc; }
    virtual void                  DILIGENT_CALL_TYPE SetMaximumFrameLatency(Uint32) override final {}

private:
    void AcquireNextDrawable();
    void CreateDepthBuffer();

    SwapChainDesc                m_Desc;
    CAMetalLayer*                m_pLayer          = nil;
    id<CAMetalDrawable>          m_CurrentDrawable = nil; // valid between Acquire and Present
    RenderDeviceMtlImpl*         m_pDevice         = nullptr;
    DeviceContextMtlImpl*        m_pImmediateCtx   = nullptr;

    RefCntAutoPtr<ITexture>      m_pDepthTexture;
    RefCntAutoPtr<ITexture>      m_pBackbufferTexture; // Hold backbuffer texture to keep view alive
    RefCntAutoPtr<ITextureView>  m_pRTV;
    RefCntAutoPtr<ITextureView>  m_pDSV;
};

} // namespace Diligent

