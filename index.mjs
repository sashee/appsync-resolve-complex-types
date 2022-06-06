const data = {
	groups: [
		{
			id: "1",
			users: [
				{
					id: "1",
					name: "user1",
				},
				{
					id: "2",
					name: "user2",
				},
			],
		},
		{
			id: "2",
			users: [
				{
					id: "3",
					name: "user3",
				},
			],
		},
	],
};

export const handler = async (event) => {
	const {arguments: {id}, info: {fieldName}} = event;
	if (fieldName === "allGroups") {
		return data.groups;
	}else if (fieldName === "group") {
		return data.groups.find((group) => group.id === id);
	}else if (fieldName === "user") {
		return data.groups.find((group) => group.users.some((user) => user.id === id))?.users.find((user) => user.id === id);
	}else {
		throw new Error(`unknown field: ${fieldName}`);
	}
};

