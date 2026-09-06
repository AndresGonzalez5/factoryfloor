import { monaco, configService, postToSwift } from './shared-init.js'

// --- Diff API ---
// Renders a vertical stack of inline diff editors, one per file. Swift sends
// metadata-only shells first (headers + placeholders paint synchronously),
// then streams each normal file's texts via loadFileContent, which upgrades
// its skeleton in place. Editors are
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
// Extra context lines assumed visible around changes in the pre-diff estimate.
// Deliberately small: underestimates grow (off-screen, invisible) once the
// diff is measured, while overestimates leave permanent blank scroll gaps.
const ESTIMATE_CONTEXT_LINES = 8
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
  viewed: 'Viewed',
  save: 'Save',
  revert: 'Revert',
  discardEdit: 'Discard unsaved edits',
  openInEditor: 'Open in Editor',
  unsavedChanges: 'Unsaved changes'
}

// Active sections keyed by file path:
// { section, host, editor, original, modified, file, mountable, mounted,
//   diffFired, collapsed, gen, dirty, cleanVersionId, contentListener,
//   contentSizeListener, syncEditUI, pendingBody, deferredNote, loadingRequested,
//   collapseBody, headerEl, viewedBox, syncChevron }
const sections = new Map()
// Path of the last-focused modified editor (sticky: updated on focus, never
// cleared on blur) so Cmd+S can save the file being typed in without a click.
// Reset on every setFiles/clear alongside the sections it points into.
let focusedPath = null
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
// Height is the max of both sides (mirroring VS Code's multi-diff editor, which
// sizes stacked items from the diff editor's combined content height): reading
// only the modified side under-measures pure-deletion hunks.
function resizeDiffEditor(diffEditor, host, gen) {
  if (gen !== jsGeneration) return
  const modifiedEditor = diffEditor.getModifiedEditor()
  const originalEditor = diffEditor.getOriginalEditor()
  const contentHeight = Math.max(
    modifiedEditor.getContentHeight(),
    originalEditor ? originalEditor.getContentHeight() : 0
  )
  const newHeight = Math.max(contentHeight + HEIGHT_PADDING, MIN_EDITOR_HEIGHT)
  // No-op when unchanged: breaks the layout→contentSizeChange→layout cycle
  // (the content-size listener below calls back into here on every change).
  if (host.style.height === `${newHeight}px`) return
  host.style.height = `${newHeight}px`
  diffEditor.layout()
}

// Dirty tracking for an editable mounted editor: version-id compare (same
// technique as main.js), reported to Swift so it can show progress + guard
// refreshes. Typing also resizes the host immediately so the page grows with
// the edit instead of waiting for the diff recompute.
function attachContentListener(entry) {
  const file = entry.file
  const host = entry.host
  const gen = entry.gen
  const diffEditor = entry.editor
  const modified = entry.modified
  if (!diffEditor || !modified) return
  entry.contentListener = modified.onDidChangeContent(() => {
    if (entry.gen !== jsGeneration) return
    const dirty = modified.getAlternativeVersionId() !== entry.cleanVersionId
    if (dirty !== entry.dirty) {
      entry.dirty = dirty
      if (entry.syncEditUI) entry.syncEditUI()
      postToSwift({ type: 'contentChanged', filePath: file.filePath, dirty })
    }
    resizeDiffEditor(diffEditor, host, gen)
  })
}

function disposeEditor(entry) {
  if (entry.contentListener) entry.contentListener.dispose()
  if (entry.contentSizeListener) entry.contentSizeListener.dispose()
  if (entry.editor) entry.editor.dispose()
  if (entry.original) entry.original.dispose()
  if (entry.modified) entry.modified.dispose()
  entry.editor = null
  entry.original = null
  entry.modified = null
  entry.contentListener = null
  entry.contentSizeListener = null
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
  focusedPath = null
  // Remove every child except the empty-state placeholder.
  for (const child of Array.from(container.children)) {
    if (child !== emptyState) child.remove()
  }
}

function isNearViewport(el, margin) {
  const r = el.getBoundingClientRect()
  return r.bottom >= -margin && r.top <= window.innerHeight + margin
}

// Mount every unmounted mountable section already near the viewport.
// Covers chunk turns lost to rAF stalls (hidden webview): those files are
// observed, but observation only fires on scroll — without this sweep they'd
// sit blank until the user scrolls or toggles collapse.
function sweepNearViewport(gen) {
  if (gen !== jsGeneration) return
  for (const entry of sections.values()) {
    if (entry.gen !== gen) continue
    if (!entry.mountable || entry.collapsed || entry.mounted || !entry.host) continue
    if (isNearViewport(entry.host, MOUNT_MARGIN)) mountEditor(entry)
  }
}

