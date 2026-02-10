#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="/var/log/lab-deploy.log"

usage() {
  cat <<'EOF'
Uso:
  deploy.sh

Descrição:
  Script de deploy idempotente para Debian 13.
  Deve ser executado como root e rodado a partir do repo clonado (clone & run).
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage; exit 0;;
    *) echo "Argumento desconhecido: $1" >&2; usage; exit 2;;
  esac
done

mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"
chmod 0600 "$LOG_FILE"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "==== Deploy iniciado: $(date -Is) ===="
echo "Log:  $LOG_FILE"

require_root() {
  [[ "$(id -u)" -eq 0 ]] || { echo "ERRO: rode como root." >&2; exit 1; }
}

have_cmd() { command -v "$1" >/dev/null 2>&1; }

ensure_pkg() {
  local pkg="$1"
  if dpkg -s "$pkg" >/dev/null 2>&1; then
    echo "[OK] Pacote já instalado: $pkg"
  else
    echo "[..] Instalando pacote: $pkg"
    apt-get update -y
    DEBIAN_FRONTEND=noninteractive apt-get install -y "$pkg"
  fi
}

ensure_group() {
  local g="$1"
  if getent group "$g" >/dev/null; then
    echo "[OK] Grupo existe: $g"
  else
    echo "[..] Criando grupo: $g"
    groupadd --system "$g" 2>/dev/null || groupadd "$g"
  fi
}

ensure_user() {
  local u="$1" primary_group="$2" supp_groups_csv="$3"
  if id "$u" >/dev/null 2>&1; then
    echo "[OK] Usuário existe: $u"
    usermod -g "$primary_group" "$u"
    IFS=',' read -r -a supp <<<"$supp_groups_csv"
    for g in "${supp[@]}"; do
      [[ -z "$g" ]] && continue
      usermod -aG "$g" "$u"
    done
  else
    echo "[..] Criando usuário: $u"
    useradd -r -m -s /usr/sbin/nologin -g "$primary_group" "$u"
    IFS=',' read -r -a supp <<<"$supp_groups_csv"
    for g in "${supp[@]}"; do
      [[ -z "$g" ]] && continue
      usermod -aG "$g" "$u"
    done
  fi
}

install_file() {
  # install_file SRC DEST MODE OWNER GROUP
  local src="$1" dest="$2" mode="$3" owner="$4" group="$5"
  [[ -f "$src" ]] || { echo "ERRO: arquivo não encontrado: $src" >&2; exit 1; }
  mkdir -p "$(dirname "$dest")"
  install -o "$owner" -g "$group" -m "$mode" "$src" "$dest"
  echo "[OK] Instalado: $dest (mode=$mode owner=$owner group=$group)"
}

systemd_vendor_dir() {
  [[ -d /usr/lib/systemd/system ]] && echo "/usr/lib/systemd/system" || echo "/lib/systemd/system"
}

daemon_reload() {
  systemctl daemon-reload
  echo "[OK] systemd daemon-reload"
}

check_service_active() {
  local svc="$1"
  if systemctl is-active --quiet "$svc"; then
    echo "[OK] Serviço ativo: $svc"
  else
    echo "[ERRO] Serviço NÃO está ativo: $svc"
    systemctl status "$svc" --no-pager || true
    exit 1
  fi
}

check_service_enabled() {
  local svc="$1"
  if systemctl is-enabled --quiet "$svc"; then
    echo "[OK] Serviço habilitado: $svc"
  else
    echo "[WARN] Serviço não habilitado: $svc"
  fi
}

