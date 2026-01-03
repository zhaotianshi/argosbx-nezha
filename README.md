# ArgoSBX + Nezha 监控版

基于 argosbx 添加哪吒监控支持的 Docker 镜像。

## 镜像地址

```
ghcr.io/zhaotianshi/argosbx-nezha:latest
```

## 服务器部署

直接填写镜像地址和环境变量即可：

| 变量 | 说明 | 必填 |
|------|------|------|
| UUID | 用户 UUID | ✅ |
| vmpt | Vmess-WS 端口 | ✅ |
| NEZHA_SERVER | 哪吒服务器地址 | 可选 |
| NEZHA_PORT | 哪吒端口（v1留空，v0填端口） | 可选 |
| NEZHA_KEY | 哪吒 Agent 密钥 | 可选 |
| vlpt | Vless-Reality 端口 | 可选 |
| sopt | Socks5 端口 | 可选 |
| reym | Reality 伪装域名 | 可选 |
| argo | Argo 隧道 | 可选 |
| agn | 固定隧道名称 | 可选 |
| agk | 固定隧道 Token | 可选 |

## 环境变量示例

```
UUID=79411d85-b0dc-4cd2-b46c-01789a18c650
vmpt=8001
NEZHA_SERVER=nz.example.com
NEZHA_KEY=你的密钥
```

## Docker 命令行部署

```bash
docker run -d \
  --name argosbx \
  -p 3000:3000 \
  -p 8001:8001 \
  -e UUID=你的UUID \
  -e vmpt=8001 \
  -e NEZHA_SERVER=nz.example.com \
  -e NEZHA_KEY=你的密钥 \
  ghcr.io/zhaotianshi/argosbx-nezha:latest
```

## 哪吒监控

- v1 版本：`NEZHA_PORT` 留空
- v0 版本：`NEZHA_PORT` 填 gRPC 端口（如 5555）

## 获取哪吒密钥

1. 登录哪吒面板
2. 进入 **服务器** → **添加**
3. 复制生成的 Agent 密钥
