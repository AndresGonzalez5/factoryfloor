// Shared VS Code service initialization for both the editor (main.js) and the
// diff view (diff.js). Extracts the duplicated setup: extension resource URL
// capture, worker config, service init, theme setup, and the JS ↔ Swift bridge.
//
// Importing this module runs the full initialization (top-level await) and
// exports the live `monaco` namespace, the `configService`, and `postToSwift`.

import { initialize, getService } from '@codingame/monaco-vscode-api'
import { IExtensionResourceLoaderService } from '@codingame/monaco-vscode-api/vscode/vs/platform/extensionResourceLoader/common/extensionResourceLoader.service'
import { IConfigurationService } from '@codingame/monaco-vscode-api/vscode/vs/platform/configuration/common/configuration.service'
import { FileAccess } from '@codingame/monaco-vscode-api/vscode/vs/base/common/network'
import getTextmateServiceOverride from '@codingame/monaco-vscode-textmate-service-override'
import getThemeServiceOverride from '@codingame/monaco-vscode-theme-service-override'
import getLanguagesServiceOverride from '@codingame/monaco-vscode-languages-service-override'
import { MenuRegistry, MenuId } from '@codingame/monaco-vscode-api/vscode/vs/platform/actions/common/actions'

// --- Capture extension resource URL mappings ---
// FileAccess.uriToBrowserUri() uses a ResourceMap internally, but the URI lookup
// can fail when the theme service constructs a new URI object (different reference).
// We capture the mappings ourselves in a simple string-keyed Map.
// This MUST run before the extension imports so the map is populated.
const extensionResourceUrls = new Map()
const origRegister = FileAccess.registerStaticBrowserUri.bind(FileAccess)
FileAccess.registerStaticBrowserUri = function (uri, browserUri) {
  extensionResourceUrls.set(uri.toString(), browserUri.toString(true))
  return origRegister(uri, browserUri)
}

// Dynamic imports so they run AFTER the monkey-patch above.
// Static imports would evaluate before the module body.
await import('@codingame/monaco-vscode-all-language-default-extensions')
await import('@codingame/monaco-vscode-theme-defaults-default-extension')

// --- JS ↔ Swift bridge ---
export function postToSwift(msg) {
  window.webkit?.messageHandlers?.editor?.postMessage(msg)
}

// Forward uncaught errors to Swift for debugging
window.onerror = (msg, src, line, col) => {
  postToSwift({ type: 'error', message: `${msg} (${src}:${line}:${col})` })
}
window.onunhandledrejection = (e) => {
  postToSwift({ type: 'error', message: `Unhandled rejection: ${e.reason}` })
}

// --- Worker setup ---
// Each language feature runs its own Web Worker for IntelliSense.
// TextMate runs grammar tokenization in a separate worker using oniguruma WASM.
// The editor worker handles diff computation, word completion, etc.
window.MonacoEnvironment = {
  getWorker(_, label) {
    if (label === 'TextMateWorker') {
      return new Worker(
        new URL('@codingame/monaco-vscode-textmate-service-override/worker', import.meta.url),
        { type: 'module' }
      )
    }
    if (label === 'typescript' || label === 'javascript') {
      return new Worker(
        new URL('@codingame/monaco-vscode-standalone-typescript-language-features/worker', import.meta.url),
        { type: 'module' }
      )
    }
    if (label === 'css' || label === 'scss' || label === 'less') {
      return new Worker(
        new URL('@codingame/monaco-vscode-standalone-css-language-features/worker', import.meta.url),
        { type: 'module' }
      )
    }
    if (label === 'html' || label === 'handlebars' || label === 'razor') {
      return new Worker(
        new URL('@codingame/monaco-vscode-standalone-html-language-features/worker', import.meta.url),
        { type: 'module' }
      )
    }
    if (label === 'json') {
      return new Worker(
        new URL('@codingame/monaco-vscode-standalone-json-language-features/worker', import.meta.url),
        { type: 'module' }
      )
    }
    return new Worker(
      new URL('monaco-editor/esm/vs/editor/editor.worker.js', import.meta.url),
      { type: 'module' }
    )
  }
}

