# ---- Build stage ----
FROM node:20-alpine AS deps

WORKDIR /app

# Copy only package files first to leverage layer cache
COPY package.json package-lock.json ./
RUN npm ci --omit=dev

# Copy prisma schema and generate client
COPY prisma ./prisma
RUN npx prisma generate

# ---- Runtime stage ----
FROM node:20-alpine AS runner

WORKDIR /app

# Non-root user for security
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copy installed node_modules + generated prisma client from deps stage
COPY --from=deps /app/node_modules ./node_modules

# Copy source code
COPY . .

# Use non-root user
USER appuser

EXPOSE 5000

# Run prisma deploy (applies pending migrations) then start server
CMD ["sh", "-c", "npx prisma migrate deploy && node server.js"]
