#!/bin/bash
export LANG=en_US.UTF-8

# 基础变量
export UUID=${UUID:-"79411d85-b0dc-4cd2-b46c-01789a18c650"}
export vlpt=${vlpt}
export vmpt=${vmpt}
export sopt=${sopt}
export reym=${reym:-"apple.com"}
export argo=${argo}
export agn=${agn}
export agk=${agk}

# 哪吒监控变量
export NEZHA_SERVER=${NEZHA_SERVER}
export NEZHA_PORT=${NEZHA_PORT}
export NEZHA_KEY=${NEZHA_KEY}

echo "=========================================="
echo "ArgoSBX + Nezha 监控版"
echo "=========================================="

case $(uname -m) in
aarch64) cpu=arm64;;
x86_64) cpu=amd64;;
*) echo "不支持 $(uname -m) 架构" && exit 1;;
esac

mkdir -p "$HOME/agsbx"

# 下载 Xray
install_xray(){
    echo "========= 下载 Xray ========="
    if [ ! -e "$HOME/agsbx/xray" ]; then
        url="https://github.com/yonggekkk/argosbx/releases/download/argosbx/xray-$cpu"
        curl -Lo "$HOME/agsbx/xray" -# --retry 2 "$url" || wget -O "$HOME/agsbx/xray" --tries=2 "$url"
        chmod +x "$HOME/agsbx/xray"
    fi
    echo "Xray 版本：$("$HOME/agsbx/xray" version 2>/dev/null | awk '/^Xray/{print $2}')"
}

# 下载并启动哪吒 Agent
install_nezha(){
    if [ -n "$NEZHA_SERVER" ] && [ -n "$NEZHA_KEY" ]; then
        echo "========= 下载哪吒 Agent ========="
        
        NEZHA_AGENT="$HOME/agsbx/nezha-agent"
        
        if [ ! -e "$NEZHA_AGENT" ]; then
            # 尝试下载 nezha-agent
            NEZHA_URL="https://github.com/nezhahq/agent/releases/latest/download/nezha-agent_linux_${cpu}.tar.gz"
            echo "下载地址: $NEZHA_URL"
            
            curl -Lo "$HOME/agsbx/nezha-agent.tar.gz" -# --retry 2 "$NEZHA_URL" || \
            wget -O "$HOME/agsbx/nezha-agent.tar.gz" --tries=2 "$NEZHA_URL"
            
            # 解压
            cd "$HOME/agsbx"
            tar -xzf nezha-agent.tar.gz
            chmod +x nezha-agent
            rm -f nezha-agent.tar.gz
            cd /app
        fi
        
        echo "========= 启动哪吒 Agent ========="
        echo "服务器: $NEZHA_SERVER"
        echo "端口: ${NEZHA_PORT:-"(v1模式)"}"
        
        if [ -n "$NEZHA_PORT" ]; then
            # v0 版本 (gRPC)
            echo "使用 v0 模式 (gRPC)"
            nohup "$NEZHA_AGENT" -s "${NEZHA_SERVER}:${NEZHA_PORT}" -p "${NEZHA_KEY}" >/dev/null 2>&1 &
        else
            # v1 版本 (WebSocket)
            echo "使用 v1 模式 (WebSocket)"
            nohup "$NEZHA_AGENT" -s "${NEZHA_SERVER}" -p "${NEZHA_KEY}" --tls >/dev/null 2>&1 &
        fi
        
        sleep 2
        if pgrep -f "nezha-agent" >/dev/null 2>&1; then
            echo "哪吒 Agent 启动成功"
        else
            echo "哪吒 Agent 启动失败"
        fi
    else
        echo "未配置哪吒监控，跳过"
    fi
}

# 生成 UUID
gen_uuid(){
    if [ -z "$UUID" ] && [ ! -e "$HOME/agsbx/uuid" ]; then
        UUID=$("$HOME/agsbx/xray" uuid)
        echo "$UUID" > "$HOME/agsbx/uuid"
    elif [ -n "$UUID" ]; then
        echo "$UUID" > "$HOME/agsbx/uuid"
    fi
    UUID=$(cat "$HOME/agsbx/uuid")
    echo "UUID：$UUID"
}

