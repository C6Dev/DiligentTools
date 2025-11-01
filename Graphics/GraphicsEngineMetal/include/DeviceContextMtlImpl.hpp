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
/// Declaration of Diligent::DeviceContextMtlImpl class

#include "EngineMtlImplTraits.hpp"
#include "DeviceContextBase.hpp"

#import <Metal/Metal.h>

namespace Diligent
{

/// Device context implementation in Metal backend.
/// This is a stub implementation that provides the required interface.
class DeviceContextMtlImpl : public DeviceContextBase<EngineMtlImplTraits>
{
public:
    using TDeviceContextBase = DeviceContextBase<EngineMtlImplTraits>;

    DeviceContextMtlImpl(IReferenceCounters*          pRefCounters,
                         RenderDeviceMtlImpl*         pDevice,
                         const EngineCreateInfo&      EngineCI,
                         const DeviceContextDesc&     Desc);
    ~DeviceContextMtlImpl();

    IMPLEMENT_QUERY_INTERFACE_IN_PLACE(IID_DeviceContextMtl, TDeviceContextBase)

    /// Implementation of IDeviceContext::Begin() in Metal backend.
    virtual void DILIGENT_CALL_TYPE Begin(Uint32 ImmediateContextId) override final;

    /// Implementation of IDeviceContext::SetPipelineState() in Metal backend.
    virtual void DILIGENT_CALL_TYPE SetPipelineState(IPipelineState* pPipelineState) override final;

    /// Implementation of IDeviceContext::TransitionShaderResources() in Metal backend.
    virtual void DILIGENT_CALL_TYPE TransitionShaderResources(IShaderResourceBinding* pShaderResourceBinding) override final;

    /// Implementation of IDeviceContext::CommitShaderResources() in Metal backend.
    virtual void DILIGENT_CALL_TYPE CommitShaderResources(IShaderResourceBinding*        pShaderResourceBinding,
                                                          RESOURCE_STATE_TRANSITION_MODE StateTransitionMode) override final;

    /// Implementation of IDeviceContext::SetStencilRef() in Metal backend.
    virtual void DILIGENT_CALL_TYPE SetStencilRef(Uint32 StencilRef) override final;

    /// Implementation of IDeviceContext::SetBlendFactors() in Metal backend.
    virtual void DILIGENT_CALL_TYPE SetBlendFactors(const float* pBlendFactors) override final;

    /// Implementation of IDeviceContext::SetVertexBuffers() in Metal backend.
    virtual void DILIGENT_CALL_TYPE SetVertexBuffers(Uint32                         StartSlot,
                                                     Uint32                         NumBuffersSet,
                                                     IBuffer* const*                ppBuffers,
                                                     const Uint64*                  pOffsets,
                                                     RESOURCE_STATE_TRANSITION_MODE StateTransitionMode,
                                                     SET_VERTEX_BUFFERS_FLAGS       Flags) override final;

    /// Implementation of IDeviceContext::InvalidateState() in Metal backend.
    virtual void DILIGENT_CALL_TYPE InvalidateState() override final;

    /// Implementation of IDeviceContext::SetIndexBuffer() in Metal backend.
    virtual void DILIGENT_CALL_TYPE SetIndexBuffer(IBuffer*                       pIndexBuffer,
                                                   Uint64                         ByteOffset,
                                                   RESOURCE_STATE_TRANSITION_MODE StateTransitionMode) override final;

    /// Implementation of IDeviceContext::SetViewports() in Metal backend.
    virtual void DILIGENT_CALL_TYPE SetViewports(Uint32          NumViewports,
                                                 const Viewport* pViewports,
                                                 Uint32          RTWidth,
                                                 Uint32          RTHeight) override final;

    /// Implementation of IDeviceContext::SetScissorRects() in Metal backend.
    virtual void DILIGENT_CALL_TYPE SetScissorRects(Uint32      NumRects,
                                                    const Rect* pRects,
                                                    Uint32      RTWidth,
                                                    Uint32      RTHeight) override final;

    /// Implementation of IDeviceContext::SetRenderTargetsExt() in Metal backend.
    virtual void DILIGENT_CALL_TYPE SetRenderTargetsExt(const SetRenderTargetsAttribs& Attribs) override final;

    /// Implementation of IDeviceContext::BeginRenderPass() in Metal backend.
    virtual void DILIGENT_CALL_TYPE BeginRenderPass(const BeginRenderPassAttribs& Attribs) override final;

    /// Implementation of IDeviceContext::NextSubpass() in Metal backend.
    virtual void DILIGENT_CALL_TYPE NextSubpass() override final;

