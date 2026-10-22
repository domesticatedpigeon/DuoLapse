#!/usr/bin/env bash
set -euo pipefail

identity_name="DuoLapse Self-Signed"
output_directory="${1:-$HOME/DuoLapse Signing}"
validity_days=3650

if [[ -e "$output_directory" ]]; then
  echo "Refusing to overwrite $output_directory. Move it away or pass another folder." >&2
  exit 1
fi

mkdir -p "$output_directory"
chmod 700 "$output_directory"
cd "$output_directory"

password="$(openssl rand -base64 24)"

cat > certificate.cnf <<CONFIG
[req]
distinguished_name = subject
x509_extensions = code_signing
prompt = no

[subject]
CN = $identity_name

[code_signing]
basicConstraints = critical, CA:false
keyUsage = critical, digitalSignature
extendedKeyUsage = critical, codeSigning
subjectKeyIdentifier = hash
CONFIG

openssl req -x509 -newkey rsa:2048 -sha256 -nodes \
  -days "$validity_days" \
  -keyout private-key.pem \
  -out certificate.pem \
  -config certificate.cnf

legacy_flag=()
if openssl pkcs12 -help 2>&1 | grep -q -- "-legacy"; then
  legacy_flag=(-legacy)
fi

openssl pkcs12 -export "${legacy_flag[@]}" \
  -inkey private-key.pem \
  -in certificate.pem \
  -name "$identity_name" \
  -out DuoLapse-signing.p12 \
  -passout "pass:$password"

base64 < DuoLapse-signing.p12 | tr -d '\n' > DuoLapse-signing.p12.base64
printf '%s' "$password" > DuoLapse-signing.password
rm private-key.pem certificate.cnf
chmod 600 ./*

cat <<NEXT

Created a 10-year code signing identity "$identity_name" in:
  $output_directory

Add these repository secrets on GitHub (Settings › Secrets and variables › Actions):
  SIGNING_CERTIFICATE_P12_BASE64  = contents of DuoLapse-signing.p12.base64
  SIGNING_CERTIFICATE_PASSWORD    = contents of DuoLapse-signing.password

Keep this folder somewhere safe and private. Every release must be signed with this
same identity, or users have to grant Screen Recording and Camera access again.
NEXT
