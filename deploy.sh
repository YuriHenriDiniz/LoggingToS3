#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="/var/log/lab-deploy.log"

usage() {
  cat <<'EOF'
Uso:
  deploy.sh --repo /caminho/do/repo [--expect-ports "514/tcp,514/udp,6514/tcp,6514/udp"]

Args:
  --repo           Caminho do repositório local (obrigatório)
  --expect-ports   Lista CSV de portas/protocolos esperados (opcional)
                   Default: 514/tcp,514/udp,6514/tcp,6514/udp
EOF
}

REPO_DIR=""
EXPECT_PORTS_CSV="514/tcp,514/udp,6514/tcp,6514/udp"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) REPO_DIR="${2:-}"; shift 2;;
    --expect-ports) EXPECT_PORTS_CSV="${2:-}"; shift 2;;
    -h|--help) usage; exit 0;;
    *) echo "Argumento desconhecido: $1" >&2; usage; exit 2;;
  esac
done

if [[ -z "$REPO_DIR" ]]; then
  echo "ERRO: --repo é obrigatório." >&2
  usage
  exit 2
fi

if [[ ! -d "$REPO_DIR" ]]; then
  echo "ERRO: repo não encontrado: $REPO_DIR" >&2
  exit 2
fi

mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"
chmod 0600 "$LOG_FILE"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "==== Deploy iniciado: $(date -Is) ===="
echo "Repo: $REPO_DIR"
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

listening_any_expected_ports() {
  local csv="$1"
  local found=1

  if ! have_cmd ss; then
    echo "[WARN] 'ss' não encontrado; pulando validação de portas."
    return 0
  fi

  echo "[..] Validando portas (esperadas): $csv"
  local ss_out
  ss_out="$(ss -lntuH || true)"

  IFS=',' read -r -a items <<<"$csv"
  for item in "${items[@]}"; do
    item="$(echo "$item" | tr -d '[:space:]')"
    [[ -z "$item" ]] && continue
    local port proto
    port="${item%/*}"
    proto="${item#*/}"

    case "$proto" in
      tcp)
        if echo "$ss_out" | awk '$1 ~ /^tcp/ {print $5}' | grep -Eq "(:|\\])${port}\$"; then
          echo "[OK] Encontrou escutando TCP porta $port"
          found=0
        fi
        ;;
      udp)
        if echo "$ss_out" | awk '$1 ~ /^udp/ {print $5}' | grep -Eq "(:|\\])${port}\$"; then
          echo "[OK] Encontrou escutando UDP porta $port"
          found=0
        fi
        ;;
      *)
        echo "[WARN] Protocolo desconhecido em expect-ports: $item"
        ;;
    esac
  done

  if [[ $found -ne 0 ]]; then
    echo "[ERRO] Não encontrei nenhuma das portas esperadas escutando."
    echo "Saída ss -lntu:"
    ss -lntu || true
    return 1
  fi

  return 0
}

require_root

# -------------------------
# Layout esperado do repo
# -------------------------
RSYSLOG_DROPIN_SRC="$REPO_DIR/rsyslog/99-lab.conf"
RSYSLOG_SERVICE_SRC="$REPO_DIR/systemd/rsyslog.service"

AWS_CONFIG_SRC="$REPO_DIR/aws/config"
AWS_CREDENTIALS_SRC="$REPO_DIR/aws/credentials"
AWS_SIGNING_HELPER_SRC="$REPO_DIR/aws/aws_signing_helper"   # binário vindo do repo

LOGSYNC_SCRIPT_SRC="$REPO_DIR/logsync/logsync.sh"
LOGSYNC_SERVICE_SRC="$REPO_DIR/systemd/logsync.service"
LOGSYNC_TIMER_SRC="$REPO_DIR/systemd/logsync.timer"

# Destino do signing helper (novo)
AWS_SIGNING_HELPER_DEST="/usr/local/bin/aws_signing_helper"

# -------------------------
# 1) Pacotes
# -------------------------
ensure_pkg "rsyslog"
ensure_pkg "awscli"

# -------------------------
# 2) Grupos e usuários
# -------------------------
ensure_group "logservices"
ensure_group "logsync"
ensure_group "rsyslog"

ensure_user "rsyslog" "rsyslog" "logservices"
ensure_user "logsync" "rsyslog" "logservices,logsync"

# -------------------------
# 3) Rsyslog
# -------------------------
echo "[..] Configurando rsyslog"

install_file "$RSYSLOG_DROPIN_SRC" "/etc/rsyslog.d/99-lab.conf" "0644" "root" "root"

mkdir -p /var/log/rsyslog
chown root:logservices /var/log/rsyslog
chmod 0770 /var/log/rsyslog
echo "[OK] /var/log/rsyslog perms: root:logservices 0770"

install_file "$RSYSLOG_SERVICE_SRC" "/etc/systemd/system/rsyslog.service" "0644" "root" "root"
daemon_reload

systemctl enable --now rsyslog
check_service_active "rsyslog"
check_service_enabled "rsyslog"
listening_any_expected_ports "$EXPECT_PORTS_CSV" || exit 1

# -------------------------
# 4) /etc/aws (somente config/credentials) + aws_signing_helper em /usr/local/bin
# -------------------------
echo "[..] Configurando /etc/aws + aws_signing_helper"

# /etc/aws com perms finais: root:logsync 0550
mkdir -p /etc/aws
chown root:logsync /etc/aws
chmod 0750 /etc/aws  # temporário pra permitir alterações "limpas" durante deploy

install_file "$AWS_CONFIG_SRC" "/etc/aws/config" "0440" "root" "logsync"
install_file "$AWS_CREDENTIALS_SRC" "/etc/aws/credentials" "0440" "root" "logsync"

chmod 0550 /etc/aws
echo "[OK] /etc/aws perms finais: root:logsync 0550"

# aws_signing_helper em /usr/local/bin com root:logsync 0550 (R-X / R-X)
install_file "$AWS_SIGNING_HELPER_SRC" "$AWS_SIGNING_HELPER_DEST" "0550" "root" "logsync"
echo "[OK] aws_signing_helper em: $AWS_SIGNING_HELPER_DEST (root:logsync 0550)"

# -------------------------
# 5) logsync (units + script)
# -------------------------
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