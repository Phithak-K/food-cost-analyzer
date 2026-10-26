FROM node:20-alpine

WORKDIR /app

# Install openssl for Prisma support on Alpine Linux
RUN apk add --no-cache openssl

# Install dependencies first (layer caching)
COPY package*.json ./
COPY prisma ./prisma/

RUN npm install
RUN npx prisma generate

# Copy application source code
COPY tsconfig.json ./
COPY src ./src/

EXPOSE 5000

ENV PORT=5000

CMD ["npm", "run", "dev"]
