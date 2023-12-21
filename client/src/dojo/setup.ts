import { createClientComponents } from "./createClientComponents";
import { createSystemCalls } from "./createSystemCalls";
import { setupNetwork } from "./setupNetwork";
import { getSyncEntities } from "@dojoengine/react";

export type SetupResult = Awaited<ReturnType<typeof setup>>;

export async function setup() {
    const network = await setupNetwork();
    const components = createClientComponents(network);
    const systemCalls = createSystemCalls(network, components);
    await getSyncEntities(
        network.toriiClient,
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        network.contractComponents as any
    );
    return {
        network,
        components,
        systemCalls,
    };
}
