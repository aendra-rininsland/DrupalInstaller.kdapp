class DrupalApp extends JView

  constructor:->

    super

    @listenWindowResize()

    @dashboardTabs = new KDTabView
      hideHandleCloseIcons : yes
      hideHandleContainer  : yes
      cssClass             : "wp-installer-tabs"

    @consoleToggle = new KDToggleButton
      states        : [
        "Console",(callback)->
          @setClass "toggle"
          split.resizePanel 250, 0
          callback null
        "Console &times;",(callback)->
          @unsetClass "toggle"
          split.resizePanel 0, 1
          callback null
      ]
    @buttonGroup = new KDButtonGroupView
      buttons       :
        "Dashboard" :
          cssClass  : "clean-gray toggle"
          callback  : => @dashboardTabs.showPaneByIndex 0
        "Install a new Drupal" :
          cssClass  : "clean-gray"
          callback  : => @dashboardTabs.showPaneByIndex 1

    @dashboardTabs.on "PaneDidShow", (pane)=>
      if pane.name is "dashboard"
        @buttonGroup.buttonReceivedClick @buttonGroup.buttons.Dashboard
      else
        @buttonGroup.buttonReceivedClick @buttonGroup.buttons["Install a new Drupal"]

  viewAppended:->

    super

    @dashboardTabs.addPane dashboard = new DashboardPane
      cssClass : "dashboard"
      name     : "dashboard"

    @dashboardTabs.addPane installPane = new InstallPane
      name     : "install"

    @dashboardTabs.showPane dashboard

    installPane.on "WordPressInstalled", (formData)->
      {domain, path} = formData
      dashboard.putNewItem formData
      KD.utils.wait 200, ->
        # timed out because we give some time to server to cleanup the temp files until it filetree refreshes
        tc.refreshFolder tc.nodes["/Users/#{nickname}/Sites/#{domain}/website"], ->
          KD.utils.wait 200, ->
            tc.selectNode tc.nodes["/Users/#{nickname}/Sites/#{domain}/website/#{path}"]

    @_windowDidResize()

  _windowDidResize:->

    @dashboardTabs.setHeight @getHeight() - @$('>header').height()

  pistachio:->

    """
    <header>
      <figure></figure>
      <article>
        <h3>Drupal Installer</h3>
        <p>This application installs Drupal instances and gives you a dashboard of what is already installed</p>
      </article>
      <section>
      {{> @buttonGroup}}
      {{> @consoleToggle}}
      </section>
    </header>
    {{> @dashboardTabs}}
    """

class DrupalSplit extends KDSplitView

  constructor:(options, data)->

    @output = new KDScrollView
      tagName  : "pre"
      cssClass : "terminal-screen"

    @drupalApp = new DrupalApp

    options.views = [ @drupalApp, @output ]

    super options, data

  viewAppended:->

    super

    @panels[1].setClass "terminal-tab"

class Pane extends KDTabPaneView

  viewAppended:->

    @setTemplate @pistachio()
    @template.update()
