import { useEffect, useState, useRef } from "react";

export const usePromiseValue = <T>(promise: Promise<T> | null) => {
    const promiseRef = useRef<typeof promise>(promise);
    const [value, setValue] = useState<T | null>(null);
    useEffect(() => {
        if (!promise) return;
        let isMounted = true;
        promiseRef.current = promise;

        promise.then((resolvedValue) => {
            if (!isMounted) return;
            if (promiseRef.current !== promise) return;
            setValue(resolvedValue);
        });
        return () => {
            isMounted = false;
        };
    }, [promise]);
    return value;
};
