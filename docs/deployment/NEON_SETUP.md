# Neon Postgres Setup

## Status

IMPLEMENTED: configuration structure and documentation prepared locally.
TESTED LOCALLY: not against a live Neon database because credentials are not available in this environment.
DEPLOYED: not yet deployed.
VERIFIED ON PHYSICAL DEVICE: not applicable.
BLOCKED BY EXTERNAL CREDENTIALS: Neon project URL, database user, and direct URL credentials.

## Required values

Set the following in the deployed Core API environment:

- DATABASE_URL
- DIRECT_URL

Use a pooled connection string for DATABASE_URL and a direct connection string for DIRECT_URL when running Prisma migrations.

Example:

```env
DATABASE_URL="postgresql://username:password@ep-example-123456.us-east-2.aws.neon.tech/neondb?sslmode=require&pgbouncer=true"
DIRECT_URL="postgresql://username:password@ep-example-123456.us-east-2.aws.neon.tech/neondb?sslmode=require"
```

## Prisma guidance

- Do not reset or recreate an existing production database.
- Run migrations only after confirming the target database is correct.
- Use `npx prisma migrate deploy` in the production deployment workflow.
- Keep the migration sequence under version control and avoid destructive commands.

## Deployment-safe configuration

- Use `sslmode=require` for PostgreSQL over Neon.
- Use the pooled connection for application traffic.
- Use `DIRECT_URL` for migration jobs when the Prisma client requires a non-pooled direct connection.
- Keep credentials in Render environment secrets rather than source control.

## Manual setup steps

1. Create or select the Neon project.
2. Copy the pooled connection string into `DATABASE_URL`.
3. Copy the direct connection string into `DIRECT_URL`.
4. Add both values to the Render Core API environment variables.
5. Validate with the Core API health check and a Prisma migration dry-run or deploy command on the target environment.
