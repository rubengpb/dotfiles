# system services and groups (docker; tailscale with --extras)

for svc in docker tailscaled; do
  if ! systemctl list-unit-files "$svc.service" >/dev/null 2>&1; then
    # tailscale comes from dnf-extras.txt: missing it is normal without --extras.
    if [[ "$svc" == tailscaled && "$EXTRAS" != 1 ]]; then continue; fi
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
