#import <Cocoa/Cocoa.h>
#import <QuartzCore/CAMetalLayer.h>
#import <CoreGraphics/CoreGraphics.h>

#include "SwapChainMtlImpl.hpp"
#include "RenderDeviceMtlImpl.hpp"
#include "DeviceContextMtlImpl.hpp"
#include "TextureMtlImpl.hpp"
#include "TextureViewMtlImpl.hpp"
#include "Cast.hpp"
#include "DebugUtilities.hpp"

namespace Diligent
{

SwapChainMtlImpl::SwapChainMtlImpl(IReferenceCounters*    pRefCounters,
                                   RenderDeviceMtlImpl*   pDevice,
                                   DeviceContextMtlImpl*  pImmediateCtx,
                                   const SwapChainDesc&   SCDesc,
                                   NSView*                pView) :
    TBase{pRefCounters},
    m_Desc{SCDesc},
    m_pDevice{pDevice},
    m_pImmediateCtx{pImmediateCtx}
{
    if (m_Desc.Width == 0)  m_Desc.Width  = 800;
    if (m_Desc.Height == 0) m_Desc.Height = 600;
    m_Desc.ColorBufferFormat = TEX_FORMAT_BGRA8_UNORM; // enforce BGRA8 for CAMetalLayer
    if (m_Desc.DepthBufferFormat == TEX_FORMAT_UNKNOWN)
        m_Desc.DepthBufferFormat = TEX_FORMAT_D32_FLOAT;

    m_pLayer = (CAMetalLayer*)[pView layer];
    if (![m_pLayer isKindOfClass:[CAMetalLayer class]])
    {
        [pView setWantsLayer:YES];
        m_pLayer = [CAMetalLayer layer];
        [pView setLayer:m_pLayer];
    }
    // Ensure layer has proper device & geometry. Use the engine's Metal device to avoid mismatch.
    id<MTLDevice> dev = m_pDevice ? m_pDevice->GetMtlDevice() : MTLCreateSystemDefaultDevice();
    if (dev)
        m_pLayer.device = dev;
    m_pLayer.frame = pView.bounds;
    m_pLayer.pixelFormat     = MTLPixelFormatBGRA8Unorm;
    m_pLayer.framebufferOnly = YES;
    m_pLayer.drawableSize    = CGSizeMake(m_Desc.Width, m_Desc.Height);
    m_pLayer.contentsScale   = [pView.window backingScaleFactor];
    m_pLayer.opaque          = YES;
    if ([m_pLayer respondsToSelector:@selector(setDisplaySyncEnabled:)])
    {
        @try { [m_pLayer setDisplaySyncEnabled:YES]; } @catch (...) {}
    }
    if ([m_pLayer respondsToSelector:@selector(setPresentsWithTransaction:)])
    {
        @try { [m_pLayer setPresentsWithTransaction:NO]; } @catch (...) {}
    }
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
    if (cs)
    {
        if ([m_pLayer respondsToSelector:@selector(setColorspace:)])
            [m_pLayer setColorspace:cs];
        CGColorSpaceRelease(cs);
    }
    [pView setNeedsDisplay:YES];

    CreateDepthBuffer();
}

void SwapChainMtlImpl::AcquireNextDrawable()
{
    if (m_CurrentDrawable)
        return;
    m_CurrentDrawable = [m_pLayer nextDrawable];
    if (!m_CurrentDrawable)
    {
        LOG_INFO_MESSAGE("Metal SwapChain: nextDrawable returned nil (layer size=", (int)m_pLayer.drawableSize.width,
                          "x", (int)m_pLayer.drawableSize.height, ") - skipping frame");
        return;
    }

    id<MTLTexture> colorTex = [m_CurrentDrawable texture];
    if (!colorTex)
        return;
    // Release previous RTV so CreateTextureFromMtlResource gets a null output
    if (m_pRTV)
        m_pRTV.Release();

    RefCntAutoPtr<ITexture> BackbufferTex; // must be null before creation
    m_pDevice->CreateTextureFromMtlResource(colorTex, RESOURCE_STATE_UNKNOWN, &BackbufferTex);
    if (BackbufferTex)
    {
        m_pBackbufferTexture = BackbufferTex; // hold reference
        m_pRTV = BackbufferTex->GetDefaultView(TEXTURE_VIEW_RENDER_TARGET);
    }
}

void SwapChainMtlImpl::CreateDepthBuffer()
{
    // Release previous depth resources to satisfy CreateTexture contract
    if (m_pDepthTexture)
    {
        m_pDSV.Release();
        m_pDepthTexture.Release();
    }
    TextureDesc DepthDesc;
    DepthDesc.Name = "DepthBuffer";
    DepthDesc.Type = RESOURCE_DIM_TEX_2D;
    DepthDesc.Format = m_Desc.DepthBufferFormat;
    DepthDesc.Width = m_Desc.Width;
    DepthDesc.Height = m_Desc.Height;
    DepthDesc.MipLevels = 1;
    DepthDesc.ArraySize = 1;
    DepthDesc.BindFlags = BIND_DEPTH_STENCIL;
    DepthDesc.ClearValue.DepthStencil = {1.f, 0};
    DepthDesc.Usage = USAGE_DEFAULT;

    m_pDevice->CreateTexture(DepthDesc, nullptr, &m_pDepthTexture);
    if (m_pDepthTexture)
        m_pDSV = m_pDepthTexture->GetDefaultView(TEXTURE_VIEW_DEPTH_STENCIL);
}

ITextureView* SwapChainMtlImpl::GetCurrentBackBufferRTV()
{
    if (!m_CurrentDrawable)
        AcquireNextDrawable();
    return m_pRTV;
}

void SwapChainMtlImpl::Resize(Uint32 NewWidth, Uint32 NewHeight, SURFACE_TRANSFORM NewPreTransform)
{
    if (NewWidth == 0 || NewHeight == 0)
        return;
    m_Desc.Width = NewWidth;
    m_Desc.Height = NewHeight;
    m_Desc.PreTransform = NewPreTransform;
    m_pLayer.drawableSize = CGSizeMake(NewWidth, NewHeight);
    CreateDepthBuffer();
}

void SwapChainMtlImpl::Present(Uint32)
{
    @autoreleasepool
    {
        if (!m_CurrentDrawable)
            AcquireNextDrawable();
        if (!m_CurrentDrawable)
        {
            // Nothing to present this frame
            return;
        }

        if (m_pImmediateCtx->m_MtlRenderEncoder != nil)
        {
            [m_pImmediateCtx->m_MtlRenderEncoder endEncoding];
            [m_pImmediateCtx->m_MtlRenderEncoder release];
            m_pImmediateCtx->m_MtlRenderEncoder = nil;
        }
        if (m_pImmediateCtx->m_MtlCommandBuffer != nil)
        {
            [m_pImmediateCtx->m_MtlCommandBuffer presentDrawable:m_CurrentDrawable];
            [m_pImmediateCtx->m_MtlCommandBuffer commit];
            [m_pImmediateCtx->m_MtlCommandBuffer release];
            m_pImmediateCtx->m_MtlCommandBuffer = nil;
        }
        // Release backbuffer RTV after presenting to avoid holding stale wrapper
        if (m_pRTV)
            m_pRTV.Release();
        if (m_pBackbufferTexture)
            m_pBackbufferTexture.Release();
        m_CurrentDrawable = nil;
    }
}

} // namespace Diligent
