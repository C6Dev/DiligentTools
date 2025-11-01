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

#include "TextureViewMtlImpl.hpp"
#include "RenderDeviceMtlImpl.hpp"
#include "TextureMtlImpl.hpp"
#include "Cast.hpp"
#import <Metal/Metal.h>

namespace Diligent
{

TextureViewMtlImpl::TextureViewMtlImpl(IReferenceCounters*    pRefCounters,
                                       RenderDeviceMtlImpl*   pDevice,
                                       const TextureViewDesc& ViewDesc,
                                       ITexture*              pTexture,
                                       bool                   bIsDefaultView) :
    TTextureViewBase{pRefCounters, pDevice, ViewDesc, pTexture, bIsDefaultView}
{
    @autoreleasepool
    {
        auto* pTextureMtl = ClassPtrCast<TextureMtlImpl>(pTexture);
        id<MTLTexture> mtlTexture = static_cast<id<MTLTexture>>(pTextureMtl->GetMtlResource());
        
        // If this is the default view, just retain the parent texture
        if (bIsDefaultView)
        {
            m_MtlTexture = mtlTexture;
            if (m_MtlTexture != nil)
            {
                [m_MtlTexture retain];
            }
        }
        else
        {
            // Create a texture view with specific mip/slice range
            if (mtlTexture != nil)
            {
                MTLTextureType textureType;
                switch (ViewDesc.ViewType)
                {
                    case TEXTURE_VIEW_SHADER_RESOURCE:
                    case TEXTURE_VIEW_UNORDERED_ACCESS:
                    case TEXTURE_VIEW_RENDER_TARGET:
                        textureType = [mtlTexture textureType];
                        break;
                    default:
                        textureType = [mtlTexture textureType];
                        break;
                }
                
                // Validate & clamp level/slice ranges to avoid Metal assertions
                Uint32 ParentMipLevels = pTextureMtl->GetDesc().MipLevels;
                Uint32 ParentArraySize = pTextureMtl->GetDesc().ArraySize;
                Uint32 MostDetailed    = ViewDesc.MostDetailedMip;
                Uint32 NumMipLevels    = ViewDesc.NumMipLevels;
                if (ParentMipLevels == 0) ParentMipLevels = 1; // safety
                if (MostDetailed >= ParentMipLevels)
                {
                    LOG_WARNING_MESSAGE("Metal: View MostDetailedMip (", MostDetailed, ") exceeds parent mip count (", ParentMipLevels, ") for texture '", (pTextureMtl->GetDesc().Name?pTextureMtl->GetDesc().Name:"<unnamed>"), "'. Clamping to 0.");
                    MostDetailed = 0;
                }
                if (NumMipLevels == 0 || MostDetailed + NumMipLevels > ParentMipLevels)
                {
                    NumMipLevels = ParentMipLevels - MostDetailed;
                }
                if (NumMipLevels == 0) NumMipLevels = 1; // must be non-zero for Metal API

                Uint32 FirstSlice   = ViewDesc.FirstArraySlice;
                Uint32 NumSlices    = ViewDesc.NumArraySlices;
                if (ParentArraySize == 0) ParentArraySize = 1;
                if (FirstSlice >= ParentArraySize)
                {
                    LOG_WARNING_MESSAGE("Metal: View FirstArraySlice (", FirstSlice, ") exceeds parent array size (", ParentArraySize, ") for texture '", (pTextureMtl->GetDesc().Name?pTextureMtl->GetDesc().Name:"<unnamed>"), "'. Clamping to 0.");
                    FirstSlice = 0;
                }
                if (NumSlices == 0 || FirstSlice + NumSlices > ParentArraySize)
                {
                    NumSlices = ParentArraySize - FirstSlice;
                }
                if (NumSlices == 0) NumSlices = 1;

                // If parent is a non-array 2D texture (ParentArraySize==1) but view asked for slice >0 or multiple slices, clamp.
                if (ParentArraySize == 1 && (FirstSlice != 0 || NumSlices != 1))
                {
                    LOG_WARNING_MESSAGE("Metal: Clamping texture view slice range [", FirstSlice, ",", (FirstSlice+NumSlices-1), "] to [0,0] for non-array texture '", (pTextureMtl->GetDesc().Name?pTextureMtl->GetDesc().Name:"<unnamed>"), "'.");
                    FirstSlice = 0;
                    NumSlices = 1;
                }

                NSRange levelRange = NSMakeRange(MostDetailed, NumMipLevels);
                NSRange sliceRange = NSMakeRange(FirstSlice, NumSlices);
                LOG_INFO_MESSAGE("Metal: Creating texture view levels=[", MostDetailed, ",", (MostDetailed+NumMipLevels-1), "] slices=[", FirstSlice, ",", (FirstSlice+NumSlices-1), "] for parent '", (pTextureMtl->GetDesc().Name?pTextureMtl->GetDesc().Name:"<unnamed>"), "'");
                
                m_MtlTexture = [mtlTexture newTextureViewWithPixelFormat:[mtlTexture pixelFormat]
                                                              textureType:textureType
                                                                   levels:levelRange
                                                                   slices:sliceRange];
            }
        }
    }
}

TextureViewMtlImpl::~TextureViewMtlImpl()
{
    if (m_MtlTexture != nil)
    {
        [m_MtlTexture release];
        m_MtlTexture = nil;
    }
}

id<MTLTexture> TextureViewMtlImpl::GetMtlTexture() const
{
    return m_MtlTexture;
}

} // namespace Diligent
