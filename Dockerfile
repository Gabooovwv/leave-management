FROM node:24-alpine AS base

FROM base AS deps
RUN apk add --no-cache libc6-compat openssl
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci

FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
ENV NEXT_TELEMETRY_DISABLED=1
ENV DATABASE_URL="mysql://leave:leave@127.0.0.1:3306/leave_management"
RUN npx prisma generate
RUN npm run build

FROM base AS prisma-cli
WORKDIR /prisma-cli
RUN npm install prisma@7.10.1

FROM base AS runner
WORKDIR /app
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
ENV PORT=3000
ENV HOSTNAME=0.0.0.0
ENV HOME=/tmp
RUN apk add --no-cache openssl \
  && addgroup --system --gid 1001 nodejs \
  && adduser --system --uid 1001 nextjs
COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static
COPY --from=builder --chown=nextjs:nodejs /app/prisma ./prisma
COPY --from=builder --chown=nextjs:nodejs /app/prisma.config.ts ./prisma.config.ts
COPY --from=prisma-cli /prisma-cli/node_modules /opt/prisma-cli/node_modules
COPY --from=builder /app/node_modules/dotenv /app/node_modules/dotenv
RUN test -f /opt/prisma-cli/node_modules/prisma/build/index.js \
  && test -f /opt/prisma-cli/node_modules/@prisma/debug/dist/index.js \
  && rm -rf /app/node_modules/prisma \
  && ln -s /opt/prisma-cli/node_modules/prisma /app/node_modules/prisma \
  && chown -R nextjs:nodejs /opt/prisma-cli /app
COPY --chmod=755 docker/entrypoint.sh ./entrypoint.sh
RUN sed -i 's/\r$//' ./entrypoint.sh
USER nextjs
EXPOSE 3000
CMD ["./entrypoint.sh"]