// --- Extension resource loader for WKWebView ---
// The default readExtensionResource is "unsupported". We provide a simple
// implementation that resolves extension-file:// URIs to ff-resource:// URLs
// using our captured mapping, then fetches via the WKURLSchemeHandler.
class ExtensionResourceLoader {
  _serviceBrand = undefined
  supportsExtensionGalleryResources = false

  async readExtensionResource(uri) {
    const uriStr = uri.toString()
    const mappedUrl = extensionResourceUrls.get(uriStr)
    if (!mappedUrl) {
      throw new Error(`No resource mapping for ${uriStr}`)
    }
    const response = await fetch(mappedUrl)
    if (!response.ok) {
      throw new Error(`Failed to load ${uriStr}: ${response.status}`)
    }
    return response.text()
  }

  async getExtensionGalleryResourceURL() {
    return undefined
  }

  getExtensionGalleryRequestHeaders() {
    return {}
  }

  async isExtensionGalleryResource() {
    return false
  }
}

// --- Initialize VS Code services ---
// MUST be called once, BEFORE creating any editor instance.
// Uses full VS Code service overrides for TextMate grammars and themes.
// Resources are served via WKURLSchemeHandler (ff-resource://) so fetch() works.
await initialize({
  ...getTextmateServiceOverride(),
  ...getThemeServiceOverride(),
  ...getLanguagesServiceOverride(),
  [IExtensionResourceLoaderService.toString()]: new ExtensionResourceLoader()
}, undefined, {
  // initialColorTheme sets the dark appearance immediately at construction time.
  // configurationDefaults is NOT wired into the config system in standalone mode,
  // so we also force the theme via configurationService after init.
  initialColorTheme: { themeType: 'dark' }
})

// Force the dark theme via the configuration service.
// configurationDefaults doesn't work in @codingame/monaco-vscode-api standalone mode
// because DefaultConfiguration.getConfigurationDefaultOverrides() is never overridden.
const configService = await getService(IConfigurationService)
await configService.updateValue('workbench.colorTheme', 'Dark Modern')

// Import monaco AFTER initialize()
const monaco = await import('monaco-editor')

// Block Monarch tokenizer registration from standalone language features.
// Their setupMode() is lazy (called via onLanguage when the first model for
// that language is created) and registers a Monarch tokenizer via
// setTokensProvider. This conflicts with the TextMate tokenizer: the
// registration fires handleChange → todo_resetTokenization before the
// TextMate grammar is loaded, crashing _toBinaryTokens. Since TextMate
// handles all syntax highlighting, we no-op setTokensProvider entirely.
// The TextMate service uses setEncodedTokensProvider (different API).
monaco.languages.setTokensProvider = () => ({ dispose() {} })

// Standalone language features — must be imported AFTER initialize() so the
// VS Code service overrides (TextMate, themes, languages) are in place.
// These restore IntelliSense (completions, hover, diagnostics) without
// needing the full extension host.
await import('@codingame/monaco-vscode-standalone-typescript-language-features')
await import('@codingame/monaco-vscode-standalone-json-language-features')
await import('@codingame/monaco-vscode-standalone-css-language-features')
await import('@codingame/monaco-vscode-standalone-html-language-features')

// Remove "Command Palette..." from the right-click context menu.
// Shared because neither the editor nor the diff view supports the command palette.
const origGetMenuItems = MenuRegistry.getMenuItems
MenuRegistry.getMenuItems = function (id) {
  const items = origGetMenuItems.call(this, id)
  if (id === MenuId.EditorContext) {
    return items.filter(item => !item.command || item.command.id !== 'workbench.action.showCommands')
  }
  return items
}

export { monaco, configService }
