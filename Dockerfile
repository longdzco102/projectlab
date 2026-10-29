FROM node:20-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production \
  PORT=3000

# 1. Cài đặt dependencies cho backend
COPY backend/package*.json ./backend/
WORKDIR /app/backend
RUN npm install --omit=dev --ignore-scripts

# 2. Copy source code backend và frontend
WORKDIR /app
COPY backend/ ./backend/
COPY frontend/ ./frontend/

WORKDIR /app/backend

# 3. Expose port 3000
EXPOSE 3000

# 4. Healthcheck tương thích với ALB health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1

# 5. Khởi chạy server
CMD ["node", "src/app.js"]
