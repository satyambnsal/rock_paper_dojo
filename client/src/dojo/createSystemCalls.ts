import { SetupNetworkResult } from "./setupNetwork";
import { ClientComponents } from "./createClientComponents";
import { MoveSystemProps, SpawnSystemProps } from "./types";
import { uuid } from "@latticexyz/utils";
import { Entity, getComponentValue } from "@dojoengine/recs";
import { getEntityIdFromKeys } from "@dojoengine/utils";
import { updatePositionWithDirection } from "./utils";

export type SystemCalls = ReturnType<typeof createSystemCalls>;

const ACTIONS_PATH = "actions";
export function createSystemCalls(
    { execute }: SetupNetworkResult,
    { Position, PlayerID, Energy }: ClientComponents
) {
    const spawn = async (props: SpawnSystemProps) => {
        try {
            console.log({ signer: props.signer, rps: props.rps });
            await execute(props.signer, ACTIONS_PATH, "spawn", [props.rps]);
        } catch (e) {
            console.error(e);
        }
    };

    const move = async (props: MoveSystemProps) => {
        const { signer, direction } = props;
        const playerID = getEntityIdFromKeys([
            BigInt(signer.address),
        ]) as Entity;

        const rpsId = getComponentValue(PlayerID, playerID)?.player_id;
        const rpsEntity = getEntityIdFromKeys([
            BigInt(rpsId?.toString() || "0"),
        ]);

        const position = getComponentValue(Position, rpsEntity);
        let currentEnergyAmt = getComponentValue(Energy, rpsEntity)?.amt || 0;

        const new_position = updatePositionWithDirection(
            direction,
            position || { x: 0, y: 0 }
        );

        const positionId = uuid();

        Position.addOverride(positionId, {
            entity: rpsEntity,
            value: { id: rpsId, x: new_position.x, y: new_position.y },
        });

        const energyId = uuid();

        Energy.addOverride(energyId, {
            entity: rpsEntity,
            value: { id: rpsId, amt: currentEnergyAmt-- },
        });

        try {
            await execute(signer, ACTIONS_PATH, "move", [direction]);

            await new Promise((resolve) => setTimeout(resolve, 1000));
        } catch (e) {
            console.log(e);
            // Position.removeOverride(positionId);
            // Energy.removeOverride(energyId);
        } finally {
            Position.removeOverride(positionId);
            Energy.removeOverride(energyId);
        }
    };

    return {
        spawn,
        move,
    };
}
