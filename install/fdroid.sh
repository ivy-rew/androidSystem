#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
FDROIDCL_BIN=""
ADB_BIN=""
FDROIDCL_VERSION="v0.8.1"
FDROIDCL_INSTALL_DIR="$ROOT_DIR/install/bin"
INSTALL_LOG="$ROOT_DIR/install.log"

die() {
	printf 'Error: %s\n' "$*" >&2
	exit 1
}

usage() {
	cat <<'EOF'
Usage: bash install/fdroid.sh COMMAND [ARGS...]

Commands:
  setup                 Download fdroidcl and refresh repository indexes
  search <query...>     Search F-Droid repositories
  show <app-id...>      Show app details
  download <app-id>     Download an APK to fdroidcl's cache
	install <app-id...>   Install app(s) via ADB and log successful package IDs
  update                Refresh repository indexes
  help                  Show this help

If more than one device is connected, select one with ANDROID_SERIAL.
Downloads the prebuilt fdroidcl binary; Go is not required.
Successful package IDs are appended one per line to ./install.log.
EOF
}

find_adb() {
	if [[ -x "$ROOT_DIR/platform-tools/adb" ]]; then
		ADB_BIN="$ROOT_DIR/platform-tools/adb"
	elif command -v adb >/dev/null 2>&1; then
		ADB_BIN="$(command -v adb)"
	else
		die "ADB was not found (expected $ROOT_DIR/platform-tools/adb or adb in PATH)."
	fi

	# fdroidcl invokes adb by name, so prefer the ADB binary bundled with this project.
	PATH="$(dirname -- "$ADB_BIN"):$PATH"
	export PATH
}

ensure_fdroidcl() {
	local arch asset expected_sha url temp_file actual_sha
	FDROIDCL_BIN="$FDROIDCL_INSTALL_DIR/fdroidcl"
	[[ -x "$FDROIDCL_BIN" ]] && return

	case "$(uname -m)" in
		x86_64|amd64)
			arch="linux_amd64"
			expected_sha="7d1feba37d2663e3e28d8b1be8ace874ca2a8c3a03ff4c0df5b8aed842d0b5d5"
			;;
		aarch64|arm64)
			arch="linux_arm64"
			expected_sha="6e7a35d57b326c077790dcb3dffad6f89ded44886eb101ee7200b9f1dc1ca749"
			;;
		*)
			die "Unsupported Linux architecture: $(uname -m). fdroidcl has prebuilt Linux amd64 and arm64 binaries."
			;;
	esac

	asset="fdroidcl_${FDROIDCL_VERSION}_${arch}"
	url="https://github.com/Hoverth/fdroidcl/releases/download/${FDROIDCL_VERSION}/${asset}"
	mkdir -p -- "$FDROIDCL_INSTALL_DIR"
	temp_file="$(mktemp "$FDROIDCL_INSTALL_DIR/.fdroidcl.XXXXXX")"
	printf 'Downloading fdroidcl %s for %s...\n' "$FDROIDCL_VERSION" "$arch"
	if command -v curl >/dev/null 2>&1; then
		if ! curl --fail --location --silent --show-error "$url" --output "$temp_file"; then
			rm -f -- "$temp_file"
			die "Could not download fdroidcl from $url."
		fi
	elif command -v wget >/dev/null 2>&1; then
		if ! wget --quiet --output-document="$temp_file" "$url"; then
			rm -f -- "$temp_file"
			die "Could not download fdroidcl from $url."
		fi
	else
		rm -f -- "$temp_file"
		die "Install curl or wget to download fdroidcl."
	fi

	if command -v sha256sum >/dev/null 2>&1; then
		actual_sha="$(sha256sum -- "$temp_file" | awk '{print $1}')"
	elif command -v shasum >/dev/null 2>&1; then
		actual_sha="$(shasum -a 256 -- "$temp_file" | awk '{print $1}')"
	else
		rm -f -- "$temp_file"
		die "Install sha256sum or shasum to verify the downloaded binary."
	fi
	if [[ "$actual_sha" != "$expected_sha" ]]; then
		rm -f -- "$temp_file"
		die "fdroidcl checksum mismatch; the binary was not installed."
	fi

	chmod 755 "$temp_file"
	mv -f -- "$temp_file" "$FDROIDCL_BIN"
	printf 'Installed fdroidcl at %s\n' "$FDROIDCL_BIN"
}

require_app_ids() {
	[[ "$#" -gt 0 ]] || die "Provide at least one app ID."
}

require_connected_device() {
	local devices count
	find_adb

	devices="$("$ADB_BIN" devices | awk 'NR > 1 && $2 == "device" { print $1 }')"
	if [[ -n "${ANDROID_SERIAL:-}" ]]; then
		printf '%s\n' "$devices" | grep -Fxq -- "$ANDROID_SERIAL" || die "ANDROID_SERIAL '$ANDROID_SERIAL' is not an authorized connected device. Check '$ADB_BIN devices'."
		return
	fi

	count="$(printf '%s\n' "$devices" | awk 'NF { n++ } END { print n+0 }')"
	if [[ "$count" -eq 0 ]]; then
		die "No authorized Android device found. Connect the phone, accept its USB debugging prompt, then check '$ADB_BIN devices'."
	fi
	if [[ "$count" -gt 1 ]]; then
		die "Multiple devices found. Set ANDROID_SERIAL to the desired device serial and retry."
	fi
}

install_apps() {
	local app_id failed=0
	for app_id in "$@"; do
		if "$FDROIDCL_BIN" install "$app_id"; then
			printf '%s\n' "$app_id" >> "$INSTALL_LOG"
			printf 'Logged successful install: %s\n' "$app_id"
		else
			printf 'Install failed: %s (not added to %s)\n' "$app_id" "$INSTALL_LOG" >&2
			failed=1
		fi
	done
	return "$failed"
}

command_name="${1:-help}"
if [[ $# -gt 0 ]]; then
	shift
fi

case "$command_name" in
	help|-h|--help)
		usage
		;;
	setup)
		ensure_fdroidcl
		find_adb
		"$ADB_BIN" --version
		"$FDROIDCL_BIN" update
		printf '\nSetup complete. Try: bash install/fdroid.sh search bible\n'
		;;
	search)
		[[ $# -gt 0 ]] || die "Usage: bash install/fdroid.sh search <query...>"
		ensure_fdroidcl
		"$FDROIDCL_BIN" search "$@"
		;;
	show)
		require_app_ids "$@"
		ensure_fdroidcl
		"$FDROIDCL_BIN" show "$@"
		;;
	download)
		require_app_ids "$@"
		ensure_fdroidcl
		"$FDROIDCL_BIN" download "$@"
		;;
	install)
		require_app_ids "$@"
		ensure_fdroidcl
		require_connected_device
		install_apps "$@"
		;;
	update)
		ensure_fdroidcl
		"$FDROIDCL_BIN" update
		;;
	*)
		usage >&2
		die "Unknown command: $command_name"
		;;
esac