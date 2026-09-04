import { monaco, configService, postToSwift } from './shared-init.js'

// --- Diff API ---
// Renders a vertical stack of inline diff editors, one per file. Editors are
// LAZY-mounted: headers + placeholders for every file are built synchronously
// (cheap DOM), while real Monaco editors mount only when their section nears
// the viewport (IntersectionObserver) and unmount when scrolled far away.
// This keeps tab-switch fast with hundreds of changed files: first paint waits
// only for the initially-visible editors, not the slowest diff in the repo.
// Binary files render a "not shown" badge; oversize files render a
// click-to-load placeholder that upgrades in place (also auto-upgraded when
// scrolled into view).
const container = document.getElementById('diffs')
const emptyState = document.getElementById('empty-state')

// Line height in pixels — must match Monaco's lineHeight (~19px at fontSize 13).
const LINE_HEIGHT = 19
const MIN_EDITOR_HEIGHT = 60
// Extra lines added to the initial estimate to cover diff decorations/widgets.
const PADDING_LINES = 2
// Padding added to the measured content height when sizing the container.
const HEIGHT_PADDING = 8
// Mount editors this far (px) beyond the viewport so scrolling never shows a
// blank host. Unmount (free) editors beyond UNMOUNT_MARGIN — hosts keep their
// measured pixel height, so disposal never shifts the scroll position.
const MOUNT_MARGIN = 1200
const UNMOUNT_MARGIN = 3000

// Localized strings injected by Swift (fall back to English if absent).
const STR = {
  binary: 'Binary file (not shown)',
  largeFile: 'Large file — %d changes, click to load',
  copyFile: 'Copy File Path',
  copied: 'File path copied',
  collapseSection: 'Collapse file',
  expandSection: 'Expand file',
  markViewed: 'Mark as viewed',
  viewed: 'Viewed'
}

// Active sections keyed by file path:
// { section, host, editor, original, modified, file, mountable, mounted,
//   diffFired, collapsed, gen }
const sections = new Map()
// Paths (current generation) awaiting their first diff before contentReady.
let pendingVisible = new Set()
let reported = false
let safetyTimer = null
// Monotonic render generation. Swift passes its content generation into
// setFiles; every async callback (diff updates, timers, observers) re-checks
// it so a superseded render can never resolve the new one's contentReady or
// resize/dispose the new render's editors.
let jsGeneration = 0

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

