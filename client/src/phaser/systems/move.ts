import {
    Entity,
    Has,
    defineSystem,
    getComponentValueStrict,
    getComponentValue,
} from "@dojoengine/recs";

import { PhaserLayer } from "..";
import { tileCoordToPixelCoord } from "@latticexyz/phaserx";
import {
    Animations,
    ORIGIN_OFFSET,
    RPSSprites,
    TILE_HEIGHT,
    TILE_WIDTH,
} from "../config/constants";

export const move = (layer: PhaserLayer) => {
    const entity_addresses: { [k: string]: string } = {};
    const {
        world,
        scenes: {
            Main: { objectPool, camera },
        },
        networkLayer: {
            components: { Position, RPSType, PlayerAddress },
            account: { address: playerAddress },
        },
    } = layer;

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    defineSystem(world, [Has(Position), Has(RPSType)], ({ entity }: any) => {
        const rpsType = getComponentValueStrict(
            RPSType,
            entity.toString() as Entity
        );
        const position = getComponentValueStrict(
            Position,
            entity.toString() as Entity
        );

        const entity_uniform = (+entity).toString();

        console.log(
            entity,
            entity_uniform,
            "\n------------pos/type triggered----------\n",
            position
        );

        const player = objectPool.get(entity_uniform, "Sprite");
        let animation = "";

        switch (String.fromCharCode(rpsType.rps)) {
            case RPSSprites.Rock:
                animation = Animations.RockIdle;
                break;
            case RPSSprites.Paper:
                animation = Animations.PaperIdle;
                break;
            case RPSSprites.Scissors:
                animation = Animations.ScissorsIdle;
                break;
        }

        player.setComponent({
            id: "animation",
            once: (sprite) => {
                sprite.play(animation);
            },
        });

        const offsetPosition = {
            x: position?.x - ORIGIN_OFFSET || 0,
            y: position?.y - ORIGIN_OFFSET || 0,
        };

        let entity_addr = entity_addresses[entity_uniform];
        if (!entity_addr) {
            const entity_addr_component = getComponentValue(
                PlayerAddress,
                entity.toString() as Entity
            );

            entity_addr = entity_addresses[entity_uniform] =
                typeof entity_addr_component?.player === "bigint"
                    ? entity_addr_component?.player.toString()
                    : entity_addr_component?.player || "";
        }

        const pixelPosition = tileCoordToPixelCoord(
            offsetPosition,
            TILE_WIDTH,
            TILE_HEIGHT
        );

        player.setComponent({
            id: "position",
            once: (sprite) => {
                sprite.setPosition(pixelPosition?.x, pixelPosition?.y);

                if (
                    BigInt(playerAddress.toString()).toString() ==
                    entity_addr.toString()
                ) {
                    camera.centerOn(pixelPosition?.x, pixelPosition?.y);
                }
            },
        });
    });
};