function mountEditor(entry) {
  if (entry.mounted || !entry.mountable || entry.collapsed) return
  if (entry.gen !== jsGeneration) return
  const host = entry.host
  if (!host) return
  // Defer creation while the page has no layout yet (e.g. setFiles racing a
  // tab-switch reparent): editors born in a zero-size host render blank and
  // never recover. The host stays observed, so the mount observer picks it up
  // once the container has size.
  if (host.clientWidth === 0) return
  const file = entry.file
  const gen = entry.gen
  host.classList.remove('unmounted')

  const original = monaco.editor.createModel(file.originalText ?? '', file.languageId || 'plaintext')
  const modified = monaco.editor.createModel(file.modifiedText ?? '', file.languageId || 'plaintext')

  // Uncommitted-mode files are editable in place (VS Code Source Control
  // style): only the modified side is writable, the original stays read-only.
  const editable = !!file.editable && file.status !== 'D'
  const options = editable
    ? { ...sharedDiffOptions, readOnly: false, originalEditable: false }
    : sharedDiffOptions
  const diffEditor = monaco.editor.createDiffEditor(host, options)
  diffEditor.setModel({ original, modified })

  // handleMouseWheel is off so vertical wheel events bubble to the page (the
  // page scrolls between files). But that also swallows horizontal gestures, so
  // route horizontal-dominant wheel events (trackpad swipe, shift+scroll) into
  // the diff editor's horizontal scroll. Vertical-dominant events are left to
  // the page so browsing between files keeps working.
  // Bound once per host (hosts survive unmount/remount cycles; re-adding
  // on every mount stacks duplicate handlers), so the editor is resolved
  // live at event time: closing over this mount's diffEditor would keep
  // driving the disposed editor after the next remount. Capture phase so an
  // inner Monaco scrollable can't stop propagation first; non-passive so
  // preventDefault is honored.
  if (!host.dataset.wheelBound) {
    host.dataset.wheelBound = '1'
    host.addEventListener('wheel', (e) => {
      const horizontalIntent = e.shiftKey && e.deltaY !== 0
      const dominantX = Math.abs(e.deltaX) > Math.abs(e.deltaY)
      if (!horizontalIntent && !dominantX) return
      const delta = scaleWheelDelta(
        horizontalIntent ? e.deltaY : e.deltaX,
        e.deltaMode
      )
      if (delta === 0) return
      const live = entry.editor?.getModifiedEditor()
      if (!live) return
      live.setScrollLeft(live.getScrollLeft() + delta)
      e.preventDefault()
    }, { capture: true, passive: false })
  }

  entry.editor = diffEditor
  entry.original = original
  entry.modified = modified
  entry.mounted = true
  if (farObserver && host.isConnected) farObserver.observe(host)

  // Dirty tracking for editable files (see attachContentListener).
  if (editable) {
    entry.cleanVersionId = modified.getAlternativeVersionId()
    entry.dirty = false
    // Sticky focus tracking for Cmd+S (dropped with the editor on dispose).
    diffEditor.getModifiedEditor().onDidFocusEditorText(() => { focusedPath = file.filePath })
    attachContentListener(entry)
  }

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

  // Resize on every content-size change (diff computed, unchanged regions
  // hidden/revealed, typing, wrapping). Same signal VS Code's own multi-diff
  // editor uses to size stacked items. onDidUpdateDiff alone is not enough: it
  // can fire before hideUnchangedRegions settles, permanently stranding the
  // host at full-file height (the giant-blank-gap bug). Guarded: the event is
  // absent from the public IDiffEditor typings (only on the widget runtime).
  if (typeof diffEditor.onDidContentSizeChange === 'function') {
    entry.contentSizeListener = diffEditor.onDidContentSizeChange(() => {
      if (entry.gen !== jsGeneration) return
      resizeDiffEditor(diffEditor, host, gen)
    })
  }
}

