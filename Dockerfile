FROM node:18-alpine

RUN apk add --no-cache bash curl wget ca-certificates tzdata

WORKDIR /app

COPY index.js ./
COPY start.sh ./
COPY package.json ./

RUN npm install --omit=dev && chmod +x start.sh

# 基础配置
ENV PORT=3000
ENV UUID=""
ENV DOMAIN=""

# Xray 端口配置
ENV vmpt=""
ENV vlpt=""
ENV sopt=""
ENV reym="apple.com"

# Argo 隧道配置
ENV argo=""
ENV agn=""
ENV agk=""

# 哪吒监控配置
ENV NEZHA_SERVER=""
ENV NEZHA_PORT=""
ENV NEZHA_KEY=""

EXPOSE 3000

CMD ["node", "index.js"]