    /// Implementation of IDeviceContext::EndRenderPass() in Metal backend.
    virtual void DILIGENT_CALL_TYPE EndRenderPass() override final;

    /// Implementation of IDeviceContext::Draw() in Metal backend.
    virtual void DILIGENT_CALL_TYPE Draw(const DrawAttribs& Attribs) override final;

    /// Implementation of IDeviceContext::DrawIndexed() in Metal backend.
    virtual void DILIGENT_CALL_TYPE DrawIndexed(const DrawIndexedAttribs& Attribs) override final;

    /// Implementation of IDeviceContext::DrawIndirect() in Metal backend.
    virtual void DILIGENT_CALL_TYPE DrawIndirect(const DrawIndirectAttribs& Attribs) override final;

    /// Implementation of IDeviceContext::DrawIndexedIndirect() in Metal backend.
    virtual void DILIGENT_CALL_TYPE DrawIndexedIndirect(const DrawIndexedIndirectAttribs& Attribs) override final;

    /// Implementation of IDeviceContext::DrawMesh() in Metal backend.
    virtual void DILIGENT_CALL_TYPE DrawMesh(const DrawMeshAttribs& Attribs) override final;

    /// Implementation of IDeviceContext::DrawMeshIndirect() in Metal backend.
    virtual void DILIGENT_CALL_TYPE DrawMeshIndirect(const DrawMeshIndirectAttribs& Attribs) override final;

    /// Implementation of IDeviceContext::DispatchCompute() in Metal backend.
    virtual void DILIGENT_CALL_TYPE DispatchCompute(const DispatchComputeAttribs& Attribs) override final;

    /// Implementation of IDeviceContext::DispatchComputeIndirect() in Metal backend.
    virtual void DILIGENT_CALL_TYPE DispatchComputeIndirect(const DispatchComputeIndirectAttribs& Attribs) override final;

    /// Implementation of IDeviceContext::ClearDepthStencil() in Metal backend.
    virtual void DILIGENT_CALL_TYPE ClearDepthStencil(ITextureView*                  pView,
                                                      CLEAR_DEPTH_STENCIL_FLAGS      ClearFlags,
                                                      float                          fDepth,
                                                      Uint8                          Stencil,
                                                      RESOURCE_STATE_TRANSITION_MODE StateTransitionMode) override final;

    /// Implementation of IDeviceContext::ClearRenderTarget() in Metal backend.
    virtual void DILIGENT_CALL_TYPE ClearRenderTarget(ITextureView*                  pView,
                                                      const void*                    RGBA,
                                                      RESOURCE_STATE_TRANSITION_MODE StateTransitionMode);

    /// Implementation of IDeviceContext::GenerateMips() in Metal backend.
    virtual void DILIGENT_CALL_TYPE GenerateMips(ITextureView* pTexView) override final;

    /// Implementation of IDeviceContext::ResolveTextureSubresource() in Metal backend.
    virtual void DILIGENT_CALL_TYPE ResolveTextureSubresource(ITexture*                               pSrcTexture,
                                                              ITexture*                               pDstTexture,
                                                              const ResolveTextureSubresourceAttribs& ResolveAttribs) override final;

    /// Implementation of IDeviceContext::UpdateBuffer() in Metal backend.
    virtual void DILIGENT_CALL_TYPE UpdateBuffer(IBuffer*                       pBuffer,
                                                 Uint64                         Offset,
                                                 Uint64                         Size,
                                                 const void*                    pData,
                                                 RESOURCE_STATE_TRANSITION_MODE StateTransitionMode) override final;

    /// Implementation of IDeviceContext::CopyBuffer() in Metal backend.
    virtual void DILIGENT_CALL_TYPE CopyBuffer(IBuffer*                       pSrcBuffer,
                                               Uint64                         SrcOffset,
                                               RESOURCE_STATE_TRANSITION_MODE SrcBufferTransitionMode,
                                               IBuffer*                       pDstBuffer,
                                               Uint64                         DstOffset,
                                               Uint64                         Size,
                                               RESOURCE_STATE_TRANSITION_MODE DstBufferTransitionMode) override final;

    /// Implementation of IDeviceContext::MapBuffer() in Metal backend.
    virtual void DILIGENT_CALL_TYPE MapBuffer(IBuffer*  pBuffer,
                                              MAP_TYPE  MapType,
                                              MAP_FLAGS MapFlags,
                                              PVoid&    pMappedData) override final;

    /// Implementation of IDeviceContext::UnmapBuffer() in Metal backend.
    virtual void DILIGENT_CALL_TYPE UnmapBuffer(IBuffer* pBuffer, MAP_TYPE MapType) override final;

