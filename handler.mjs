export const handler = async (event) => {
	const {arguments, prev, stash, identity, source} = event;
	console.log(JSON.stringify(event, undefined, 4));
	return JSON.stringify({arguments, prev, stash, identity, source});
};