function reportContentReady(gen) {
  if (reported || gen !== jsGeneration) return
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
// Stale-generation callbacks (disposed editors of a previous render) are
// ignored: resizing a recycled host would corrupt the new render's layout.
function resizeDiffEditor(diffEditor, host, gen) {
  if (gen !== jsGeneration) return
  const modifiedEditor = diffEditor.getModifiedEditor()
  const contentHeight = modifiedEditor.getContentHeight()
  const newHeight = Math.max(contentHeight + HEIGHT_PADDING, MIN_EDITOR_HEIGHT)
  host.style.height = `${newHeight}px`
  diffEditor.layout()
}

function disposeEditor(entry) {
  if (entry.editor) entry.editor.dispose()
  if (entry.original) entry.original.dispose()
  if (entry.modified) entry.modified.dispose()
  entry.editor = null
  entry.original = null
  entry.modified = null
  entry.mounted = false
}

function disposeSection(entry) {
  disposeEditor(entry)
}

function clearDiffs() {
  if (mountObserver) mountObserver.disconnect()
  if (farObserver) farObserver.disconnect()
  for (const entry of sections.values()) disposeSection(entry)
  sections.clear()
  pendingVisible.clear()
  // Remove every child except the empty-state placeholder.
  for (const child of Array.from(container.children)) {
    if (child !== emptyState) child.remove()
  }
}

function isNearViewport(el, margin) {
  const r = el.getBoundingClientRect()
  return r.bottom >= -margin && r.top <= window.innerHeight + margin
}

function mountEditor(entry) {
  if (entry.mounted || !entry.mountable || entry.collapsed) return
  if (entry.gen !== jsGeneration) return
  const host = entry.host
  if (!host) return
  const file = entry.file
  const gen = entry.gen
  host.classList.remove('unmounted')

  const original = monaco.editor.createModel(file.originalText ?? '', file.languageId || 'plaintext')
  const modified = monaco.editor.createModel(file.modifiedText ?? '', file.languageId || 'plaintext')

  const diffEditor = monaco.editor.createDiffEditor(host, sharedDiffOptions)
  diffEditor.setModel({ original, modified })

  // handleMouseWheel is off so vertical wheel events bubble to the page (the
  // page scrolls between files). But that also swallows horizontal gestures, so
  // route horizontal-dominant wheel events (trackpad swipe, shift+scroll) into
  // the diff editor's horizontal scroll. Vertical-dominant events are left to
  // the page so browsing between files keeps working.
  host.addEventListener('wheel', (e) => {
    const horizontalIntent = e.shiftKey && e.deltaY !== 0
    const dominantX = Math.abs(e.deltaX) > Math.abs(e.deltaY)
    if (!horizontalIntent && !dominantX) return
    const delta = scaleWheelDelta(
      horizontalIntent ? e.deltaY : e.deltaX,
      e.deltaMode
    )
    if (delta === 0) return
    const modifiedEditor = diffEditor.getModifiedEditor()
    modifiedEditor.setScrollLeft(modifiedEditor.getScrollLeft() + delta)
    e.preventDefault()
  })

  entry.editor = diffEditor
  entry.original = original
  entry.modified = modified
  entry.mounted = true
  if (farObserver && host.isConnected) farObserver.observe(host)

  // onDidUpdateDiff can fire multiple times per editor (layout, folding);
  // only the first firing counts toward contentReady.
  diffEditor.onDidUpdateDiff(() => {
    if (gen !== jsGeneration) return
    resizeDiffEditor(diffEditor, host, gen)
    if (!entry.diffFired) {
      entry.diffFired = true
      pendingVisible.delete(entry.file.filePath)
      if (pendingVisible.size === 0) reportContentReady(gen)
    }
  })
}

// Free a far-off-screen editor. The host keeps its measured pixel height, so
// disposal is scroll-position neutral; the mount observer remounts on return.
function unmountEditor(entry) {
  if (!entry.mounted) return
  if (entry.host) {
    if (mountObserver) mountObserver.unobserve(entry.host)
    if (farObserver) farObserver.unobserve(entry.host)
    entry.host.classList.add('unmounted')
  }
  disposeEditor(entry)
  // Remount when scrolled back into range.
  if (entry.host && entry.host.isConnected && mountObserver) {
    mountObserver.observe(entry.host)
  }
}

// Mount when approaching the viewport; unmount only when TRULY far (a second
// observer with a wider margin) to avoid mount/unmount thrash at the edge.
let mountObserver = null
let farObserver = null

function ensureObservers() {
  if (!mountObserver && 'IntersectionObserver' in window) {
    mountObserver = new IntersectionObserver((records) => {
      for (const record of records) {
        const path = record.target.dataset.filePath
        const entry = path && sections.get(path)
        if (!entry || entry.gen !== jsGeneration) {
          mountObserver.unobserve(record.target)
          continue
        }
        if (!record.isIntersecting || entry.collapsed) continue
        if (entry.mountable) {
          if (!entry.mounted) mountEditor(entry)
        } else if (!entry.loadingRequested && entry.deferredNote) {
          // Deferred placeholder scrolled near: auto-upgrade (idempotent;
          // click-to-load sets the same flag).
          entry.loadingRequested = true
          entry.deferredNote.dataset.loading = '1'
          entry.deferredNote.classList.add('loading')
          postToSwift({ type: 'loadFile', filePath: entry.file.filePath })
        }
      }
    }, { root: null, rootMargin: `${MOUNT_MARGIN}px 0px`, threshold: 0 })
    farObserver = new IntersectionObserver((records) => {
      for (const record of records) {
        if (record.isIntersecting) continue
        const path = record.target.dataset.filePath
        const entry = path && sections.get(path)
        if (!entry || entry.gen !== jsGeneration) {
          farObserver.unobserve(record.target)
          continue
        }
        if (entry.mounted) unmountEditor(entry)
      }
    }, { root: null, rootMargin: `${UNMOUNT_MARGIN}px 0px`, threshold: 0 })
  }
}

function makeHeader(file, entry) {
  const header = document.createElement('div')
  header.className = 'diff-header'

  // Collapse chevron (GitHub-style per-file collapse).
  const chevron = document.createElement('button')
  chevron.className = 'collapse-btn'
  chevron.type = 'button'
  const syncChevron = () => {
    chevron.textContent = entry.collapsed ? '▸' : '▾'
    const label = entry.collapsed ? STR.expandSection : STR.collapseSection
    chevron.title = label
    chevron.setAttribute('aria-label', label)
  }
  syncChevron()
  chevron.addEventListener('click', () => {
    setCollapsed(entry, !entry.collapsed, true)
  })
  header.appendChild(chevron)
  entry.syncChevron = syncChevron

  const badge = document.createElement('span')
  badge.className = `status-badge ${STATUS_CLASS[file.status] || 'modified'}`
  badge.textContent = file.status || 'M'
  header.appendChild(badge)

  const path = document.createElement('span')
  path.className = 'file-path'
  path.textContent = file.filePath
  header.appendChild(path)

  // Copy button: always visible next to the file path, copies the full relative
  // path and flashes a checkmark as confirmation (Swift performs the actual
  // pasteboard write via the copyPath message; the DOM icon is just feedback).
  const copy = document.createElement('button')
  copy.className = 'copy-btn'
  copy.type = 'button'
  copy.title = STR.copyFile
  copy.setAttribute('aria-label', STR.copyFile)

  const copyIcon = document.createElementNS('http://www.w3.org/2000/svg', 'svg')
  copyIcon.setAttribute('viewBox', '0 0 16 16')
  copyIcon.classList.add('icon-copy')
  copyIcon.innerHTML =
    '<path d="M0 6.75C0 5.784.784 5 1.75 5h1.5a.75.75 0 0 1 0 1.5h-1.5a.25.25 0 0 0-.25.25v6.5c0 .138.112.25.25.25h6.5a.25.25 0 0 0 .25-.25v-1.5a.75.75 0 0 1 1.5 0v1.5A1.75 1.75 0 0 1 8.25 15h-6.5A1.75 1.75 0 0 1 0 13.25Zm5-5C5 .784 5.784 0 6.75 0h7.5C15.216 0 16 .784 16 1.75v7.5A1.75 1.75 0 0 1 14.25 11h-7.5A1.75 1.75 0 0 1 5 9.25Zm1.75-.25a.25.25 0 0 0-.25.25v7.5c0 .138.112.25.25.25h7.5a.25.25 0 0 0 .25-.25v-7.5a.25.25 0 0 0-.25-.25Z" />'
  const checkIcon = document.createElementNS('http://www.w3.org/2000/svg', 'svg')
  checkIcon.setAttribute('viewBox', '0 0 16 16')
  checkIcon.classList.add('icon-check')
  checkIcon.innerHTML =
    '<path d="M13.78 4.22a.75.75 0 0 1 0 1.06l-7.25 7.25a.75.75 0 0 1-1.06 0L2.22 9.28a.751.751 0 0 1 1.06-1.06L6 10.94l6.72-6.72a.75.75 0 0 1 1.06 0Z" />'

  const reset = () => {
    copy.classList.remove('copied')
    copy.title = STR.copyFile
    copy.setAttribute('aria-label', STR.copyFile)
  }
  copy.addEventListener('click', () => {
    postToSwift({ type: 'copyPath', filePath: file.filePath })
    copy.classList.add('copied')
    copy.title = STR.copied
    copy.setAttribute('aria-label', STR.copied)
    setTimeout(reset, 1500)
  })

  copy.appendChild(copyIcon)
  copy.appendChild(checkIcon)
  header.appendChild(copy)

  // Viewed checkbox (right-aligned, GitHub-style). State persists in Swift;
  // Swift clears it when the file's content changes under the mark.
  const viewedWrap = document.createElement('label')
  viewedWrap.className = 'viewed-wrap'
  const viewedBox = document.createElement('input')
  viewedBox.type = 'checkbox'
  viewedBox.className = 'viewed-box'
  viewedBox.checked = !!file.viewed
  viewedBox.title = STR.markViewed
  viewedBox.setAttribute('aria-label', STR.markViewed)
  viewedBox.addEventListener('change', () => {
    entry.section.classList.toggle('viewed', viewedBox.checked)
    postToSwift({ type: 'viewed', filePath: file.filePath, viewed: viewedBox.checked })
  })
  const viewedLabel = document.createElement('span')
  viewedLabel.className = 'viewed-label'
  viewedLabel.textContent = STR.viewed
  viewedWrap.appendChild(viewedBox)
  viewedWrap.appendChild(viewedLabel)
  header.appendChild(viewedWrap)
  entry.viewedBox = viewedBox

  return header
}

function setCollapsed(entry, collapsed, notify) {
  entry.collapsed = collapsed
  entry.section.classList.toggle('collapsed', collapsed)
  if (entry.syncChevron) entry.syncChevron()
  if (collapsed) {
    if (entry.mounted) unmountEditor(entry)
    else if (entry.host && mountObserver) mountObserver.unobserve(entry.host)
  } else {
    // Expanding: mount now when already near the viewport, otherwise the
    // mount observer picks it up on scroll. Deferred placeholders resume
    // scroll-into-view auto-upgrade.
    if (entry.mountable && !entry.mounted && entry.host) {
      if (mountObserver) mountObserver.observe(entry.host)
      if (isNearViewport(entry.host, MOUNT_MARGIN)) mountEditor(entry)
    } else if (!entry.mountable && entry.deferredNote && mountObserver) {
      mountObserver.observe(entry.deferredNote)
    }
  }
  if (notify) {
    postToSwift({ type: 'sectionToggled', filePath: entry.file.filePath, collapsed })
  }
}

function makePlaceholderHost(entry, file) {
  const host = document.createElement('div')
  host.className = 'diff-body unmounted'
  host.dataset.filePath = file.filePath
  host.style.height = `${calculateEditorHeight(file.originalText, file.modifiedText)}px`
  entry.host = host
  return host
}

// Normalize a wheel delta to pixels. Line-based (mouse wheels) and page-based
// deltas arrive unscaled in WKWebView; Monaco expects pixel deltas.
function scaleWheelDelta(raw, deltaMode) {
  if (deltaMode === WheelEvent.DOM_DELTA_LINE) return raw * LINE_HEIGHT
  if (deltaMode === WheelEvent.DOM_DELTA_PAGE) return raw * 100
  return raw
}

window.diffAPI = {
  setFiles(files, generation) {
    jsGeneration = (typeof generation === 'number') ? generation : jsGeneration + 1
    const myGen = jsGeneration
    reported = false
    if (safetyTimer) { clearTimeout(safetyTimer); safetyTimer = null }
    clearDiffs()
    ensureObservers()

    if (!files || files.length === 0) {
      emptyState.classList.add('visible')
      reportContentReady(myGen)
      return
    }
    emptyState.classList.remove('visible')

    // Safety: report ready after 5s even if some onDidUpdateDiff never fires.
    safetyTimer = setTimeout(() => reportContentReady(myGen), 5000)

    for (const file of files) {
      const section = document.createElement('div')
      section.className = 'diff-section'
      section.dataset.filePath = file.filePath
      const entry = {
        section, host: null, editor: null, original: null, modified: null,
        file, mountable: false, mounted: false, diffFired: false,
        collapsed: !!file.collapsed, gen: myGen
      }
      section.appendChild(makeHeader(file, entry))
      if (file.viewed) section.classList.add('viewed')
      if (entry.collapsed) section.classList.add('collapsed')

      if (file.binary) {
        const note = document.createElement('div')
        note.className = 'placeholder placeholder-binary'
        note.textContent = STR.binary
        section.appendChild(note)
        // Visibility while collapsed is driven purely by the section's
        // `collapsed` CSS class (no inline display toggles — they would
        // survive the expand and keep the body hidden).
        entry.collapseBody = note
        container.appendChild(section)
        sections.set(file.filePath, entry)
        continue
      }

      if (file.deferred) {
        const note = document.createElement('div')
        note.className = 'placeholder placeholder-large'
        note.dataset.filePath = file.filePath
        note.textContent = STR.largeFile.replace('%d', file.changedLines ?? 0)
        note.setAttribute('role', 'button')
        note.tabIndex = 0
        const request = () => {
          if (entry.loadingRequested) return
          entry.loadingRequested = true
          note.dataset.loading = '1'
          note.classList.add('loading')
          postToSwift({ type: 'loadFile', filePath: file.filePath })
        }
        note.addEventListener('click', request)
        note.addEventListener('keydown', (e) => {
          if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); request() }
        })
        section.appendChild(note)
        entry.collapseBody = note
        entry.deferredNote = note
        container.appendChild(section)
        sections.set(file.filePath, entry)
        // Auto-upgrade when scrolled near (click still works as fallback).
        if (!entry.collapsed && mountObserver) mountObserver.observe(note)
        continue
      }

      const host = makePlaceholderHost(entry, file)
      section.appendChild(host)
      entry.collapseBody = host
      entry.mountable = true
      container.appendChild(section)
      sections.set(file.filePath, entry)
    }

    // Mount what is already near the viewport synchronously-ish (chunked over
    // frames so a huge repo doesn't block first paint), then observe the rest.
    // contentReady waits only for THESE editors — below-the-fold files mount
    // (and diff) on scroll without holding the loading indicator.
    const mountables = []
    for (const entry of sections.values()) {
      if (!entry.mountable || entry.collapsed || !entry.host) continue
      if (isNearViewport(entry.host, MOUNT_MARGIN)) mountables.push(entry)
      else if (mountObserver) mountObserver.observe(entry.host)
    }
    pendingVisible = new Set(mountables.map(e => e.file.filePath))

    if (mountables.length === 0) {
      reportContentReady(myGen)
      return
    }
    const CHUNK = 4
    let i = 0
    const mountChunk = () => {
      if (myGen !== jsGeneration) return
      const slice = mountables.slice(i, i + CHUNK)
      for (const entry of slice) {
        mountEditor(entry)
        // Mounted editors still need scroll-away disposal tracking.
        if (mountObserver && entry.host) mountObserver.observe(entry.host)
      }
      i += CHUNK
      if (i < mountables.length) {
        requestAnimationFrame(mountChunk)
      } else if (pendingVisible.size === 0) {
        reportContentReady(myGen)
      }
    }
    requestAnimationFrame(mountChunk)
  },

  // Replace a deferred file's placeholder with a real diff editor in place.
  // Shared upgrade path for click-to-load AND scroll-into-view auto-upgrade.
  // Idempotent: duplicate deliveries (click + auto-upgrade racing) are ignored.
  loadFileContent(file) {
    const entry = sections.get(file.filePath)
    if (!entry || entry.gen !== jsGeneration) return
    if (entry.mountable) return
    const section = entry.section

    // Remove the placeholder note (keep the header).
    const placeholder = section.querySelector('.placeholder')
    if (placeholder) {
      if (mountObserver) mountObserver.unobserve(placeholder)
      placeholder.remove()
    }
    entry.deferredNote = null

    entry.file = { ...entry.file, ...file, deferred: false }
    entry.mountable = true
    const host = makePlaceholderHost(entry, entry.file)
    section.appendChild(host)
    entry.collapseBody = host
    if (entry.collapsed) return
    mountEditor(entry)
    if (mountObserver && host.isConnected) mountObserver.observe(host)
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
    jsGeneration++
    clearDiffs()
    emptyState.classList.add('visible')
    reportContentReady(jsGeneration)
  },

  layout() {
    for (const entry of sections.values()) {
      if (entry.editor) entry.editor.layout()
    }
  },

  // Set one file's Viewed checkbox from Swift (e.g. clearing a stale mark).
  setViewed(path, viewed) {
    const entry = sections.get(path)
    if (!entry) return
    if (entry.viewedBox) entry.viewedBox.checked = !!viewed
    entry.section.classList.toggle('viewed', !!viewed)
  },

  // Collapse/expand every section at once. Expanding mounts only sections
  // already near the viewport; the mount observer handles the rest on scroll.
  setAllCollapsed(collapsed) {
    for (const entry of sections.values()) {
      if (entry.collapsed === !!collapsed) continue
      setCollapsed(entry, !!collapsed, false)
    }
  },

  // Scroll the diff page so the given file's section is at the top of the
  // viewport. Works for normal, binary, and deferred (placeholder) files since
  // every file registers its section element in `sections` keyed by exact path.
  // Lazy placeholders are force-mounted first (expanding collapsed sections),
  // and navigation uses instant scrolling: smooth scrolling gets interrupted
  // by the layout shifts of editors still computing diffs and lands wrong.
  scrollToFile(path) {
    const entry = sections.get(path)
    if (!entry || !entry.section) return
    if (entry.collapsed) setCollapsed(entry, false, true)
    if (entry.mountable && !entry.mounted) {
      mountEditor(entry)
    } else if (!entry.mountable && !entry.loadingRequested) {
      // Navigated to an unloaded large file: start loading it immediately.
      entry.loadingRequested = true
      if (entry.deferredNote) {
        entry.deferredNote.dataset.loading = '1'
        entry.deferredNote.classList.add('loading')
      }
      postToSwift({ type: 'loadFile', filePath: path })
    }
    entry.section.scrollIntoView({ behavior: 'auto', block: 'start' })
    entry.section.classList.remove('flash')
    // Force reflow so a repeated navigation to the same file re-flashes.
    void entry.section.offsetWidth
    entry.section.classList.add('flash')
    setTimeout(() => entry.section.classList.remove('flash'), 1300)
  }
}

// Signal readiness to Swift (diffAPI available, no content yet).
postToSwift({ type: 'ready' })

setTimeout(() => document.body.classList.remove('loading'))
