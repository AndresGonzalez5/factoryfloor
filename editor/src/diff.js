import { monaco, configService, postToSwift } from './shared-init.js'

// --- Diff API ---
// Renders a vertical stack of inline diff editors, one per file. Each editor is
// sized to its content height so the page (not the editor) scrolls and there is
// no trailing empty editor background below the content. Binary files render a
// "not shown" badge; oversize files render a click-to-load placeholder.
const container = document.getElementById('diffs')
const emptyState = document.getElementById('empty-state')

// Line height in pixels — must match Monaco's lineHeight (~19px at fontSize 13).
const LINE_HEIGHT = 19
const MIN_EDITOR_HEIGHT = 60
// Extra lines added to the initial estimate to cover diff decorations/widgets.
const PADDING_LINES = 2
// Padding added to the measured content height when sizing the container.
const HEIGHT_PADDING = 8

// Localized strings injected by Swift (fall back to English if absent).
const STR = {
  binary: 'Binary file (not shown)',
  largeFile: 'Large file — %d changes, click to load'
}

// Active diff editors keyed by file path: { host, editor, original, modified }.
const sections = new Map()
// Editors awaiting their first onDidUpdateDiff before we report contentReady.
let pendingCount = 0
let reported = false
let safetyTimer = null

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

const STATUS_CLASS = { A: 'added', M: 'modified', D: 'deleted', R: 'renamed' }

function reportContentReady() {
  if (reported) return
  reported = true
  if (safetyTimer) { clearTimeout(safetyTimer); safetyTimer = null }
  postToSwift({ type: 'contentReady' })
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

function disposeSection(entry) {
  if (entry.editor) entry.editor.dispose()
  if (entry.original) entry.original.dispose()
  if (entry.modified) entry.modified.dispose()
}

function clearDiffs() {
  for (const entry of sections.values()) disposeSection(entry)
  sections.clear()
  // Remove every child except the empty-state placeholder.
  for (const child of Array.from(container.children)) {
    if (child !== emptyState) child.remove()
  }
}

function makeHeader(file) {
  const header = document.createElement('div')
  header.className = 'diff-header'

  const badge = document.createElement('span')
  badge.className = `status-badge ${STATUS_CLASS[file.status] || 'modified'}`
  badge.textContent = file.status || 'M'
  header.appendChild(badge)

  const path = document.createElement('span')
  path.className = 'file-path'
  path.textContent = file.filePath
  header.appendChild(path)

  return header
}

// Build a real Monaco diff editor into `host` for the given file content.
function mountDiffEditor(host, file) {
  const original = monaco.editor.createModel(file.originalText ?? '', file.languageId || 'plaintext')
  const modified = monaco.editor.createModel(file.modifiedText ?? '', file.languageId || 'plaintext')

  const diffEditor = monaco.editor.createDiffEditor(host, sharedDiffOptions)
  diffEditor.setModel({ original, modified })

  return { editor: diffEditor, original, modified }
}

window.diffAPI = {
  setFiles(files) {
    reported = false
    if (safetyTimer) { clearTimeout(safetyTimer); safetyTimer = null }
    clearDiffs()

    if (!files || files.length === 0) {
      emptyState.classList.add('visible')
      reportContentReady()
      return
    }
    emptyState.classList.remove('visible')

    // Count only the files that will actually compute a diff (normal files).
    pendingCount = files.filter(f => !f.binary && !f.deferred).length

    // Safety: report ready after 5s even if some onDidUpdateDiff never fires.
    safetyTimer = setTimeout(reportContentReady, 5000)

    for (const file of files) {
      const section = document.createElement('div')
      section.className = 'diff-section'
      section.appendChild(makeHeader(file))

      if (file.binary) {
        const note = document.createElement('div')
        note.className = 'placeholder placeholder-binary'
        note.textContent = STR.binary
        section.appendChild(note)
        container.appendChild(section)
        sections.set(file.filePath, { host: section, editor: null })
        continue
      }

      if (file.deferred) {
        const note = document.createElement('div')
        note.className = 'placeholder placeholder-large'
        note.textContent = STR.largeFile.replace('%d', file.changedLines ?? 0)
        note.setAttribute('role', 'button')
        note.tabIndex = 0
        const request = () => {
          if (note.dataset.loading === '1') return
          note.dataset.loading = '1'
          note.classList.add('loading')
          postToSwift({ type: 'loadFile', filePath: file.filePath })
        }
        note.addEventListener('click', request)
        note.addEventListener('keydown', (e) => {
          if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); request() }
        })
        section.appendChild(note)
        container.appendChild(section)
        sections.set(file.filePath, { host: section, editor: null })
        continue
      }

      const host = document.createElement('div')
      host.className = 'diff-body'
      // Initial estimate; refined to exact content height in onDidUpdateDiff.
      host.style.height = `${calculateEditorHeight(file.originalText, file.modifiedText)}px`
      section.appendChild(host)
      container.appendChild(section)

      const mounted = mountDiffEditor(host, file)
      mounted.host = section

      // Once the diff is computed (and unchanged regions folded), size the
      // container to the exact content height so no empty editor area remains.
      mounted.editor.onDidUpdateDiff(() => {
        resizeDiffEditor(mounted.editor, host)
        pendingCount--
        if (pendingCount <= 0) reportContentReady()
      })

      sections.set(file.filePath, mounted)
    }

    // No normal editors to wait on (all binary/deferred/empty) — ready now.
    if (pendingCount <= 0) reportContentReady()
  },

  // Replace a deferred file's placeholder with a real diff editor in place.
  loadFileContent(file) {
    const entry = sections.get(file.filePath)
    if (!entry || !entry.host) return
    const section = entry.host

    // Remove the placeholder note (keep the header).
    const placeholder = section.querySelector('.placeholder')
    if (placeholder) placeholder.remove()

    const host = document.createElement('div')
    host.className = 'diff-body'
    host.style.height = `${calculateEditorHeight(file.originalText, file.modifiedText)}px`
    section.appendChild(host)

    const mounted = mountDiffEditor(host, file)
    mounted.host = section
    mounted.editor.onDidUpdateDiff(() => {
      resizeDiffEditor(mounted.editor, host)
    })
    sections.set(file.filePath, mounted)
  },

  setStrings(strings) {
    if (!strings || typeof strings !== 'object') return
    Object.assign(STR, strings)
    if (strings.noChanges) {
      const msg = emptyState && emptyState.querySelector('.message')
      if (msg) msg.textContent = strings.noChanges
    }
  },

  setTheme(isDark) {
    configService.updateValue('workbench.colorTheme', isDark ? 'Dark Modern' : 'Light Modern')
    document.documentElement.style.colorScheme = isDark ? 'dark' : 'light'
  },

  clear() {
    clearDiffs()
    emptyState.classList.add('visible')
    reportContentReady()
  },

  layout() {
    for (const entry of sections.values()) {
      if (entry.editor) entry.editor.layout()
    }
  },

  // Scroll the diff page so the given file's section is at the top of the
  // viewport. Works for normal, binary, and deferred (placeholder) files since
  // every file registers its section element in `sections` keyed by exact path.
  scrollToFile(path) {
    const entry = sections.get(path)
    if (!entry || !entry.host) return
    entry.host.scrollIntoView({ behavior: 'smooth', block: 'start' })
  }
}

// Signal readiness to Swift (diffAPI available, no content yet).
postToSwift({ type: 'ready' })

setTimeout(() => document.body.classList.remove('loading'))
