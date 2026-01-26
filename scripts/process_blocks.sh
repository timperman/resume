#! /bin/sh

awk '
  BEGIN { gh=0; pdf=0 }

  # --- GitHub-only blocks (remove everything inside) ---
  /^<!--[[:space:]]*BEGIN:[[:space:]]*GitHub-only/ { gh=1; next }
  /^<!--[[:space:]]*END:[[:space:]]*GitHub-only/   { gh=0; next }
  gh==1 { next }

  # --- PDF-only blocks (emit as raw LaTeX) ---
  /^<!--[[:space:]]*BEGIN:[[:space:]]*PDF-only/ {
    pdf=1
    print "```{=latex}"
    next
  }

  pdf==1 && /END:[[:space:]]*PDF-only/ {
    pdf=0
    print "```"
    next
  }

  pdf==1 { print; next }

  # --- Normal lines ---
  { print }
' $1 > $2
