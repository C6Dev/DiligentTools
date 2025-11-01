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

#include "TextureMtlImpl.hpp"
#include "TextureViewMtlImpl.hpp"
#include "RenderDeviceMtlImpl.hpp"
#include "Cast.hpp"
#import <Metal/Metal.h>

namespace Diligent
{

static MTLPixelFormat GetMtlPixelFormat(TEXTURE_FORMAT Format)
{
    switch (Format)
    {
        case TEX_FORMAT_RGBA8_UNORM: return MTLPixelFormatRGBA8Unorm;
        case TEX_FORMAT_BGRA8_UNORM: return MTLPixelFormatBGRA8Unorm;
        case TEX_FORMAT_R32_FLOAT: return MTLPixelFormatR32Float;
        case TEX_FORMAT_RG32_FLOAT: return MTLPixelFormatRG32Float;
        case TEX_FORMAT_RGBA32_FLOAT: return MTLPixelFormatRGBA32Float;
        case TEX_FORMAT_D32_FLOAT: return MTLPixelFormatDepth32Float;
        
        // Add more common formats
        case TEX_FORMAT_RGBA8_UNORM_SRGB: return MTLPixelFormatRGBA8Unorm_sRGB;
        case TEX_FORMAT_BGRA8_UNORM_SRGB: return MTLPixelFormatBGRA8Unorm_sRGB;
        case TEX_FORMAT_R8_UNORM: return MTLPixelFormatR8Unorm;
        case TEX_FORMAT_RG8_UNORM: return MTLPixelFormatRG8Unorm;
        case TEX_FORMAT_R16_FLOAT: return MTLPixelFormatR16Float;
        case TEX_FORMAT_RG16_FLOAT: return MTLPixelFormatRG16Float;
        case TEX_FORMAT_RGBA16_FLOAT: return MTLPixelFormatRGBA16Float;
        case TEX_FORMAT_R32_UINT: return MTLPixelFormatR32Uint;
        case TEX_FORMAT_RG32_UINT: return MTLPixelFormatRG32Uint;
        case TEX_FORMAT_RGBA32_UINT: return MTLPixelFormatRGBA32Uint;
        case TEX_FORMAT_D24_UNORM_S8_UINT: return MTLPixelFormatDepth24Unorm_Stencil8;
        case TEX_FORMAT_D32_FLOAT_S8X24_UINT: return MTLPixelFormatDepth32Float_Stencil8;
        
        // BC compressed formats
        case TEX_FORMAT_BC1_UNORM_SRGB: return MTLPixelFormatBC1_RGBA_sRGB;
        case TEX_FORMAT_BC1_UNORM: return MTLPixelFormatBC1_RGBA;
        case TEX_FORMAT_BC1_TYPELESS: return MTLPixelFormatBC1_RGBA;
        
        default: 
            printf("Unsupported texture format: %d, using RGBA8Unorm as fallback\n", Format);
            return MTLPixelFormatRGBA8Unorm; // Use a safe fallback instead of invalid
    }
}

TextureMtlImpl::TextureMtlImpl(IReferenceCounters*        pRefCounters,
                               FixedBlockMemoryAllocator& TexViewObjMemAllocator,
                               RenderDeviceMtlImpl*       pDeviceMtl,
                               const TextureDesc&         TexDesc,
                               const TextureData*         pData) :
    TTextureBase{pRefCounters, TexViewObjMemAllocator, pDeviceMtl, TexDesc}
{
    @autoreleasepool
    {
        id<MTLDevice> mtlDevice = pDeviceMtl->GetMtlDevice();
        
        MTLTextureDescriptor* texDesc = [[MTLTextureDescriptor alloc] init];
        LOG_INFO_MESSAGE("Metal: Creating texture '", (TexDesc.Name?TexDesc.Name:"<unnamed>"), "' Type=", (int)TexDesc.Type,
                         " WxH=", TexDesc.Width, "x", TexDesc.Height,
                         " Depth=", TexDesc.Depth, " Array=", TexDesc.ArraySize,
                         " Mips=", TexDesc.MipLevels, " Format=", (int)TexDesc.Format);

        // Infer mip levels if zero (full chain) to avoid creating a 0-length level range later
        if (TexDesc.MipLevels == 0)
        {
            Uint32 Dim = std::max({TexDesc.Width, TexDesc.Height, TexDesc.Depth});
            Uint32 Levels = 0;
            while (Dim > 0) { ++Levels; Dim >>= 1; }
            if (Levels == 0) Levels = 1;
            m_Desc.MipLevels = Levels; // update internal desc
            LOG_INFO_MESSAGE("Metal: Inferred mip levels for texture '", (TexDesc.Name?TexDesc.Name:"<unnamed>"), "' -> ", Levels);
        }
        
        switch (TexDesc.Type)
        {
            case RESOURCE_DIM_TEX_2D:
                texDesc.textureType = MTLTextureType2D;
                break;
            case RESOURCE_DIM_TEX_CUBE:
                texDesc.textureType = MTLTextureTypeCube;
                break;
            case RESOURCE_DIM_TEX_3D:
                texDesc.textureType = MTLTextureType3D;
                break;
            default:
                texDesc.textureType = MTLTextureType2D;
                break;
        }
        
        texDesc.pixelFormat = GetMtlPixelFormat(TexDesc.Format);
        texDesc.width = TexDesc.Width;
        texDesc.height = TexDesc.Height;
        texDesc.depth = TexDesc.Depth;
    texDesc.mipmapLevelCount = m_Desc.MipLevels; // use possibly inferred value
        texDesc.arrayLength = TexDesc.ArraySize;

        // Metal validation: MTLTextureType2D requires depth == 1 and arrayLength == 1 (unless using texture arrays, which need appropriate type).
        // Our pseudo path may be passing Depth/ArraySize >1 for 2D textures; clamp to 1 to avoid assertion until full texture type handling implemented.
        if (texDesc.textureType == MTLTextureType2D)
        {
            if (texDesc.depth > 1 || texDesc.arrayLength > 1)
            {
                LOG_WARNING_MESSAGE("Metal: Adjusting 2D texture descriptor depth=", texDesc.depth, " arrayLength=", texDesc.arrayLength, " -> 1,1 to satisfy Metal constraints.");
                texDesc.depth = 1;
                texDesc.arrayLength = 1;
            }
        }
        texDesc.usage = MTLTextureUsageShaderRead | MTLTextureUsageRenderTarget;
        
        // Check if format is compressed before releasing the descriptor
        bool isCompressed = (texDesc.pixelFormat >= MTLPixelFormatBC1_RGBA && texDesc.pixelFormat <= MTLPixelFormatBC7_RGBAUnorm_sRGB);
        
        m_MtlTexture = [mtlDevice newTextureWithDescriptor:texDesc];
        [texDesc release];
        
        if (m_MtlTexture == nil)
        {
            LOG_ERROR_AND_THROW("Failed to create Metal texture");
        }
        
        // Upload initial data if provided
        if (pData != nullptr && pData->pSubResources != nullptr)
        {
            // Skip data upload for compressed formats for now to avoid AGX alignment issues
            
            if (!isCompressed)
            {
                for (Uint32 mip = 0; mip < TexDesc.MipLevels; ++mip)
                {
                    for (Uint32 slice = 0; slice < TexDesc.ArraySize; ++slice)
                    {
                        Uint32 subresIdx = mip + slice * TexDesc.MipLevels;
                        const auto& subres = pData->pSubResources[subresIdx];
                        
                        if (subres.pData != nullptr)
                        {
                            MTLRegion region = MTLRegionMake2D(0, 0, 
                                                              std::max(1u, TexDesc.Width >> mip),
                                                              std::max(1u, TexDesc.Height >> mip));
                            
                            [m_MtlTexture replaceRegion:region
                                            mipmapLevel:mip
                                                  slice:slice
                                              withBytes:subres.pData
                                            bytesPerRow:subres.Stride
                                          bytesPerImage:subres.DepthStride];
                        }
                    }
                }
            }
            else
            {
                printf("Skipping texture data upload for compressed format to avoid AGX alignment issues\n");
            }
        }
    }
}

TextureMtlImpl::TextureMtlImpl(IReferenceCounters*        pRefCounters,
                               FixedBlockMemoryAllocator& TexViewObjMemAllocator,
                               RenderDeviceMtlImpl*       pDeviceMtl,
                               const TextureDesc&         TexDesc,
                               RESOURCE_STATE             InitialState,
                               id<MTLTexture>             mtlTexture) :
    TTextureBase{pRefCounters, TexViewObjMemAllocator, pDeviceMtl, TexDesc},
    m_MtlTexture{mtlTexture}
{
    if (m_MtlTexture != nil)
    {
        [m_MtlTexture retain];
    }
}

TextureMtlImpl::~TextureMtlImpl()
{
    if (m_MtlTexture != nil)
    {
        [m_MtlTexture release];
        m_MtlTexture = nil;
    }
}

id<MTLResource> TextureMtlImpl::GetMtlResource() const
{
    return m_MtlTexture;
}

id<MTLHeap> TextureMtlImpl::GetMtlHeap() const
{
    return m_MtlTexture != nil ? [m_MtlTexture heap] : nil;
}

Uint64 TextureMtlImpl::GetNativeHandle()
{
    return BitCast<Uint64>(m_MtlTexture);
}

void TextureMtlImpl::CreateViewInternal(const TextureViewDesc& ViewDesc, ITextureView** ppView, bool bIsDefaultView)
{
    VERIFY(ppView != nullptr, "Null pointer provided");
    if (!ppView) return;
    VERIFY(*ppView == nullptr, "Overwriting reference to existing object may cause memory leaks");

    *ppView = nullptr;

    try
    {
        auto* pDeviceMtl = GetDevice();
        auto& TexViewAllocator = pDeviceMtl->GetTexViewObjAllocator();
        VERIFY(&TexViewAllocator == &m_dbgTexViewObjAllocator, "Texture view allocator does not match allocator provided during texture initialization");

        TextureViewMtlImpl* pViewMtl = NEW_RC_OBJ(TexViewAllocator, "TextureViewMtlImpl instance", TextureViewMtlImpl)
                                       (GetDevice(), ViewDesc, this, bIsDefaultView);
        pViewMtl->QueryInterface(IID_TextureView, reinterpret_cast<IObject**>(ppView));
    }
    catch (const std::runtime_error&)
    {
        const auto* ViewTypeName = GetTexViewTypeLiteralName(ViewDesc.ViewType);
        LOG_ERROR("Failed to create view \"", ViewDesc.Name ? ViewDesc.Name : "", "\" (", ViewTypeName, ") for texture \"", m_Desc.Name, "\"");
    }
}

} // namespace Diligent
