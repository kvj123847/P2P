-- Non-destructive follow-up migration. Verify the target database with
-- `prisma migrate status` before applying this migration.

ALTER TABLE "content_reviews"
  DROP CONSTRAINT IF EXISTS "content_review_course_fk",
  DROP CONSTRAINT IF EXISTS "content_review_session_fk";

DROP INDEX IF EXISTS "content_reviews_contentId_contentType_idx";

ALTER TABLE "content_reviews"
  ADD COLUMN "courseId" TEXT,
  ADD COLUMN "liveSessionId" TEXT;

UPDATE "content_reviews"
SET "courseId" = "contentId"
WHERE "contentType" = 'COURSE';

UPDATE "content_reviews"
SET "liveSessionId" = "contentId"
WHERE "contentType" = 'SESSION';

ALTER TABLE "content_reviews"
  DROP COLUMN "contentId";

ALTER TABLE "content_reviews"
  ADD CONSTRAINT "content_review_exactly_one_content"
    CHECK (("courseId" IS NOT NULL)::int + ("liveSessionId" IS NOT NULL)::int = 1),
  ADD CONSTRAINT "content_review_course_fk"
    FOREIGN KEY ("courseId") REFERENCES "courses"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT "content_review_session_fk"
    FOREIGN KEY ("liveSessionId") REFERENCES "live_sessions"("id") ON DELETE CASCADE ON UPDATE CASCADE;

CREATE INDEX "content_reviews_courseId_idx" ON "content_reviews"("courseId");
CREATE INDEX "content_reviews_liveSessionId_idx" ON "content_reviews"("liveSessionId");
CREATE INDEX "content_reviews_contentType_status_idx" ON "content_reviews"("contentType", "status");

CREATE TYPE "PaymentProvider" AS ENUM ('MOCK');

ALTER TABLE "payments"
  ADD COLUMN "provider" "PaymentProvider" NOT NULL DEFAULT 'MOCK',
  ADD COLUMN "providerReference" TEXT;

CREATE INDEX "payments_provider_providerReference_idx"
  ON "payments"("provider", "providerReference");
