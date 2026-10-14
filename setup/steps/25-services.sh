# system services and groups (docker, tailscale)

for svc in docker tailscaled; do
  if ! systemctl list-unit-files "$svc.service" >/dev/null 2>&1; then
    warn "$svc is not installed (run the dnf step first)"
  elif systemctl is-enabled --quiet "$svc"; then
    ok "$svc enabled"
  else
    run sudo systemctl enable --now "$svc"
  fi
done

if id -nG "$USER" | tr ' ' '\n' | grep -qx docker; then
  ok "$USER in group docker"
else
  run sudo usermod -aG docker "$USER"
  warn "log out and back in to use docker without sudo"
fi

if have tailscale && ! tailscale status >/dev/null 2>&1; then
  warn "tailscale is not logged in: run 'sudo tailscale up'"
fi
