import { store } from "../store";
import { CreateAccount } from "./CreateAccount";
import { EnergyLevels } from "./EnergyLevels";

export const UI = () => {
    const layers = store((state) => {
        return {
            networkLayer: state.networkLayer,
            phaserLayer: state.phaserLayer,
        };
    });

    if (!layers.networkLayer || !layers.phaserLayer) return null;

    return (
        <div className="absolute inset-0 pointer-events-none">
            <EnergyLevels />
            <CreateAccount />
        </div>
    );
};
