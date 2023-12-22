import { useEffect } from "react";
import "./App.css";
import { useNetworkLayer } from "./ui/hooks/useNetworkLayer";
import { store } from "./store";
import { PhaserLayer } from "./phaser/phaserLayer";
import { UI } from "./ui";

function App() {
    const networkLayer = useNetworkLayer();
    useEffect(() => {
        if (!networkLayer || !networkLayer.account) return;
        console.log("Setting network layer");
        store.setState({ networkLayer });
    }, [networkLayer]);

    return (
        <div className="w-full h-screen bg-black text-white flex justify-between">
            <div className="self-center">{!networkLayer && "loading..."}</div>
            <PhaserLayer networkLayer={networkLayer} />
            <UI />
        </div>
    );
}

export default App;