// Free a far-off-screen editor. The host keeps its measured pixel height, so
// disposal is scroll-position neutral; the mount observer remounts on return.
// Dirty (unsaved) editors are NEVER unmounted — disposal would drop the edit.
function unmountEditor(entry) {
  if (!entry.mounted) return
  if (entry.dirty) return
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
  entry.headerEl = header

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

  // Inline-edit controls (VS Code Source Control style). Only for editable
  // files with loaded content — deleted/binary/deferred placeholders never
  // get them here. Deferred files get them on upgrade (see loadFileContent),
  // and so do pending shells once their streamed bodies arrive: adding them
  // earlier would let Save persist the empty shell text over the real file.
  if (isEditCapable(file) && !file.deferred && !file.pending) {
    addEditControls(header, file, entry, null)
  }

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
    // GitHub-style: marking viewed collapses the file. Unchecking leaves the
    // collapsed state alone (expand via chevron). setCollapsed notifies Swift,
    // so persistence and the toolbar toggle mirror update automatically.
    if (viewedBox.checked) setCollapsed(entry, true, true)
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

// Whether a file can ever show inline-edit controls: flagged editable by
// Swift (uncommitted mode) and not deleted/binary. Deferred files qualify —
// their controls are added on upgrade once real content is loaded.
function isEditCapable(file) {
  return !!file.editable && file.status !== 'D' && !file.binary
}

// Build the Save / dirty-dot / Open-in-Editor header controls. `before` is
// an optional child to insert ahead of (used on deferred upgrade, where the
// Viewed checkbox already exists).
function addEditControls(header, file, entry, before) {
  if (entry.syncEditUI) return
  const dirtyDot = document.createElement('span')
  dirtyDot.className = 'dirty-dot'
  dirtyDot.textContent = '●'
  dirtyDot.title = STR.unsavedChanges
  dirtyDot.setAttribute('aria-label', STR.unsavedChanges)
  dirtyDot.hidden = true

  const save = document.createElement('button')
  save.className = 'save-btn'
  save.type = 'button'
  save.textContent = STR.save
  save.title = STR.unsavedChanges
  save.disabled = true
  save.addEventListener('click', () => {
    postToSwift({ type: 'saveFile', filePath: file.filePath })
  })

  const open = document.createElement('button')
  open.className = 'open-btn'
  open.type = 'button'
  open.textContent = '↗'
  open.title = STR.openInEditor
  open.setAttribute('aria-label', STR.openInEditor)
  open.addEventListener('click', () => {
    postToSwift({ type: 'openInEditor', filePath: file.filePath })
  })

  // Revert (VS Code Source Control style): drop the inline edit and restore
  // the last loaded text. The escape hatch for the refresh/mode-switch
  // guards, which block while any edit is unsaved.
  const revert = document.createElement('button')
  revert.className = 'save-btn'
  revert.type = 'button'
  revert.textContent = STR.revert
  revert.title = STR.discardEdit
  revert.setAttribute('aria-label', STR.discardEdit)
  revert.disabled = true
  revert.addEventListener('click', () => {
    postToSwift({ type: 'revertFile', filePath: file.filePath })
  })

  if (before) {
    header.insertBefore(dirtyDot, before)
    header.insertBefore(save, before)
    header.insertBefore(revert, before)
    header.insertBefore(open, before)
  } else {
    header.appendChild(dirtyDot)
    header.appendChild(save)
    header.appendChild(revert)
    header.appendChild(open)
  }

  entry.syncEditUI = () => {
    save.disabled = !entry.dirty
    revert.disabled = !entry.dirty
    dirtyDot.hidden = !entry.dirty
  }
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
  host.style.height = `${estimateEditorHeight(file)}px`
  entry.host = host
  return host
}

// Pre-diff host height. Estimated from the changed line count — not the full
// file length: hideUnchangedRegions folds everything else away, so full-file
// estimates reserve thousands of pixels of blank scroll space for sections
// that haven't measured yet. Underestimates are harmless (hosts grow on mount,
// ~1200px before becoming visible); overestimates are the blank-gap bug.
function estimateEditorHeight(file) {
  if (typeof file.changedLines === 'number' && file.changedLines >= 0) {
    const lines = file.changedLines + ESTIMATE_CONTEXT_LINES + PADDING_LINES
    return Math.max(lines * LINE_HEIGHT, MIN_EDITOR_HEIGHT)
  }
  return calculateEditorHeight(file.originalText, file.modifiedText)
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

    // Safety: after 5s, mount anything near that never got going (rAF stall)
    // and report ready even if some onDidUpdateDiff never fires.
    safetyTimer = setTimeout(() => {
      sweepNearViewport(myGen)
      reportContentReady(myGen)
    }, 5000)

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

      // Pending shells (shells-first transport): bodies stream in via
      // loadFileContent right after first paint. A textless shimmer block at
      // the estimated height — never observed, never clickable — upgraded by
      // the shared deferred path on delivery.
      if (file.pending) {
        const note = document.createElement('div')
        note.className = 'placeholder placeholder-pending'
        note.dataset.filePath = file.filePath
        note.style.minHeight = `${estimateEditorHeight(file)}px`
        section.appendChild(note)
        entry.collapseBody = note
        entry.pendingBody = true
        container.appendChild(section)
        sections.set(file.filePath, entry)
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
    // Every mountable host is observed up front: chunk-mounting below can
    // stall partway (rAF pauses while the webview is hidden), and a file that
    // misses its chunk turn would otherwise sit blank forever — no observer
    // would ever mount it on scroll. Collapse/expand only masked this.
    const mountables = []
    for (const entry of sections.values()) {
      if (!entry.mountable || entry.collapsed || !entry.host) continue
      if (mountObserver) mountObserver.observe(entry.host)
      if (isNearViewport(entry.host, MOUNT_MARGIN)) mountables.push(entry)
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
      }
      i += CHUNK
      if (i < mountables.length) {
        requestAnimationFrame(mountChunk)
      } else {
        // Queue drained: mount anything near that lost its turn to a stall.
        sweepNearViewport(myGen)
        if (pendingVisible.size === 0) reportContentReady(myGen)
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
    entry.pendingBody = false

    entry.file = { ...entry.file, ...file, deferred: false, pending: false }
    entry.mountable = true
    const host = makePlaceholderHost(entry, entry.file)
    section.appendChild(host)
    entry.collapseBody = host
    // Deferred files flagged editable gain their Save/Open controls now that
    // real content exists. Insert ahead of the Viewed checkbox (last child).
    if (isEditCapable(entry.file) && entry.headerEl) {
      addEditControls(entry.headerEl, entry.file, entry, entry.headerEl.lastChild)
    }
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

  // Current modified-side text for a file: live editor content when mounted,
  // otherwise the last loaded text. Swift reads this to persist an edit.
  getContent(path) {
    const entry = sections.get(path)
    if (!entry) return null
    if (entry.mounted && entry.modified) return entry.modified.getValue()
    return entry.file.modifiedText ?? null
  },

  // Ordered save targets for Cmd+S: the focused dirty file wins (the one
  // being typed in); else the selected tree file when dirty; else every dirty
  // file — an explicit Save persists all Changes-tab work. Empty when clean.
  saveTargets(selectedPath) {
    const dirty = []
    for (const [path, entry] of sections) {
      if (entry.dirty) dirty.push(path)
    }
    if (dirty.length === 0) return []
    if (focusedPath) {
      const focused = sections.get(focusedPath)
      if (focused && focused.dirty) return [focusedPath]
    }
    if (selectedPath && dirty.includes(selectedPath)) return [selectedPath]
    return dirty
  },

  // Mark a model as clean (after save). Always clears the JS dirty flag —
  // even when unmounted — so the JS mirror can never disagree with Swift's.
  markClean(path) {
    const entry = sections.get(path)
    if (!entry) return
    entry.dirty = false
    if (entry.syncEditUI) entry.syncEditUI()
    if (!entry.mounted || !entry.modified) return
    entry.cleanVersionId = entry.modified.getAlternativeVersionId()
  },

  // Replace a file's texts in place (revert-to-disk, post-save refresh):
  // updates the stored texts and, when mounted, both live models. The dirty
  // listener is detached across the programmatic set so no spurious
  // contentChanged messages escape; Swift clears its own mirrors after this
  // returns. No-op for unknown paths or superseded generations.
  setFileContent(payload) {
    const entry = sections.get(payload?.filePath)
    if (!entry || entry.gen !== jsGeneration) return
    const originalText = payload.originalText ?? ''
    const modifiedText = payload.modifiedText ?? ''
    entry.file = { ...entry.file, originalText, modifiedText }
    if (entry.mounted && entry.editor && entry.original && entry.modified) {
      if (entry.contentListener) entry.contentListener.dispose()
      entry.contentListener = null
      entry.original.setValue(originalText)
      entry.modified.setValue(modifiedText)
      entry.cleanVersionId = entry.modified.getAlternativeVersionId()
      entry.dirty = false
      if (entry.syncEditUI) entry.syncEditUI()
      if (entry.file.editable && entry.file.status !== 'D') attachContentListener(entry)
      resizeDiffEditor(entry.editor, entry.host, entry.gen)
    } else {
      entry.dirty = false
      if (entry.syncEditUI) entry.syncEditUI()
    }
  },

  // Drop one file's section entirely (post-delete prune while other dirty
  // files block a full reload). Disposes its editor; scroll neighbors keep
  // their measured heights so the removal is position-neutral for them.
  removeFile(path) {
    const entry = sections.get(path)
    if (!entry || entry.gen !== jsGeneration) return
    if (mountObserver) {
      if (entry.host) mountObserver.unobserve(entry.host)
      if (entry.deferredNote) mountObserver.unobserve(entry.deferredNote)
    }
    if (farObserver && entry.host) farObserver.unobserve(entry.host)
    disposeSection(entry)
    if (entry.section) entry.section.remove()
    sections.delete(path)
    pendingVisible.delete(path)
    if (focusedPath === path) focusedPath = null
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
  // Per-entry guard: one failing section (e.g. a Monaco mount throwing after
  // its class already toggled) must never abort the loop and strand the rest
  // in the old state. Failures are reported to Swift for diagnosis.
  setAllCollapsed(collapsed) {
    for (const entry of sections.values()) {
      if (entry.collapsed === !!collapsed) continue
      try {
        setCollapsed(entry, !!collapsed, false)
      } catch (e) {
        postToSwift({ type: 'error', message: `setAllCollapsed failed for ${entry.file?.filePath}: ${e?.message ?? e}` })
      }
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
