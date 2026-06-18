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
// Each editor is sized to its content height so the page (not the editor)
// scrolls and there is no trailing empty editor background below the content.
const container = document.getElementById('diffs')
const diffEditors = []

// Line height in pixels — must match Monaco's lineHeight (~19px at fontSize 13).
const LINE_HEIGHT = 19
const MIN_EDITOR_HEIGHT = 60
// Extra lines added to the initial estimate to cover diff decorations/widgets.
const PADDING_LINES = 2
// Padding added to the measured content height when sizing the container.
const HEIGHT_PADDING = 8

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
  // The page scrolls, not the editor: hide the editor's own vertical scrollbar
  // and let wheel events bubble so the container can be sized to content.
  scrollbar: {
    vertical: 'hidden',
    horizontal: 'auto',
    verticalScrollbarSize: 0,
    horizontalScrollbarSize: 8,
    alwaysConsumeMouseWheel: false,
    handleMouseWheel: false
  }
}

// Estimate an initial container height from the line count so the editor has a
// sensible size before its diff is computed (avoids a 0px flash).
function calculateEditorHeight(originalText, modifiedText) {
  const origLines = originalText ? originalText.split('\n').length : 0
  const modLines = modifiedText ? modifiedText.split('\n').length : 0
  const lines = Math.max(origLines, modLines) + PADDING_LINES
  return Math.max(lines * LINE_HEIGHT, MIN_EDITOR_HEIGHT)
}

// Resize a diff editor's container to fit its actual content height. This is
// what makes each editor shrink/grow to exactly its content (accounting for
// hideUnchangedRegions folding) so the stacked page has no trailing gray gap.
function resizeDiffEditor(diffEditor, host) {
  const modifiedEditor = diffEditor.getModifiedEditor()
  const contentHeight = modifiedEditor.getContentHeight()
  const newHeight = Math.max(contentHeight + HEIGHT_PADDING, MIN_EDITOR_HEIGHT)
  host.style.height = `${newHeight}px`
  diffEditor.layout()
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
      // Initial estimate; refined to exact content height in onDidUpdateDiff.
      host.style.height = `${calculateEditorHeight(file.originalText, file.modifiedText)}px`
      section.appendChild(host)
      container.appendChild(section)

      const original = monaco.editor.createModel(file.originalText ?? '', file.languageId || 'plaintext')
      const modified = monaco.editor.createModel(file.modifiedText ?? '', file.languageId || 'plaintext')

      const diffEditor = monaco.editor.createDiffEditor(host, sharedDiffOptions)
      diffEditor.setModel({ original, modified })

      // Once the diff is computed (and unchanged regions folded), size the
      // container to the exact content height so no empty editor area remains.
      diffEditor.onDidUpdateDiff(() => {
        resizeDiffEditor(diffEditor, host)
      })

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
