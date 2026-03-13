import type { Plugin } from "@opencode-ai/plugin"
import { existsSync } from "fs"
import { join } from "path"

export const VerifyOnEditPlugin: Plugin = async ({ client, $, directory }) => {
  return {
    event: async ({ event }) => {
      if (event.type !== "file.edited") {
        return
      }

      const filePath = event.properties?.filePath as string | undefined
      if (!filePath?.endsWith(".py")) {
        return
      }

      const justfilePath = join(directory, "justfile")
      if (!existsSync(justfilePath)) {
        return
      }

      await client.app.log({
        service: "verify-on-edit",
        level: "info",
        message: `Running verification after editing ${filePath}`,
      })

      const errors: string[] = []

      try {
        await $`just format --check`.cwd(directory)
      } catch (e) {
        errors.push(`Format check failed:\n${e}`)
      }

      try {
        await $`just lint`.cwd(directory)
      } catch (e) {
        errors.push(`Lint failed:\n${e}`)
      }

      try {
        await $`just type`.cwd(directory)
      } catch (e) {
        errors.push(`Type check failed:\n${e}`)
      }

      if (errors.length > 0) {
        const errorMessage = errors.join("\n\n")
        await client.app.log({
          service: "verify-on-edit",
          level: "error",
          message: errorMessage,
        })
        throw new Error(
          `Verification failed after editing ${filePath}:\n\n${errorMessage}`
        )
      }

      await client.app.log({
        service: "verify-on-edit",
        level: "info",
        message: "All checks passed",
      })
    },
  }
}
