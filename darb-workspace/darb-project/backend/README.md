# DARB Backend

NestJS API with Prisma, PostgreSQL/PostGIS and Redis.

## Implemented routes

| Method | Route | Access |
|---|---|---|
| POST | `/api/v1/auth/otp/request` | Public |
| POST | `/api/v1/auth/otp/verify` | Public |
| POST | `/api/v1/auth/refresh` | Public |
| GET | `/api/v1/auth/me` | Authenticated |
| GET | `/api/v1/cities` | Public |
| GET | `/api/v1/cities/:code` | Public |
| GET | `/api/v1/vendors?cityId=&locale=ar` | Public |
| GET | `/api/v1/vendors/:id` | Public |
| GET | `/api/v1/vendors/mine` | Vendor |
| GET | `/api/v1/vendors/:vendorId/products?locale=ar` | Public |
| POST | `/api/v1/vendors/apply` | Customer |
| POST | `/api/v1/drivers/apply` | Customer |
| GET/POST | `/api/v1/addresses` | Customer |
| POST | `/api/v1/vendor/products` | Approved vendor |
| POST | `/api/v1/orders` | Customer |
| GET | `/api/v1/orders/mine` | Customer |
| GET | `/api/v1/orders/vendor` | Vendor |
| GET | `/api/v1/orders/driver/available` | Approved online driver |
| GET | `/api/v1/orders/driver/mine` | Driver |
| POST | `/api/v1/orders/:id/claim` | Driver |
| PATCH | `/api/v1/orders/:id/status` | Owning vendor/driver |
| GET | `/api/v1/drivers/me` | Driver |
| PATCH | `/api/v1/drivers/online` | Driver |
| GET | `/api/v1/drivers/me` | Driver |
| GET | `/api/v1/admin/vendors/pending` | Admin |
| PATCH | `/api/v1/admin/vendors/:id/status` | Admin |
| GET | `/api/v1/admin/drivers/pending` | Admin |
| PATCH | `/api/v1/admin/drivers/:id/status` | Admin |

Admin moderation API is present but the admin mobile/web console is not. SMS provider integration, FCM, live maps and geospatial fee calculation are still outstanding. Prisma migrations must be generated before deployment. Review root README before deployment.

## Important deployment blocker

There is currently no `prisma/migrations` directory. Generate and review an initial migration against PostgreSQL/PostGIS before running `prisma migrate deploy` or deploying the Docker image. The example Docker Compose credentials are development-only. Create the first ADMIN account through a controlled database bootstrap procedure; never expose public admin registration.
