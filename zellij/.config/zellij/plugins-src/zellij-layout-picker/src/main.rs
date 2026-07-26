use std::collections::BTreeMap;
use std::path::PathBuf;

use zellij_tile::prelude::*;

const LIST_LAYOUTS_CONTEXT_KEY: &str = "op";
const LIST_LAYOUTS_CONTEXT_VALUE: &str = "list_layouts";
const LIST_LAYOUTS_COMMAND: &str = "home_dir=\"$(cd ~ 2>/dev/null && pwd)\"; if [ -n \"$XDG_CONFIG_HOME\" ]; then layout_dir=\"$XDG_CONFIG_HOME/zellij/layouts\"; else layout_dir=\"$home_dir/.config/zellij/layouts\"; fi; for f in \"$layout_dir\"/*.kdl; do [ -e \"$f\" ] || continue; name=\"$(basename \"$f\" .kdl)\"; printf '%s\t%s\\n' \"$name\" \"$f\"; done | sort -u";

#[derive(Clone, Debug, Eq, PartialEq)]
struct LayoutEntry {
    name: String,
    path: String,
}

#[derive(Default)]
struct State {
    error: Option<String>,
    input: String,
    layouts: Vec<LayoutEntry>,
    selected_layout: Option<LayoutEntry>,
    permissions_granted: bool,
    active_tab_position: Option<usize>,
}

register_plugin!(State);

impl ZellijPlugin for State {
    fn load(&mut self, _configuration: BTreeMap<String, String>) {
        request_permission(&[
            PermissionType::ReadApplicationState,
            PermissionType::ChangeApplicationState,
            PermissionType::RunCommands,
        ]);
        subscribe(&[
            EventType::Key,
            EventType::TabUpdate,
            EventType::RunCommandResult,
            EventType::PermissionRequestResult,
        ]);
        rename_plugin_pane(get_plugin_ids().plugin_id, "LayoutPicker");
    }

    fn update(&mut self, event: Event) -> bool {
        match event {
            Event::RunCommandResult(_, stdout, stderr, context) => {
                if context.get(LIST_LAYOUTS_CONTEXT_KEY).map(String::as_str)
                    != Some(LIST_LAYOUTS_CONTEXT_VALUE)
                {
                    return false;
                }

                if !stderr.is_empty() {
                    self.error = Some(String::from_utf8_lossy(&stderr).trim().to_string());
                } else {
                    self.layouts = parse_layout_entries(&stdout);
                    self.selected_layout = matching_layouts(&self.layouts, &self.input)
                        .into_iter()
                        .next();
                    self.error = None;
                }

                true
            }
            Event::PermissionRequestResult(status) => {
                self.permissions_granted = status == PermissionStatus::Granted;
                self.error = permission_error_message(status);
                if self.permissions_granted {
                    self.request_layouts();
                }
                true
            }
            Event::TabUpdate(tab_infos) => {
                self.active_tab_position = active_tab_index(&tab_infos);
                false
            }
            Event::Key(key) => self.handle_key_event(key),
            _ => false,
        }
    }

    fn render(&mut self, _rows: usize, _cols: usize) {
        println!("Global Zellij Layouts");
        println!("Type to filter, Enter to apply");
        println!();

        println!("> {}", self.input);
        match &self.selected_layout {
            Some(layout) => println!("Selected: {}", layout.name),
            None => println!("Selected: none"),
        }

        if let Some(error) = &self.error {
            println!();
            println!("Error: {}", error);
            return;
        }

        if !self.permissions_granted {
            println!();
            println!("Waiting for permission grant...");
            return;
        }

        let matched = matching_layouts(&self.layouts, &self.input);
        if matched.is_empty() {
            println!();
            if self.layouts.is_empty() {
                println!("No layouts found in ~/.config/zellij/layouts");
            } else {
                println!("No matching layouts");
            }
            return;
        }

        println!();
        println!("Matches:");
        for layout in matched.iter().take(10) {
            println!("- {}", layout.name);
        }
    }
}

impl State {
    fn request_layouts(&self) {
        let mut context = BTreeMap::new();
        context.insert(
            LIST_LAYOUTS_CONTEXT_KEY.to_string(),
            LIST_LAYOUTS_CONTEXT_VALUE.to_string(),
        );
        run_command_with_env_variables_and_cwd(
            &["sh", "-lc", LIST_LAYOUTS_COMMAND],
            BTreeMap::new(),
            PathBuf::from("/"),
            context,
        );
    }

    fn handle_key_event(&mut self, key: KeyWithModifier) -> bool {
        if is_close_binding(&key.bare_key, key.has_modifiers(&[KeyModifier::Ctrl])) {
            close_plugin_pane(get_plugin_ids().plugin_id);
            return true;
        }

        match key.bare_key {
            BareKey::Backspace => {
                self.input.pop();
                self.selected_layout = matching_layouts(&self.layouts, &self.input)
                    .into_iter()
                    .next();
                true
            }
            BareKey::Enter => {
                if let Some((layout_info, tab_to_close)) =
                    enter_actions(self.selected_layout.as_ref(), self.active_tab_position)
                {
                    new_tabs_with_layout_info(layout_info);
                    close_tab_with_index(tab_to_close);
                    hide_self();
                    return true;
                }

                if self.selected_layout.is_some() {
                    self.error = Some("Could not determine active tab position".to_string());
                    return true;
                }

                false
            }
            BareKey::Char(character) => {
                self.input.push(character);
                self.selected_layout = matching_layouts(&self.layouts, &self.input)
                    .into_iter()
                    .next();
                true
            }
            _ => false,
        }
    }
}

