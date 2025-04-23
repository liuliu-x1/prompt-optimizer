# 阶段1：基础环境
FROM node:20-slim AS base
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
RUN npm install -g corepack@latest && corepack enable

# 阶段2：构建
FROM base AS build
WORKDIR /app
COPY . .
# Windows 兼容方案（无缓存）
RUN pnpm install --frozen-lockfile && \
    pnpm run build

# 阶段3：生产
FROM nginx:stable-alpine
# 安装 dos2unix（Alpine 版）
RUN apk add --no-cache dos2unix
# 复制配置和构建产物
COPY docker/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/packages/web/dist /usr/share/nginx/html
# 处理启动脚本
COPY docker/generate-config.sh /docker-entrypoint.d/40-generate-config.sh
RUN dos2unix /docker-entrypoint.d/40-generate-config.sh && \
    chmod +x /docker-entrypoint.d/40-generate-config.sh

EXPOSE 80