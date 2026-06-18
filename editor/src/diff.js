import { initialize, getService } from '@codingame/monaco-vscode-api'
import { IExtensionResourceLoaderService } from '@codingame/monaco-vscode-api/vscode/vs/platform/extensionResourceLoader/common/extensionResourceLoader.service'
import { IConfigurationService } from '@codingame/monaco-vscode-api/vscode/vs/platform/configuration/common/configuration.service'
import { FileAccess } from '@codingame/monaco-vscode-api/vscode/vs/base/common/network'
import getTextmateServiceOverride from '@codingame/monaco-vscode-textmate-service-override'
import getThemeServiceOverride from '@codingame/monaco-vscode-theme-service-override'
import getLanguagesServiceOverride from '@codingame/monaco-vscode-languages-service-override'

// NOTE (Phase 0): the VS Code service init below is duplicated from main.js.
// Phase 6 extracts it into a shared-init.js module consumed by both entries.

// --- Capture extension resource URL mappings ---
const extensionResourceUrls = new Map()
const origRegister = FileAccess.registerStaticBrowserUri.bind(FileAccess)
FileAccess.registerStaticBrowserUri = function (uri, browserUri) {
  extensionResourceUrls.set(uri.toString(), browserUri.toString(true))
  return origRegister(uri, browserUri)
}

await import('@codingame/monaco-vscode-all-language-default-extensions')
await import('@codingame/monaco-vscode-theme-defaults-default-extension')

// --- JS ↔ Swift bridge ---
function postToSwift(msg) {
  window.webkit?.messageHandlers?.editor?.postMessage(msg)
}

window.onerror = (msg, src, line, col) => {
  postToSwift({ type: 'error', message: `${msg} (${src}:${line}:${col})` })
}
window.onunhandledrejection = (e) => {
  postToSwift({ type: 'error', message: `Unhandled rejection: ${e.reason}` })
}

// --- Worker setup ---
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
await initialize({
  ...getTextmateServiceOverride(),
  ...getThemeServiceOverride(),
  ...getLanguagesServiceOverride(),
  [IExtensionResourceLoaderService.toString()]: new ExtensionResourceLoader()
}, undefined, {
  initialColorTheme: { themeType: 'dark' }
})

const configService = await getService(IConfigurationService)
await configService.updateValue('workbench.colorTheme', 'Dark Modern')

const monaco = await import('monaco-editor')

// Block Monarch tokenizer registration (TextMate handles highlighting).
monaco.languages.setTokensProvider = () => ({ dispose() {} })

await import('@codingame/monaco-vscode-standalone-typescript-language-features')
await import('@codingame/monaco-vscode-standalone-json-language-features')
await import('@codingame/monaco-vscode-standalone-css-language-features')
await import('@codingame/monaco-vscode-standalone-html-language-features')

// --- Diff API ---
// Renders a vertical stack of inline diff editors, one per file.
const container = document.getElementById('diffs')
const diffEditors = []

const sharedDiffOptions = {
  automaticLayout: true,
  renderSideBySide: false,
  readOnly: true,
  minimap: { enabled: false },
  fontSize: 13,
  fontFamily: 'Menlo, monospace',
  scrollBeyondLastLine: false,
  overviewRulerLanes: 0,
  hideUnchangedRegions: { enabled: true },
  scrollbar: {
    verticalScrollbarSize: 8,
    horizontalScrollbarSize: 8,
    alwaysConsumeMouseWheel: false
  }
}

function clearDiffs() {
  for (const ed of diffEditors) ed.dispose()
  diffEditors.length = 0
  container.replaceChildren()
}

window.diffAPI = {
  setFiles(files) {
    clearDiffs()

    if (!files || files.length === 0) {
      // Empty state is owned by Swift in Phase 0; leave the area blank.
      postToSwift({ type: 'contentReady' })
      return
    }

    for (const file of files) {
      const section = document.createElement('div')
      section.className = 'diff-section'

      const header = document.createElement('div')
      header.className = 'diff-header'
      header.textContent = file.filePath
      section.appendChild(header)

      const host = document.createElement('div')
      host.className = 'diff-body'
      section.appendChild(host)
      container.appendChild(section)

      const original = monaco.editor.createModel(file.originalText ?? '', file.languageId || 'plaintext')
      const modified = monaco.editor.createModel(file.modifiedText ?? '', file.languageId || 'plaintext')

      const diffEditor = monaco.editor.createDiffEditor(host, sharedDiffOptions)
      diffEditor.setModel({ original, modified })
      diffEditors.push(diffEditor)
    }

    postToSwift({ type: 'contentReady' })
  },

  setTheme(isDark) {
    configService.updateValue('workbench.colorTheme', isDark ? 'Dark Modern' : 'Light Modern')
    document.documentElement.style.colorScheme = isDark ? 'dark' : 'light'
  },

  clear() {
    clearDiffs()
  },

  layout() {
    for (const ed of diffEditors) ed.layout()
  }
}

// Signal readiness to Swift (diffAPI available, no content yet).
postToSwift({ type: 'ready' })

setTimeout(() => document.body.classList.remove('loading'))
