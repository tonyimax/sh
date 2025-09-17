#!/bin/bash

# ============================================
# Ubuntu MySQL 最新版自动化安装脚本
# 支持自定义配置，并包含基础安全设置
# 日期: 2025-09-14
# ============================================

# --- 用户可配置参数 (按需修改) ---
# 设置 MySQL root 密码 :cite[1]
MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:-'Aa123456.!'}
# MySQL 监听端口 :cite[1]
MYSQL_PORT=${MYSQL_PORT:-3306}
# MySQL 绑定地址 (0.0.0.0 允许远程；127.0.0.1 仅本地) :cite[1]
MYSQL_BIND_ADDRESS=${MYSQL_BIND_ADDRESS:-'127.0.0.1'}
# 是否允许远程 root 登录 (yes|no) :cite[1]
ALLOW_REMOTE_ROOT=${ALLOW_REMOTE_ROOT:-'no'}
# 为应用程序创建一个数据库和用户 :cite[4]
APP_DB_NAME=${APP_DB_NAME:-'test_db'}
APP_DB_USER=${APP_DB_USER:-'test'}
APP_DB_PASS=${APP_DB_PASS:-'Aa123456.!'}

# --- 颜色定义 (用于输出) ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# --- 异常处理 ---
trap 'echo -e "${RED}\n脚本被用户中断。退出...${NC}"; exit 1' INT TERM

# --- 函数定义 ---

# 检查命令是否执行成功
check_command_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}成功${NC}"
    else
        echo -e "${RED}失败! 请检查错误信息。${NC}"
        exit 1
    fi
}

# 检查是否支持包管理器
check_package_manager() {
    if command -v apt-get &> /dev/null; then
        PKG_MANAGER="apt"
        echo -e "检测到包管理器: ${GREEN}APT${NC}"
    elif command -v yum &> /dev/null; then
        PKG_MANAGER="yum"
        echo -e "检测到包管理器: ${GREEN}YUM${NC}"
        echo -e "${RED}此脚本主要针对 Ubuntu/Debian 设计。CentOS/RHEL 系统可能需要调整。${NC}"
    else
        echo -e "${RED}不支持的包管理器或系统。请手动安装。${NC}"
        exit 1
    fi
}

# 安装 MySQL
install_mysql() {
    echo -e "${YELLOW}[1/7] 更新软件包列表...${NC}"
    sudo apt-get update -qq
    check_command_status

    echo -e "${YELLOW}[2/7] 安装 MySQL Server...${NC}"
    # 使用非交互方式安装以避免提示 :cite[1]:cite[7]
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -yqq mysql-server
    check_command_status
}

# 配置 MySQL
configure_mysql() {
    echo -e "${YELLOW}[3/7] 配置 MySQL (端口: $MYSQL_PORT, 绑定地址: $MYSQL_BIND_ADDRESS)...${NC}"

    # 备份原始配置文件
    MYSQL_CONF="/etc/mysql/mysql.conf.d/mysqld.cnf"
    sudo cp "$MYSQL_CONF" "$MYSQL_CONF.backup.$(date +%Y%m%d%H%M%S)"

    # 使用 sed 修改绑定地址和端口 :cite[1]
    sudo sed -i "s/^bind-address.*/bind-address = ${MYSQL_BIND_ADDRESS}/" "$MYSQL_CONF"
    sudo sed -i "s/^port.*/port = ${MYSQL_PORT}/" "$MYSQL_CONF"
    # 为兼容更多客户端，修改默认认证插件 :cite[1]
    echo -e "[mysqld]\ndefault_authentication_plugin=mysql_native_password" | sudo tee -a /etc/mysql/conf.d/custom.cnf > /dev/null

    check_command_status
}

