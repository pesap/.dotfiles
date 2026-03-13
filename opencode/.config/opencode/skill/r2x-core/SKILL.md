---
name: r2x-core Plugin Generator
description: Generate boilerplate code for a new r2x-core plugin with an interactive wizard. Use this skill when users want to create a new plugin, scaffold plugin code, or set up the file structure for an r2x-core plugin.
---

# r2x-core Plugin Generator

Generate boilerplate code for a new r2x-core plugin with an interactive wizard.

## Instructions

Follow these steps to create a new plugin:

### Step 1: Gather Plugin Metadata

Use `AskUserQuestion` to collect the following information:

**Question 1: Plugin Name**
Ask for the plugin name (e.g., "ReEDS", "PLEXOS", "Sienna"). This will be used to generate class names like `{Name}Plugin` and `{Name}Config`.

**Question 2: Output Directory**
Ask where to create the plugin directory. Default to `src/` if the user doesn't specify.

**Question 3: Hooks to Implement**
Ask which lifecycle hooks the plugin should implement. Use `multiSelect: true`. Options:
- `on_validate` - Validate inputs/config
- `on_prepare` - Load data, setup resources
- `on_build` - Create system from scratch
- `on_transform` - Modify existing system
- `on_translate` - Convert source to target system
- `on_export` - Write system to files
- `on_cleanup` - Cleanup resources

**Question 4: Configuration Fields (Optional)**
Ask if the user wants to add custom configuration fields beyond the base `models` field. If yes, ask for field details (name, type, default value).

### Step 2: Generate Plugin Files

Create the following directory structure using the `Write` tool:

```
<output_dir>/<plugin_name_lower>/
├── __init__.py
├── config.py
├── plugin.py
└── config/
    ├── defaults.json
    └── file_mapping.json
```

### File Templates

#### `__init__.py`
```python
"""<Name> plugin for r2x-core."""

from .config import <Name>Config
from .plugin import <Name>Plugin

__all__ = ["<Name>Config", "<Name>Plugin"]
```

#### `config.py`
```python
"""Configuration for <Name> plugin."""

from pathlib import Path

from pydantic import Field

from r2x_core import PluginConfig


class <Name>Config(PluginConfig):
    """Configuration for <Name> plugin.

    Attributes
    ----------
    models : tuple[str, ...]
        Module path(s) for component classes.
    <additional fields as specified by user>
    """

    models: tuple[str, ...] = ()
    # Add user-specified config fields here with Field() defaults
```

#### `plugin.py`
```python
"""<Name> plugin implementation."""

from __future__ import annotations

from typing import TYPE_CHECKING

from rust_ok import Err, Ok, Result

from r2x_core import Plugin

from .config import <Name>Config

if TYPE_CHECKING:
    from r2x_core import System


class <Name>Plugin(Plugin[<Name>Config]):
    """Plugin implementation for <Name>.

    Implements the following hooks:
    <list selected hooks>
    """

    # Include only the hooks selected by the user
    # Each hook should have a stub implementation returning Ok(...)
```

#### Hook Implementation Stubs

For each selected hook, generate the appropriate stub:

**on_validate:**
```python
def on_validate(self) -> Result[None, str]:
    """Validate plugin configuration.

    Returns
    -------
    Result[None, str]
        Ok(None) if validation passes, Err with message otherwise.
    """
    return Ok(None)
```

**on_prepare:**
```python
def on_prepare(self) -> Result[None, str]:
    """Prepare resources for plugin execution.

    Returns
    -------
    Result[None, str]
        Ok(None) if preparation succeeds, Err with message otherwise.
    """
    return Ok(None)
```

**on_build:**
```python
def on_build(self) -> Result[System, str]:
    """Build a new system from scratch.

    Returns
    -------
    Result[System, str]
        Ok(System) with the built system, Err with message otherwise.
    """
    from r2x_core import System

    system = System(name=self.__class__.__name__)
    return Ok(system)
```

**on_transform:**
```python
def on_transform(self) -> Result[System, str]:
    """Transform the existing system.

    Returns
    -------
    Result[System, str]
        Ok(System) with the transformed system, Err with message otherwise.
    """
    return Ok(self.system)
```

**on_translate:**
```python
def on_translate(self) -> Result[System, str]:
    """Translate source system to target system.

    Returns
    -------
    Result[System, str]
        Ok(System) with the target system, Err with message otherwise.
    """
    from r2x_core import System

    target = System(name=f"{self.source_system.name}_translated")
    return Ok(target)
```

**on_export:**
```python
def on_export(self) -> Result[None, str]:
    """Export the system to files.

    Returns
    -------
    Result[None, str]
        Ok(None) if export succeeds, Err with message otherwise.
    """
    return Ok(None)
```

**on_cleanup:**
```python
def on_cleanup(self) -> Result[None, str]:
    """Clean up resources after plugin execution.

    Returns
    -------
    Result[None, str]
        Ok(None) if cleanup succeeds, Err with message otherwise.
    """
    return Ok(None)
```

#### `config/defaults.json`
```json
{}
```

#### `config/file_mapping.json`
```json
{}
```

### Step 3: Summary

After generating all files, provide a summary:

1. List all created files with their paths
2. Show how to import and use the plugin:
   ```python
   from <plugin_name_lower> import <Name>Plugin, <Name>Config
   from r2x_core import PluginContext

   config = <Name>Config(models="my_package.models")
   ctx = PluginContext(config=config)
   plugin = <Name>Plugin.from_context(ctx)
   result = plugin.run()
   ```
3. Remind the user to:
   - Add any required dependencies to their `pyproject.toml`
   - Implement the actual logic in each hook
   - Update the `defaults.json` and `file_mapping.json` as needed

## Important Notes

- Use PascalCase for class names (e.g., `ReEDSPlugin`, `PLEXOSConfig`)
- Use lowercase with underscores for the directory name (e.g., `reeds`, `plexos`)
- Always include proper type hints from `rust_ok` (`Ok`, `Err`, `Result`)
- Follow the existing patterns from `src/r2x_core/plugin_base.py` and `src/r2x_core/plugin_config.py`
