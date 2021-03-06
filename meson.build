#project('libengine', 'vala', 'c')

engine_vapi_dir = meson.current_source_dir() + '/vapi'
add_project_arguments(['--vapidir', engine_vapi_dir], language: 'vala')
add_project_arguments('-D', get_option('buildtype').to_upper(), language: 'vala')
add_project_arguments('-D', target_machine.system().to_upper(), language: 'vala')
add_project_arguments('-DGLEW_NO_GLU', language: 'c')

cc = meson.get_compiler('c')
valac = meson.get_compiler('vala')
engine_dependencies = [
    dependency('glib-2.0', version: '>=2.54'),
    dependency('gobject-2.0'),
    dependency('gio-2.0'),
    dependency('gee-0.8'),
    dependency('gtk+-3.0'),
    dependency('glew'),
    dependency('SDL2_image'),
    dependency('SDL2_mixer'),
    dependency('sdl2'),
    dependency('pangoft2'),
    dependency('zlib'),
    cc.find_library('m', required : false),
    valac.find_library('stb', dirs: engine_vapi_dir),
]

if target_machine.system() == 'windows'
    engine_dependencies += cc.find_library('opengl32')
    engine_dependencies += valac.find_library('gl', dirs: engine_vapi_dir)
else
    engine_dependencies += dependency('gl')
endif


engine_sources = files(
    'Engine.vala',
    'EngineLog.vala',
    'Audio/AudioPlayer.vala',
    'Files/FileLoader.vala',
    'Files/ObjParser.vala',
    'Helper/Calculations.vala',
    'Helper/DeltaTimers.vala',
    'Helper/EngineMutex.vala',
    'Helper/Helper.vala',
    'Helper/ImageLoader.vala',
    'Helper/ImageLoadWrap.vala',
    'Helper/Keys.vala',
    'Helper/LabelLoader.vala',
    'Helper/Networking.vala',
    'Helper/RandomClass.vala',
    'Helper/Threading.vala',
    'Helper/Timers.vala',
    'Properties/Animation.vala',
    'Properties/Color.vala',
    'Properties/Curve.vala',
    'Properties/DeltaArgs.vala',
    'Properties/Mat3.vala',
    'Properties/Mat4.vala',
    'Properties/Orientation.vala',
    'Properties/Path.vala',
    'Properties/Quat.vala',
    'Properties/Ray.vala',
    'Properties/Rectangle.vala',
    'Properties/ScreenTypeEnum.vala',
    'Properties/Size2.vala',
    'Properties/Size2i.vala',
    'Properties/Transform.vala',
    'Properties/Vec2.vala',
    'Properties/Vec2i.vala',
    'Properties/Vec3.vala',
    'Properties/Vec4.vala',
    'Rendering/BasicGeometry.vala',
    'Rendering/Camera.vala',
    'Rendering/DebugInfo.vala',
    'Rendering/DebugView.vala',
    'Rendering/IRenderTarget.vala',
    'Rendering/LightSource.vala',
    'Rendering/OpenGLRenderer/OpenGLFrameBuffer.vala',
    'Rendering/OpenGLRenderer/OpenGLFunctions.vala',
    'Rendering/OpenGLRenderer/OpenGLRenderBuffer.vala',
    'Rendering/OpenGLRenderer/OpenGLRenderer.vala',
    'Rendering/OpenGLRenderer/Shaders/OpenGL2DShaderBuilder.vala',
    'Rendering/OpenGLRenderer/Shaders/OpenGLShader.vala',
    'Rendering/OpenGLRenderer/Shaders/OpenGLShaderBuilder.vala',
    'Rendering/OpenGLRenderer/Shaders/OpenGLShaderProgram2D.vala',
    'Rendering/OpenGLRenderer/Shaders/OpenGLShaderProgram3D.vala',
    'Rendering/OpenGLRenderer/Shaders/OpenGLStandardShaderBuilder.vala',
    'Rendering/RenderGeometry3D.vala',
    'Rendering/RenderObject2D.vala',
    'Rendering/RenderObject3D.vala',
    'Rendering/RenderScene2D.vala',
    'Rendering/RenderScene3D.vala',
    'Rendering/RenderState.vala',
    'Rendering/RenderTarget.vala',
    'Rendering/Resources/IResourceHandle.vala',
    'Rendering/Resources/RenderMaterial.vala',
    'Rendering/Resources/RenderModel.vala',
    'Rendering/Resources/RenderTexture.vala',
    'Rendering/Resources/ResourceStore.vala',
    'Rendering/World/World.vala',
    'Rendering/World/WorldCamera.vala',
    'Rendering/World/WorldLabel.vala',
    'Rendering/World/WorldLight.vala',
    'Rendering/World/WorldObject.vala',
    'Rendering/World/WorldObjectAnimation.vala',
    'Rendering/World/WorldObjectTransformable.vala',
    'Window/Container.vala',
    'Window/Control.vala',
    'Window/Controls/ImageControl.vala',
    'Window/Controls/LabelControl.vala',
    'Window/Controls/LineControl.vala',
    'Window/Controls/ListControl.vala',
    'Window/Controls/MenuButton.vala',
    'Window/Controls/MenuTextButton.vala',
    'Window/Controls/RectangleControl.vala',
    'Window/Controls/ScrollBarControl.vala',
    'Window/Controls/SizingControl.vala',
    'Window/Controls/TextInputControl.vala',
    'Window/IWindowTarget.vala',
    'Window/MainView.vala',
    'Window/RenderWindow.vala',
    'Window/SDLWindowTarget.vala',
    'Window/View2D.vala',
    'Window/View3D.vala',
)

engine_includes = include_directories('include')

#libengine = shared_library('libengine', engine_sources, dependencies: engine_dependencies, include_directories: engine_includes)
#libengine_dep = declare_dependency(include: libengine, link_with: libengine)