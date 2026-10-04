return {
	cmd = { "rust-analyzer" },
	cmd_env = { RUSTUP_TOOLCHAIN = "1.99.0" },
	filetypes = { "rust" },
	root_markers = { ".git", "Cargo.toml", "requirements.txt" },
}