# 生成 Xray 配置
gen_xray_config(){
    echo "========= 生成 Xray 配置 ========="
    
    cat > "$HOME/agsbx/xr.json" <<EOF
{
  "log": { "loglevel": "warning" },
  "inbounds": [
EOF

    local has_inbound=false

    # Vless-tcp-reality
    if [ -n "$vlpt" ]; then
        echo "Vless-Reality 端口：$vlpt"
        
        if [ ! -e "$HOME/agsbx/xrk/private_key" ]; then
            mkdir -p "$HOME/agsbx/xrk"
            key_pair=$("$HOME/agsbx/xray" x25519)
            echo "$key_pair" | grep "Private" | awk '{print $2}' > "$HOME/agsbx/xrk/private_key"
            echo "$key_pair" | grep "Public" | awk '{print $2}' > "$HOME/agsbx/xrk/public_key"
            date +%s%N | sha256sum | cut -c 1-8 > "$HOME/agsbx/xrk/short_id"
        fi
        
        private_key=$(cat "$HOME/agsbx/xrk/private_key")
        short_id=$(cat "$HOME/agsbx/xrk/short_id")
        
        [ "$has_inbound" = true ] && echo "," >> "$HOME/agsbx/xr.json"
        cat >> "$HOME/agsbx/xr.json" <<EOF
    {
      "tag": "reality-vision",
      "listen": "::",
      "port": $vlpt,
      "protocol": "vless",
      "settings": {
        "clients": [{"id": "${UUID}", "flow": "xtls-rprx-vision"}],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "fingerprint": "chrome",
          "dest": "${reym}:443",
          "serverNames": ["${reym}"],
          "privateKey": "$private_key",
          "shortIds": ["$short_id"]
        }
      },
      "sniffing": {"enabled": true, "destOverride": ["http", "tls", "quic"]}
    }
EOF
        has_inbound=true
    fi

    # Vmess-ws
    if [ -n "$vmpt" ]; then
        echo "Vmess-WS 端口：$vmpt"
        [ "$has_inbound" = true ] && echo "," >> "$HOME/agsbx/xr.json"
        cat >> "$HOME/agsbx/xr.json" <<EOF
    {
      "tag": "vmess-ws",
      "listen": "::",
      "port": ${vmpt},
      "protocol": "vmess",
      "settings": { "clients": [{"id": "${UUID}"}] },
      "streamSettings": { "network": "ws", "wsSettings": {"path": "${UUID}-vm"} },
      "sniffing": {"enabled": true, "destOverride": ["http", "tls", "quic"]}
    }
EOF
        has_inbound=true
    fi

    # Socks5
    if [ -n "$sopt" ]; then
        echo "Socks5 端口：$sopt"
        [ "$has_inbound" = true ] && echo "," >> "$HOME/agsbx/xr.json"
        cat >> "$HOME/agsbx/xr.json" <<EOF
    {
      "tag": "socks5",
      "port": ${sopt},
      "listen": "::",
      "protocol": "socks",
      "settings": { "auth": "password", "accounts": [{"user": "${UUID}", "pass": "${UUID}"}], "udp": true },
      "sniffing": {"enabled": true, "destOverride": ["http", "tls", "quic"]}
    }
EOF
        has_inbound=true
    fi

    cat >> "$HOME/agsbx/xr.json" <<EOF
  ],
  "outbounds": [
    { "protocol": "freedom", "tag": "direct" },
    { "protocol": "blackhole", "tag": "block" }
  ]
}
EOF
    echo "Xray 配置生成完成"
}

# 启动 Xray
start_xray(){
    echo "========= 启动 Xray ========="
    nohup "$HOME/agsbx/xray" run -c "$HOME/agsbx/xr.json" >/dev/null 2>&1 &
    sleep 2
    if pgrep -f "agsbx/xray" >/dev/null 2>&1; then
        echo "Xray 启动成功"
    else
        echo "Xray 启动失败"
    fi
}

# 启动 Argo 隧道
start_argo(){
    if [ -n "$argo" ]; then
        echo "========= 启动 Argo 隧道 ========="
        if [ ! -e "$HOME/agsbx/cloudflared" ]; then
            url="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-$cpu"
            curl -Lo "$HOME/agsbx/cloudflared" -# --retry 2 "$url" || wget -O "$HOME/agsbx/cloudflared" --tries=2 "$url"
            chmod +x "$HOME/agsbx/cloudflared"
        fi
        
        if [ -n "${agn}" ] && [ -n "${agk}" ]; then
            echo "使用固定隧道：$agn"
            nohup "$HOME/agsbx/cloudflared" tunnel --no-autoupdate --edge-ip-version auto --protocol http2 run --token "${agk}" >/dev/null 2>&1 &
        else
            echo "使用临时隧道"
            argoport=${vmpt:-$vlpt}
            nohup "$HOME/agsbx/cloudflared" tunnel --url http://localhost:${argoport} --edge-ip-version auto --no-autoupdate --protocol http2 > "$HOME/agsbx/argo.log" 2>&1 &
            sleep 5
            argodomain=$(grep -a trycloudflare.com "$HOME/agsbx/argo.log" 2>/dev/null | awk 'NR==2{print}' | awk -F// '{print $2}' | awk '{print $1}')
            echo "临时隧道域名：$argodomain"
        fi
    fi
}

# 主流程
main(){
    install_xray
    gen_uuid
    install_nezha
    gen_xray_config
    start_xray
    start_argo
    
    echo ""
    echo "========= 部署完成 ========="
    echo "UUID: $UUID"
    [ -n "$vlpt" ] && echo "Vless-Reality: $vlpt"
    [ -n "$vmpt" ] && echo "Vmess-WS: $vmpt"
    [ -n "$sopt" ] && echo "Socks5: $sopt"
    [ -n "$NEZHA_SERVER" ] && echo "哪吒监控: $NEZHA_SERVER"
}

main
