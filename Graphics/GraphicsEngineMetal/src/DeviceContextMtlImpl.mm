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

#include "DeviceContextMtlImpl.hpp"
#include "RenderDeviceMtlImpl.hpp"
#include "PipelineStateMtlImpl.hpp"
#include "BufferMtlImpl.hpp"
#include "TextureMtlImpl.hpp"
#include "TextureViewMtlImpl.hpp"
#include "RenderPassMtlImpl.hpp"
#include "QueryMtlImpl.hpp"
#include "FenceMtlImpl.hpp"
#include "BottomLevelASMtlImpl.hpp"
#include "TopLevelASMtlImpl.hpp"
#include "GraphicsAccessories.hpp"
#include "Cast.hpp"
#import <Metal/Metal.h>

namespace Diligent
{

DeviceContextMtlImpl::DeviceContextMtlImpl(IReferenceCounters*      pRefCounters,
                                           RenderDeviceMtlImpl*     pDevice,
                                           const EngineCreateInfo&  EngineCI,
                                           const DeviceContextDesc& Desc) :
    TDeviceContextBase{pRefCounters, pDevice, Desc}
{
    auto* pDeviceMtl = static_cast<RenderDeviceMtlImpl*>(GetDevice());
    id<MTLDevice> mtlDevice = pDeviceMtl->GetMtlDevice();
    m_MtlCommandQueue = [mtlDevice newCommandQueue];
}

DeviceContextMtlImpl::~DeviceContextMtlImpl()
{
    if (m_MtlRenderEncoder != nil)
    {
        [m_MtlRenderEncoder endEncoding];
        [m_MtlRenderEncoder release];
        m_MtlRenderEncoder = nil;
    }
    
    if (m_MtlComputeEncoder != nil)
    {
        [m_MtlComputeEncoder endEncoding];
        [m_MtlComputeEncoder release];
        m_MtlComputeEncoder = nil;
    }
    
    if (m_MtlBlitEncoder != nil)
    {
        [m_MtlBlitEncoder endEncoding];
        [m_MtlBlitEncoder release];
        m_MtlBlitEncoder = nil;
    }
    
    if (m_MtlCommandBuffer != nil)
    {
        [m_MtlCommandBuffer release];
        m_MtlCommandBuffer = nil;
    }
    
    if (m_MtlCommandQueue != nil)
    {
        [m_MtlCommandQueue release];
        m_MtlCommandQueue = nil;
    }
}

void DeviceContextMtlImpl::Begin(Uint32 ImmediateContextId)
{
    TDeviceContextBase::Begin(DeviceContextIndex{ImmediateContextId}, COMMAND_QUEUE_TYPE_GRAPHICS);
}

void DeviceContextMtlImpl::EnsureCommandBuffer()
{
    if (m_MtlCommandBuffer == nil)
    {
        m_MtlCommandBuffer = [m_MtlCommandQueue commandBuffer];
        [m_MtlCommandBuffer retain];
    }
}

void DeviceContextMtlImpl::EndAllEncoders()
{
    if (m_MtlRenderEncoder != nil)
    {
        [m_MtlRenderEncoder endEncoding];
        [m_MtlRenderEncoder release];
        m_MtlRenderEncoder = nil;
    }
    
    if (m_MtlComputeEncoder != nil)
    {
        [m_MtlComputeEncoder endEncoding];
        [m_MtlComputeEncoder release];
        m_MtlComputeEncoder = nil;
    }
    
    if (m_MtlBlitEncoder != nil)
    {
        [m_MtlBlitEncoder endEncoding];
        [m_MtlBlitEncoder release];
        m_MtlBlitEncoder = nil;
    }
}

void DeviceContextMtlImpl::SetPipelineState(IPipelineState* pPipelineState)
{
    m_pPipelineState = pPipelineState;
    
    if (m_MtlRenderEncoder != nil && pPipelineState != nullptr)
    {
        auto* pPSOMtl = static_cast<PipelineStateMtlImpl*>(pPipelineState);
        
        id<MTLRenderPipelineState> mtlPipeline = pPSOMtl->GetMtlRenderPipeline();
        if (mtlPipeline != nil)
        {
            [m_MtlRenderEncoder setRenderPipelineState:mtlPipeline];
        }
        
        id<MTLDepthStencilState> mtlDepthStencil = pPSOMtl->GetMtlDepthStencilState();
        if (mtlDepthStencil != nil)
        {
            [m_MtlRenderEncoder setDepthStencilState:mtlDepthStencil];
        }
    }
    else if (m_MtlComputeEncoder != nil && pPipelineState != nullptr)
    {
        auto* pPSOMtl = static_cast<PipelineStateMtlImpl*>(pPipelineState);
        
        id<MTLComputePipelineState> mtlPipeline = pPSOMtl->GetMtlComputePipeline();
        if (mtlPipeline != nil)
        {
            [m_MtlComputeEncoder setComputePipelineState:mtlPipeline];
        }
    }
}

void DeviceContextMtlImpl::TransitionShaderResources(IShaderResourceBinding* pShaderResourceBinding)
{
    // Metal doesn't require explicit resource transitions
    // Resources are automatically transitioned based on usage
}

void DeviceContextMtlImpl::CommitShaderResources(IShaderResourceBinding* pShaderResourceBinding, RESOURCE_STATE_TRANSITION_MODE StateTransitionMode)
{
    if (pShaderResourceBinding == nullptr)
        return;
    
    // Metal resource binding is done through shader resource binding object
    // In a full implementation, this would:
    // 1. Iterate through bound resources in the shader resource binding
    // 2. Call setBuffer, setTexture, setSampler on the appropriate encoder
    // 3. Set resources for vertex, fragment, and/or compute shaders
    
    // For now, this provides the interface for future full implementation
    // Actual binding would look like:
    // if (m_MtlRenderEncoder != nil)
    // {
    //     for each buffer: [m_MtlRenderEncoder setVertexBuffer:mtlBuffer offset:0 atIndex:index];
    //     for each texture: [m_MtlRenderEncoder setFragmentTexture:mtlTexture atIndex:index];
    //     for each sampler: [m_MtlRenderEncoder setFragmentSamplerState:mtlSampler atIndex:index];
    // }
    // else if (m_MtlComputeEncoder != nil)
    // {
    //     Similar binding for compute resources
    // }
}

void DeviceContextMtlImpl::SetStencilRef(Uint32 StencilRef)
{
    if (m_MtlRenderEncoder != nil)
    {
        [m_MtlRenderEncoder setStencilReferenceValue:StencilRef];
    }
}

void DeviceContextMtlImpl::SetBlendFactors(const float* pBlendFactors)
{
    if (m_MtlRenderEncoder != nil && pBlendFactors != nullptr)
    {
        [m_MtlRenderEncoder setBlendColorRed:pBlendFactors[0]
                                       green:pBlendFactors[1]
                                        blue:pBlendFactors[2]
                                       alpha:pBlendFactors[3]];
    }
}

void DeviceContextMtlImpl::SetVertexBuffers(Uint32 StartSlot, Uint32 NumBuffersSet, IBuffer* const* ppBuffers, const Uint64* pOffsets, RESOURCE_STATE_TRANSITION_MODE StateTransitionMode, SET_VERTEX_BUFFERS_FLAGS Flags)
{
    if (m_MtlRenderEncoder == nil)
        return;
    
    for (Uint32 i = 0; i < NumBuffersSet; ++i)
    {
        if (ppBuffers[i] != nullptr)
        {
            auto* pBufferMtl = static_cast<BufferMtlImpl*>(ppBuffers[i]);
            id<MTLBuffer> mtlBuffer = pBufferMtl->GetMtlResource();
            Uint64 offset = pOffsets ? pOffsets[i] : 0;
            
            [m_MtlRenderEncoder setVertexBuffer:mtlBuffer
                                         offset:offset
                                        atIndex:StartSlot + i];
        }
    }
}

void DeviceContextMtlImpl::InvalidateState()
{
    // Invalidate cached state
    m_pPipelineState = nullptr;
}

void DeviceContextMtlImpl::SetIndexBuffer(IBuffer* pIndexBuffer, Uint64 ByteOffset, RESOURCE_STATE_TRANSITION_MODE StateTransitionMode)
{
    // Metal doesn't have a separate SetIndexBuffer call
    // Index buffer is specified in draw calls
    // Store for later use in DrawIndexed
    m_pIndexBuffer = pIndexBuffer;
    m_IndexBufferOffset = ByteOffset;
}

void DeviceContextMtlImpl::SetViewports(Uint32 NumViewports, const Viewport* pViewports, Uint32 RTWidth, Uint32 RTHeight)
{
    if (m_MtlRenderEncoder == nil || NumViewports == 0)
        return;
    
    MTLViewport mtlViewport;
    mtlViewport.originX = pViewports[0].TopLeftX;
    mtlViewport.originY = pViewports[0].TopLeftY;
    mtlViewport.width   = pViewports[0].Width;
    mtlViewport.height  = pViewports[0].Height;
    mtlViewport.znear   = pViewports[0].MinDepth;
    mtlViewport.zfar    = pViewports[0].MaxDepth;
    
    [m_MtlRenderEncoder setViewport:mtlViewport];
}

void DeviceContextMtlImpl::SetScissorRects(Uint32 NumRects, const Rect* pRects, Uint32 RTWidth, Uint32 RTHeight)
{
    if (m_MtlRenderEncoder == nil || NumRects == 0)
        return;
    
    MTLScissorRect mtlScissor;
    mtlScissor.x      = pRects[0].left;
    mtlScissor.y      = pRects[0].top;
    mtlScissor.width  = pRects[0].right - pRects[0].left;
    mtlScissor.height = pRects[0].bottom - pRects[0].top;
    
    [m_MtlRenderEncoder setScissorRect:mtlScissor];
}

void DeviceContextMtlImpl::SetRenderTargetsExt(const SetRenderTargetsAttribs& Attribs)
{
    auto NumRenderTargets = Attribs.NumRenderTargets;
    auto ppRenderTargets = Attribs.ppRenderTargets;
    auto pDepthStencil = Attribs.pDepthStencil;

    EndAllEncoders();
    EnsureCommandBuffer();

    @autoreleasepool
    {
        MTLRenderPassDescriptor* renderPassDesc = [MTLRenderPassDescriptor renderPassDescriptor];

        // Configure color attachments
        for (Uint32 i = 0; i < NumRenderTargets; ++i)
        {
            if (ppRenderTargets[i] != nullptr)
            {
                auto* pRTVMtl = static_cast<TextureViewMtlImpl*>(ppRenderTargets[i]);
                id<MTLTexture> mtlTexture = pRTVMtl->GetMtlTexture();

                if (mtlTexture != nil)
                {
                    renderPassDesc.colorAttachments[i].texture = mtlTexture;
                    renderPassDesc.colorAttachments[i].loadAction = MTLLoadActionLoad;
                    renderPassDesc.colorAttachments[i].storeAction = MTLStoreActionStore;
                }
            }
        }

        // Configure depth/stencil attachment
        if (pDepthStencil != nullptr)
        {
            auto* pDSVMtl = static_cast<TextureViewMtlImpl*>(pDepthStencil);
            id<MTLTexture> mtlTexture = pDSVMtl->GetMtlTexture();

            if (mtlTexture != nil)
            {
                renderPassDesc.depthAttachment.texture = mtlTexture;
                renderPassDesc.depthAttachment.loadAction = MTLLoadActionLoad;
                renderPassDesc.depthAttachment.storeAction = MTLStoreActionStore;

                renderPassDesc.stencilAttachment.texture = mtlTexture;
                renderPassDesc.stencilAttachment.loadAction = MTLLoadActionLoad;
                renderPassDesc.stencilAttachment.storeAction = MTLStoreActionStore;
            }
        }

        // Create render command encoder
        m_MtlRenderEncoder = [m_MtlCommandBuffer renderCommandEncoderWithDescriptor:renderPassDesc];
        [m_MtlRenderEncoder retain];
    }
}

void DeviceContextMtlImpl::BeginRenderPass(const BeginRenderPassAttribs& Attribs)
{
    EndAllEncoders();
    EnsureCommandBuffer();
    
    // Metal doesn't use separate framebuffer objects
    // For now, store the render pass for reference
    // Actual encoding happens when SetRenderTargets is called or draw commands are issued
    m_pActiveRenderPass = Attribs.pRenderPass;
    m_pClearValues = Attribs.pClearValues;
    m_ClearValueCount = Attribs.ClearValueCount;
}

void DeviceContextMtlImpl::NextSubpass()
{
    // Metal doesn't support subpasses like Vulkan
    // This would require ending current encoder and starting a new one
}

void DeviceContextMtlImpl::EndRenderPass()
{
    if (m_MtlRenderEncoder != nil)
    {
        [m_MtlRenderEncoder endEncoding];
        [m_MtlRenderEncoder release];
        m_MtlRenderEncoder = nil;
    }
}

void DeviceContextMtlImpl::Draw(const DrawAttribs& Attribs)
{
    if (m_MtlRenderEncoder == nil)
        return;
    printf("[Metal] Draw vertices=%u start=%u instances=%u baseInstance=%u\n",
           (unsigned)Attribs.NumVertices,
           (unsigned)Attribs.StartVertexLocation,
           (unsigned)Attribs.NumInstances,
           (unsigned)Attribs.FirstInstanceLocation);

    [m_MtlRenderEncoder drawPrimitives:MTLPrimitiveTypeTriangle
                           vertexStart:Attribs.StartVertexLocation
                           vertexCount:Attribs.NumVertices
                         instanceCount:Attribs.NumInstances
                          baseInstance:Attribs.FirstInstanceLocation];
}

void DeviceContextMtlImpl::DrawIndexed(const DrawIndexedAttribs& Attribs)
{
    if (m_MtlRenderEncoder == nil || m_pIndexBuffer == nil)
        return;
    
    auto* pIndexBufferMtl = static_cast<BufferMtlImpl*>(m_pIndexBuffer);
    id<MTLBuffer> mtlIndexBuffer = pIndexBufferMtl->GetMtlResource();
    
    if (mtlIndexBuffer != nil)
    {
        [m_MtlRenderEncoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle
                                       indexCount:Attribs.NumIndices
                                        indexType:MTLIndexTypeUInt32
                                      indexBuffer:mtlIndexBuffer
                                indexBufferOffset:m_IndexBufferOffset + Attribs.FirstIndexLocation * sizeof(Uint32)
                                    instanceCount:Attribs.NumInstances
                                       baseVertex:Attribs.BaseVertex
                                     baseInstance:Attribs.FirstInstanceLocation];
    }
}

void DeviceContextMtlImpl::DrawIndirect(const DrawIndirectAttribs& Attribs)
{
    if (m_MtlRenderEncoder == nil || Attribs.pAttribsBuffer == nullptr)
        return;
    
    auto* pIndirectBufferMtl = static_cast<BufferMtlImpl*>(Attribs.pAttribsBuffer);
    id<MTLBuffer> mtlIndirectBuffer = pIndirectBufferMtl->GetMtlResource();
    
    if (mtlIndirectBuffer != nil)
    {
        // DrawAttribsBuffer offset must be offset in the buffer where draw commands start
        NSUInteger offset = Attribs.DrawArgsOffset;
        
        for (Uint32 i = 0; i < Attribs.DrawCount; ++i)
        {
            [m_MtlRenderEncoder drawPrimitives:MTLPrimitiveTypeTriangle
                                indirectBuffer:mtlIndirectBuffer
                          indirectBufferOffset:offset + i * Attribs.DrawArgsStride];
        }
    }
}

void DeviceContextMtlImpl::DrawIndexedIndirect(const DrawIndexedIndirectAttribs& Attribs)
{
    if (m_MtlRenderEncoder == nil || Attribs.pAttribsBuffer == nullptr || m_pIndexBuffer == nullptr)
        return;
    
    auto* pIndirectBufferMtl = static_cast<BufferMtlImpl*>(Attribs.pAttribsBuffer);
    id<MTLBuffer> mtlIndirectBuffer = pIndirectBufferMtl->GetMtlResource();
    
    auto* pIndexBufferMtl = static_cast<BufferMtlImpl*>(m_pIndexBuffer);
    id<MTLBuffer> mtlIndexBuffer = pIndexBufferMtl->GetMtlResource();
    
    if (mtlIndirectBuffer != nil && mtlIndexBuffer != nil)
    {
        NSUInteger offset = Attribs.DrawArgsOffset;
        
        for (Uint32 i = 0; i < Attribs.DrawCount; ++i)
        {
            [m_MtlRenderEncoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle
                                            indexType:MTLIndexTypeUInt32
                                          indexBuffer:mtlIndexBuffer
                                    indexBufferOffset:m_IndexBufferOffset
                                       indirectBuffer:mtlIndirectBuffer
                                 indirectBufferOffset:offset + i * Attribs.DrawArgsStride];
        }
    }
}

void DeviceContextMtlImpl::DrawMesh(const DrawMeshAttribs& Attribs)
{
    if (@available(macOS 13.0, iOS 16.0, *))
    {
        if (m_MtlRenderEncoder == nil)
            return;

        // Metal mesh shaders use drawMeshThreadgroups API
        // This requires a render command encoder and mesh shader pipeline
        
        MTLSize threadgroupsPerGrid = MTLSizeMake(Attribs.ThreadGroupCountX, 
                                                   Attribs.ThreadGroupCountY, 
                                                   Attribs.ThreadGroupCountZ);
        
        // Would call: [m_MtlRenderEncoder drawMeshThreadgroups:threadgroupsPerGrid ...]
        // Actual implementation needs threadsPerObjectThreadgroup and threadsPerMeshThreadgroup
    }
    else
    {
        // Mesh shaders require Metal 3.0 (macOS 13.0, iOS 16.0)
    }
}

void DeviceContextMtlImpl::DrawMeshIndirect(const DrawMeshIndirectAttribs& Attribs)
{
    if (@available(macOS 13.0, iOS 16.0, *))
    {
        if (m_MtlRenderEncoder == nil || Attribs.pAttribsBuffer == nullptr)
            return;

        auto* pAttribsBuffer = ClassPtrCast<BufferMtlImpl>(Attribs.pAttribsBuffer);
        id<MTLBuffer> indirectBuffer = pAttribsBuffer->GetMtlResource();

        if (indirectBuffer == nil)
            return;

        // Metal mesh shaders with indirect buffer
        // Would call: [m_MtlRenderEncoder drawMeshThreadgroupsWithIndirectBuffer:indirectBuffer ...]
        // Actual implementation needs indirect buffer offset and other parameters
    }
    else
    {
        // Mesh shaders require Metal 3.0 (macOS 13.0, iOS 16.0)
    }
}

void DeviceContextMtlImpl::DispatchCompute(const DispatchComputeAttribs& Attribs)
{
    EndAllEncoders();
    EnsureCommandBuffer();
    
    if (m_pPipelineState == nullptr)
        return;
    
    m_MtlComputeEncoder = [m_MtlCommandBuffer computeCommandEncoder];
    [m_MtlComputeEncoder retain];
    
    auto* pPSOMtl = static_cast<PipelineStateMtlImpl*>(m_pPipelineState);
    id<MTLComputePipelineState> mtlPipeline = pPSOMtl->GetMtlComputePipeline();
    
    if (mtlPipeline != nil)
    {
        [m_MtlComputeEncoder setComputePipelineState:mtlPipeline];
        
        MTLSize threadgroupSize = MTLSizeMake(Attribs.ThreadGroupCountX, Attribs.ThreadGroupCountY, Attribs.ThreadGroupCountZ);
        MTLSize threadgroups = MTLSizeMake(1, 1, 1);
        
        [m_MtlComputeEncoder dispatchThreadgroups:threadgroups
                            threadsPerThreadgroup:threadgroupSize];
    }
    
    [m_MtlComputeEncoder endEncoding];
    [m_MtlComputeEncoder release];
    m_MtlComputeEncoder = nil;
}

void DeviceContextMtlImpl::DispatchComputeIndirect(const DispatchComputeIndirectAttribs& Attribs)
{
    if (m_pPipelineState == nullptr || Attribs.pAttribsBuffer == nullptr)
        return;
    
    EndAllEncoders();
    EnsureCommandBuffer();
    
    m_MtlComputeEncoder = [m_MtlCommandBuffer computeCommandEncoder];
    [m_MtlComputeEncoder retain];
    
    auto* pPSOMtl = static_cast<PipelineStateMtlImpl*>(m_pPipelineState);
    id<MTLComputePipelineState> mtlPipeline = pPSOMtl->GetMtlComputePipeline();
    
    if (mtlPipeline != nil)
    {
        [m_MtlComputeEncoder setComputePipelineState:mtlPipeline];
        
        auto* pIndirectBufferMtl = static_cast<BufferMtlImpl*>(Attribs.pAttribsBuffer);
        id<MTLBuffer> mtlIndirectBuffer = pIndirectBufferMtl->GetMtlResource();
        
        if (mtlIndirectBuffer != nil)
        {
            // Get max threads per threadgroup from pipeline
            NSUInteger maxThreadsPerThreadgroup = [mtlPipeline maxTotalThreadsPerThreadgroup];
            
            [m_MtlComputeEncoder dispatchThreadgroupsWithIndirectBuffer:mtlIndirectBuffer
                                                   indirectBufferOffset:Attribs.DispatchArgsByteOffset
                                                  threadsPerThreadgroup:MTLSizeMake(maxThreadsPerThreadgroup, 1, 1)];
        }
    }
    
    [m_MtlComputeEncoder endEncoding];
    [m_MtlComputeEncoder release];
    m_MtlComputeEncoder = nil;
}

void DeviceContextMtlImpl::ClearDepthStencil(ITextureView* pView, CLEAR_DEPTH_STENCIL_FLAGS ClearFlags, float fDepth, Uint8 Stencil, RESOURCE_STATE_TRANSITION_MODE StateTransitionMode)
{
    if (pView == nullptr)
        return;
    
    EndAllEncoders();
    EnsureCommandBuffer();
    
    @autoreleasepool
    {
        auto* pDSVMtl = static_cast<TextureViewMtlImpl*>(pView);
        id<MTLTexture> mtlTexture = pDSVMtl->GetMtlTexture();
        
        if (mtlTexture == nil)
            return;
        
        MTLRenderPassDescriptor* renderPassDesc = [MTLRenderPassDescriptor renderPassDescriptor];
        
        // Configure depth attachment
        if (ClearFlags & CLEAR_DEPTH_FLAG)
        {
            renderPassDesc.depthAttachment.texture = mtlTexture;
            renderPassDesc.depthAttachment.loadAction = MTLLoadActionClear;
            renderPassDesc.depthAttachment.storeAction = MTLStoreActionStore;
            renderPassDesc.depthAttachment.clearDepth = fDepth;
        }
        
        // Configure stencil attachment
        if (ClearFlags & CLEAR_STENCIL_FLAG)
        {
            renderPassDesc.stencilAttachment.texture = mtlTexture;
            renderPassDesc.stencilAttachment.loadAction = MTLLoadActionClear;
            renderPassDesc.stencilAttachment.storeAction = MTLStoreActionStore;
            renderPassDesc.stencilAttachment.clearStencil = Stencil;
        }
        
        // Create a temporary render encoder just to perform the clear
        id<MTLRenderCommandEncoder> tempEncoder = [m_MtlCommandBuffer renderCommandEncoderWithDescriptor:renderPassDesc];
        [tempEncoder endEncoding];
    }
}

void DeviceContextMtlImpl::ClearRenderTarget(ITextureView* pView, const void* RGBA, RESOURCE_STATE_TRANSITION_MODE StateTransitionMode)
{
    if (pView == nullptr || RGBA == nullptr)
        return;
    
    EndAllEncoders();
    EnsureCommandBuffer();
    
    @autoreleasepool
    {
        auto* pRTVMtl = static_cast<TextureViewMtlImpl*>(pView);
        id<MTLTexture> mtlTexture = pRTVMtl->GetMtlTexture();
        
        if (mtlTexture == nil)
            return;
        
        MTLRenderPassDescriptor* renderPassDesc = [MTLRenderPassDescriptor renderPassDescriptor];
        
        // Configure color attachment
        renderPassDesc.colorAttachments[0].texture = mtlTexture;
        renderPassDesc.colorAttachments[0].loadAction = MTLLoadActionClear;
        renderPassDesc.colorAttachments[0].storeAction = MTLStoreActionStore;
        const float* rgba = static_cast<const float*>(RGBA);
        renderPassDesc.colorAttachments[0].clearColor = MTLClearColorMake(rgba[0], rgba[1], rgba[2], rgba[3]);
        
        // Create a temporary render encoder just to perform the clear
        id<MTLRenderCommandEncoder> tempEncoder = [m_MtlCommandBuffer renderCommandEncoderWithDescriptor:renderPassDesc];
        [tempEncoder endEncoding];
    }
}

void DeviceContextMtlImpl::GenerateMips(ITextureView* pTexView)
{
    if (pTexView == nullptr)
        return;
    
    EndAllEncoders();
    EnsureCommandBuffer();
    
    auto* pTextureViewMtl = static_cast<TextureViewMtlImpl*>(pTexView);
    id<MTLTexture> mtlTexture = pTextureViewMtl->GetMtlTexture();
    
    if (mtlTexture == nil || ![mtlTexture supportsMipmaps])
        return;
    
    m_MtlBlitEncoder = [m_MtlCommandBuffer blitCommandEncoder];
    [m_MtlBlitEncoder retain];
    
    // Generate mipmaps using Metal's built-in mipmap generation
    [m_MtlBlitEncoder generateMipmapsForTexture:mtlTexture];
    
    [m_MtlBlitEncoder endEncoding];
    [m_MtlBlitEncoder release];
    m_MtlBlitEncoder = nil;
}

void DeviceContextMtlImpl::ResolveTextureSubresource(ITexture*                               pSrcTexture,
                                                     ITexture*                               pDstTexture,
                                                     const ResolveTextureSubresourceAttribs& ResolveAttribs)
{
    if (pSrcTexture == nullptr || pDstTexture == nullptr)
        return;
    
    EndAllEncoders();
    EnsureCommandBuffer();
    
    auto* pSrcTextureMtl = static_cast<TextureMtlImpl*>(pSrcTexture);
    auto* pDstTextureMtl = static_cast<TextureMtlImpl*>(pDstTexture);
    
    id<MTLTexture> srcMtlTexture = static_cast<id<MTLTexture>>(pSrcTextureMtl->GetMtlResource());
    id<MTLTexture> dstMtlTexture = static_cast<id<MTLTexture>>(pDstTextureMtl->GetMtlResource());
    
    if (srcMtlTexture == nil || dstMtlTexture == nil)
        return;
    
    m_MtlBlitEncoder = [m_MtlCommandBuffer blitCommandEncoder];
    [m_MtlBlitEncoder retain];
    
    MTLOrigin srcOrigin = MTLOriginMake(0, 0, 0);
    MTLSize srcSize = MTLSizeMake([srcMtlTexture width], [srcMtlTexture height], [srcMtlTexture depth]);
    MTLOrigin dstOrigin = MTLOriginMake(0, 0, 0);
    
    // Resolve multisample texture to single sample
    [m_MtlBlitEncoder resolveCountersInRange:NSMakeRange(0, 1)
                                   sampleIndex:0
                                      fromRange:NSMakeRange(0, 1)
                                        toRange:NSMakeRange(0, 1)];
    
    [m_MtlBlitEncoder endEncoding];
    [m_MtlBlitEncoder release];
    m_MtlBlitEncoder = nil;
}

void DeviceContextMtlImpl::UpdateBuffer(IBuffer* pBuffer, Uint64 Offset, Uint64 Size, const void* pData, RESOURCE_STATE_TRANSITION_MODE StateTransitionMode)
{
    if (pBuffer == nullptr || pData == nullptr || Size == 0)
        return;
    
    auto* pBufferMtl = static_cast<BufferMtlImpl*>(pBuffer);
    id<MTLBuffer> mtlBuffer = pBufferMtl->GetMtlResource();
    
    if (mtlBuffer != nil)
    {
        void* pMapped = [mtlBuffer contents];
        if (pMapped != nullptr)
        {
            memcpy(static_cast<uint8_t*>(pMapped) + Offset, pData, Size);
        }
    }
}

void DeviceContextMtlImpl::CopyBuffer(IBuffer* pSrcBuffer, Uint64 SrcOffset, RESOURCE_STATE_TRANSITION_MODE SrcBufferTransitionMode, IBuffer* pDstBuffer, Uint64 DstOffset, Uint64 Size, RESOURCE_STATE_TRANSITION_MODE DstBufferTransitionMode)
{
    if (pSrcBuffer == nullptr || pDstBuffer == nullptr || Size == 0)
        return;
    
    EndAllEncoders();
    EnsureCommandBuffer();
    
    auto* pSrcBufferMtl = static_cast<BufferMtlImpl*>(pSrcBuffer);
    auto* pDstBufferMtl = static_cast<BufferMtlImpl*>(pDstBuffer);
    
    id<MTLBuffer> srcMtlBuffer = pSrcBufferMtl->GetMtlResource();
    id<MTLBuffer> dstMtlBuffer = pDstBufferMtl->GetMtlResource();
    
    m_MtlBlitEncoder = [m_MtlCommandBuffer blitCommandEncoder];
    [m_MtlBlitEncoder retain];
    
    [m_MtlBlitEncoder copyFromBuffer:srcMtlBuffer
                        sourceOffset:SrcOffset
                            toBuffer:dstMtlBuffer
                   destinationOffset:DstOffset
                                size:Size];
    
    [m_MtlBlitEncoder endEncoding];
    [m_MtlBlitEncoder release];
    m_MtlBlitEncoder = nil;
}

void DeviceContextMtlImpl::MapBuffer(IBuffer* pBuffer, MAP_TYPE MapType, MAP_FLAGS MapFlags, PVoid& pMappedData)
{
    pMappedData = nullptr;
    
    if (pBuffer == nullptr)
        return;
    
    auto* pBufferMtl = static_cast<BufferMtlImpl*>(pBuffer);
    id<MTLBuffer> mtlBuffer = pBufferMtl->GetMtlResource();
    
    if (mtlBuffer != nil)
    {
        pMappedData = [mtlBuffer contents];
    }
}

void DeviceContextMtlImpl::UnmapBuffer(IBuffer* pBuffer, MAP_TYPE MapType)
{
    // Metal buffers don't need explicit unmap
    // Data is coherent for shared storage mode
}

void DeviceContextMtlImpl::UpdateTexture(ITexture* pTexture, Uint32 MipLevel, Uint32 Slice, const Box& DstBox, const TextureSubResData& SubresData, RESOURCE_STATE_TRANSITION_MODE SrcBufferTransitionMode, RESOURCE_STATE_TRANSITION_MODE DstTextureTransitionMode)
{
    if (pTexture == nullptr || SubresData.pData == nullptr)
        return;
    
    auto* pTextureMtl = static_cast<TextureMtlImpl*>(pTexture);
    id<MTLTexture> mtlTexture = static_cast<id<MTLTexture>>(pTextureMtl->GetMtlResource());
    
    if (mtlTexture != nil)
    {
        MTLRegion region;
        region.origin = MTLOriginMake(DstBox.MinX, DstBox.MinY, DstBox.MinZ);
        region.size = MTLSizeMake(DstBox.MaxX - DstBox.MinX, DstBox.MaxY - DstBox.MinY, DstBox.MaxZ - DstBox.MinZ);
        
        [mtlTexture replaceRegion:region
                      mipmapLevel:MipLevel
                            slice:Slice
                        withBytes:SubresData.pData
                      bytesPerRow:SubresData.Stride
                    bytesPerImage:SubresData.DepthStride];
    }
}

void DeviceContextMtlImpl::CopyTexture(const CopyTextureAttribs& CopyAttribs)
{
    if (CopyAttribs.pSrcTexture == nullptr || CopyAttribs.pDstTexture == nullptr)
        return;
    
    EndAllEncoders();
    EnsureCommandBuffer();
    
    auto* pSrcTextureMtl = static_cast<TextureMtlImpl*>(CopyAttribs.pSrcTexture);
    auto* pDstTextureMtl = static_cast<TextureMtlImpl*>(CopyAttribs.pDstTexture);
    
    id<MTLTexture> srcMtlTexture = static_cast<id<MTLTexture>>(pSrcTextureMtl->GetMtlResource());
    id<MTLTexture> dstMtlTexture = static_cast<id<MTLTexture>>(pDstTextureMtl->GetMtlResource());
    
    if (srcMtlTexture != nil && dstMtlTexture != nil)
    {
        m_MtlBlitEncoder = [m_MtlCommandBuffer blitCommandEncoder];
        [m_MtlBlitEncoder retain];
        
        MTLOrigin srcOrigin = MTLOriginMake(0, 0, 0);
        MTLSize srcSize = MTLSizeMake([srcMtlTexture width], [srcMtlTexture height], [srcMtlTexture depth]);
        MTLOrigin dstOrigin = MTLOriginMake(0, 0, 0);
        
        [m_MtlBlitEncoder copyFromTexture:srcMtlTexture
                              sourceSlice:0
                              sourceLevel:0
                             sourceOrigin:srcOrigin
                               sourceSize:srcSize
                                toTexture:dstMtlTexture
                         destinationSlice:0
                         destinationLevel:0
                        destinationOrigin:dstOrigin];
        
        [m_MtlBlitEncoder endEncoding];
        [m_MtlBlitEncoder release];
        m_MtlBlitEncoder = nil;
    }
}

void DeviceContextMtlImpl::MapTextureSubresource(ITexture* pTexture, Uint32 MipLevel, Uint32 ArraySlice, MAP_TYPE MapType, MAP_FLAGS MapFlags, const Box* pMapRegion, MappedTextureSubresource& MappedData)
{
    MappedData = {};
    
    if (pTexture == nullptr)
        return;
    
    auto* pTextureMtl = static_cast<TextureMtlImpl*>(pTexture);
    id<MTLTexture> mtlTexture = static_cast<id<MTLTexture>>(pTextureMtl->GetMtlResource());
    
    if (mtlTexture != nil)
    {
        // Metal textures cannot be directly mapped
        // Would need to use a staging buffer for texture mapping
        // For now, this is a stub
    }
}

void DeviceContextMtlImpl::UnmapTextureSubresource(ITexture* pTexture, Uint32 MipLevel, Uint32 ArraySlice)
{
    // Metal textures don't support direct mapping
}

void DeviceContextMtlImpl::FinishCommandList(ICommandList** ppCommandList)
{
    // Stub: Finish command list
    if (ppCommandList)
        *ppCommandList = nullptr;
}

void DeviceContextMtlImpl::ExecuteCommandLists(Uint32 NumCommandLists, ICommandList* const* ppCommandLists)
{
    // Stub: Execute command lists
}

void DeviceContextMtlImpl::EnqueueSignal(IFence* pFence, Uint64 Value)
{
    if (pFence == nullptr)
        return;
    
    EnsureCommandBuffer();
    
    auto* pFenceMtl = static_cast<FenceMtlImpl*>(pFence);
    
    if (@available(macOS 10.14, iOS 12.0, tvOS 12.0, *))
    {
        id<MTLSharedEvent> sharedEvent = pFenceMtl->GetMtlSharedEvent();
        if (sharedEvent != nil && m_MtlCommandBuffer != nil)
        {
            [m_MtlCommandBuffer encodeSignalEvent:sharedEvent value:Value];
        }
    }
}

void DeviceContextMtlImpl::DeviceWaitForFence(IFence* pFence, Uint64 Value)
{
    if (pFence == nullptr)
        return;
    
    EnsureCommandBuffer();
    
    auto* pFenceMtl = static_cast<FenceMtlImpl*>(pFence);
    
    if (@available(macOS 10.14, iOS 12.0, tvOS 12.0, *))
    {
        id<MTLSharedEvent> sharedEvent = pFenceMtl->GetMtlSharedEvent();
        if (sharedEvent != nil && m_MtlCommandBuffer != nil)
        {
            [m_MtlCommandBuffer encodeWaitForEvent:sharedEvent value:Value];
        }
    }
}

void DeviceContextMtlImpl::WaitForIdle()
{
    EndAllEncoders();
    
    if (m_MtlCommandBuffer != nil)
    {
        [m_MtlCommandBuffer commit];
        [m_MtlCommandBuffer waitUntilCompleted];
        [m_MtlCommandBuffer release];
        m_MtlCommandBuffer = nil;
    }
}

void DeviceContextMtlImpl::BeginQuery(IQuery* pQuery)
{
    if (pQuery == nullptr)
        return;
    
    // Metal queries are handled differently depending on query type
    // For timestamp queries, we sample at begin time
    // For occlusion queries, we start visibility testing
    auto* pQueryMtl = static_cast<QueryMtlImpl*>(pQuery);
    const QueryDesc& Desc = pQueryMtl->GetDesc();
    
    if (Desc.Type == QUERY_TYPE_OCCLUSION)
    {
        // Metal occlusion queries use visibility result mode
        if (m_MtlRenderEncoder != nil)
        {
            // Store query for tracking
            // Actual visibility counting would be set via setVisibilityResultMode
        }
    }
}

void DeviceContextMtlImpl::EndQuery(IQuery* pQuery)
{
    if (pQuery == nullptr)
        return;
    
    // Metal queries are completed when command buffer finishes
    // For timestamp queries, we sample at end time
    // For occlusion queries, we stop visibility testing
    auto* pQueryMtl = static_cast<QueryMtlImpl*>(pQuery);
    const QueryDesc& Desc = pQueryMtl->GetDesc();
    
    if (Desc.Type == QUERY_TYPE_TIMESTAMP)
    {
        // Record timestamp - Metal uses GPU timestamps
        // Would need MTLCounterSampleBuffer for actual implementation
    }
    else if (Desc.Type == QUERY_TYPE_OCCLUSION)
    {
        // End occlusion query
        if (m_MtlRenderEncoder != nil)
        {
            // Visibility results would be written to buffer
        }
    }
}

void DeviceContextMtlImpl::Flush()
{
    EndAllEncoders();
    
    if (m_MtlCommandBuffer != nil)
    {
        [m_MtlCommandBuffer commit];
        [m_MtlCommandBuffer release];
        m_MtlCommandBuffer = nil;
    }
}

void DeviceContextMtlImpl::BuildBLAS(const BuildBLASAttribs& Attribs)
{
    if (@available(macOS 11.0, iOS 14.0, *))
    {
        if (Attribs.pBLAS == nullptr || Attribs.pScratchBuffer == nullptr)
            return;

        EndAllEncoders();
        EnsureCommandBuffer();

        auto* pBLASMtl = ClassPtrCast<BottomLevelASMtlImpl>(Attribs.pBLAS);
        auto* pScratchBufferMtl = ClassPtrCast<BufferMtlImpl>(Attribs.pScratchBuffer);

        id<MTLAccelerationStructure> mtlAS = pBLASMtl->GetMtlAccelerationStructure();
        id<MTLBuffer> scratchBuffer = pScratchBufferMtl->GetMtlResource();

        if (mtlAS == nil || scratchBuffer == nil)
            return;

        // Create acceleration structure command encoder
        id<MTLAccelerationStructureCommandEncoder> asEncoder = 
            [m_MtlCommandBuffer accelerationStructureCommandEncoder];
        
        if (asEncoder != nil)
        {
            // Build the BLAS - actual geometry setup would require more complex descriptor creation
            // For now, just end the encoder as this is a placeholder implementation
            [asEncoder endEncoding];
        }
    }
}

void DeviceContextMtlImpl::BuildTLAS(const BuildTLASAttribs& Attribs)
{
    if (@available(macOS 11.0, iOS 14.0, *))
    {
        if (Attribs.pTLAS == nullptr || Attribs.pScratchBuffer == nullptr)
            return;

        EndAllEncoders();
        EnsureCommandBuffer();

        auto* pTLASMtl = ClassPtrCast<TopLevelASMtlImpl>(Attribs.pTLAS);
        auto* pScratchBufferMtl = ClassPtrCast<BufferMtlImpl>(Attribs.pScratchBuffer);

        id<MTLAccelerationStructure> mtlAS = pTLASMtl->GetMtlAccelerationStructure();
        id<MTLBuffer> scratchBuffer = pScratchBufferMtl->GetMtlResource();

        if (mtlAS == nil || scratchBuffer == nil)
            return;

        // Create acceleration structure command encoder
        id<MTLAccelerationStructureCommandEncoder> asEncoder = 
            [m_MtlCommandBuffer accelerationStructureCommandEncoder];
        
        if (asEncoder != nil)
        {
            // Build the TLAS - actual instance setup would require more complex descriptor creation
            // For now, just end the encoder as this is a placeholder implementation
            [asEncoder endEncoding];
        }
    }
}

void DeviceContextMtlImpl::CopyBLAS(const CopyBLASAttribs& Attribs)
{
    if (@available(macOS 11.0, iOS 14.0, *))
    {
        if (Attribs.pSrc == nullptr || Attribs.pDst == nullptr)
            return;

        EndAllEncoders();
        EnsureCommandBuffer();

        auto* pSrcBLAS = ClassPtrCast<BottomLevelASMtlImpl>(Attribs.pSrc);
        auto* pDstBLAS = ClassPtrCast<BottomLevelASMtlImpl>(Attribs.pDst);

        id<MTLAccelerationStructure> srcAS = pSrcBLAS->GetMtlAccelerationStructure();
        id<MTLAccelerationStructure> dstAS = pDstBLAS->GetMtlAccelerationStructure();

        if (srcAS == nil || dstAS == nil)
            return;

        // Create acceleration structure command encoder
        id<MTLAccelerationStructureCommandEncoder> asEncoder = 
            [m_MtlCommandBuffer accelerationStructureCommandEncoder];
        
        if (asEncoder != nil)
        {
            [asEncoder copyAccelerationStructure:srcAS toAccelerationStructure:dstAS];
            [asEncoder endEncoding];
        }
    }
}

void DeviceContextMtlImpl::CopyTLAS(const CopyTLASAttribs& Attribs)
{
    if (@available(macOS 11.0, iOS 14.0, *))
    {
        if (Attribs.pSrc == nullptr || Attribs.pDst == nullptr)
            return;

        EndAllEncoders();
        EnsureCommandBuffer();

        auto* pSrcTLAS = ClassPtrCast<TopLevelASMtlImpl>(Attribs.pSrc);
        auto* pDstTLAS = ClassPtrCast<TopLevelASMtlImpl>(Attribs.pDst);

        id<MTLAccelerationStructure> srcAS = pSrcTLAS->GetMtlAccelerationStructure();
        id<MTLAccelerationStructure> dstAS = pDstTLAS->GetMtlAccelerationStructure();

        if (srcAS == nil || dstAS == nil)
            return;

        // Create acceleration structure command encoder
        id<MTLAccelerationStructureCommandEncoder> asEncoder = 
            [m_MtlCommandBuffer accelerationStructureCommandEncoder];
        
        if (asEncoder != nil)
        {
            [asEncoder copyAccelerationStructure:srcAS toAccelerationStructure:dstAS];
            [asEncoder endEncoding];
        }
    }
}

void DeviceContextMtlImpl::WriteBLASCompactedSize(const WriteBLASCompactedSizeAttribs& Attribs)
{
    if (@available(macOS 11.0, iOS 14.0, *))
    {
        if (Attribs.pBLAS == nullptr || Attribs.pDestBuffer == nullptr)
            return;

        EndAllEncoders();
        EnsureCommandBuffer();

        auto* pBLAS = ClassPtrCast<BottomLevelASMtlImpl>(Attribs.pBLAS);
        auto* pDestBuffer = ClassPtrCast<BufferMtlImpl>(Attribs.pDestBuffer);

        id<MTLAccelerationStructure> mtlAS = pBLAS->GetMtlAccelerationStructure();
        id<MTLBuffer> destBuffer = pDestBuffer->GetMtlResource();

        if (mtlAS == nil || destBuffer == nil)
            return;

        // Create acceleration structure command encoder
        id<MTLAccelerationStructureCommandEncoder> asEncoder = 
            [m_MtlCommandBuffer accelerationStructureCommandEncoder];
        
        if (asEncoder != nil)
        {
            // Write compacted size to buffer
            [asEncoder writeCompactedAccelerationStructureSize:mtlAS
                                                      toBuffer:destBuffer
                                                        offset:Attribs.DestBufferOffset];
            [asEncoder endEncoding];
        }
    }
}

void DeviceContextMtlImpl::WriteTLASCompactedSize(const WriteTLASCompactedSizeAttribs& Attribs)
{
    if (@available(macOS 11.0, iOS 14.0, *))
    {
        if (Attribs.pTLAS == nullptr || Attribs.pDestBuffer == nullptr)
            return;

        EndAllEncoders();
        EnsureCommandBuffer();

        auto* pTLAS = ClassPtrCast<TopLevelASMtlImpl>(Attribs.pTLAS);
        auto* pDestBuffer = ClassPtrCast<BufferMtlImpl>(Attribs.pDestBuffer);

        id<MTLAccelerationStructure> mtlAS = pTLAS->GetMtlAccelerationStructure();
        id<MTLBuffer> destBuffer = pDestBuffer->GetMtlResource();

        if (mtlAS == nil || destBuffer == nil)
            return;

        // Create acceleration structure command encoder
        id<MTLAccelerationStructureCommandEncoder> asEncoder = 
            [m_MtlCommandBuffer accelerationStructureCommandEncoder];
        
        if (asEncoder != nil)
        {
            // Write compacted size to buffer
            [asEncoder writeCompactedAccelerationStructureSize:mtlAS
                                                      toBuffer:destBuffer
                                                        offset:Attribs.DestBufferOffset];
            [asEncoder endEncoding];
        }
    }
}

void DeviceContextMtlImpl::TraceRays(const TraceRaysAttribs& Attribs)
{
    if (@available(macOS 11.0, iOS 14.0, *))
    {
        if (Attribs.pSBT == nullptr)
            return;

        EndAllEncoders();
        EnsureCommandBuffer();

        // Create compute command encoder for ray tracing
        m_MtlComputeEncoder = [m_MtlCommandBuffer computeCommandEncoder];
        
        if (m_MtlComputeEncoder != nil)
        {
            [m_MtlComputeEncoder retain];
            
            // Ray tracing in Metal is done via compute shaders with acceleration structures
            // The actual dispatch would require setting up the compute pipeline, buffers, and AS
            // This is a placeholder that sets up the encoder structure
            
            // Dispatch would be: [m_MtlComputeEncoder dispatchThreadgroups:... threadsPerThreadgroup:...]
            
            [m_MtlComputeEncoder endEncoding];
            [m_MtlComputeEncoder release];
            m_MtlComputeEncoder = nil;
        }
    }
}

void DeviceContextMtlImpl::TraceRaysIndirect(const TraceRaysIndirectAttribs& Attribs)
{
    if (@available(macOS 11.0, iOS 14.0, *))
    {
        if (Attribs.pSBT == nullptr || Attribs.pAttribsBuffer == nullptr)
            return;

        EndAllEncoders();
        EnsureCommandBuffer();

        auto* pAttribsBuffer = ClassPtrCast<BufferMtlImpl>(Attribs.pAttribsBuffer);
        id<MTLBuffer> indirectBuffer = pAttribsBuffer->GetMtlResource();

        if (indirectBuffer == nil)
            return;

        // Create compute command encoder for indirect ray tracing
        m_MtlComputeEncoder = [m_MtlCommandBuffer computeCommandEncoder];
        
        if (m_MtlComputeEncoder != nil)
        {
            [m_MtlComputeEncoder retain];
            
            // Ray tracing in Metal with indirect dispatch
            // Would use: [m_MtlComputeEncoder dispatchThreadgroupsWithIndirectBuffer:...]
            
            [m_MtlComputeEncoder endEncoding];
            [m_MtlComputeEncoder release];
            m_MtlComputeEncoder = nil;
        }
    }
}

void DeviceContextMtlImpl::UpdateSBT(IShaderBindingTable* pSBT, const UpdateIndirectRTBufferAttribs* pUpdateIndirectBufferAttribs)
{
    if (@available(macOS 11.0, iOS 14.0, *))
    {
        // In Metal, shader binding tables are managed differently than D3D12/Vulkan
        // Metal uses intersection function tables and visible function tables
        // This is a placeholder for managing those tables
        
        if (pSBT == nullptr)
            return;
        
        // Metal SBT updates would involve updating the visible function table
        // and intersection function table references in the pipeline state
    }
}

id<MTLCommandBuffer> DeviceContextMtlImpl::GetMtlCommandBuffer()
{
    EnsureCommandBuffer();
    return m_MtlCommandBuffer;
}

void DeviceContextMtlImpl::SetComputeThreadgroupMemoryLength(Uint32 Length, Uint32 Index)
{
    if (m_MtlComputeEncoder != nil)
    {
        // Set threadgroup memory length for compute shaders
        [m_MtlComputeEncoder setThreadgroupMemoryLength:Length atIndex:Index];
    }
}

void DeviceContextMtlImpl::SetTileThreadgroupMemoryLength(Uint32 Length, Uint32 Offset, Uint32 Index)
{
    if (m_MtlRenderEncoder != nil)
    {
        // Set threadgroup memory length for tile shaders (fragment shaders with tile memory)
        [m_MtlRenderEncoder setTileThreadgroupMemoryLength:Length atIndex:Index];
    }
}

void DeviceContextMtlImpl::MultiDraw(const MultiDrawAttribs& Attribs)
{
    // Metal doesn't have native multi-draw support
    // Implement as multiple draw calls
    for (Uint32 i = 0; i < Attribs.DrawCount; ++i)
    {
        const MultiDrawItem& item = Attribs.pDrawItems[i];
        DrawAttribs drawAttribs;
        drawAttribs.NumVertices = item.NumVertices;
        drawAttribs.StartVertexLocation = item.StartVertexLocation;
        drawAttribs.NumInstances = Attribs.NumInstances;
        drawAttribs.FirstInstanceLocation = Attribs.FirstInstanceLocation;
        drawAttribs.Flags = Attribs.Flags;
        
        Draw(drawAttribs);
    }
}

void DeviceContextMtlImpl::MultiDrawIndexed(const MultiDrawIndexedAttribs& Attribs)
{
    // Metal doesn't have native multi-draw indexed support
    // Implement as multiple draw indexed calls
    for (Uint32 i = 0; i < Attribs.DrawCount; ++i)
    {
        const MultiDrawIndexedItem& item = Attribs.pDrawItems[i];
        DrawIndexedAttribs drawAttribs;
        drawAttribs.NumIndices = item.NumIndices;
        drawAttribs.FirstIndexLocation = item.FirstIndexLocation;
        drawAttribs.BaseVertex = item.BaseVertex;
        drawAttribs.IndexType = Attribs.IndexType;
        drawAttribs.NumInstances = Attribs.NumInstances;
        drawAttribs.FirstInstanceLocation = Attribs.FirstInstanceLocation;
        drawAttribs.Flags = Attribs.Flags;
        
        DrawIndexed(drawAttribs);
    }
}

void DeviceContextMtlImpl::FinishFrame()
{
    // Commit and wait for the current command buffer to complete
    EndAllEncoders();
    
    if (m_MtlCommandBuffer != nil)
    {
        [m_MtlCommandBuffer commit];
        [m_MtlCommandBuffer waitUntilCompleted];
        [m_MtlCommandBuffer release];
        m_MtlCommandBuffer = nil;
    }
}

void DeviceContextMtlImpl::TransitionResourceStates(Uint32 BarrierCount, const StateTransitionDesc* pResourceBarriers)
{
    // Metal doesn't require explicit resource transitions like Vulkan/D3D12
    // Resources are automatically transitioned based on usage
    // This is a no-op for Metal
}

void DeviceContextMtlImpl::BeginDebugGroup(const Char* Name, const float* pColor)
{
    if (m_MtlCommandBuffer != nil && Name != nullptr)
    {
        NSString* label = [NSString stringWithUTF8String:Name];
        [m_MtlCommandBuffer pushDebugGroup:label];
    }
}

void DeviceContextMtlImpl::EndDebugGroup()
{
    if (m_MtlCommandBuffer != nil)
    {
        [m_MtlCommandBuffer popDebugGroup];
    }
}

void DeviceContextMtlImpl::InsertDebugLabel(const Char* Label, const float* pColor)
{
    if (m_MtlCommandBuffer != nil && Label != nullptr)
    {
        NSString* label = [NSString stringWithUTF8String:Label];
        [m_MtlCommandBuffer insertDebugSignpost:label];
    }
}

ICommandQueue* DeviceContextMtlImpl::LockCommandQueue()
{
    // Metal command queues are not lockable like D3D12
    // Return the command queue associated with this context
    return nullptr; // Would need to implement a command queue wrapper
}

void DeviceContextMtlImpl::UnlockCommandQueue()
{
    // Metal command queues are not lockable like D3D12
    // This is a no-op
}

void DeviceContextMtlImpl::SetShadingRate(SHADING_RATE BaseRate, SHADING_RATE_COMBINER PrimitiveCombiner, SHADING_RATE_COMBINER TextureCombiner)
{
    // Metal doesn't support variable shading rate like D3D12
    // This is a no-op for Metal
}

void DeviceContextMtlImpl::BindSparseResourceMemory(const BindSparseResourceMemoryAttribs& Attribs)
{
    // Metal doesn't support sparse resources like Vulkan
    // This is a no-op for Metal
}

} // namespace Diligent
