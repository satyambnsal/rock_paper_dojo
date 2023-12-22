import { Tileset } from "../../assets/world";
import { PhaserLayer } from "..";
import { snoise } from "@dojoengine/utils";
import { MAP_AMPLITUDE } from "../config/constants";

export function mapSystem(layer: PhaserLayer) {
    const {
        scenes: {
            Main: {
                maps: {
                    Main: { putTileAt },
                },
            },
        },
    } = layer;

    for (let x = 0; x < 50; x++) {
        for (let y = 0; y < 50; y++) {
            const coord = { x, y };
            const seed =
                Math.floor(
                    (snoise([x / MAP_AMPLITUDE, 0, y / MAP_AMPLITUDE]) + 1) / 2
                ) * 100;
            if (seed > 70) {
                putTileAt(coord, Tileset.Sea, "Foreground");
            } else if (seed > 60) {
                putTileAt(coord, Tileset.Desert, "Foreground");
            } else if (seed > 53) {
                putTileAt(coord, Tileset.Forest, "Foreground");
            } else {
                putTileAt(coord, Tileset.Land, "Foreground");
            }
        }
    }
}