    /// Implementation of IDeviceContext::UpdateTexture() in Metal backend.
    virtual void DILIGENT_CALL_TYPE UpdateTexture(ITexture*                      pTexture,
                                                  Uint32                         MipLevel,
                                                  Uint32                         Slice,
                                                  const Box&                     DstBox,
                                                  const TextureSubResData&       SubresData,
                                                  RESOURCE_STATE_TRANSITION_MODE SrcBufferTransitionMode,
                                                  RESOURCE_STATE_TRANSITION_MODE DstTextureTransitionMode) override final;

    /// Implementation of IDeviceContext::CopyTexture() in Metal backend.
    virtual void DILIGENT_CALL_TYPE CopyTexture(const CopyTextureAttribs& CopyAttribs) override final;

    /// Implementation of IDeviceContext::MapTextureSubresource() in Metal backend.
    virtual void DILIGENT_CALL_TYPE MapTextureSubresource(ITexture*                 pTexture,
                                                          Uint32                    MipLevel,
                                                          Uint32                    ArraySlice,
                                                          MAP_TYPE                  MapType,
                                                          MAP_FLAGS                 MapFlags,
                                                          const Box*                pMapRegion,
                                                          MappedTextureSubresource& MappedData) override final;

    /// Implementation of IDeviceContext::UnmapTextureSubresource() in Metal backend.
    virtual void DILIGENT_CALL_TYPE UnmapTextureSubresource(ITexture* pTexture, Uint32 MipLevel, Uint32 ArraySlice) override final;

    /// Implementation of IDeviceContext::FinishCommandList() in Metal backend.
    virtual void DILIGENT_CALL_TYPE FinishCommandList(ICommandList** ppCommandList) override final;

    /// Implementation of IDeviceContext::ExecuteCommandLists() in Metal backend.
    virtual void DILIGENT_CALL_TYPE ExecuteCommandLists(Uint32               NumCommandLists,
                                                        ICommandList* const* ppCommandLists) override final;

    /// Implementation of IDeviceContext::EnqueueSignal() in Metal backend.
    virtual void DILIGENT_CALL_TYPE EnqueueSignal(IFence* pFence, Uint64 Value) override final;

    /// Implementation of IDeviceContext::DeviceWaitForFence() in Metal backend.
    virtual void DILIGENT_CALL_TYPE DeviceWaitForFence(IFence* pFence, Uint64 Value) override final;

    /// Implementation of IDeviceContext::WaitForIdle() in Metal backend.
    virtual void DILIGENT_CALL_TYPE WaitForIdle() override final;

    /// Implementation of IDeviceContext::BeginQuery() in Metal backend.
    virtual void DILIGENT_CALL_TYPE BeginQuery(IQuery* pQuery) override final;

    /// Implementation of IDeviceContext::EndQuery() in Metal backend.
    virtual void DILIGENT_CALL_TYPE EndQuery(IQuery* pQuery) override final;

    /// Implementation of IDeviceContext::Flush() in Metal backend.
    virtual void DILIGENT_CALL_TYPE Flush() override final;

    /// Implementation of IDeviceContext::BuildBLAS() in Metal backend.
    virtual void DILIGENT_CALL_TYPE BuildBLAS(const BuildBLASAttribs& Attribs) override final;

    /// Implementation of IDeviceContext::BuildTLAS() in Metal backend.
    virtual void DILIGENT_CALL_TYPE BuildTLAS(const BuildTLASAttribs& Attribs) override final;

    /// Implementation of IDeviceContext::CopyBLAS() in Metal backend.
    virtual void DILIGENT_CALL_TYPE CopyBLAS(const CopyBLASAttribs& Attribs) override final;

    /// Implementation of IDeviceContext::CopyTLAS() in Metal backend.
    virtual void DILIGENT_CALL_TYPE CopyTLAS(const CopyTLASAttribs& Attribs) override final;

    /// Implementation of IDeviceContext::WriteBLASCompactedSize() in Metal backend.
    virtual void DILIGENT_CALL_TYPE WriteBLASCompactedSize(const WriteBLASCompactedSizeAttribs& Attribs) override final;

    /// Implementation of IDeviceContext::WriteTLASCompactedSize() in Metal backend.
    virtual void DILIGENT_CALL_TYPE WriteTLASCompactedSize(const WriteTLASCompactedSizeAttribs& Attribs) override final;

    /// Implementation of IDeviceContext::TraceRays() in Metal backend.
    virtual void DILIGENT_CALL_TYPE TraceRays(const TraceRaysAttribs& Attribs) override final;

