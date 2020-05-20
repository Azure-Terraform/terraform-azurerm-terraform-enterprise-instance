{
  "DaemonAuthenticationType": "password",
  "DaemonAuthenticationPassword": "PLACEHOLDER_ADMIN_UI_PASSWORD",
  "TlsBootstrapType": "server-path",
  "TlsBootstrapHostname": "${hostname}",
  "TlsBootstrapCert": "/home/${username}/.acme.sh/${hostname}/fullchain.cer",
  "TlsBootstrapKey": "/home/${username}/.acme.sh/${hostname}/${hostname}.key",
  "BypassPreflightChecks": false,
  "ImportSettingsFrom": "${app_settings_path}",
  "LicenseFileLocation": "/home/${username}/${license_file_name}",
  "SnapshotsStore": "local",
  "SnapshotsPath": "${snapshots_path}"
}