import {
    defineSceneConfig,
    AssetType,
    defineScaleConfig,
    defineMapConfig,
    defineCameraConfig,
} from "@latticexyz/phaserx";
import { TileAnimations, Tileset } from "../../assets/world";
import {
    Sprites,
    Assets,
    Maps,
    Scenes,
    TILE_HEIGHT,
    TILE_WIDTH,
    Animations,
} from "./constants";

const ANIMATION_INTERVAL = 200;

const mainMap = defineMapConfig({
    chunkSize: TILE_WIDTH * 64,
    tileWidth: TILE_WIDTH,
    tileHeight: TILE_HEIGHT,
    backgroundTile: [Tileset.Land],
    animationInterval: ANIMATION_INTERVAL,
    tileAnimations: TileAnimations,
    layers: {
        layers: {
            Background: { tilesets: ["Default"] },
            Foreground: { tilesets: ["Default"] },
        },
        defaultLayer: "Background",
    },
});

export const phaserConfig = {
    sceneConfig: {
        [Scenes.Main]: defineSceneConfig({
            assets: {
                [Assets.Tileset]: {
                    type: AssetType.Image,
                    key: Assets.Tileset,
                    path: "assets/tilesets/land.png",
                },
                [Assets.MainAtlas]: {
                    type: AssetType.MultiAtlas,
                    key: Assets.MainAtlas,
                    path: `assets/atlases/atlas.json?timestamp=${Date.now()}`,
                    options: {
                        imagePath: "assets/atlases/",
                    },
                },
            },
            maps: {
                [Maps.Main]: mainMap,
            },
            sprites: {
                [Sprites.Soldier]: {
                    assetKey: Assets.MainAtlas,
                    frame: "sprites/soldier/idle/0.png",
                },
            },
            animations: [
                {
                    key: Animations.RockIdle,
                    assetsKey: Assets.MainAtlas,
                    startFrame: 0,
                    endFrame: 0,
                    frameRate: 6,
                    repeat: -1,
                    prefix: "sprites/rock/",
                    suffix: ".png",
                },
                {
                    key: Animations.ScissorsIdle,
                    assetsKey: Assets.MainAtlas,
                    startFrame: 0,
                    endFrame: 0,
                    frameRate: 6,
                    repeat: -1,
                    prefix: "sprites/scissors/",
                    suffix: ".png",
                },
                {
                    key: Animations.PaperIdle,
                    assetsKey: Assets.MainAtlas,
                    startFrame: 0,
                    endFrame: 0,
                    frameRate: 6,
                    repeat: -1,
                    prefix: "sprites/paper/",
                    suffix: ".png",
                },
            ],
            tilesets: {
                Default: {
                    assetKey: Assets.Tileset,
                    tileWidth: TILE_WIDTH,
                    TILE_HEIGHT: TILE_HEIGHT,
                },
            },
        }),
    },

    scale: defineScaleConfig({
        parent: "phaser-game",
        zoom: 1,
        mode: Phaser.Scale.None,
    }),
    cameraConfig: defineCameraConfig({
        pinchSpeed: 1,
        wheelSpeed: 1,
        maxZoom: 3,
        minZoom: 1,
    }),
    cullingChunkSize: TILE_HEIGHT * 16,
};