check_listening_514() {
  # Verifica se ao menos uma das combinações 514/tcp ou 514/udp está em LISTEN
  if ! have_cmd ss; then
    echo "[WARN] 'ss' não encontrado; pulando validação de portas."
    return 0
  fi

  echo "[..] Validando portas do rsyslog (esperado: 514/tcp e/ou 514/udp)"
  local ss_out
  ss_out="$(ss -lntuH || true)"

  local ok=1
  # tcp 514
  if echo "$ss_out" | awk '$1 ~ /^tcp/ {print $5}' | grep -Eq "(:|\\])514\$"; then
    echo "[OK] Encontrou escutando TCP 514"
    ok=0
  fi
  # udp 514
  if echo "$ss_out" | awk '$1 ~ /^udp/ {print $5}' | grep -Eq "(:|\\])514\$"; then
    echo "[OK] Encontrou escutando UDP 514"
    ok=0
  fi

  if [[ $ok -ne 0 ]]; then
    echo "[ERRO] Não encontrei 514/tcp nem 514/udp escutando."
    ss -lntu || true
    return 1
  fi
}

require_root

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_DIR"
echo "[..] Repo detectado: $REPO_DIR"

RSYSLOG_DROPIN_SRC="$REPO_DIR/rsyslog.conf"
RSYSLOG_SERVICE_SRC="$REPO_DIR/rsyslog.service"

AWS_CONFIG_SRC="$REPO_DIR/config"
AWS_CREDENTIALS_SRC="$REPO_DIR/credentials"
AWS_SIGNING_HELPER_SRC="$REPO_DIR/aws_signing_helper"

LOGSYNC_SCRIPT_SRC="$REPO_DIR/logsync.sh"
LOGSYNC_SERVICE_SRC="$REPO_DIR/logsync.service"
LOGSYNC_TIMER_SRC="$REPO_DIR/logsync.timer"

AWS_SIGNING_HELPER_DEST="/usr/local/bin/aws_signing_helper"

ensure_pkg "rsyslog"
ensure_pkg "awscli"

ensure_group "logservices"
ensure_group "logsync"
ensure_group "rsyslog"

ensure_user "rsyslog" "rsyslog" "logservices"
ensure_user "logsync" "rsyslog" "logservices,logsync"

echo "[..] Configurando rsyslog"

install_file "$RSYSLOG_DROPIN_SRC" "/etc/rsyslog.d/rsyslog.conf" "0644" "root" "root"

mkdir -p /var/log/rsyslog
chown root:logservices /var/log/rsyslog
chmod 0770 /var/log/rsyslog
echo "[OK] /var/log/rsyslog perms: root:logservices 0770"

install_file "$RSYSLOG_SERVICE_SRC" "/etc/systemd/system/rsyslog.service" "0644" "root" "root"
daemon_reload

systemctl enable --now rsyslog
check_service_active "rsyslog"
check_service_enabled "rsyslog"
check_listening_514

echo "[..] Configurando /etc/aws + aws_signing_helper"

mkdir -p /etc/aws
chown root:logsync /etc/aws
chmod 0750 /etc/aws  # temporário

install_file "$AWS_CONFIG_SRC" "/etc/aws/config" "0440" "root" "logsync"
install_file "$AWS_CREDENTIALS_SRC" "/etc/aws/credentials" "0440" "root" "logsync"

chmod 0550 /etc/aws
echo "[OK] /etc/aws perms finais: root:logsync 0550"

install_file "$AWS_SIGNING_HELPER_SRC" "$AWS_SIGNING_HELPER_DEST" "0550" "root" "logsync"
echo "[OK] aws_signing_helper em: $AWS_SIGNING_HELPER_DEST (root:logsync 0550)"

echo "[..] Instalando logsync (script + units)"

VENDOR_DIR="$(systemd_vendor_dir)"
echo "[..] systemd vendor dir: $VENDOR_DIR"

install_file "$LOGSYNC_SERVICE_SRC" "$VENDOR_DIR/logsync.service" "0644" "root" "root"
install_file "$LOGSYNC_TIMER_SRC"   "$VENDOR_DIR/logsync.timer"   "0644" "root" "root"
install_file "$LOGSYNC_SCRIPT_SRC" "/usr/local/sbin/logsync.sh" "0550" "root" "logsync"

daemon_reload

echo "[INFO] logsync.service/.timer instalados, mas NÃO serão habilitados/iniciados automaticamente."
echo "==== Deploy concluído com sucesso: $(date -Is) ===="
echo "Dica: para habilitar depois:"
echo "  systemctl enable --now logsync.timer"