fn parse_layout_entries(stdout: &[u8]) -> Vec<LayoutEntry> {
    let mut unique = BTreeMap::new();
    for raw in String::from_utf8_lossy(stdout).lines() {
        let trimmed = raw.trim();
        if trimmed.is_empty() {
            continue;
        }

        let mut parts = trimmed.splitn(2, '\t');
        let name = parts.next().unwrap_or("").trim();
        let path = parts.next().unwrap_or("").trim();
        if name.is_empty() || path.is_empty() {
            continue;
        }

        unique.insert(
            name.to_string(),
            LayoutEntry {
                name: name.to_string(),
                path: path.to_string(),
            },
        );
    }

    unique.into_values().collect()
}

fn matching_layouts(layouts: &[LayoutEntry], query: &str) -> Vec<LayoutEntry> {
    let needle = query.trim().to_lowercase();
    if needle.is_empty() {
        return layouts.to_vec();
    }

    layouts
        .iter()
        .filter(|layout| layout.name.to_lowercase().contains(&needle))
        .cloned()
        .collect()
}

fn layout_info_for_selection(selected_layout: &LayoutEntry) -> LayoutInfo {
    LayoutInfo::File(selected_layout.path.clone(), LayoutMetadata::default())
}

fn active_tab_index(tab_infos: &[TabInfo]) -> Option<usize> {
    tab_infos
        .iter()
        .find(|tab| tab.active)
        .map(|tab| tab.position)
}

fn enter_actions(
    selected_layout: Option<&LayoutEntry>,
    active_tab_position: Option<usize>,
) -> Option<(LayoutInfo, usize)> {
    let selected_layout = selected_layout?;
    let active_tab_position = active_tab_position?;
    Some((
        layout_info_for_selection(selected_layout),
        active_tab_position,
    ))
}

fn is_close_binding(bare_key: &BareKey, ctrl_pressed: bool) -> bool {
    matches!(bare_key, BareKey::Esc)
        || (ctrl_pressed && matches!(bare_key, BareKey::Char('c') | BareKey::Char('y')))
}

fn permission_error_message(status: PermissionStatus) -> Option<String> {
    match status {
        PermissionStatus::Granted => None,
        PermissionStatus::Denied => Some("RunCommands permission denied".to_string()),
    }
}

#[cfg(test)]
mod tests {
    use super::{
        active_tab_index, enter_actions, is_close_binding, layout_info_for_selection,
        matching_layouts, parse_layout_entries, LayoutEntry,
    };
    use zellij_tile::prelude::BareKey;
    use zellij_tile::prelude::LayoutInfo;
    use zellij_tile::prelude::PermissionStatus;
    use zellij_tile::prelude::TabInfo;

    #[test]
    fn parse_layout_entries_reads_name_and_path() {
        let output = b"default\t/home/morgoth/.config/zellij/layouts/default.kdl\n";
        let parsed = parse_layout_entries(output);
        assert_eq!(
            parsed,
            vec![LayoutEntry {
                name: "default".to_string(),
                path: "/home/morgoth/.config/zellij/layouts/default.kdl".to_string(),
            }]
        );
    }

    #[test]
    fn matching_layouts_filters_case_insensitively() {
        let layouts = vec![
            LayoutEntry {
                name: "default".to_string(),
                path: "/tmp/default.kdl".to_string(),
            },
            LayoutEntry {
                name: "opencode-dev".to_string(),
                path: "/tmp/opencode-dev.kdl".to_string(),
            },
            LayoutEntry {
                name: "python".to_string(),
                path: "/tmp/python.kdl".to_string(),
            },
        ];
        let matched = matching_layouts(&layouts, "OP");
        assert_eq!(matched[0].name, "opencode-dev");
    }

    #[test]
    fn selected_layout_uses_file_layout_info() {
        let selected = LayoutEntry {
            name: "rust".to_string(),
            path: "/tmp/rust.kdl".to_string(),
        };
        let info = layout_info_for_selection(&selected);
        assert_eq!(
            info,
            zellij_tile::prelude::LayoutInfo::File(
                "/tmp/rust.kdl".to_string(),
                zellij_tile::prelude::LayoutMetadata::default(),
            )
        );
    }

    #[test]
    fn permission_denied_surfaces_error_message() {
        let error = super::permission_error_message(PermissionStatus::Denied);
        assert_eq!(error, Some("RunCommands permission denied".to_string()));
    }

    #[test]
    fn permission_granted_has_no_error_message() {
        let error = super::permission_error_message(PermissionStatus::Granted);
        assert_eq!(error, None);
    }

    #[test]
    fn close_binding_accepts_escape_and_ctrl_y() {
        assert!(is_close_binding(&BareKey::Esc, false));
        assert!(is_close_binding(&BareKey::Char('y'), true));
        assert!(is_close_binding(&BareKey::Char('c'), true));
        assert!(!is_close_binding(&BareKey::Char('y'), false));
    }

    #[test]
    fn active_tab_index_reads_active_tab_position() {
        let tabs = vec![
            TabInfo {
                position: 0,
                active: false,
                ..Default::default()
            },
            TabInfo {
                position: 1,
                active: true,
                ..Default::default()
            },
        ];
        assert_eq!(active_tab_index(&tabs), Some(1));
    }

    #[test]
    fn enter_actions_replaces_current_tab_with_selected_layout() {
        let selected = LayoutEntry {
            name: "rust".to_string(),
            path: "/tmp/rust.kdl".to_string(),
        };

        let action = enter_actions(Some(&selected), Some(2));
        assert_eq!(
            action,
            Some((
                LayoutInfo::File(
                    "/tmp/rust.kdl".to_string(),
                    zellij_tile::prelude::LayoutMetadata::default(),
                ),
                2,
            ))
        );
    }
}
