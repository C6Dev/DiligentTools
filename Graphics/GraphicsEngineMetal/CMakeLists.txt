cmake_minimum_required (VERSION 3.11)

project(Diligent-GraphicsEngineMetal CXX)

set(INCLUDE
    include/BottomLevelASMtlImpl.hpp
    include/BufferMtlImpl.hpp
    include/BufferViewMtlImpl.hpp
    include/DeviceContextMtlImpl.hpp
    include/DeviceMemoryMtlImpl.hpp
    include/DeviceObjectArchiveMtlImpl.hpp
    include/EngineMtlImplTraits.hpp
    include/FenceMtlImpl.hpp
    include/FramebufferMtlImpl.hpp
    include/PipelineResourceSignatureMtlImpl.hpp
    include/PipelineStateCacheMtlImpl.hpp
    include/PipelineStateMtlImpl.hpp
    include/QueryMtlImpl.hpp
    include/RenderDeviceMtlImpl.hpp
    include/RenderPassMtlImpl.hpp
    include/SamplerMtlImpl.hpp
    include/SwapChainMtlImpl.hpp
    include/ShaderBindingTableMtlImpl.hpp
    include/ShaderMtlImpl.hpp
    include/ShaderResourceBindingMtlImpl.hpp
    include/ShaderResourceCacheMtl.hpp
    include/ShaderVariableManagerMtl.hpp
    include/TextureMtlImpl.hpp
    include/TextureViewMtlImpl.hpp
    include/TopLevelASMtlImpl.hpp
)

set(INTERFACE
    interface/BottomLevelASMtl.h
    interface/BufferMtl.h
    interface/BufferViewMtl.h
    interface/CommandQueueMtl.h
    interface/DeviceContextMtl.h
    interface/DeviceMemoryMtl.h
    interface/EngineFactoryMtl.h
    interface/FenceMtl.h
    interface/PipelineStateCacheMtl.h
    interface/PipelineStateMtl.h
    interface/QueryMtl.h
    interface/RasterizationRateMapMtl.h
    interface/RenderDeviceMtl.h
    interface/SamplerMtl.h
    interface/ShaderMtl.h
    interface/ShaderResourceBindingMtl.h
    interface/SwapChainMtl.h
    interface/TextureMtl.h
    interface/TextureViewMtl.h
    interface/TopLevelASMtl.h
)

set(SRC
    src/BottomLevelASMtlImpl.mm
    src/BufferMtlImpl.mm
    src/BufferViewMtlImpl.mm
    src/DeviceContextMtlImpl.mm
    src/DeviceMemoryMtlImpl.mm
    src/EngineFactoryMtl.mm
    src/FenceMtlImpl.mm
    src/FramebufferMtlImpl.mm
    src/PipelineResourceSignatureMtlImpl.mm
    src/PipelineStateCacheMtlImpl.mm
    src/PipelineStateMtlImpl.mm
    src/PipelineStateValidationMtl.cpp
    src/QueryMtlImpl.mm
    src/RenderDeviceMtlImpl.mm
    src/RenderPassMtlImpl.mm
    src/SamplerMtlImpl.mm
    src/ShaderBindingTableMtlImpl.mm
    src/ShaderMtlImpl.mm
    src/ShaderVariableManagerMtl.cpp
    src/TextureMtlImpl.mm
    src/TextureViewMtlImpl.mm
    src/TopLevelASMtlImpl.mm
    src/SwapChainMtlImpl.mm
)

# Metal backend is only available on Apple platforms
if(APPLE)
    add_library(Diligent-GraphicsEngineMetalInterface INTERFACE)
    target_link_libraries(Diligent-GraphicsEngineMetalInterface 
        INTERFACE 
        Diligent-GraphicsEngineInterface
    )
    target_include_directories(Diligent-GraphicsEngineMetalInterface 
        INTERFACE 
        interface
    )

    add_library(Diligent-GraphicsEngineMetal-static STATIC
        ${SRC} 
        ${INTERFACE} 
        ${INCLUDE}
        readme.md
    )

    target_include_directories(Diligent-GraphicsEngineMetal-static
        PRIVATE
            include
    )

    target_link_libraries(Diligent-GraphicsEngineMetal-static
        PRIVATE
            Diligent-BuildSettings
            Diligent-Common
            Diligent-GraphicsEngine
            Diligent-GraphicsEngineNextGenBase
            Diligent-TargetPlatform
            Diligent-ShaderTools
            "-framework Metal"
            "-framework Foundation"
        PUBLIC
            Diligent-GraphicsEngineMetalInterface
    )

    set_target_properties(Diligent-GraphicsEngineMetal-static PROPERTIES
        FOLDER DiligentCore/Graphics
    )

    source_group("src" FILES ${SRC})
    source_group("include" FILES ${INCLUDE})
    source_group("interface" FILES ${INTERFACE})

    set_source_files_properties(${SRC} PROPERTIES
        COMPILE_FLAGS "-x objective-c++"
    )

    target_compile_definitions(Diligent-GraphicsEngineMetal-static 
        PRIVATE 
        DILIGENT_ENGINE_DLL=0
    )

else()
    message(STATUS "Metal backend is only available on Apple platforms - skipping")
endif()
