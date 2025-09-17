#!/bin/bash

# Ubuntu Nginx 自动化安装脚本
# 作者: AI助手
# 描述: 自动安装和配置Nginx on Ubuntu

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# 检查是否以root权限运行
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "此脚本必须以root权限运行"
        exit 1
    fi
}

# 更新系统
update_system() {
    log_info "更新系统包列表..."
    apt-get update
    log_info "升级已安装的包..."
    apt-get upgrade -y
}

# 安装Nginx
install_nginx() {
    log_info "安装Nginx..."
    apt-get install -y nginx

    # 检查安装是否成功
    if systemctl is-active --quiet nginx; then
        log_info "Nginx 安装成功并正在运行"
    else
        log_error "Nginx 安装后未能启动"
        exit 1
    fi
}

# 配置防火墙
configure_firewall() {
    log_info "配置防火墙..."
    if command -v ufw &> /dev/null; then
        ufw allow 'Nginx HTTP'
        ufw allow 'Nginx HTTPS'
        log_info "防火墙已配置允许HTTP和HTTPS流量"
    else
        log_warning "ufw未安装，跳过防火墙配置"
    fi
}

# 基本安全配置
configure_security() {
    log_info "应用基本安全配置..."

    # 隐藏Nginx版本号
    sed -i 's/# server_tokens off;/server_tokens off;/' /etc/nginx/nginx.conf

    # 创建安全头配置文件
    cat > /etc/nginx/conf.d/security-headers.conf << EOF
# 安全头部设置
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header X-Content-Type-Options "nosniff" always;
add_header Referrer-Policy "no-referrer-when-downgrade" always;
add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
EOF

    log_info "安全配置已应用"
}

# 创建示例网站
create_example_site() {
    local site_name=${1:-"example.com"}
    local root_dir="/var/www/${site_name}"

    log_info "创建示例网站: ${site_name}"

    # 创建网站目录
    mkdir -p "${root_dir}"
    chown -R www-data:www-data "${root_dir}"
    chmod -R 755 "${root_dir}"

    # 创建示例页面
    cat > "${root_dir}/index.html" << EOF
<!DOCTYPE html>
<html lang="zh">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>欢迎使用 Nginx</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            text-align: center;
        }
        .success {
            color: #2ecc71;
        }
    </style>
</head>
<body>
    <h1 class="success">🎉 成功!</h1>
    <h2>Nginx 已成功安装和配置</h2>
    <p>您的网站 <strong>${site_name}</strong> 现已上线</p>
    <p>服务器: Ubuntu $(lsb_release -ds)</p>
    <p>Nginx 版本: $(nginx -v 2>&1 | cut -d'/' -f2)</p>
</body>
</html>
EOF

    # 创建Nginx配置文件
    cat > "/etc/nginx/sites-available/${site_name}" << EOF
server {
    listen 80;
    listen [::]:80;

    server_name ${site_name};
    root ${root_dir};
    index index.html index.htm;

    access_log /var/log/nginx/${site_name}.access.log;
    error_log /var/log/nginx/${site_name}.error.log;

    location / {
        try_files \$uri \$uri/ =404;
    }

    # 禁止访问隐藏文件
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
}
EOF

    # 启用网站
    ln -sf "/etc/nginx/sites-available/${site_name}" "/etc/nginx/sites-enabled/"

    # 禁用默认网站
    if [[ -f "/etc/nginx/sites-enabled/default" ]]; then
        rm "/etc/nginx/sites-enabled/default"
    fi

    log_info "示例网站 ${site_name} 已创建"
}

# 测试Nginx配置
test_nginx_config() {
    log_info "测试Nginx配置..."
    if nginx -t; then
        log_info "Nginx配置测试成功"
    else
        log_error "Nginx配置测试失败"
        exit 1
    fi
}

# 重启Nginx
restart_nginx() {
    log_info "重启Nginx服务..."
    systemctl restart nginx
    systemctl enable nginx
}

# 显示安装结果
show_installation_result() {
    local site_name=${1:-"example.com"}

    echo ""
    echo -e "${GREEN}=========================================${NC}"
    echo -e "${GREEN}        Nginx 安装完成!${NC}"
    echo -e "${GREEN}=========================================${NC}"
    echo ""
    echo -e "服务器IP: $(hostname -I | awk '{print $1}')"
    echo -e "Nginx 状态: $(systemctl is-active nginx)"
    echo -e "Nginx 版本: $(nginx -v 2>&1 | cut -d'/' -f2)"
    echo -e "示例网站: http://${site_name}"
    echo ""
    echo -e "网站根目录: /var/www/${site_name}"
    echo -e "Nginx配置目录: /etc/nginx/"
    echo -e "访问日志: /var/log/nginx/${site_name}.access.log"
    echo ""
    echo -e "常用命令:"
    echo -e "  重启Nginx: systemctl restart nginx"
    echo -e "  查看状态: systemctl status nginx"
    echo -e "  查看日志: tail -f /var/log/nginx/error.log"
    echo -e "${GREEN}=========================================${NC}"
}

# 主函数
main() {
    local site_name=${1:-"example.com"}

    log_info "开始安装Nginx..."
    check_root
    update_system
    install_nginx
    configure_firewall
    configure_security
    create_example_site "$site_name"
    test_nginx_config
    restart_nginx
    show_installation_result "$site_name"

    log_info "安装完成!"
}

# 使用方法
usage() {
    echo "用法: $0 [网站名称]"
    echo "示例: $0 mywebsite.com"
    echo "       $0 (使用默认名称 example.com)"
}

# 脚本入口
if [[ $# -gt 1 ]]; then
    usage
    exit 1
fi

# 执行主函数
main "$@"