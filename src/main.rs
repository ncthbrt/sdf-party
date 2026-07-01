//! A minimal example that outputs "hello world"

use std::{mem::forget, ops::Div};

use bevy::{
    camera::Hdr, core_pipeline::{
        Core2dSystems, fullscreen_material::{FullscreenMaterial, FullscreenMaterialPlugin}, tonemapping::Tonemapping,
    }, ecs::{schedule::ScheduleConfigs, system::BoxedSystem}, post_process::bloom::Bloom, prelude::*, render::{extract_component::ExtractComponent, render_resource::ShaderType, view::ColorGrading},
};



fn main() {
    App::new()
        .add_plugins((
            DefaultPlugins,
            WeslDependenciesPlugin,
            FullscreenMaterialPlugin::<SdfPlayground>::default(),
        ))
        .add_systems(Startup, setup)
        .add_systems(Update, update)
        .run();
}

#[derive(ShaderType, Component, Default, ExtractComponent, Clone, Copy)]
struct SdfPlayground {
    pub time: f32,
    pub screen: Vec2,
    pub cursor_position: Vec3,
}

impl FullscreenMaterial for SdfPlayground {
    fn fragment_shader() -> bevy::shader::ShaderRef {
        "shaders/main.wesl".into()
    }
    fn schedule() -> impl bevy::ecs::schedule::ScheduleLabel + Clone {
        bevy::core_pipeline::Core2d
    }
    fn schedule_configs(system: ScheduleConfigs<BoxedSystem>) -> ScheduleConfigs<BoxedSystem> {
        system.in_set(Core2dSystems::MainPass)
    }
}

struct WeslDependenciesPlugin;


impl Plugin for WeslDependenciesPlugin {
    fn build(&self, app: &mut App) {
        let asset_server = app
            .world_mut()
            .resource_mut::<AssetServer>();
        std::mem::forget(asset_server.load::<Shader>("shaders/noise.wesl"));
        std::mem::forget(asset_server.load::<Shader>("shaders/sdfs.wesl"));            
    }
}


fn setup(mut commands: Commands) {
    commands.spawn((
        Camera2d, 
        SdfPlayground::default(),
        Hdr,
        Bloom::OLD_SCHOOL,
        Tonemapping::TonyMcMapface
    ));
}

fn update(time: Res<Time>, windows_query: Query<&Window>, mut sdf_playground_query: Query<&mut SdfPlayground>) {
    let time = time.elapsed_secs_wrapped();    
    let window = windows_query.single().unwrap();
    let size = Vec2::new(window.width(), window.height());
    let maybe_cursor_position = window.cursor_position();
    let cursor_position = maybe_cursor_position.unwrap_or_default();
    for mut sdf_material in sdf_playground_query.iter_mut() {
        sdf_material.time = time;
        sdf_material.screen = size;
        sdf_material.cursor_position = cursor_position.div(size).extend(if window.cursor_position().is_some() { 1. } else { 0. });
    }
}
