export const listEventsMapper = (ev: any) => {
    return ev.map((e: any) => {
        const dateStart = new Date(parseInt(e[3]) * 1000);
        const dateEnd = new Date(parseInt(e[4]) * 1000);
        return {
            id: e[0].toString(),
            name: e[1].toString(),
            description: e[2].toString(),
            dateStart: dateStart.toISOString(),
            dateEnd: dateEnd.toISOString(),
            creator: e[5].toString(),
        }
    })
}