# 安全加固 MySQL
secure_mysql() {
    echo -e "${YELLOW}[4/7] 启动 MySQL 服务...${NC}"
    sudo systemctl enable mysql
    sudo systemctl start mysql
    check_command_status

    echo -e "${YELLOW}[5/7] 执行安全加固...${NC}"
    # 检查 MySQL 8.0+ 是否生成了临时密码
    TEMP_LOG="/var/log/mysql/error.log"
    if [ ! -f "$TEMP_LOG" ]; then
        TEMP_LOG="/var/log/mysqld.log"
    fi

    # 对于 MySQL 8.0，首次安装可能会生成临时密码 :cite[4]
    if sudo grep -q "temporary password" "$TEMP_LOG" 2>/dev/null; then
        TEMP_PASS=$(sudo grep 'temporary password' "$TEMP_LOG" | awk '{print $NF}')
        echo -e "${YELLOW}检测到临时密码，正在设置新 root 密码...${NC}"
        # 使用临时密码登录并更改root密码 :cite[4]
        mysql -u root -p"$TEMP_PASS" --connect-expired-password -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${MYSQL_ROOT_PASSWORD}'; FLUSH PRIVILEGES;" 2>/dev/null
    else
        # 如果没有临时密码，则直接设置（适用于旧版本或某些情况）
        sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${MYSQL_ROOT_PASSWORD}'; FLUSH PRIVILEGES;" 2>/dev/null
    fi

    # 运行部分安全设置 :cite[4]
    mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "DELETE FROM mysql.user WHERE User=''; DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1'); DROP DATABASE IF EXISTS test; FLUSH PRIVILEGES;" 2>/dev/null

    # 根据配置决定是否允许远程 root 访问 :cite[1]
    if [ "$ALLOW_REMOTE_ROOT" = "yes" ]; then
        echo -e "${YELLOW}配置允许远程 root 登录（注意安全风险）...${NC}"
        mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}'; GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION; FLUSH PRIVILEGES;" 2>/dev/null
        # 如果绑定地址是本地，需要提醒用户 :cite[1]
        if [ "$MYSQL_BIND_ADDRESS" = "127.0.0.1" ]; then
            echo -e "${RED}警告：您允许了远程root，但绑定地址为 127.0.0.1，远程仍无法连接。请检查配置！${NC}"
        fi
    else
        echo -e "${GREEN}禁止远程 root 登录。${NC}"
    fi

    check_command_status
}

# 创建应用数据库和用户
create_app_db_user() {
    echo -e "${YELLOW}[6/7] 创建应用数据库 '${APP_DB_NAME}' 和用户 '${APP_DB_USER}'...${NC}"
    mysql -u root -p"${MYSQL_ROOT_PASSWORD}" <<EOF
CREATE DATABASE IF NOT EXISTS ${APP_DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${APP_DB_USER}'@'localhost' IDENTIFIED BY '${APP_DB_PASS}';
CREATE USER IF NOT EXISTS '${APP_DB_USER}'@'%' IDENTIFIED BY '${APP_DB_PASS}';
GRANT ALL PRIVILEGES ON ${APP_DB_NAME}.* TO '${APP_DB_USER}'@'localhost';
GRANT ALL PRIVILEGES ON ${APP_DB_NAME}.* TO '${APP_DB_USER}'@'%';
FLUSH PRIVILEGES;
EOF
    check_command_status
}

# 验证安装
verify_installation() {
    echo -e "${YELLOW}[7/7] 最终验证...${NC}"
    echo -e "${GREEN}MySQL 服务状态:${NC}"
    sudo systemctl status mysql --no-pager -l
    echo -e "\n${GREEN}MySQL 版本信息:${NC}"
    mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SELECT VERSION();" 2>/dev/null
}

# --- 主执行逻辑 ---
echo -e "${GREEN}开始自动化安装 MySQL...${NC}"

# 检查权限
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}请使用 sudo 运行此脚本！${NC}"
    exit 1
fi

check_package_manager
install_mysql
configure_mysql
secure_mysql
create_app_db_user
verify_installation

# --- 安装完成输出信息 ---
echo -e "\n${GREEN}============================================${NC}"
echo -e "${GREEN} MySQL 自动化安装完成！${NC}"
echo -e "${GREEN}============================================${NC}"
echo -e "Root 密码: ${MYSQL_ROOT_PASSWORD}"
echo -e "MySQL 绑定地址: ${MYSQL_BIND_ADDRESS}"
echo -e "MySQL 端口: ${MYSQL_PORT}"
echo -e "应用数据库: ${APP_DB_NAME}"
echo -e "应用用户: ${APP_DB_USER}"
echo -e "应用用户密码: ${APP_DB_PASS}"
if [ "$MYSQL_BIND_ADDRESS" = "0.0.0.0" ]; then
    echo -e "${YELLOW}注意：MySQL 已配置为允许远程连接。请确保防火墙已开放端口 ${MYSQL_PORT}。${NC}:cite[1]"
fi
if [ "$ALLOW_REMOTE_ROOT" = "yes" ]; then
    echo -e "${YELLOW}注意：已允许远程 root 登录，请知晓安全风险。${NC}"
fi
echo -e "${GREEN}连接命令: mysql -u root -p -h ${MYSQL_BIND_ADDRESS} -P ${MYSQL_PORT}${NC}"
echo -e "${GREEN}============================================${NC}"