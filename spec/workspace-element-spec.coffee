ipc = require 'ipc'
path = require 'path'
temp = require('temp').track()

describe "WorkspaceElement", ->
  describe "when the workspace element is focused", ->
    it "transfers focus to the active pane", ->
      workspaceElement = atom.views.getView(atom.workspace)
      jasmine.attachToDOM(workspaceElement)
      activePaneElement = atom.views.getView(atom.workspace.getActivePane())
      document.body.focus()
      expect(document.activeElement).not.toBe(activePaneElement)
      workspaceElement.focus()
      expect(document.activeElement).toBe(activePaneElement)

  describe "the scrollbar visibility class", ->
    it "has a class based on the style of the scrollbar", ->
      observeCallback = null
      scrollbarStyle = require 'scrollbar-style'
      spyOn(scrollbarStyle, 'observePreferredScrollbarStyle').andCallFake (cb) -> observeCallback = cb
      workspaceElement = atom.views.getView(atom.workspace)

      observeCallback('legacy')
      expect(workspaceElement.className).toMatch 'scrollbars-visible-always'

      observeCallback('overlay')
      expect(workspaceElement).toHaveClass 'scrollbars-visible-when-scrolling'

  describe "the 'window:toggle-invisibles' command", ->
    it "shows/hides invisibles in all open and future editors", ->
      workspaceElement = atom.views.getView(atom.workspace)
      expect(atom.config.get('editor.showInvisibles')).toBe false
      atom.commands.dispatch(workspaceElement, 'window:toggle-invisibles')
      expect(atom.config.get('editor.showInvisibles')).toBe true
      atom.commands.dispatch(workspaceElement, 'window:toggle-invisibles')
      expect(atom.config.get('editor.showInvisibles')).toBe false

  describe "the 'window:run-package-specs' command", ->
    it "runs the package specs for the active item's project path, or the first project path", ->
      workspaceElement = atom.views.getView(atom.workspace)
      spyOn(ipc, 'send')

      # No project paths. Don't try to run specs.
      atom.commands.dispatch(workspaceElement, "window:run-package-specs")
      expect(ipc.send).not.toHaveBeenCalledWith("run-package-specs")

      projectPaths = [temp.mkdirSync("dir1-"), temp.mkdirSync("dir2-")]
      atom.project.setPaths(projectPaths)

      # No active item. Use first project directory.
      atom.commands.dispatch(workspaceElement, "window:run-package-specs")
      expect(ipc.send).toHaveBeenCalledWith("run-package-specs", path.join(projectPaths[0], "spec"))
      ipc.send.reset()

      # Active item doesn't implement ::getPath(). Use first project directory.
      item = document.createElement("div")
      atom.workspace.getActivePane().activateItem(item)
      atom.commands.dispatch(workspaceElement, "window:run-package-specs")
      expect(ipc.send).toHaveBeenCalledWith("run-package-specs", path.join(projectPaths[0], "spec"))
      ipc.send.reset()

      # Active item has no path. Use first project directory.
      item.getPath = -> null
      atom.commands.dispatch(workspaceElement, "window:run-package-specs")
      expect(ipc.send).toHaveBeenCalledWith("run-package-specs", path.join(projectPaths[0], "spec"))
      ipc.send.reset()

      # Active item has path. Use project path for item path.
      item.getPath = -> path.join(projectPaths[1], "a-file.txt")
      atom.commands.dispatch(workspaceElement, "window:run-package-specs")
      expect(ipc.send).toHaveBeenCalledWith("run-package-specs", path.join(projectPaths[1], "spec"))
      ipc.send.reset()
