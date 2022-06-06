# Sample code for how to resolve complex types with resolvers

## Deploy

* ```terraform init```
* ```terraform apply```

## Usage

Get all groups with all users:

```graphql
query MyQuery {
  allGroups {
    id
    users {
      name
      id
    }
  }
}
```

Get a group by id:

```graphql
query MyQuery {
  group(id: "1") {
    id
    users {
      id
      name
    }
  }
}
```

Get a user by id:

```graphql
query MyQuery {
  user(id: "1") {
    id
    name
  }
}
```

## How it works

All 3 queries are resolved by a single Lambda function returning a complex structure that matches the GraphQL schema. Lists are returned as Arrays, and Types are Objects.

## Cleanup

* ```terraform destroy```