    /// Implementation of IDeviceContext::TraceRaysIndirect() in Metal backend.
    virtual void DILIGENT_CALL_TYPE TraceRaysIndirect(const TraceRaysIndirectAttribs& Attribs) override final;

    /// Implementation of IDeviceContext::UpdateSBT() in Metal backend.
    virtual void DILIGENT_CALL_TYPE UpdateSBT(IShaderBindingTable* pSBT, const UpdateIndirectRTBufferAttribs* pUpdateIndirectBufferAttribs) override final;

    /// Implementation of IDeviceContextMtl::GetMtlCommandBuffer().
    virtual id<MTLCommandBuffer> DILIGENT_CALL_TYPE GetMtlCommandBuffer() override final;

    /// Implementation of IDeviceContextMtl::SetComputeThreadgroupMemoryLength().
    virtual void DILIGENT_CALL_TYPE SetComputeThreadgroupMemoryLength(Uint32 Length, Uint32 Index) override final;

    /// Implementation of IDeviceContextMtl::SetTileThreadgroupMemoryLength().
    virtual void DILIGENT_CALL_TYPE SetTileThreadgroupMemoryLength(Uint32 Length, Uint32 Offset, Uint32 Index) override final;

    /// Implementation of IDeviceContext::MultiDraw() in Metal backend.
    virtual void DILIGENT_CALL_TYPE MultiDraw(const MultiDrawAttribs& Attribs) override final;

    /// Implementation of IDeviceContext::MultiDrawIndexed() in Metal backend.
    virtual void DILIGENT_CALL_TYPE MultiDrawIndexed(const MultiDrawIndexedAttribs& Attribs) override final;

    /// Implementation of IDeviceContext::FinishFrame() in Metal backend.
    virtual void DILIGENT_CALL_TYPE FinishFrame() override final;

    /// Implementation of IDeviceContext::TransitionResourceStates() in Metal backend.
    virtual void DILIGENT_CALL_TYPE TransitionResourceStates(Uint32 BarrierCount, const StateTransitionDesc* pResourceBarriers) override final;

    /// Implementation of IDeviceContext::BeginDebugGroup() in Metal backend.
    virtual void DILIGENT_CALL_TYPE BeginDebugGroup(const Char* Name, const float* pColor) override final;

    /// Implementation of IDeviceContext::EndDebugGroup() in Metal backend.
    virtual void DILIGENT_CALL_TYPE EndDebugGroup() override final;

    /// Implementation of IDeviceContext::InsertDebugLabel() in Metal backend.
    virtual void DILIGENT_CALL_TYPE InsertDebugLabel(const Char* Label, const float* pColor) override final;

    /// Implementation of IDeviceContext::LockCommandQueue() in Metal backend.
    virtual ICommandQueue* DILIGENT_CALL_TYPE LockCommandQueue() override final;

    /// Implementation of IDeviceContext::UnlockCommandQueue() in Metal backend.
    virtual void DILIGENT_CALL_TYPE UnlockCommandQueue();

    /// Implementation of IDeviceContext::SetShadingRate() in Metal backend.
    virtual void DILIGENT_CALL_TYPE SetShadingRate(SHADING_RATE BaseRate, SHADING_RATE_COMBINER PrimitiveCombiner, SHADING_RATE_COMBINER TextureCombiner) override final;

    /// Implementation of IDeviceContext::BindSparseResourceMemory() in Metal backend.
    virtual void DILIGENT_CALL_TYPE BindSparseResourceMemory(const BindSparseResourceMemoryAttribs& Attribs) override final;

private:
    void EnsureCommandBuffer();
    void EndAllEncoders();

    // Temporary friend access for minimal swap chain implementation to end encoders
    // and present command buffer. This should be removed when a proper Metal backend
    // presentation pathway is implemented.
    friend class SwapChainMtlImpl;
    
    id<MTLCommandQueue>          m_MtlCommandQueue    = nil;
    id<MTLCommandBuffer>         m_MtlCommandBuffer   = nil;
    id<MTLRenderCommandEncoder>  m_MtlRenderEncoder   = nil;
    id<MTLComputeCommandEncoder> m_MtlComputeEncoder  = nil;
    id<MTLBlitCommandEncoder>    m_MtlBlitEncoder     = nil;
    
    IPipelineState*              m_pPipelineState     = nullptr;
    IBuffer*                     m_pIndexBuffer       = nullptr;
    Uint64                       m_IndexBufferOffset  = 0;
    
    IRenderPass*                 m_pActiveRenderPass  = nullptr;
    const OptimizedClearValue*   m_pClearValues       = nullptr;
    Uint32                       m_ClearValueCount    = 0;
    
    IObject*                     m_pUserData          = nullptr;
};

} // namespace Diligent
